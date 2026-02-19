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

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}

function jsonResponse(body: object, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders() },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200, headers: corsHeaders() });
  }

  if (req.method !== "POST") {
    return jsonResponse({ ok: false, message: "Method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonResponse({ ok: false, message: "Invalid or missing JWT" }, 401);
  }

  try {
    const supabaseAuth = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userError } =
      await supabaseAuth.auth.getUser();
    if (userError || !userData?.user) {
      return jsonResponse({ ok: false, message: "Invalid or missing JWT" }, 401);
    }

    const email = userData.user.email?.toLowerCase();
    const userId = userData.user.id;
    if (!email) {
      return jsonResponse({ ok: false, message: "No email" }, 401);
    }

    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { data: profileRow } = await adminClient
      .from("profiles")
      .select("role")
      .eq("id", userId)
      .maybeSingle();
    const role = (profileRow?.role ?? "").toString().trim().toLowerCase();
    const isAdminByRole = role.includes("admin");
    const isAdminByEmail = ADMIN_EMAILS.includes(email);

    if (!isAdminByRole && !isAdminByEmail) {
      return jsonResponse(
        { ok: false, message: "Forbidden: not admin" },
        403
      );
    }

    const body = await req.json().catch(() => ({}));
    const action = String(body?.action ?? "").toLowerCase();

    switch (action) {
      case "create": {
        const name = String(body?.name ?? "").trim();
        const code = String(body?.code ?? "").trim().toUpperCase();
        if (!name || !code) {
          return jsonResponse({
            ok: false,
            message: "name and code are required",
          }, 400);
        }
        const { data, error } = await adminClient
          .from("influencers")
          .insert({ name, code })
          .select("id, name, code, is_active, created_at")
          .single();
        if (error) {
          if (error.code === "23505") {
            return jsonResponse({
              ok: false,
              message: "Code already exists",
            }, 400);
          }
          return jsonResponse({
            ok: false,
            message: error.message,
          }, 400);
        }
        return jsonResponse({ ok: true, influencer: data });
      }

      case "toggle_active": {
        const id = body?.id;
        if (!id) {
          return jsonResponse({ ok: false, message: "id required" }, 400);
        }
        const { data: row } = await adminClient
          .from("influencers")
          .select("is_active")
          .eq("id", id)
          .is("deleted_at", null)
          .maybeSingle();
        if (!row) {
          return jsonResponse({ ok: false, message: "Influencer not found" }, 404);
        }
        const newActive = !row.is_active;
        const { error } = await adminClient
          .from("influencers")
          .update({ is_active: newActive })
          .eq("id", id);
        if (error) {
          return jsonResponse({ ok: false, message: error.message }, 400);
        }
        return jsonResponse({ ok: true, is_active: newActive });
      }

      case "list": {
        const { data, error } = await adminClient
          .from("influencer_stats")
          .select("*")
          .order("total_users", { ascending: false });
        if (error) {
          return jsonResponse({ ok: false, message: error.message }, 400);
        }
        return jsonResponse({ ok: true, influencers: data ?? [] });
      }

      case "delete": {
        const id = body?.id;
        if (!id) {
          return jsonResponse({ ok: false, message: "id required" }, 400);
        }
        const { error } = await adminClient
          .from("influencers")
          .update({ deleted_at: new Date().toISOString(), is_active: false })
          .eq("id", id);
        if (error) {
          return jsonResponse({ ok: false, message: error.message }, 400);
        }
        return jsonResponse({ ok: true, message: "Soft deleted" });
      }

      default:
        return jsonResponse({
          ok: false,
          message: "Unknown action. Use: create, toggle_active, list, delete",
        }, 400);
    }
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    return jsonResponse({ ok: false, message }, 500);
  }
});
