import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import api from '../api'

vi.mock('../api', () => ({
  default: {
    post: vi.fn(),
    delete: vi.fn(),
  },
}))

// Mock the public config so isConfigured() returns true and the real code path runs.
vi.mock('../firebaseConfig', () => ({
  firebaseConfig: {
    apiKey: 'test-api-key',
    authDomain: 'test.firebaseapp.com',
    projectId: 'test-project',
    storageBucket: 'test.appspot.com',
    messagingSenderId: 'test-sender',
    appId: 'test-app',
  },
  vapidKey: 'test-vapid',
}))

const firebase = await import('../firebase')

const msgCb = { current: null }

function makeMessagingMock() {
  return {
    getToken: vi.fn().mockResolvedValue('fcm-token-test'),
    onMessage: vi.fn((cb) => {
      msgCb.current = cb
      return () => {}
    }),
  }
}

function installFcmGlobals() {
  // Mutate the existing jsdom globals so 'window.firebase', 'navigator.serviceWorker'
  // and 'Notification' all resolve consistently inside the module under test.
  const messagingMock = makeMessagingMock()
  window.firebase = {
    apps: [],
    initializeApp: vi.fn(),
    app: vi.fn(() => ({})),
    messaging: vi.fn(() => messagingMock),
  }
  window.__messagingMock = messagingMock
  navigator.serviceWorker = {
    register: vi.fn().mockResolvedValue({}),
    ready: vi.fn().mockResolvedValue({ active: { postMessage: vi.fn() } }),
  }
  Object.defineProperty(globalThis, 'Notification', {
    value: {
      permission: 'granted',
      requestPermission: vi.fn().mockResolvedValue('granted'),
    },
    configurable: true,
    writable: true,
  })
}

beforeEach(() => {
  api.post.mockClear()
  api.delete.mockClear()
  installFcmGlobals()
})

afterEach(() => {
  vi.clearAllMocks()
})

describe('FCM service', () => {
  it('registers a token with the backend when permission is granted', async () => {
    const result = await firebase.initFcmForUser()

    expect(window.firebase.initializeApp).toHaveBeenCalled()
    expect(window.firebase.messaging).toHaveBeenCalled()
    expect(api.post).toHaveBeenCalledWith('/fcm-tokens', expect.objectContaining({
      platform: 'web',
    }))
    expect(result.enabled).toBe(true)
    expect(result.token).toBe('fcm-token-test')
  })

  it('does not prompt again when permission was already granted', async () => {
    await firebase.initFcmForUser()
    expect(Notification.requestPermission).not.toHaveBeenCalled()
  })

  it('skips registration silently when permission is denied', async () => {
    Notification.permission = 'denied'
    const result = await firebase.initFcmForUser()
    expect(result.enabled).toBe(false)
    expect(result.reason).toBe('denied')
    expect(api.post).not.toHaveBeenCalled()
  })

  it('unregisters a token via DELETE', async () => {
    await firebase.unregisterToken('abc')
    expect(api.delete).toHaveBeenCalledWith('/fcm-tokens', { data: { token: 'abc' } })
  })

  it('unregisterToken does nothing with no token', async () => {
    await firebase.unregisterToken(null)
    expect(api.delete).not.toHaveBeenCalled()
  })

  it('onForegroundMessage calls back with parsed payload', async () => {
    const onForeground = vi.fn()
    await firebase.onForegroundMessage(onForeground)

    expect(window.firebase.messaging).toHaveBeenCalled()
    expect(typeof msgCb.current).toBe('function')

    msgCb.current({
      notification: { title: 'Informasi Anak', body: 'Ada info baru' },
      data: { link: '/parent/information', child_id: '5' },
    })

    expect(onForeground).toHaveBeenCalledWith(expect.objectContaining({
      title: 'Informasi Anak',
      body: 'Ada info baru',
      link: '/parent/information',
      child_id: '5',
    }))
  })
})
