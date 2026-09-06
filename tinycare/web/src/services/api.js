import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || '/api/v1';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
});

// Request interceptor - add auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor - handle errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Auth API
export const authAPI = {
  login: (data) => api.post('/auth/login', data),
  logout: () => api.post('/auth/logout'),
  me: () => api.get('/auth/me'),
  changePassword: (data) => api.put('/auth/change-password', data),
  registerParent: (data) => api.post('/auth/register-parent', data),
};

// User Management API (Admin)
export const userManagementAPI = {
  list: (params) => api.get('/admin/users', { params }),
  pending: (params) => api.get('/admin/users/pending', { params }),
  approve: (id) => api.post(`/admin/users/${id}/approve`),
  reject: (id, data) => api.post(`/admin/users/${id}/reject`, data),
  activate: (id) => api.post(`/admin/users/${id}/activate`),
  deactivate: (id) => api.post(`/admin/users/${id}/deactivate`),
};

// Admin Management API (Admin Master)
export const adminManagementAPI = {
  list: (params) => api.get('/admin/admins', { params }),
  get: (id) => api.get(`/admin/admins/${id}`),
  create: (data) => api.post('/admin/admins', data),
  update: (id, data) => api.put(`/admin/admins/${id}`, data),
  delete: (id) => api.delete(`/admin/admins/${id}`),
  activate: (id) => api.post(`/admin/admins/${id}/activate`),
  deactivate: (id) => api.post(`/admin/admins/${id}/deactivate`),
};

