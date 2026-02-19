import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const ADMIN_EMAIL = (Deno.env.get("ADMIN_EMAIL") ?? "").trim().toLowerCase();
const APPLE_SHARED_SECRET = Deno.env.get("APPLE_SHARED_SECRET") ?? "";
const GOOGLE_PLAY_SERVICE_ACCOUNT_JSON = Deno.env.get(
  "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON",
) ?? "";
const ANDROID_PACKAGE_NAME = (Deno.env.get("ANDROID_PACKAGE_NAME") ?? "").trim();

const LIFETIME_PRODUCT_ID = "lifetime_all_access";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Platform = "ios" | "android";

interface RequestBody {
  platform: Platform;
  product_id: string;
  receipt_data_base64?: string;
  purchase_token?: string;
  package_name?: string;
  mock?: boolean;
}

interface VerifyResponse {
  ok: boolean;
  lifetime_access: boolean;
  platform?: string;
  product_id?: string;
  code?: string;
  message?: string;
}

interface AppleVerifyResponse {
  status: number;
  receipt?: {
    in_app?: Array<{
      product_id: string;
      original_transaction_id: string;
      transaction_id: string;
    }>;
  };
  latest_receipt_info?: Array<{
    product_id: string;
    original_transaction_id: string;
    transaction_id: string;
  }>;
}

