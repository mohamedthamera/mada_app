import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const PAYMENT_REDIRECT_BASE =
  Deno.env.get("PAYMENT_REDIRECT_BASE") ?? "https://example-pay.test/session/";

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }
  const supabaseAuth = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: {
      headers: { Authorization: req.headers.get("Authorization") ?? "" },
    },
  });
  const { data: userData, error: userErr } = await supabaseAuth.auth.getUser();
  if (userErr || !userData?.user) {
    return new Response("Unauthorized", { status: 401 });
  }
  const body = await req.json().catch(() => ({}));
  const provider = String(body.provider ?? "custom");
  const amount = Number(body.amount ?? 0);
  const currency = String(body.currency ?? "USD").toUpperCase();
  if (!(amount > 0)) {
    return new Response(JSON.stringify({ error: "invalid_amount" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }
  const provider_ref = crypto.randomUUID();
  const payment_url = `${PAYMENT_REDIRECT_BASE}${provider_ref}`;
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const { error } = await supabase.from("payments").insert({
    user_id: userData.user.id,
    provider,
    amount,
    currency,
    status: "pending",
    provider_ref,
    raw_payload: { payment_url },
  });
  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }
  return new Response(JSON.stringify({ payment_url, provider_ref }), {
    headers: { "Content-Type": "application/json" },
  });
});