// Children API
export const childrenAPI = {
  list: (params) => api.get('/admin/children', { params }),
  get: (id) => api.get(`/admin/children/${id}`),
  create: (data) => api.post('/admin/children', data, {
    headers: data instanceof FormData ? { 'Content-Type': 'multipart/form-data' } : {},
  }),
  update: (id, data) => {
    if (data instanceof FormData) {
      // Laravel/PHP does not populate $_FILES for real PUT multipart bodies,
      // so spoof the method via POST + "_method=PUT" to ensure file uploads work.
      data.append('_method', 'PUT');
      return api.post(`/admin/children/${id}`, data, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
    }
    return api.put(`/admin/children/${id}`, data);
  },
  delete: (id) => api.delete(`/admin/children/${id}`),
};

// Parents API
export const parentsAPI = {
  list: (params) => api.get('/admin/parents', { params }),
  get: (id) => api.get(`/admin/parents/${id}`),
  create: (data) => api.post('/admin/parents', data),
  update: (id, data) => api.put(`/admin/parents/${id}`, data),
  delete: (id) => api.delete(`/admin/parents/${id}`),
};

// Packages API
export const packagesAPI = {
  list: (params) => api.get('/admin/packages', { params }),
  get: (id) => api.get(`/admin/packages/${id}`),
  create: (data) => api.post('/admin/packages', data),
  update: (id, data) => api.put(`/admin/packages/${id}`, data),
  delete: (id) => api.delete(`/admin/packages/${id}`),
  assignToChild: (childId, data) => api.post(`/admin/children/${childId}/packages`, data),
  childPackages: (childId) => api.get(`/admin/children/${childId}/packages`),
};

// Vouchers API
export const vouchersAPI = {
  list: (params) => api.get('/admin/vouchers', { params }),
  get: (id) => api.get(`/admin/vouchers/${id}`),
  create: (data) => api.post('/admin/vouchers', data),
  update: (id, data) => api.put(`/admin/vouchers/${id}`, data),
  delete: (id) => api.delete(`/admin/vouchers/${id}`),
};

// Attendance API
export const attendanceAPI = {
  list: (params) => api.get('/admin/attendance', { params }),
  create: (data) => api.post('/admin/attendance', data),
  update: (id, data) => api.put(`/admin/attendance/${id}`, data),
};

// Daily Stories API
export const dailyStoriesAPI = {
  list: (params) => api.get('/admin/daily-stories', { params }),
  create: (childId, data) => api.post(`/admin/children/${childId}/daily-stories`, data),
  update: (id, data) => api.put(`/admin/daily-stories/${id}`, data),
};

// Activities API
export const activitiesAPI = {
  list: (params) => api.get('/admin/activities', { params }),
  create: (data) => api.post('/admin/activities', data),
  update: (id, data) => api.put(`/admin/activities/${id}`, data),
  delete: (id) => api.delete(`/admin/activities/${id}`),
  addChildActivity: (childId, data) => api.post(`/admin/children/${childId}/activities`, data),
};

// Development API
export const developmentAPI = {
  categories: () => api.get('/admin/development-categories'),
  createCategory: (data) => api.post('/admin/development-categories', data),
  childDevelopment: (childId) => api.get(`/admin/children/${childId}/development`),
  addAssessment: (childId, data) => api.post(`/admin/children/${childId}/development-assessments`, data),
  updateAssessment: (id, data) => api.put(`/admin/development-assessments/${id}`, data),
  deleteAssessment: (id) => api.delete(`/admin/development-assessments/${id}`),
};

// Invoices API
export const invoicesAPI = {
  list: (params) => api.get('/admin/invoices', { params }),
  get: (id) => api.get(`/admin/invoices/${id}`),
  create: (data) => api.post('/admin/invoices', data),
  updateStatus: (id, data) => api.put(`/admin/invoices/${id}/status`, data),
};

// Payments API
export const paymentsAPI = {
  list: (params) => api.get('/admin/payments', { params }),
  verify: (id) => api.post(`/admin/payments/${id}/verify`),
  reject: (id, data) => api.post(`/admin/payments/${id}/reject`, data),
  getProof: (id) => api.get(`/admin/payments/${id}/proof`),
};

// Media API
export const mediaAPI = {
  upload: (data) => api.post('/admin/media', data, {
    headers: { 'Content-Type': 'multipart/form-data' },
  }),
  delete: (id) => api.delete(`/admin/media/${id}`),
  get: (id) => api.get(`/admin/media/${id}`),
};

// Announcements API
export const announcementsAPI = {
  list: (params) => api.get('/admin/announcements', { params }),
  create: (data) => api.post('/admin/announcements', data),
  update: (id, data) => api.put(`/admin/announcements/${id}`, data),
  delete: (id) => api.delete(`/admin/announcements/${id}`),
};

// Child Information API
export const childInformationAPI = {
  list: (params) => api.get('/admin/child-information', { params }),
  get: (id) => api.get(`/admin/child-information/${id}`),
  create: (data) => api.post('/admin/child-information', data),
  update: (id, data) => api.put(`/admin/child-information/${id}`, data),
  delete: (id) => api.delete(`/admin/child-information/${id}`),
};

// Events API
export const eventsAPI = {
  list: (params) => api.get('/admin/events', { params }),
  create: (data) => api.post('/admin/events', data),
  update: (id, data) => api.put(`/admin/events/${id}`, data),
  delete: (id) => api.delete(`/admin/events/${id}`),
};

// Feedback API
export const feedbackAPI = {
  list: (params) => api.get('/admin/feedback', { params }),
  respond: (id, data) => api.post(`/admin/feedback/${id}/respond`, data),
  updateStatus: (id, data) => api.put(`/admin/feedback/${id}/status`, data),
};

// Pickup API
export const pickupAPI = {
  childPickups: (childId) => api.get(`/admin/children/${childId}/authorized-pickups`),
};

// Reports API
export const reportsAPI = {
  weeklyList: (params) => api.get('/admin/reports/weekly', { params }),
  monthlyList: (params) => api.get('/admin/reports/monthly', { params }),
  generateWeekly: (childId, data) => api.post(`/admin/children/${childId}/reports/weekly`, data),
  generateMonthly: (childId, data) => api.post(`/admin/children/${childId}/reports/monthly`, data),
};

// Public Stats API (Landing page)
export const publicStatsAPI = {
  get: () => api.get('/public/stats'),
};

// Notifications API
export const notificationsAPI = {
  list: (params) => api.get('/notifications', { params }),
  markAsRead: (id) => api.put(`/notifications/${id}/read`),
  markAllAsRead: () => api.put('/notifications/read-all'),
};

// ==================== PARENT API ====================

export const parentAPI = {
  dashboard: () => api.get('/parent/dashboard'),
  children: () => api.get('/parent/children'),
  childDetail: (childId) => api.get(`/parent/children/${childId}`),
  childDevelopment: (childId) => api.get(`/parent/children/${childId}/development`),
  childDevelopmentTimeline: (childId) => api.get(`/parent/children/${childId}/development/timeline`),
  childAttendance: (childId) => api.get(`/parent/children/${childId}/attendance`),
  childActivities: (childId) => api.get(`/parent/children/${childId}/activities`),
  childDailyStories: (childId) => api.get(`/parent/children/${childId}/daily-stories`),
  childInformation: (childId) => api.get('/parent/child-information', { params: childId ? { child_id: childId } : {} }),
  childMedia: (childId) => api.get(`/parent/children/${childId}/media`),
  childPackage: (childId) => api.get(`/parent/children/${childId}/package`),
  childPackageHistory: (childId) => api.get(`/parent/children/${childId}/package/history`),
  invoices: () => api.get('/parent/invoices'),
  invoiceDetail: (invoiceId) => api.get(`/parent/invoices/${invoiceId}`),
  initiatePayment: (invoiceId, data) => api.post(`/parent/invoices/${invoiceId}/pay`, data),
  submitPayment: (data) => api.post('/parent/payments', data, {
    headers: data instanceof FormData ? { 'Content-Type': 'multipart/form-data' } : {},
  }),
  checkPaymentStatus: (paymentId) => api.get(`/parent/payments/${paymentId}/status`),
  invoicePayments: (invoiceId) => api.get(`/parent/invoices/${invoiceId}/payments`),
  announcements: () => api.get('/parent/announcements'),
  events: () => api.get('/parent/events'),
  feedback: () => api.get('/parent/feedback'),
  submitFeedback: (data) => api.post('/parent/feedback', data),
  vouchers: () => api.get('/parent/vouchers'),
  applyVoucher: (data) => api.post('/parent/vouchers/apply', data),
  authorizedPickups: (childId) => api.get(`/parent/children/${childId}/authorized-pickups`),
  addAuthorizedPickup: (childId, data) => api.post(`/parent/children/${childId}/authorized-pickups`, data),
  updateAuthorizedPickup: (pickupId, data) => api.put(`/parent/authorized-pickups/${pickupId}`, data),
  deleteAuthorizedPickup: (pickupId) => api.delete(`/parent/authorized-pickups/${pickupId}`),
  childWeeklyReports: (childId) => api.get(`/parent/children/${childId}/reports/weekly`),
  childMonthlyReports: (childId) => api.get(`/parent/children/${childId}/reports/monthly`),
};

export default api;
