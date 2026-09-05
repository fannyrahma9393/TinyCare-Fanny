/**
 * Public Firebase web configuration.
 *
 * Read from the environment once at load time. These are PUBLIC values (web
 * config + VAPID key) — never private credentials. The service worker receives
 * a copy of this object at registration time (it cannot read import.meta.env).
 *
 * Kept in a separate module so tests can mock it without touching firebase.js.
 */

export const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || '',
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || '',
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || '',
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || '',
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || '',
  appId: import.meta.env.VITE_FIREBASE_APP_ID || '',
};

export const vapidKey = import.meta.env.VITE_FIREBASE_VAPID_KEY || '';
