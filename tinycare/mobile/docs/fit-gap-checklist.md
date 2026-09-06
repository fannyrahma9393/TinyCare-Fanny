# TinyCare Web → Mobile (Flutter) — Fit & Gap Checklist

Acuan: WEB di `web/` + Backend di `backend/` (Laravel, prefix `/api/v1`).
Target: `mobile/` (Flutter).

## LEGEND
- ✅ Sudah ada & berfungsi
- 🟡 Ada tapi tidak lengkap
- ❌ Belum ada
- ⚪ Tidak diporting (tidak relevan di mobile, atau memang tidak ada di web)

---

## ARSITEKTUR & UMUM

| Item | Web | Mobile | Catatan |
|---|---|---|---|
| API service terpusat (dio + interceptor 401/retry) | ✅ | ✅ | `api_service.dart` — +`baseOrigin`, `resolveMediaUrl` |
| Error 401/403/404/422/500 + network | ✅ | ✅ | `api_error.dart`, interceptor |
| Loading & empty state reusable | ✅ | ✅ | `AppWidgets` |
| Auth Provider + auto-restore token | ✅ | ✅ | `auth_provider.dart` |
| Base URL config (--dart-define) | ✅ | ✅ | emulator 10.0.2.2 fallback |
| Dark/Light theme terpusat + persist | ✅ | ✅ | `theme_provider.dart` + `app_theme.dart` |
| **Reusable ChildPhoto 4:6** | ✅ | ✅ | `widgets/child_photo.dart` — dipakai dashboard, children, daily-stories, parents, child detail, story detail |

## AUTH & ROLE

| Item | Web | Mobile | Catatan |
|---|---|---|---|
| Login parent | ✅ | ✅ | `login_page.dart` |
| Login admin | ✅ | ✅ | membawa role dari backend; **tanpa field admin_access_code** (web tidak punya; backend tidak require) |
| Register parent | ✅ | ✅ | `register_page.dart` |
| Logout (unregister FCM + revoke token) | ✅ | ✅ | auth_provider + fcm teardown |
| Role guard route (parent/admin) | ✅ | ✅ | `_AuthGuard` di main.dart |
| Change password | ✅ | ✅ | `change_password_page.dart` via `/change-password` + menu Profil |
| Forgot/reset password | ✅ | ✅ | `forgot_password_page.dart` + `reset_password_page.dart`; link dari login |

## ORANG TUA (PARENT)

| Fitur | Web | Mobile | Catatan |
|---|---|---|---|
| Dashboard/Beranda (+foto anak) | ✅ | ✅ | `dashboard_page.dart` + ChildPhoto |
| Daftar Anak | ✅ | ✅ | `children_page.dart` |
| Detail anak (tab Ringkasan/Perkembangan/Kehadiran/Aktivitas) | ✅ | ✅ | `child_detail_page.dart`; dari kartu anak |
| Aktivitas: **card anak → detail aktivitas** | ✅ | ✅ | `activities_page.dart` → `activities_detail_page.dart` |
| Perkembangan: **card anak → detail** | ✅ | ✅ | `development_page.dart` → `development_detail_page.dart` |
| Daily Story: **card anak → detail story** | ✅ | ✅ | `daily_stories_page.dart` + `daily_story_detail_page.dart` (text-based; media url tidak diserialkan backend) |
| Child Information: list + pilih anak | ✅ | ✅ | `child_information_page.dart`; quick action + route `/information` + FCM |
| Authorized Pickups CRUD | ✅ | ✅ | `pickups_page.dart`; dari detail anak (list/tambah/edit/hapus/status) |
| Paket: child package + history | ✅ | ✅ | `package_page.dart`; dari detail anak (paket aktif + riwayat) |
| Voucher: list + apply | ✅ | 🟡 | `vouchers_page.dart` admin ada; apply sengaja parent-only di web → parity |
| Invoice: list + **detail** | ✅ | ✅ | `invoices_page.dart` + `invoice_detail_page.dart` |
| Pembayaran: initiate + VA + copy + submit proof + status | ✅ | ✅ | `invoice_detail_page.dart` (image_picker) |
| Pengumuman: list + detail | ✅ | ✅ | `announcements_page.dart` |
| Feedback: list + submit + status | ✅ | ✅ | `feedback_page.dart` |
| Profil: view + ubah password + theme + logout | ✅ | ✅ | `profile_page.dart` (+menu Ubah Password) & tab profil dashboard |
| Notifications (in-app list) | ✅ | ✅ | `notifications_page.dart`; quick action + menu profil + `getNotifications` |