function jsonResponse(body: VerifyResponse, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

function log(msg: string, data?: Record<string, unknown>) {
  const safe = data ? ` ${JSON.stringify(data)}` : "";
  console.log(`[verify_lifetime] ${msg}${safe}`);
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse(
      { ok: false, lifetime_access: false, code: "METHOD_NOT_ALLOWED", message: "Method not allowed" },
      405,
    );
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonResponse(
      { ok: false, lifetime_access: false, code: "UNAUTHORIZED", message: "Invalid or missing JWT" },
      401,
    );
  }

  const supabaseAuth = createClient(SUPABASE_URL, Deno.env.get("SUPABASE_ANON_KEY") ?? "", {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: userData, error: userError } = await supabaseAuth.auth.getUser();
  if (userError || !userData?.user) {
    log("auth failed", { error: userError?.message ?? "no user" });
    return jsonResponse(
      { ok: false, lifetime_access: false, code: "UNAUTHORIZED", message: "Invalid or missing JWT" },
      401,
    );
  }

  const userId = userData.user.id;
  const userEmail = (userData.user.email ?? "").toLowerCase();

  let body: RequestBody;
  try {
    body = (await req.json()) as RequestBody;
  } catch {
    return jsonResponse(
      { ok: false, lifetime_access: false, code: "INVALID_BODY", message: "Invalid JSON body" },
      400,
    );
  }

  const platform = body.platform as Platform | undefined;
  const productId = String(body.product_id ?? "").trim();
  const mock = body.mock === true;

  if (!platform || !["ios", "android"].includes(platform)) {
    return jsonResponse(
      { ok: false, lifetime_access: false, code: "INVALID_PLATFORM", message: "Invalid platform" },
      400,
    );
  }

  if (productId !== LIFETIME_PRODUCT_ID) {
    return jsonResponse(
      { ok: false, lifetime_access: false, code: "INVALID_PRODUCT", message: "Invalid product_id" },
      400,
    );
  }

  const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  // ---------- MOCK MODE: only allow admin email ----------
  if (mock) {
    if (!ADMIN_EMAIL || userEmail !== ADMIN_EMAIL) {
      log("mock denied", { userEmail: userEmail ? "***" : "none" });
      return jsonResponse(
        {
          ok: false,
          lifetime_access: false,
          code: "MOCK_DENIED",
          message: "Mock mode: only admin email can grant lifetime",
        },
        403,
      );
    }

    const { error: upsertErr } = await supabaseAdmin.from("entitlements").upsert(
      {
        user_id: userId,
        lifetime_access: true,
        platform,
        product_id: productId,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "user_id" },
    );

    if (upsertErr) {
      log("mock upsert error", { code: upsertErr.code });
      return jsonResponse(
        { ok: false, lifetime_access: false, code: "DB_ERROR", message: "Server error" },
        500,
      );
    }

    return jsonResponse({
      ok: true,
      lifetime_access: true,
      platform,
      product_id: productId,
    });
  }

  // ---------- REAL MODE: iOS ----------
  if (platform === "ios") {
    const receiptDataBase64 = body.receipt_data_base64?.trim();
    if (!receiptDataBase64) {
      return jsonResponse(
        { ok: false, lifetime_access: false, code: "RECEIPT_MISSING", message: "Missing receipt_data_base64" },
        400,
      );
    }

    const appleResult = await verifyAppleReceipt(receiptDataBase64);
    if (!appleResult.valid) {
      log("Apple verify failed", { status: appleResult.error });
      return jsonResponse(
        {
          ok: false,
          lifetime_access: false,
          code: "APPLE_VERIFY_FAILED",
          message: appleResult.error ?? "Apple verification failed",
        },
        400,
      );
    }

    const iosRow: Record<string, unknown> = {
      user_id: userId,
      lifetime_access: true,
      platform: "ios",
      product_id: productId,
      updated_at: new Date().toISOString(),
    };
    if (appleResult.originalTransactionId)
      iosRow.ios_original_transaction_id = appleResult.originalTransactionId;
    if (appleResult.transactionId)
      iosRow.ios_latest_transaction_id = appleResult.transactionId;

    const { error: upsertErr } = await supabaseAdmin
      .from("entitlements")
      .upsert(iosRow, { onConflict: "user_id" });

    if (upsertErr) {
      log("iOS upsert error", { code: upsertErr.code });
      return jsonResponse(
        { ok: false, lifetime_access: false, code: "DB_ERROR", message: "Server error" },
        500,
      );
    }

    return jsonResponse({
      ok: true,
      lifetime_access: true,
      platform: "ios",
      product_id: productId,
    });
  }

  // ---------- REAL MODE: Android ----------
  const purchaseToken = body.purchase_token?.trim();
  const clientPackageName = body.package_name?.trim();

  if (!purchaseToken) {
    return jsonResponse(
      { ok: false, lifetime_access: false, code: "PURCHASE_TOKEN_MISSING", message: "Missing purchase_token" },
      400,
    );
  }

  if (!ANDROID_PACKAGE_NAME) {
    log("Android config missing: ANDROID_PACKAGE_NAME");
    return jsonResponse(
      { ok: false, lifetime_access: false, code: "CONFIG_ERROR", message: "Server configuration error" },
      500,
    );
  }

  if (clientPackageName && clientPackageName !== ANDROID_PACKAGE_NAME) {
    log("Package name mismatch", { expected: ANDROID_PACKAGE_NAME });
    return jsonResponse(
      { ok: false, lifetime_access: false, code: "PACKAGE_MISMATCH", message: "Invalid request" },
      400,
    );
  }

  if (!GOOGLE_PLAY_SERVICE_ACCOUNT_JSON) {
    log("Android config missing: GOOGLE_PLAY_SERVICE_ACCOUNT_JSON");
    return jsonResponse(
      { ok: false, lifetime_access: false, code: "CONFIG_ERROR", message: "Server configuration error" },
      500,
    );
  }

  const googleResult = await verifyGooglePurchase(
    purchaseToken,
    productId,
    ANDROID_PACKAGE_NAME,
    GOOGLE_PLAY_SERVICE_ACCOUNT_JSON,
  );

  if (!googleResult.valid) {
    log("Google verify failed", { code: googleResult.code });
    return jsonResponse(
      {
        ok: false,
        lifetime_access: false,
        code: "GOOGLE_VERIFY_FAILED",
        message: googleResult.message ?? "Google Play verification failed",
      },
      400,
    );
  }

  const { error: upsertErr } = await supabaseAdmin.from("entitlements").upsert(
    {
      user_id: userId,
      lifetime_access: true,
      platform: "android",
      product_id: productId,
      android_purchase_token: purchaseToken,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "user_id" },
  );

  if (upsertErr) {
    log("Android upsert error", { code: upsertErr.code });
    return jsonResponse(
      { ok: false, lifetime_access: false, code: "DB_ERROR", message: "Server error" },
      500,
    );
  }

  return jsonResponse({
    ok: true,
    lifetime_access: true,
    platform: "android",
    product_id: productId,
  });
});

