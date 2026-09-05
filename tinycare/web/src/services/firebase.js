/**
 * TinyCare Firebase Cloud Messaging (FCM) web integration.
 *
 * Responsibilities:
 *  - initialize Firebase from public VITE_FIREBASE_* env vars
 *  - request notification permission with good UX (never more than needed)
 *  - generate a registration token (VAPID) and register it with the backend
 *    for the currently authenticated user (supports multiple devices)
 *  - handle foreground messages (show an in-app toast, not a duplicate
 *    browser notification)
 *  - clean up the token on logout
 *
 * The Firebase Messaging SDK is loaded from the Google CDN via the compat
 * build (same version as public/firebase-messaging-sw.js). It is exposed as
 * window.firebase. This avoids a build-time dependency on the `firebase` npm
 * package, so the app builds and runs even before credentials are supplied.
 * When credentials or the SDK are unavailable, FCM silently disables itself
 * and the app keeps working. Only PUBLIC web config lives here — never secret.
 */

import api from './api';
import { firebaseConfig, vapidKey } from './firebaseConfig';

function isConfigured() {
  return Boolean(
    firebaseConfig.apiKey &&
      firebaseConfig.projectId &&
      firebaseConfig.messagingSenderId &&
      firebaseConfig.appId &&
      vapidKey
  );
}

function supportsFcm() {
  return (
    typeof window !== 'undefined' &&
    'serviceWorker' in navigator &&
    'Notification' in window &&
    typeof window.firebase !== 'undefined' &&
    typeof window.firebase.messaging === 'function'
  );
}

/**
 * Send the public config to the service worker (which cannot read import.meta.env).
 */
function sendConfigToWorker(registration) {
  try {
    const active = registration?.active || registration?.waiting || registration?.installing;
    if (active) {
      active.postMessage({ type: 'TINYCARE_FIREBASE_CONFIG', config: firebaseConfig });
    }
  } catch (e) {
    // Non-fatal
  }
}

/**
 * Register the service worker, request permission, then register the FCM token
 * with the backend for the logged-in user. Never prompts repeatedly.
 */
export async function initFcmForUser() {
  if (!isConfigured() || !supportsFcm()) {
    return { enabled: false, reason: 'not-configured' };
  }

  if (Notification.permission === 'denied') {
    return { enabled: false, reason: 'denied' };
  }

  if (Notification.permission === 'default') {
    const result = await Notification.requestPermission();
    if (result !== 'granted') {
      return { enabled: false, reason: result === 'denied' ? 'denied' : 'default' };
    }
  }

  try {
    window.firebase.initializeApp(firebaseConfig);
    const messaging = window.firebase.messaging();

    const registration = await navigator.serviceWorker.register(
      `${import.meta.env.BASE_URL || '/'}firebase-messaging-sw.js`
    );
    sendConfigToWorker(await navigator.serviceWorker.ready);

    const currentToken = await messaging.getToken({
      vapidKey,
      serviceWorkerRegistration: registration,
    });

    if (currentToken) {
      await registerToken(currentToken);
      return { enabled: true, token: currentToken };
    }
  } catch (e) {
    // eslint-disable-next-line no-console
    console.warn('TinyCare: FCM token failed.', e?.message);
  }

  return { enabled: false, reason: 'error' };
}

/**
 * Register (upsert) the FCM token with the backend, tied to the logged-in user.
 */
export async function registerToken(token) {
  await api.post('/fcm-tokens', {
    token,
    platform: 'web',
    device: navigator.userAgent || 'web',
  });
}

/**
 * Remove the FCM token from the backend (e.g. on logout).
 */
export async function unregisterToken(token) {
  if (!token) return;
  try {
    await api.delete('/fcm-tokens', { data: { token } });
  } catch (e) {
    // Non-fatal
  }
}

/**
 * Subscribe to foreground FCM messages so the app can show an in-app toast.
 * The browser only auto-displays notifications for background messages, so we
 * must render our own toast here while the tab is open (no duplication).
 */
export async function onForegroundMessage(onForeground) {
  if (!isConfigured() || !supportsFcm()) {
    return () => {};
  }
  try {
    const app = window.firebase.apps?.length ? window.firebase.app() : window.firebase.initializeApp(firebaseConfig);
    const messaging = window.firebase.messaging(app);
    const unsubscribe = messaging.onMessage((payload) => {
      onForeground({
        title: payload?.notification?.title || 'TinyCare',
        body: payload?.notification?.body || payload?.data?.body || '',
        link: payload?.data?.link || '/parent/information',
        child_id: payload?.data?.child_id || null,
        information_id: payload?.data?.information_id || null,
      });
    });
    return unsubscribe;
  } catch (e) {
    // eslint-disable-next-line no-console
    console.warn('TinyCare: foreground message subscription failed.', e?.message);
    return () => {};
  }
}
