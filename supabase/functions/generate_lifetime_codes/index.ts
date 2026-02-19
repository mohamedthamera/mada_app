import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const ADMIN_EMAILS = (Deno.env.get("ADMIN_EMAILS") ?? "")
  .split(",")
  .map((e) => e.trim().toLowerCase())
  .filter(Boolean);

function randomCode(prefix: string) {
  const rand = crypto.randomUUID().replace(/-/g, "").slice(0, 16).toUpperCase();
  const parts = rand.match(/.{1,4}/g) ?? [rand];
  return `${prefix}${parts.join("-")}`;
}

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}

serve(async (req) => {
  console.log("=== HIT: generate_lifetime_codes ===");
  console.log("Method:", req.method);
  console.log("URL:", req.url);

  // Handle CORS preflight request
  if (req.method === "OPTIONS") {
    console.log("CORS preflight request");
    return new Response("ok", {
      status: 200,
      headers: corsHeaders(),
    });
  }

  if (req.method !== "POST") {
    console.log("Method not allowed:", req.method);
    return new Response(
      JSON.stringify({ ok: false, message: "Method not allowed" }),
      {
        status: 405,
        headers: { "Content-Type": "application/json", ...corsHeaders() },
      },
    );
  }

  const authHeader = req.headers.get("Authorization");
  console.log("Authorization header exists:", !!authHeader);
  if (authHeader) {
    console.log("Token length:", authHeader.length);
    console.log("Starts with Bearer:", authHeader.startsWith("Bearer "));
  }

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    console.log("Missing or invalid authorization header");
    return new Response(
      JSON.stringify({ ok: false, message: "Invalid or missing JWT" }),
      {
        status: 401,
        headers: { "Content-Type": "application/json", ...corsHeaders() },
      },
    );
  }

  try {
    console.log("Creating Supabase client for auth verification...");
    // Use the user's JWT to create a Supabase client
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: {
        headers: { Authorization: authHeader },
      },
    });

    console.log("Getting user from JWT...");
    const { data: userData, error: userError } = await supabase.auth.getUser();

    console.log("Auth getUser success:", !userError);
    if (userError) {
      console.log("JWT verification failed:", userError.message);
    }
    if (userData?.user) {
      console.log("User data found:", userData.user.email);
    }

    if (userError) {
      return new Response(
        JSON.stringify({ ok: false, message: "Invalid or missing JWT" }),
        {
          status: 401,
          headers: { "Content-Type": "application/json", ...corsHeaders() },
        },
      );
    }

    if (!userData?.user) {
      console.log("No user data found");
      return new Response(
        JSON.stringify({ ok: false, message: "Invalid or missing JWT" }),
        {
          status: 401,
          headers: { "Content-Type": "application/json", ...corsHeaders() },
        },
      );
    }

    const email = userData.user.email?.toLowerCase();
    const userId = userData.user.id;

    console.log("User authenticated:", { email, userId });
    console.log("Admin emails list:", ADMIN_EMAILS);
    console.log(
      "Is admin by email:",
      email,
      "in",
      ADMIN_EMAILS,
      "=",
      ADMIN_EMAILS.includes(email || ""),
    );

    if (!email) {
      console.log("No email found in user data");
      return new Response(
        JSON.stringify({ ok: false, message: "Invalid or missing JWT" }),
        {
          status: 401,
          headers: { "Content-Type": "application/json", ...corsHeaders() },
        },
      );
    }

    // Check admin role from profiles table (preferred) via service role, and allowlist fallback
    const supabaseAdminForRole = createClient(
      SUPABASE_URL,
      SUPABASE_SERVICE_ROLE_KEY,
    );
    const { data: profileRow, error: profileErr } = await supabaseAdminForRole
      .from("profiles")
      .select("role")
      .eq("id", userId)
      .maybeSingle();

    const role = profileRow?.role ?? null;
    const isAdminByRole = role === "admin";
    const isAdminByEmail = ADMIN_EMAILS.includes(email || "");

    console.log("Profile role fetch error:", !!profileErr, "role:", role);
    console.log("Is admin by role:", isAdminByRole);
    console.log("Is admin by email (fallback):", isAdminByEmail);

    if (!isAdminByRole && !isAdminByEmail) {
      console.log("Access denied: user is not admin");
      return new Response(
        JSON.stringify({
          ok: false,
          message: "Forbidden: not admin",
          details: "User role must be 'admin' or email in ADMIN_EMAILS",
          adminEmails: ADMIN_EMAILS,
          userEmail: email,
          role,
        }),
        {
          status: 403,
          headers: { "Content-Type": "application/json", ...corsHeaders() },
        },
      );
    }

    console.log("Admin access granted, processing request...");
    const body = await req.json().catch(() => ({}));
    console.log("Request body:", body);

    const count = Math.max(1, Math.min(Number(body.count ?? 10), 1000));
    const prefix = String(body.prefix ?? "").toUpperCase();
    const expires_at = body.expires_at ? new Date(body.expires_at) : null;
    const max_redemptions = Math.max(
      1,
      Math.min(Number(body.max_redemptions ?? 1), 1000),
    );

    console.log("Generating codes:", {
      count,
      prefix,
      expires_at,
      max_redemptions,
    });

    const codes: Array<{
      code: string;
      created_by: string;
      expires_at: string | null;
      max_redemptions: number;
    }> = [];

    for (let i = 0; i < count; i++) {
      codes.push({
        code: randomCode(prefix ? `${prefix}-` : ""),
        created_by: userId,
        expires_at: expires_at ? expires_at.toISOString() : null,
        max_redemptions,
      });
    }

    console.log("Inserting codes into database...");
    const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { data, error } = await supabaseAdmin
      .from("lifetime_codes")
      .insert(codes)
      .select("code, expires_at, max_redemptions, created_at");

    if (error) {
      console.log("Database error:", error);
      return new Response(
        JSON.stringify({
          ok: false,
          message: "Database error",
          details: error.message,
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json", ...corsHeaders() },
        },
      );
    }

    // Generate CSV for download
    const csvLines = ["code,expires_at,max_redemptions"];
    data?.forEach((code: any) => {
      csvLines.push(
        `"${code.code}","${code.expires_at ?? ""}","${code.max_redemptions}"`,
      );
    });
    const csv = csvLines.join("\n");

    console.log("Successfully generated codes:", data?.length || 0);
    return new Response(
      JSON.stringify({
        ok: true,
        codes: data,
        csv: csv,
        count: data?.length || 0,
      }),
      {
        headers: { "Content-Type": "application/json", ...corsHeaders() },
      },
    );
  } catch (error: any) {
    console.log("Unexpected error:", error);
    return new Response(
      JSON.stringify({
        ok: false,
        message: "Internal server error",
        details: error.message,
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders() },
      },
    );
  }
});
