/**
 * FirebaseNotifications
 * -----------------------
 * Mount this once inside authenticated layouts. It:
 *  - initializes FCM + registers a token for the logged-in user (parents)
 *  - shows an in-app toast for foreground push messages
 *  - unregisters the FCM token when the user logs out
 *
 * It is intentionally small and defensive: if Firebase is not configured or the
 * `firebase` package is missing, it silently does nothing and the app keeps
 * working.
 */

import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { initFcmForUser, unregisterToken, onForegroundMessage } from '../services/firebase';

export default function FirebaseNotifications() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [toast, setToast] = useState(null);
  const tokenRef = useRef(null);
  const unsubRef = useRef(null);

  useEffect(() => {
    if (!user) {
      return;
    }

    let cancelled = false;

    const setupForeground = async () => {
      const unsubscribe = await onForegroundMessage((msg) => {
        if (cancelled) return;
        setToast({
          title: msg.title,
          body: msg.body,
          link: msg.link,
          child_id: msg.child_id,
          information_id: msg.information_id,
        });
      });
      if (!cancelled) unsubRef.current = unsubscribe;
    };

    const setup = async () => {
      // Push notifications target parents, so only initialize for the parent role.
      if (user?.role !== 'parent') {
        return;
      }
      const result = await initFcmForUser();
      if (!cancelled && result?.token) {
        tokenRef.current = result.token;
      }
    };

    setup();
    setupForeground();

    return () => {
      cancelled = true;
      if (unsubRef.current) {
        try {
          unsubRef.current();
        } catch (e) {
          /* ignore */
        }
        unsubRef.current = null;
      }
    };
  }, [user?.id]);

  // On logout (user becomes null), clear the backend token.
  useEffect(() => {
    if (!user && tokenRef.current) {
      unregisterToken(tokenRef.current);
      tokenRef.current = null;
    }
  }, [user]);

  // Auto-dismiss toast after 6s.
  useEffect(() => {
    if (!toast) return;
    const t = setTimeout(() => setToast(null), 6000);
    return () => clearTimeout(t);
  }, [toast]);

  if (!toast) return null;

  const openNotification = () => {
    navigate(toast.link || '/parent/information');
    setToast(null);
  };

  return (
    <div
      onClick={openNotification}
      role="alert"
      style={{
        position: 'fixed',
        bottom: '24px',
        right: '24px',
        zIndex: 9999,
        display: 'flex',
        alignItems: 'center',
        gap: '12px',
        maxWidth: '360px',
        padding: '12px 14px',
        borderRadius: 'var(--radius-lg)',
        background: 'var(--color-surface)',
        border: '1px solid var(--color-border)',
        boxShadow: 'var(--shadow-lg)',
        cursor: 'pointer',
      }}
    >
      <span style={{ fontSize: '20px' }}>🔔</span>
      <div style={{ minWidth: 0, flex: 1 }}>
        <p style={{ fontSize: '13px', fontWeight: '700', color: 'var(--color-text)', marginBottom: '2px' }}>
          {toast.title}
        </p>
        <p style={{ fontSize: '12px', color: 'var(--color-text-secondary)', lineHeight: '1.4' }}>{toast.body}</p>
      </div>
      <button
        onClick={(e) => {
          e.stopPropagation();
          setToast(null);
        }}
        aria-label="Tutup"
        style={{
          border: 'none',
          background: 'transparent',
          color: 'var(--color-text-muted)',
          fontSize: '18px',
          cursor: 'pointer',
          lineHeight: 1,
        }}
      >
        ×
      </button>
    </div>
  );
}
