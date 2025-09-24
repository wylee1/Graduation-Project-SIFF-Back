// functions/index.js
const { onCall } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const OpenAI = require("openai");
const logger = require("firebase-functions/logger");

// --- Firebase Admin ---
try { admin.initializeApp(); } catch (_) {}
const db = admin.firestore();

// --- Secret (CLI에서 등록한 이름과 동일) ---
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

// --- 유틸 ---
function cosine(a, b) {
  let dot = 0, na = 0, nb = 0;
  for (let i = 0; i < a.length; i++) { dot += a[i] * b[i]; na += a[i]*a[i]; nb += b[i]*b[i]; }
  return dot / (Math.sqrt(na) * Math.sqrt(nb) + 1e-12);
}

// map_marker 문서 -> 검색 텍스트
function stringifyMapMarker(d) {
  return [
    d.name,
    d.Description,
    d.Address,
    d["Crime Type"],
    d.Time,
    d.url,
    d["위도"], d["경도"]
  ].filter(Boolean).join("\n");
}

// report_community 문서 -> 검색 텍스트
function stringifyReportCommunity(d) {
  return [
    d.title, d.description, d.incidentType, d.location, d.regionName,
    d.occurDate, d.occurTime, d.status, d.writerName, d.imageUrl
  ].filter(Boolean).join("\n");
}

/**
 * 진단용: 컬렉션 count/샘플 리턴
 * Flutter에서 `httpsCallable('peekData')` 로 호출해서 info를 확인하세요.
 */
exports.peekData = onCall(async () => {
  const info = { projectId: process.env.GCLOUD_PROJECT };

  try {
    const mm = await db.collection("map_marker").count().get();
    info.map_marker_count = mm.data().count;
  } catch (e) {
    info.map_marker_count = -1;
    info.map_marker_count_error = String(e);
  }

  try {
    const rc = await db.collection("report_community").count().get();
    info.report_community_count = rc.data().count;
  } catch (e) {
    info.report_community_count = -1;
    info.report_community_count_error = String(e);
  }

  const mmSnap = await db.collection("map_marker").limit(3).get().catch(e => (info.mm_error = String(e), null));
  const rcSnap = await db.collection("report_community").limit(3).get().catch(e => (info.rc_error = String(e), null));

  info.mm_docs = mmSnap ? mmSnap.size : 0;
  info.rc_docs = rcSnap ? rcSnap.size : 0;

  info.mm_samples = mmSnap ? mmSnap.docs.map(d => ({
    id: d.id, name: d.data().name, address: d.data().Address, crimeType: d.data()["Crime Type"],
  })) : [];

  info.rc_samples = rcSnap ? rcSnap.docs.map(d => ({
    id: d.id, title: d.data().title, incidentType: d.data().incidentType, location: d.data().location,
  })) : [];

  return { ok: true, info };
});

/**
 * RAG 간이 버전: 두 컬렉션(map_marker, report_community)에서 최근 문서 읽어와서
 * 질문/문서 모두 임베딩 → 코사인유사도 Top-K → 답변 생성
 */
exports.chatRag = onCall({ secrets: [OPENAI_API_KEY] }, async (req) => {
  const debug = !!req.data?.debug;
  const info = { projectId: process.env.GCLOUD_PROJECT, step: "start" };

  try {
    const question = (req.data?.question || "").toString().trim();
    const topK = Number(req.data?.topK ?? 5);
    if (!question) return { answer: "질문이 비어 있습니다.", info };

    // 핸들러 내부에서 키 주입
    const openai = new OpenAI({ apiKey: OPENAI_API_KEY.value() });

    // 후보 수집
    const MAX_DOCS = 80;
    let mmSnap, rcSnap;

    try { mmSnap = await db.collection("map_marker").limit(MAX_DOCS).get(); }
    catch (e) { info.mm_error = String(e); }

    try {
      try { rcSnap = await db.collection("report_community").orderBy("createdAt", "desc").limit(MAX_DOCS).get(); }
      catch { rcSnap = await db.collection("report_community").limit(MAX_DOCS).get(); }
    } catch (e) { info.rc_error = String(e); }

    info.mm_docs = mmSnap?.size ?? 0;
    info.rc_docs = rcSnap?.size ?? 0;

    const candidates = [];
    mmSnap?.forEach(doc => {
      const d = doc.data() || {};
      candidates.push({
        id: `map_marker/${doc.id}`,
        type: "map_marker",
        title: d.name || d["Crime Type"] || d.Address || doc.id,
        text: stringifyMapMarker(d),
      });
    });
    rcSnap?.forEach(doc => {
      const d = doc.data() || {};
      candidates.push({
        id: `report_community/${doc.id}`,
        type: "report_community",
        title: d.title || d.incidentType || d.location || doc.id,
        text: stringifyReportCommunity(d),
      });
    });

    info.candidate_count = candidates.length;
    info.sample_titles = candidates.slice(0, 5).map(c => `${c.type}:${c.title}`);

    if (!candidates.length) {
      return { answer: "데이터베이스에서 문서를 찾지 못했습니다.", info: debug ? info : undefined };
    }

    // 질문 임베딩
    const qEmb = await openai.embeddings.create({
      model: "text-embedding-3-small",
      input: question,
    });
    const qVec = qEmb.data[0].embedding;

    // 후보 임베딩 (시범: 호출당 비용 발생)
    const embResp = await openai.embeddings.create({
      model: "text-embedding-3-small",
      input: candidates.map(c => (c.text || "").slice(0, 7000)),
    });

    const top = candidates.map((c, i) => ({ ...c, score: cosine(qVec, embResp.data[i].embedding) }))
                          .sort((a,b) => b.score - a.score)
                          .slice(0, topK);

    const context = top.map((c, i) =>
      `[#${i+1} ${c.type}] ${c.title}\n${(c.text || "").slice(0, 1200)}`
    ).join("\n\n");

    const chat = await openai.chat.completions.create({
      model: "gpt-4.1-mini",
      temperature: 0.2,
      messages: [
        { role: "system", content: "너는 Firestore(map_marker, report_community)의 데이터만 근거로 사실대로 답한다. 모르면 모른다고 답한다." },
        { role: "user", content: `질문: ${question}\n\n관련 데이터:\n${context}\n\n가능하면 출처(#번호/컬렉션)을 괄호로 표시.` },
      ],
    });

    const answer = chat.choices?.[0]?.message?.content ?? "응답이 없습니다.";
    return {
      answer,
      sources: top.map(c => ({ id: c.id, type: c.type, score: c.score })),
      info: debug ? info : undefined,
    };
  } catch (e) {
    logger.error("chatRag fatal", e);
    info.error = String(e);
    return { answer: "서버 오류가 발생했습니다.", info: debug ? info : undefined };
  }
});
