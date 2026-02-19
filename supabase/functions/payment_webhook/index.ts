import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { timingSafeEqual } from "https://deno.land/std@0.224.0/crypto/timing_safe_equal.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const WEBHOOK_SECRET = Deno.env.get("WEBHOOK_SECRET") ?? "";

async function validSignature(req: Request, raw: Uint8Array) {
  const sig = req.headers.get("x-signature") ?? "";
  if (!sig || !WEBHOOK_SECRET) return false;
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(WEBHOOK_SECRET), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const mac = await crypto.subtle.sign("HMAC", key, raw);
  const hex = Array.from(new Uint8Array(mac)).map((b) => b.toString(16).padStart(2, "0")).join("");
  try {
    const a = new TextEncoder().encode(hex);
    const b = new TextEncoder().encode(sig);
    return a.length === b.length && timingSafeEqual(a, b);
  } catch {
    return false;
  }
}

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }
  const raw = new Uint8Array(await req.arrayBuffer());
  const ok = await validSignature(req, raw);
  if (!ok) {
    return new Response("Unauthorized", { status: 401 });
  }
  const payload = JSON.parse(new TextDecoder().decode(raw));
  const provider_ref = String(payload.provider_ref ?? "");
  const status = String(payload.status ?? "");
  const user_id = String(payload.user_id ?? "");
  if (!provider_ref) {
    return new Response(JSON.stringify({ error: "missing_provider_ref" }), { status: 400, headers: { "Content-Type": "application/json" } });
  }
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  if (status === "paid") {
    const { data: payRows, error: payErr } = await supabase.from("payments").update({ status: "paid", verified_at: new Date().toISOString(), raw_payload: payload }).eq("provider_ref", provider_ref).select("user_id").limit(1);
    if (payErr) {
      return new Response(JSON.stringify({ error: payErr.message }), { status: 400, headers: { "Content-Type": "application/json" } });
    }
    const uid = payRows && payRows.length > 0 ? payRows[0].user_id : user_id || null;
    if (uid) {
      await supabase.from("user_subscriptions").upsert({ user_id: uid, is_lifetime: true, source: "gateway", activated_at: new Date().toISOString() });
    }
  } else if (status === "failed" || status === "canceled") {
    await supabase.from("payments").update({ status, raw_payload: payload }).eq("provider_ref", provider_ref);
  }
  return new Response(JSON.stringify({ ok: true }), { headers: { "Content-Type": "application/json" } });
});*** End Patch```  }}}}}  }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} }}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
