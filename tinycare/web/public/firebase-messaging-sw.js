/*
 * TinyCare Firebase Messaging Service Worker
 * ---------------------------------------------------------------
 * Handles BACKGROUND push notifications:
 *   - receives messages when the tab is not focused
 *   - displays the notification
 *   - opens the relevant TinyCare page on click
 *
 * Firebase is loaded from the Google CDN via importScripts (the standard
 * pattern for service workers, which cannot import npm modules directly).
 * The config values come from the Vite build-time injected globals below.
 *
 * NOTE: Requires the `firebase` npm package in web/package.json and the
 * VITE_FIREBASE_* variables. Without real values this worker logs a warning
 * and does nothing — it never breaks the app.
 */

/* globals importScripts, firebase */

importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

const firebaseConfig = {
  apiKey: self.__FIREBASE_API_KEY || '',
  authDomain: self.__FIREBASE_AUTH_DOMAIN || '',
  projectId: self.__FIREBASE_PROJECT_ID || '',
  storageBucket: self.__FIREBASE_STORAGE_BUCKET || '',
  messagingSenderId: self.__FIREBASE_MESSAGING_SENDER_ID || '',
  appId: self.__FIREBASE_APP_ID || '',
};

// PWA/notification icon (relative to app; update if you add a real logo).
const ICON = './favicon.svg';
const DEFAULT_LINK = './parent/information';

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

// Runtime config is injected by src/services/firebase.js BEFORE registration
// using message passing. Fall back to build-time globals otherwise.
let resolvedConfig = null;

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'TINYCARE_FIREBASE_CONFIG') {
    resolvedConfig = event.data.config || null;
    try {
      if (resolvedConfig && resolvedConfig.apiKey) {
        initializeMessaging();
      }
    } catch (e) {
      // eslint-disable-next-line no-console
      console.warn('TinyCare SW: Firebase init failed', e);
    }
  }
});

function getConfig() {
  return resolvedConfig || firebaseConfig;
}

function initializeMessaging() {
  const config = getConfig();
  firebase.initializeApp(config);
  // eslint-disable-next-line no-unused-vars
  const messaging = firebase.messaging();
}

self.addEventListener('push', (event) => {
  const config = getConfig();
  if (!config.apiKey) {
    return;
  }

  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch (e) {
    payload = { notification: {} };
  }

  const notification = payload.notification || {};
  const data = payload.data || {};

  const title = notification.title || 'TinyCare';
  const options = {
    body: notification.body || 'Informasi baru tentang anak Anda.',
    icon: notification.icon || ICON,
    badge: './favicon.svg',
    data: {
      link: data.link || DEFAULT_LINK,
      child_id: data.child_id || null,
      information_id: data.information_id || null,
    },
    vibrate: [100, 50, 100],
  };

  const clickAction = data.link || DEFAULT_LINK;
  if (clickAction) {
    options.data.link = clickAction;
  }

  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const target = (event.notification.data && event.notification.data.link) || DEFAULT_LINK;
  const urlToOpen = new URL(target, self.location.origin).href;

  // Bring an existing TinyCare tab into focus, else open a new one.
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url && client.url.indexOf(self.location.origin) === 0 && 'focus' in client) {
          return client.navigate(urlToOpen).then(() => client.focus());
        }
      }
      return self.clients.openWindow(urlToOpen);
    })
  );
});
