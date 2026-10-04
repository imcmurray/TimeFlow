// TimeFlow offline support.
//
// Network first, so a connected browser always gets the latest version;
// every successful response is also kept in a cache that is used when
// there's no connection. Only same-origin GET requests are handled (the web
// build bundles CanvasKit and fonts, so the app has no other origins).
const CACHE = 'timeflow';

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(['./', 'index.html'])));
});

// The page loads before this worker controls it, so it sends the list of
// files it already fetched (see index.html) to be cached for offline use.
self.addEventListener('message', (event) => {
  const urls = (event.data && event.data.cache) || [];
  const sameOrigin = urls.filter((u) => new URL(u).origin === self.location.origin);
  event.waitUntil(caches.open(CACHE).then((cache) =>
    Promise.all(sameOrigin.map((u) => cache.add(u).catch(() => {})))));
});
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  if (new URL(request.url).origin !== self.location.origin) return;

  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    try {
      const response = await fetch(request);
      if (response.ok) cache.put(request, response.clone());
      return response;
    } catch (error) {
      const cached = await cache.match(request, { ignoreSearch: true });
      if (cached) return cached;
      if (request.mode === 'navigate') {
        const shell = (await cache.match('./')) || (await cache.match('index.html'));
        if (shell) return shell;
      }
      throw error;
    }
  })());
});
