/* Jen-Z Express — Customer Portal service worker (scope: /customer/) */
const VERSION = "jenz-customer-v2";
const SHELL = "/customer/";

self.addEventListener("install", (e) => {
  e.waitUntil(
    caches
      .open(VERSION)
      .then((c) => c.add(SHELL).catch(() => {}))
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(
          keys.filter((k) => k !== VERSION).map((k) => caches.delete(k)),
        ),
      )
      .then(() => self.clients.claim()),
  );
});

self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return; // never touch Supabase / API calls

  // Page loads: network first, fall back to the cached app shell when offline.
  if (req.mode === "navigate") {
    e.respondWith(
      fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(VERSION).then((c) => c.put(SHELL, copy));
          return res;
        })
        .catch(() => caches.match(SHELL)),
    );
    return;
  }

  // Hashed build files (/assets/*), icons, fonts: cache first.
  if (
    url.pathname.startsWith("/assets/") ||
    url.pathname.startsWith("/customer/icons/")
  ) {
    e.respondWith(
      caches.match(req).then(
        (hit) =>
          hit ||
          fetch(req).then((res) => {
            if (res.ok) {
              const copy = res.clone();
              caches.open(VERSION).then((c) => c.put(req, copy));
            }
            return res;
          }),
      ),
    );
  }
});

// ---------- Web Push ----------
// Payload sent by the send-push Edge Function: { title, body, url, tag }
self.addEventListener("push", (e) => {
  let data = {};
  try {
    data = e.data ? e.data.json() : {};
  } catch {
    data = { title: "Jen-Z Express", body: e.data ? e.data.text() : "" };
  }
  const title = data.title || "Jen-Z Express";
  e.waitUntil(
    self.registration.showNotification(title, {
      body: data.body || "",
      tag: data.tag,
      data: { url: data.url || "/customer/" },
    }),
  );
});

self.addEventListener("notificationclick", (e) => {
  e.notification.close();
  const target = new URL(
    (e.notification.data && e.notification.data.url) || "/customer/",
    self.location.origin,
  ).href;
  e.waitUntil(
    self.clients
      .matchAll({ type: "window", includeUncontrolled: true })
      .then((list) => {
        for (const c of list) {
          if (
            c.url.startsWith(self.location.origin + "/customer/") &&
            "focus" in c
          ) {
            c.navigate(target).catch(() => {});
            return c.focus();
          }
        }
        return self.clients.openWindow(target);
      }),
  );
});
