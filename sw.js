// LEANON 상담 관리 앱 서비스워커 — 상담 관리 전용.
const CACHE = 'leanon-app-v2';
const SHELL = [
  '/consult_admin/',
  '/logo.png',
  '/assets/app/icon-192.png',
  '/assets/app/icon-512.png',
  '/assets/brand/wordmark-dark.png'
];

self.addEventListener('install', (e) => {
  self.skipWaiting();
  e.waitUntil(
    caches.open(CACHE).then((c) => Promise.allSettled(SHELL.map((u) => c.add(u))))
  );
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// 네트워크 우선 → 실패 시 캐시(오프라인 껍데기). Supabase API 및 비 GET 은 건드리지 않음.
self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.hostname.endsWith('supabase.co')) return; // 실시간 데이터는 항상 네트워크

  e.respondWith(
    fetch(req)
      .then((res) => {
        if (url.origin === location.origin && res && res.status === 200) {
          const copy = res.clone();
          caches.open(CACHE).then((c) => c.put(req, copy)).catch(() => {});
        }
        return res;
      })
      .catch(() =>
        caches.match(req).then((hit) => hit || caches.match('/consult_admin/'))
      )
  );
});