// ---------- Apple verifyReceipt ----------
async function verifyAppleReceipt(
  receiptDataBase64: string,
): Promise<{
  valid: boolean;
  originalTransactionId?: string;
  transactionId?: string;
  error?: string;
}> {
  const payload: Record<string, string> = {
    "receipt-data": receiptDataBase64,
  };
  if (APPLE_SHARED_SECRET) {
    payload.password = APPLE_SHARED_SECRET;
  }

  const productionUrl = "https://buy.itunes.apple.com/verifyReceipt";
  const sandboxUrl = "https://sandbox.itunes.apple.com/verifyReceipt";

  let res = await fetch(productionUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  let data: AppleVerifyResponse = await res.json().catch(() => ({}));

  if (data.status === 21007) {
    res = await fetch(sandboxUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    data = await res.json().catch(() => ({}));
  }

  if (data.status !== 0) {
    return {
      valid: false,
      error: `Apple status ${data.status}`,
    };
  }

  const inApp = data.receipt?.in_app ?? [];
  const latest = data.latest_receipt_info ?? [];
  const all = [...inApp, ...latest];
  const our = all.find((t) => t.product_id === LIFETIME_PRODUCT_ID);
  if (!our) {
    return { valid: false, error: "Product not found in receipt" };
  }

  return {
    valid: true,
    originalTransactionId: our.original_transaction_id,
    transactionId: our.transaction_id,
  };
}

// ---------- Google Play: purchases.products.get (one-time product) ----------
async function verifyGooglePurchase(
  purchaseToken: string,
  productId: string,
  packageName: string,
  serviceAccountJson: string,
): Promise<{ valid: boolean; code?: string; message?: string }> {
  try {
    const sa = JSON.parse(serviceAccountJson) as {
      client_email?: string;
      private_key?: string;
    };
    const clientEmail = sa.client_email;
    const privateKey = sa.private_key?.replace(/\\n/g, "\n");
    if (!clientEmail || !privateKey) {
      return { valid: false, code: "INVALID_SA", message: "Invalid service account JSON" };
    }

    const jwt = await createGoogleJwt(clientEmail, privateKey);
    const accessToken = await getGoogleAccessToken(jwt);

    const url =
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;

    const res = await fetch(url, {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });

    if (!res.ok) {
      const text = await res.text();
      log("Google API error", { status: res.status });
      return {
        valid: false,
        code: "GOOGLE_API_ERROR",
        message: res.status === 404 ? "Purchase not found or expired" : "Verification failed",
      };
    }

    const purchase = await res.json() as {
      purchaseState?: number;
      productId?: string;
    };

    // purchaseState: 0 = Purchased, 1 = Canceled, 2 = Pending
    if (purchase.purchaseState !== 0) {
      return {
        valid: false,
        code: "NOT_PURCHASED",
        message: purchase.purchaseState === 1 ? "Purchase was canceled" : "Purchase not completed",
      };
    }

    if (purchase.productId && purchase.productId !== productId) {
      return { valid: false, code: "PRODUCT_MISMATCH", message: "Product ID mismatch" };
    }

    return { valid: true };
  } catch (e) {
    log("Google verify exception", { msg: (e as Error).message });
    return {
      valid: false,
      code: "GOOGLE_VERIFY_FAILED",
      message: "Verification failed",
    };
  }
}

function createGoogleJwt(
  clientEmail: string,
  privateKey: string,
): Promise<string> {
  const header = btoa(
    JSON.stringify({ alg: "RS256", typ: "JWT" }),
  ).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  const now = Math.floor(Date.now() / 1000);
  const payload = btoa(
    JSON.stringify({
      iss: clientEmail,
      scope: "https://www.googleapis.com/auth/androidpublisher",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  ).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  const signatureInput = `${header}.${payload}`;

  return crypto.subtle
    .importKey(
      "pkcs8",
      pemToArrayBuffer(privateKey),
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"],
    )
    .then((key) =>
      crypto.subtle.sign(
        "RSASSA-PKCS1-v1_5",
        key,
        new TextEncoder().encode(signatureInput),
      )
    )
    .then((sig) => {
      const signature = btoa(String.fromCharCode(...new Uint8Array(sig)))
        .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
      return `${signatureInput}.${signature}`;
    });
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const lines = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binary = Uint8Array.from(atob(lines), (c) => c.charCodeAt(0));
  return binary.buffer;
}

async function getGoogleAccessToken(jwt: string): Promise<string> {
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Google OAuth error: ${res.status}`);
  }

  const data = await res.json() as { access_token?: string };
  return data.access_token ?? "";
}