## ADMIN

| Fitur | Web | Mobile | Catatan |
|---|---|---|---|
| Dashboard admin | ✅ | ✅ | `admin_dashboard_page.dart` (+menu Informasi Anak) |
| Kelola Orang Tua: list + **detail** (anak + foto) | ✅ | ✅ | `parents_page.dart` + `ParentDetailPage` |
| Kelola Anak: list + tambah + edit + status + hapus | ✅ | ✅ | `children_page.dart`; **foto upload + address/health/emergency** ditambah |
| Detail anak admin | ✅ | ⚪ | parity web: tap anak = form edit (bukan tab page parent) |
| Daily Story: list + tambah + **edit** | ✅ | ✅ | `daily_stories_page.dart` (`_StoryFormPage` edit mode, admin_notes) |
| Daily Story: detail | ✅ | ⚪ | admin tidak punya GET detail; `update` saja |
| Aktivitas master CRUD | ✅ | ✅ | `activities_page.dart` |
| Perkembangan: kategori + assessment CRUD | ✅ | ✅ | `development_page.dart` |
| Child Information CRUD + filter anak | ✅ | ✅ | `child_information_page.dart` admin branch |
| Paket CRUD + assign ke anak | ✅ | 🟡 | `packages_page.dart` |
| Voucher CRUD | ✅ | ✅ | `vouchers_page.dart` |
| Invoice: list + **create + status** | ✅ | ✅ | `invoices_page.dart` (updateStatus + form) |
| Pembayaran: verify/reject/proof | ✅ | ✅ | `payments_page.dart` |
| Pengumuman CRUD | ✅ | ✅ | `announcements_page.dart` (add/edit/delete/priority) |
| Feedback: list + respond + status | ✅ | ✅ | `feedback_page.dart` |
| Kelola Admin (admin_master) | ✅ | 🟡 | `admin_management_page.dart` |
| Kelola User (approve/reject user parent) | ✅ | ✅ | `user_management_page.dart` |
| Laporan mingguan/bulanan | ⚪ | ✅ | `reports_page.dart`; tersisa (page+route) tapi TIDAK di menu — mirror web (route `/reports` ada, sidebar tidak) |
| Media documentation | ✅ | ⚪ | API ada; web juga minor |

## FCM (WAJIB & SUDAH TERHUBUNG)

| Item | Status | Bukti/catatan |
|---|---|---|
| Firebase init (guarded) | ✅ | `fcm_service.dart` |
| Login parent → token → POST `/v1/fcm-tokens` platform=android | ✅ | auth_provider `_setupFcm()` |
| Logout → DELETE `/v1/fcm-tokens` | ✅ | teardown |
| Foreground/background/terminated + tap routing | ✅ | onMessage / onMessageOpenedApp / getInitialMessage |
| Token refresh re-register | ✅ | onTokenRefresh |
| Targeting child→parent (strict backend) | ✅ | backend; tidak diubah |
| **child_information → `/information` route** | ✅ | `resolveRoute()` + register route + test |

## ALUR FOTO ANAK (WAJIB 4:6)

- Prioritas source: `photo_url` → `photo` → `image_url` → placeholder (ikon, tanpa huruf).
- Frame FIX 4:6 (width × 1.5), `cover`, center crop, rounded (bukan circle).
- **Status: ✅** `widgets/child_photo.dart` + dipakai di SEMUA halaman anak.
- Upload foto anak di form admin (`_ChildFormPage`) → multipart `photo`.

## CATATAN ROUTE / NAVIGASI

- `main.dart` routes: login, register, **forgot-password, reset-password**, dashboard, admin-dashboard, children, daily-stories, development, invoices, announcements, feedback, profile, **notifications, change-password**, users, admin-management, activities, packages, vouchers, parents, payments, reports, **information**.
- **PARITY (2026-09-05):** Attendance & Events DIHAPUS dari mobile (page+routes+menu admin+quick action parent+child-card button+API methods) karena WEB sudah hapus keduanya. Sisa `getAttendance` parent-only untuk tab Kehadiran detail anak (web: newsfeed). Admin dashboard stat cards disamakan (Pengguna Menunggu→`/users`, Informasi Anak→`/information`, Invoice Pending→`/invoices`, Lunas→`/payments`). Quick action "Laporan" admin dihapus. `_AuthGuard` kini blok parent ke route admin-only (`/users,/packages,/vouchers,/payments,/parents,/admin-management,/activities,/reports`). Kartu anak di Beranda parent → detail anak (bukan pindah tab). Keep-by-user-decision (ada di mobile, TIDAK di web): Package page, Pickups, Notifications in-app, Change Password, Forgot/Reset Password.
- Detail pages dipush via `MaterialPageRoute` (child detail, story detail, invoice detail, development/activities detail, **package**, **pickups**).
- `AppScaffold` (bottom nav) = placeholder; parent memakai bottom-nav internal di `dashboard_page.dart`.

