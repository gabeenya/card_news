// Supabase Edge Function: image
// 서버에서 OpenAI 이미지 API를 호출한다. API 키는 서버 시크릿에만 존재.
// 로그인한 사용자만 호출 가능.
import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "POST only" }, 405);

  try {
    // 1) 로그인 검증
    const authHeader = req.headers.get("Authorization") ?? "";
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user }, error: authErr } = await supabase.auth.getUser();
    if (authErr || !user) return json({ error: "로그인이 필요합니다." }, 401);

    // 1-b) 관리자 승인 여부 검증
    const { data: profile } = await supabase
      .from("profiles").select("approved").eq("id", user.id).single();
    if (!profile?.approved) {
      return json({ error: "관리자 승인 대기 중입니다. 승인 후 사용할 수 있어요." }, 403);
    }

    // 2) OpenAI 이미지 호출 (키는 서버 시크릿)
    const { prompt, model, size, quality } = await req.json();
    if (!prompt) return json({ error: "prompt가 비었습니다." }, 400);

    const r = await fetch("https://api.openai.com/v1/images/generations", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + Deno.env.get("OPENAI_API_KEY")!,
      },
      body: JSON.stringify({
        model: model || "gpt-image-1",
        prompt,
        n: 1,
        size: size || "1024x1024",
        quality: quality || "medium",
      }),
    });

    const data = await r.json();
    return json(data, r.status);
  } catch (e) {
    return json({ error: e instanceof Error ? e.message : String(e) }, 500);
  }
});