## STATUS SESSION (latest)

- `flutter analyze` clean; `flutter test` 12/12; backend `artisan test` 204/204; web vitest 9/9 + build + lint OK; `flutter build apk --debug` sukses.
- APK terbaru: `mobile/build/app/outputs/flutter-apk/app-debug.apk` (≈167 MB, debug) — 2026-09-06.
- **Build APK biar sesuai web (server production):** `flutter build apk --debug --dart-define=API_BASE_URL=https://tinycare.my.id/api`. Tanpa `API_BASE_URL`, APK default ke `10.0.2.2:8000` (server dev/emulator) sehingga foto & data anak beda dari web.
- Fix build Android: `android/build.gradle.kts` buildscript kini punya `repositories { google(); mavenCentral() }` (dibutuhkan sejak `google-services.json` aktif untuk FCM → classpath `com.google.gms:google-services:4.4.2`).

## GAP CLOSURE (2026-09-06) — samakan fitur & tampilan dengan web online

| Item | Sebelum | Sesudah |
|---|---|---|
| Admin Pembayaran: filter status | ❌ belum ada | ✅ tab Semua/Menunggu/Terverifikasi/Ditolak (`payments_page.dart`, `getAdminPayments({status})`) |
| Admin Pembayaran: detail + bukti | ❌ `showPaymentProof` tidak dipakai | ✅ tombol Detail per kartu → bottom sheet (invoice/anak/ortua/metode/jumlah/tanggal/catatan/alasan tolak) + bukti gambar (viewer full-screen) / `Buka Bukti (PDF)` via url_launcher |
| Admin Pembayaran: format rupiah | ❌ `Rp ${raw}` | ✅ `CurrencyHelper.formatRupiah` |
| Parent: "Bayar Sekarang" (daftar tagihan) | 💀 buka `_InvoiceDetailPage` privat TANPA form bukti (buntu) | ✅ membuka `InvoiceDetailPage` penuh (VA + upload bukti); `_InvoiceDetailPage` privat DIHAPUS |
| Parent: pending payment tanpa bukti | ❌ hanya "masih dalam proses verifikasi", tidak bisa kirim bukti | ✅ `pendingNoProof` → pesan + tombol `Kirim Bukti Pembayaran` (mirror web) |
| Parent: riwayat pembayaran | ❌ tanpa bukti | ✅ header `Riwayat Pembayaran & Bukti` + thumbnail gambar (tap → viewer) / `Lihat Bukti (PDF)` + baris `Catatan` (mirror web) |
| Desain token | 🟡 minor beda | ✅ light+dark disinkronkan dengan `web/src/index.css` (#2C5A47, #E8F4ED, #F0F7F3, #EDEEF0, #0E1510, #223028, dst) |
| Admin form buat invoice | ❌ tanpa voucher | ✅ field `Kode Voucher` (opsional) dikirim via `createInvoice(voucherCode)` — cek: web voucher cuma dipakai di form ini (parent-apply TIDAK ada di web) |
| Dead code | ❌ events/attendance/parent_invoices_detail/parent_payment/child_information_detail masih ada | ✅ 5 file halaman tidak ter-route DIHAPUS |
| Depedensi | — | ✅ `url_launcher` (buka PDF/signed URL di browser) |

### Catatan audit
- Paket assign ke anak ✅ (form anak admin `_ChildFormPage` → `assignPackageToChild`).
- Kelola Admin ✅ (list + status aktif/nonaktif + tambah + role admin/admin_master + guard `isAdminMaster`).
- CRUD lain (anak, aktivitas, perkembangan, child info, pengumuman, feedback, users, voucher, daily story) sudah ✅ sesuai checklist.
- `flutter analyze` 0 issues; `flutter test` 12/12.