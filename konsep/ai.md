{
  "role": "Anda adalah Senior Software Architect + Senior Laravel Developer + Senior React Developer + Senior Flutter Developer.",
  "project": "TinyCare",
  "project_type": "Digital Daycare Management System untuk SATU DAYCARE (bukan marketplace, bukan multi-daycare).",
  "instruction": "Dokumen ini adalah SATU-SATUNYA sumber kebenaran (single source of truth) untuk pengembangan TinyCare. Baca seluruh isi dokumen ini sebelum melakukan pekerjaan apa pun. Jangan berasumsi di luar isi dokumen ini.",
  "project_overview": {
    "project_name": "TinyCare",
    "tagline": "Digital Daycare Management & Parent Child Development Platform",
    "concept": "Sistem digital untuk SATU daycare yang menghubungkan Admin Daycare dan Orang Tua dalam satu ekosistem administrasi, operasional, komunikasi, serta pemantauan aktivitas dan tumbuh kembang anak.",
    "is_not": [
      "Bukan marketplace daycare",
      "Bukan aplikasi multi-daycare",
      "Bukan aplikasi diagnosis medis anak",
      "Bukan aplikasi konsultasi medis"
    ],
    "core_value_proposition": "Orang tua bisa tahu apa yang terjadi pada anaknya di daycare, sementara daycare punya sistem administrasi dan operasional yang rapi.",
    "positioning_statement": "Sistem daycare digital yang membuat pengelolaan daycare lebih mudah dan orang tua lebih dekat dengan aktivitas serta perkembangan anak.",
    "primary_goals": [
      "Membantu daycare mengelola operasional harian",
      "Membantu admin mencatat aktivitas dan perkembangan anak",
      "Membantu orang tua memantau anak secara transparan",
      "Membantu daycare mengelola paket, voucher, tagihan, dan pembayaran",
      "Membuat daycare terlihat lebih profesional dan modern sehingga memiliki nilai jual"
    ],
    "differentiator_features": [
      "Hari Ini di Daycare / Today's Story",
      "Daily Child Report",
      "Child Development Journal",
      "Development Timeline",
      "Dokumentasi aktivitas anak"
    ],
    "target_users": {
      "parent": {
        "platform": "Flutter mobile app",
        "needs": [
          "melihat data anak",
          "melihat profil anak",
          "melihat paket daycare yang sedang digunakan anak",
          "melihat detail paket, harga, fasilitas, masa berlaku, dan status",
          "melihat riwayat paket anak",
          "melihat status pembayaran",
          "melihat invoice",
          "melihat riwayat pembayaran",
          "melihat voucher",
          "menggunakan voucher saat checkout jika tersedia",
          "melihat status kehadiran anak",
          "melihat Hari Ini di Daycare",
          "melihat aktivitas anak",
          "melihat makan, tidur, mood, dan catatan admin",
          "melihat dokumentasi kegiatan yang berkaitan dengan anak",
          "melihat perkembangan anak",
          "melihat Development Timeline",
          "menerima notifikasi",
          "melihat pengumuman",
          "melihat jadwal dan kalender kegiatan daycare",
          "mengelola profil sendiri",
          "mengelola daftar authorized pickup",
          "memberikan feedback"
        ]
      },
      "admin": {
        "platform": "React + Tailwind web dashboard",
        "description": "Admin Daycare menangani seluruh operasional daycare pada V1. Tidak ada role Guru terpisah.",
        "needs": [
          "mengelola anak",
          "mengelola orang tua",
          "mengelola admin",
          "mengelola paket",
          "mengelola pendaftaran paket anak",
          "mengelola voucher",
          "mengelola invoice",
          "mengelola pembayaran",
          "mencatat kehadiran",
          "membuat dan mengelola Hari Ini di Daycare",
          "mencatat aktivitas anak",
          "mencatat perkembangan anak",
          "mengunggah dokumentasi",
          "mengirim pengumuman",
          "mengelola kalender dan jadwal kegiatan",
          "mengelola authorized pickup",
          "melihat laporan daycare",
          "melihat dashboard operasional",
          "mengelola setting daycare"
        ]
      }
    },
    "role_model": {
      "roles": [
        "parent",
        "admin"
      ],
      "important_decision": "Role teacher dihapus dari V1. Seluruh tugas operasional dan pencatatan yang sebelumnya diberikan kepada teacher digabung ke admin.",
      "future_note": "Jika di masa depan daycare membutuhkan pembagian akses Admin dan Guru, role teacher dapat ditambahkan sebagai pengembangan berikutnya tanpa mengubah prinsip ownership data."
    },
    "tech_stack": {
      "backend": [
        "Laravel",
        "PHP",
        "REST API",
        "Laravel Sanctum",
        "MySQL"
      ],
      "web_admin": [
        "React",
        "Tailwind CSS",
        "Vite",
        "React Router",
        "Axios"
      ],
      "mobile": [
        "Flutter",
        "Dart",
        "REST API",
        "Flutter Secure Storage"
      ],
      "database": [
        "MySQL"
      ]
    },
    "architecture_summary": "React Admin dan Flutter Parent sama-sama mengonsumsi satu Laravel REST API yang terhubung ke satu database MySQL.",
    "monetization_model": {
      "type": "Tiered SaaS package dijual ke daycare",
      "tiers": {
        "basic": [
          "Parent App",
          "Admin Dashboard",
          "Child Management",
          "Attendance",
          "Package",
          "Invoice"
        ],
        "professional": [
          "Semua fitur Basic",
          "Hari Ini di Daycare / Daily Report",
          "Child Development",
          "Photo Documentation",
          "Notifications",
          "Voucher",
          "Monthly Report"
        ],
        "premium": [
          "Semua fitur Professional",
          "QR Attendance",
          "Pickup Management",
          "Advanced Reports",
          "Parent Feedback",
          "Event Management",
          "Advanced Analytics"
        ]
      }
    },
    "top_5_priority_features": [
      "Hari Ini di Daycare / Today's Story",
      "Child Development Tracking",
      "Parent App",
      "Payment + Package",
      "Daycare Management Dashboard"
    ]
  },
  "roles_permissions": {
    "roles": [
      {
        "role": "parent",
        "platform": "Flutter",
        "description": "Orang tua/wali dari satu atau lebih anak yang terdaftar di daycare.",
        "permissions": [
          "view_own_children_only",
          "view_own_child_profile",
          "view_own_child_package",
          "view_own_child_package_history",
          "view_own_invoices",
          "view_own_payments",
          "view_own_payment_history",
          "view_own_vouchers",
          "use_voucher_on_checkout",
          "view_own_child_attendance",
          "view_own_child_daily_story",
          "view_own_child_activities",
          "view_own_child_development",
          "view_own_child_development_timeline",
          "view_own_child_documentation",
          "view_schedule",
          "view_calendar",
          "receive_notifications",
          "view_announcements",
          "manage_own_profile",
          "manage_authorized_pickup_list",
          "give_feedback"
        ],
        "forbidden": [
          "view_other_children",
          "view_other_parent_invoices",
          "view_other_child_development_report",
          "access_admin_endpoints",
          "edit_child_core_data",
          "edit_attendance",
          "edit_daily_story",
          "edit_development_assessment",
          "edit_payment_status",
          "edit_package_assignment"
        ]
      },
      {
        "role": "admin",
        "platform": "React Web",
        "description": "Pengelola daycare dengan akses operasional dan finansial penuh sesuai permission.",
        "permissions": [
          "manage_children",
          "manage_parents",
          "manage_admin_accounts",
          "manage_packages",
          "manage_child_package_assignments",
          "manage_vouchers",
          "manage_invoices",
          "manage_payments",
          "manage_attendance",
          "manage_daily_story",
          "manage_child_activities",
          "manage_child_development",
          "upload_documentation",
          "manage_notifications",
          "manage_announcements",
          "manage_schedule",
          "manage_events",
          "manage_pickup",
          "view_all_reports",
          "view_audit_logs",
          "manage_roles_permissions",
          "manage_daycare_settings"
        ],
        "forbidden": [
          "impersonate_parent_without_audit_trail",
          "bypass_validation_rules",
          "delete_audit_logs_without_authorized_process"
        ]
      }
    ],
    "role_based_access_principle": "Setiap endpoint API wajib memvalidasi role DAN ownership sebelum mengembalikan data. Role menentukan JENIS akses, ownership menentukan CAKUPAN data.",
    "authorization_mechanism": "Laravel Policies + Sanctum ability/token scope + middleware role check pada route group.",
    "critical_rule": "Parent hanya dapat mengakses data anak yang terhubung langsung dengannya melalui tabel parent_child. Tidak ada pengecualian tanpa audit log eksplisit."
  },
  "business_rules": {
    "domain": "Single-daycare digital operations",
    "core_business_flow": "Admin mengelola anak, paket, voucher, pembayaran, kehadiran, Hari Ini di Daycare, aktivitas, dokumentasi, perkembangan, jadwal, pengumuman, dan laporan. Orang tua memantau anaknya sendiri melalui aplikasi Flutter.",
    "rules": {
      "child": [
        "Satu anak wajib terhubung ke minimal satu orang tua melalui parent_child",
        "Satu orang tua dapat memiliki lebih dari satu anak",
        "Anak berstatus aktif atau nonaktif; anak nonaktif tidak muncul di dashboard operasional aktif",
        "Data kesehatan dasar hanya untuk keperluan operasional daycare, bukan rekam medis"
      ],
      "package": [
        "Paket memiliki nama, deskripsi, harga, durasi, fasilitas, kuota, status aktif, tanggal mulai dan berakhir",
        "Anak harus terdaftar pada satu paket aktif (child_packages) untuk bisa ditagih",
        "Perubahan paket anak dicatat sebagai riwayat, bukan overwrite",
        "Orang tua dapat melihat paket aktif yang sedang digunakan setiap anak yang terhubung ke akunnya",
        "Orang tua dapat melihat detail paket, harga, fasilitas, status, masa berlaku, dan riwayat paket",
        "Orang tua tidak dapat mengubah assignment paket secara langsung"
      ],
      "voucher": [
        "Voucher memiliki kode unik, nominal atau persentase diskon, minimum transaksi, masa berlaku, dan batas jumlah penggunaan",
        "Voucher yang kadaluarsa atau nonaktif tidak dapat digunakan saat checkout",
        "Setiap penggunaan voucher dicatat di voucher_usages untuk mencegah pemakaian melebihi batas"
      ],
      "invoice_payment": [
        "Invoice dibuat dari kombinasi child + package + voucher opsional",
        "Status pembayaran: pending, paid, failed, expired, cancelled",
        "Tahap awal hanya mendukung manual payment dengan upload bukti pembayaran",
        "Perubahan status invoice hanya boleh mengikuti alur yang diizinkan",
        "Arsitektur payment harus modular agar payment gateway dapat ditambahkan tanpa mengubah struktur inti",
        "Nominal invoice dihitung dan divalidasi di backend"
      ],
      "attendance": [
        "Status kehadiran: hadir, izin, sakit, tidak_hadir",
        "Setiap catatan kehadiran menyimpan jam masuk, jam keluar, admin pencatat, dan catatan opsional",
        "Orang tua dapat melihat status kehadiran anaknya sendiri",
        "Check-in/check-out dapat dikembangkan menjadi QR Attendance pada fase premium"
      ],
      "daily_story": [
        "Hari Ini di Daycare adalah pengalaman utama untuk merangkum kegiatan anak dalam satu hari",
        "Daily Story menggabungkan daily report, aktivitas, makan, tidur, mood, catatan admin, dokumentasi, dan perkembangan yang relevan",
        "Satu anak hanya memiliki satu Daily Story per hari",
        "Data tetap disimpan secara terstruktur agar dapat digunakan untuk laporan dan timeline",
        "Tampilan untuk parent harus terasa seperti ringkasan cerita harian yang mudah dipahami, bukan sekadar tabel administrasi",
        "Admin dapat membuat dan memperbarui Daily Story pada hari yang sama atau sesuai kebijakan daycare"
      ],
      "child_activity": [
        "Aktivitas memiliki master activity",
        "Aktivitas anak menyimpan child_id, activity_id, tanggal, waktu opsional, status/hasil opsional, dan catatan",
        "Aktivitas yang ditampilkan kepada parent harus hanya aktivitas anak yang terhubung dengan account tersebut"
      ],
      "child_development": [
        "Perkembangan dikelompokkan ke domain: motorik, bahasa, sosial, kognitif, kemandirian",
        "Setiap penilaian memiliki indikator, catatan, progress, dan tanggal observasi",
        "Skor/progress perkembangan adalah catatan internal daycare, BUKAN diagnosis medis dan tidak boleh diframe sebagai diagnosis",
        "Development Timeline menggabungkan riwayat observasi lintas waktu",
        "Parent dapat melihat perkembangan anaknya sendiri"
      ],
      "documentation": [
        "Dokumentasi dapat terhubung dengan child, activity, daily_story, atau event sesuai kebutuhan",
        "Orang tua hanya boleh melihat dokumentasi yang terkait langsung dengan anak sesuai kebijakan privasi daycare",
        "Dilarang menampilkan foto anak lain kepada orang tua yang tidak berkaitan",
        "File bukti pembayaran dan file sensitif harus disimpan secara private"
      ],
      "pickup_management": [
        "Orang tua dapat menentukan daftar penjemput yang diizinkan",
        "Setiap authorized pickup memiliki identitas, hubungan dengan anak, status aktif/nonaktif, dan data yang diperlukan daycare",
        "Admin dapat melihat dan memverifikasi daftar pickup",
        "Fitur verifikasi QR/pickup dapat dikembangkan setelah V1"
      ],
      "schedule_calendar": [
        "Admin dapat membuat jadwal dan event daycare",
        "Parent dapat melihat jadwal dan event yang relevan",
        "Event dapat memiliki judul, deskripsi, tanggal, waktu, lokasi opsional, dan status"
      ]
    },
    "excluded_from_v1": [
      "AI diagnosis anak",
      "AI medical assessment",
      "Video call",
      "Live CCTV",
      "Marketplace multi-daycare",
      "Payment gateway kompleks",
      "Chat real-time kompleks di luar moderasi dasar",
      "Role teacher terpisah"
    ]
  },
  "database_schema": {
    "database": "MySQL",
    "principle": "Database harus dibuat berdasarkan domain bisnis, bukan berdasarkan tampilan UI. Gunakan foreign key dan constraint yang jelas.",
    "entities": [
      {
        "name": "users",
        "purpose": "Akun login dasar (email, password hash, role reference)"
      },
      {
        "name": "roles",
        "purpose": "Definisi role: parent, admin"
      },
      {
        "name": "parents",
        "purpose": "Profil orang tua/wali"
      },
      {
        "name": "admins",
        "purpose": "Profil admin daycare"
      },
      {
        "name": "children",
        "purpose": "Data anak: nama, tanggal lahir, jenis kelamin, foto, alamat, info kesehatan dasar, emergency contact, status aktif"
      },
      {
        "name": "parent_child",
        "purpose": "Relasi many-to-many antara parents dan children"
      },
      {
        "name": "packages",
        "purpose": "Paket daycare: nama, deskripsi, harga, durasi, fasilitas, kuota, status, tanggal mulai/berakhir"
      },
      {
        "name": "child_packages",
        "purpose": "Riwayat pendaftaran anak pada suatu paket"
      },
      {
        "name": "vouchers",
        "purpose": "Kode voucher, nominal/persen diskon, min transaksi, masa berlaku, batas penggunaan, status aktif"
      },
      {
        "name": "voucher_usages",
        "purpose": "Riwayat pemakaian voucher per invoice/parent"
      },
      {
        "name": "invoices",
        "purpose": "Tagihan: child, package, voucher opsional, subtotal, discount, total, tanggal jatuh tempo, status"
      },
      {
        "name": "payments",
        "purpose": "Bukti dan riwayat pembayaran terhadap invoice"
      },
      {
        "name": "attendance",
        "purpose": "Catatan kehadiran anak per tanggal: status, jam masuk/keluar, admin pencatat, catatan"
      },
      {
        "name": "daily_stories",
        "purpose": "Ringkasan harian terstruktur untuk satu anak pada satu tanggal yang menggabungkan makan, tidur, mood, aktivitas, catatan admin, dan relasi dokumentasi/perkembangan"
      },
      {
        "name": "activities",
        "purpose": "Master daftar aktivitas/kegiatan daycare"
      },
      {
        "name": "child_activities",
        "purpose": "Relasi anak dengan aktivitas yang diikuti pada tanggal tertentu"
      },
      {
        "name": "development_categories",
        "purpose": "Kategori perkembangan: motorik, bahasa, sosial, kognitif, kemandirian"
      },
      {
        "name": "development_assessments",
        "purpose": "Penilaian perkembangan anak per kategori, indikator, progress, tanggal observasi"
      },
      {
        "name": "development_notes",
        "purpose": "Catatan naratif admin terkait perkembangan anak"
      },
      {
        "name": "media",
        "purpose": "File dokumentasi/foto kegiatan, terhubung ke child/activity/daily_story/event"
      },
      {
        "name": "notifications",
        "purpose": "Notifikasi untuk parent/admin"
      },
      {
        "name": "announcements",
        "purpose": "Pengumuman daycare"
      },
      {
        "name": "events",
        "purpose": "Kalender kegiatan daycare"
      },
      {
        "name": "authorized_pickups",
        "purpose": "Daftar penjemput yang diizinkan oleh parent untuk anak"
      },
      {
        "name": "audit_logs",
        "purpose": "Log aksi penting untuk keamanan dan akuntabilitas"
      }
    ],
    "key_relationships": [
      "parents 1..N <-> N..1 children melalui parent_child",
      "children 1..N child_packages N..1 packages",
      "children 1..N invoices",
      "invoices 1..N payments",
      "invoices N..1 vouchers (opsional) melalui voucher_usages",
      "children 1..N attendance",
      "children 1..1 per tanggal daily_stories",
      "children N..N activities melalui child_activities",
      "children 1..N development_assessments N..1 development_categories",
      "children 1..N media",
      "daily_stories 1..N media",
      "children 1..N authorized_pickups",
      "users 1..N audit_logs"
    ],
    "constraints_required": [
      "Foreign key wajib pada semua relasi antar entity",
      "Unique constraint pada kode voucher",
      "Unique constraint pada kombinasi child_id + tanggal untuk daily_stories",
      "Index pada kolom yang sering difilter: child_id, parent_id, status, tanggal",
      "Index pada invoice status dan due_date",
      "Index pada notification recipient dan read status"
    ]
  },
  "api_specification": {
    "base_stack": "Laravel REST API dengan Laravel Sanctum untuk autentikasi token-based",
    "conventions": {
      "format": "JSON request/response",
      "auth_header": "Authorization: Bearer {token}",
      "versioning": "Prefix /api/v1/",
      "response_envelope": {
        "success": "boolean",
        "message": "string",
        "data": "object|array|null",
        "errors": "object|null"
      }
    },
    "endpoint_groups": [
      {
        "group": "auth",
        "endpoints": [
          "POST /api/v1/auth/login",
          "POST /api/v1/auth/logout",
          "POST /api/v1/auth/forgot-password",
          "POST /api/v1/auth/reset-password",
          "GET /api/v1/auth/me",
          "PUT /api/v1/auth/change-password"
        ]
      },
      {
        "group": "parents_admin",
        "endpoints": [
          "GET /api/v1/admin/parents",
          "POST /api/v1/admin/parents",
          "GET /api/v1/admin/parents/{id}",
          "PUT /api/v1/admin/parents/{id}",
          "DELETE /api/v1/admin/parents/{id}"
        ]
      },
      {
        "group": "admins",
        "endpoints": [
          "GET /api/v1/admin/admins",
          "POST /api/v1/admin/admins",
          "GET /api/v1/admin/admins/{id}",
          "PUT /api/v1/admin/admins/{id}",
          "DELETE /api/v1/admin/admins/{id}"
        ]
      },
      {
        "group": "children",
        "endpoints": [
          "GET /api/v1/admin/children",
          "POST /api/v1/admin/children",
          "GET /api/v1/admin/children/{id}",
          "PUT /api/v1/admin/children/{id}",
          "DELETE /api/v1/admin/children/{id}",
          "GET /api/v1/parent/children",
          "GET /api/v1/parent/children/{id}"
        ]
      },
      {
        "group": "packages",
        "endpoints": [
          "GET /api/v1/admin/packages",
          "POST /api/v1/admin/packages",
          "GET /api/v1/admin/packages/{id}",
          "PUT /api/v1/admin/packages/{id}",
          "DELETE /api/v1/admin/packages/{id}",
          "POST /api/v1/admin/children/{child_id}/packages",
          "GET /api/v1/admin/children/{child_id}/packages",
          "GET /api/v1/parent/children/{id}/package",
          "GET /api/v1/parent/children/{id}/package/history"
        ]
      },
      {
        "group": "vouchers",
        "endpoints": [
          "GET /api/v1/admin/vouchers",
          "POST /api/v1/admin/vouchers",
          "GET /api/v1/admin/vouchers/{id}",
          "PUT /api/v1/admin/vouchers/{id}",
          "DELETE /api/v1/admin/vouchers/{id}",
          "GET /api/v1/parent/vouchers",
          "POST /api/v1/parent/vouchers/apply"
        ]
      },
      {
        "group": "attendance",
        "endpoints": [
          "POST /api/v1/admin/attendance",
          "PUT /api/v1/admin/attendance/{id}",
          "GET /api/v1/admin/attendance",
          "GET /api/v1/parent/children/{id}/attendance"
        ]
      },
      {
        "group": "invoices_payments",
        "endpoints": [
          "GET /api/v1/admin/invoices",
          "POST /api/v1/admin/invoices",
          "GET /api/v1/admin/invoices/{id}",
          "PUT /api/v1/admin/invoices/{id}/status",
          "GET /api/v1/parent/invoices",
          "GET /api/v1/parent/invoices/{id}",
          "POST /api/v1/parent/payments",
          "GET /api/v1/admin/payments"
        ]
      },
      {
        "group": "daily_story",
        "endpoints": [
          "POST /api/v1/admin/children/{id}/daily-stories",
          "PUT /api/v1/admin/daily-stories/{id}",
          "GET /api/v1/admin/daily-stories",
          "GET /api/v1/parent/children/{id}/daily-stories",
          "GET /api/v1/parent/children/{id}/daily-stories/{date}"
        ]
      },
      {
        "group": "activities",
        "endpoints": [
          "GET /api/v1/admin/activities",
          "POST /api/v1/admin/activities",
          "PUT /api/v1/admin/activities/{id}",
          "DELETE /api/v1/admin/activities/{id}",
          "POST /api/v1/admin/children/{id}/activities",
          "GET /api/v1/parent/children/{id}/activities"
        ]
      },
      {
        "group": "child_development",
        "endpoints": [
          "GET /api/v1/admin/development-categories",
          "POST /api/v1/admin/development-categories",
          "POST /api/v1/admin/children/{id}/development-assessments",
          "PUT /api/v1/admin/development-assessments/{id}",
          "GET /api/v1/parent/children/{id}/development",
          "GET /api/v1/parent/children/{id}/development/timeline"
        ]
      },
      {
        "group": "media_documentation",
        "endpoints": [
          "POST /api/v1/admin/media",
          "DELETE /api/v1/admin/media/{id}",
          "GET /api/v1/parent/children/{id}/media"
        ]
      },
      {
        "group": "notifications_announcements",
        "endpoints": [
          "GET /api/v1/notifications",
          "PUT /api/v1/notifications/{id}/read",
          "GET /api/v1/announcements",
          "POST /api/v1/admin/announcements",
          "PUT /api/v1/admin/announcements/{id}",
          "DELETE /api/v1/admin/announcements/{id}"
        ]
      },
      {
        "group": "schedule_events",
        "endpoints": [
          "GET /api/v1/events",
          "POST /api/v1/admin/events",
          "PUT /api/v1/admin/events/{id}",
          "DELETE /api/v1/admin/events/{id}"
        ]
      },
      {
        "group": "pickup",
        "endpoints": [
          "GET /api/v1/parent/children/{id}/authorized-pickups",
          "POST /api/v1/parent/children/{id}/authorized-pickups",
          "PUT /api/v1/parent/authorized-pickups/{id}",
          "DELETE /api/v1/parent/authorized-pickups/{id}",
          "GET /api/v1/admin/children/{id}/authorized-pickups"
        ]
      },
      {
        "group": "dashboard_reports",
        "endpoints": [
          "GET /api/v1/admin/dashboard",
          "GET /api/v1/parent/dashboard",
          "GET /api/v1/admin/reports/weekly",
          "GET /api/v1/admin/reports/monthly"
        ]
      }
    ],
    "mandatory_rules": [
      "Setiap endpoint /parent/* wajib memfilter data berdasarkan parent_id dari token, bukan dari parameter request sebagai sumber ownership",
      "Setiap endpoint /admin/* wajib melalui middleware role check",
      "Setiap resource anak yang diakses parent wajib melalui Laravel Policy/ownership validation",
      "Perubahan API contract wajib didokumentasikan di file ini sebelum diimplementasikan",
      "Nominal invoice harus dihitung dan diverifikasi backend"
    ]
  },
  "features": {
    "v1_features": {
      "authentication": [
        "login",
        "logout",
        "forgot_password",
        "reset_password",
        "profile",
        "change_password",
        "role_based_access"
      ],
      "child_management": [
        "tambah_anak",
        "edit_anak",
        "detail_anak",
        "status_aktif_nonaktif",
        "foto",
        "alamat",
        "info_kesehatan_dasar",
        "kontak_orang_tua",
        "emergency_contact"
      ],
      "parent_management": [
        "tambah_orang_tua",
        "edit_orang_tua",
        "lihat_anak_terhubung",
        "riwayat_pembayaran",
        "paket_digunakan"
      ],
      "daycare_package": [
        "buat_paket",
        "detail_paket",
        "harga",
        "durasi",
        "fasilitas",
        "kuota",
        "status_aktif",
        "tanggal_mulai_berakhir",
        "assign_paket_ke_anak",
        "riwayat_paket_anak",
        "parent_melihat_paket_anak"
      ],
      "voucher_promotion": [
        "buat_voucher",
        "kode_voucher",
        "diskon_nominal_persen",
        "min_transaksi",
        "masa_berlaku",
        "batas_penggunaan",
        "aktif_nonaktif"
      ],
      "attendance": [
        "catat_hadir_izin_sakit_tidak_hadir",
        "jam_masuk_keluar",
        "admin_pencatat",
        "catatan",
        "riwayat_kehadiran_untuk_parent"
      ],
      "today_at_daycare": [
        "ringkasan_harian_anak",
        "makan",
        "tidur",
        "mood",
        "aktivitas",
        "catatan_admin",
        "dokumentasi_foto",
        "waktu_kegiatan",
        "perkembangan_relevan",
        "timeline_harian",
        "satu_daily_story_per_anak_per_tanggal"
      ],
      "child_activity": [
        "master_aktivitas",
        "aktivitas_anak_per_tanggal",
        "catatan_aktivitas"
      ],
      "child_development": [
        "kategori_motorik_bahasa_sosial_kognitif_kemandirian",
        "indikator_catatan_progress_tanggal_observasi",
        "development_journal",
        "development_timeline"
      ],
      "documentation": [
        "upload_foto_kegiatan",
        "catatan_kegiatan",
        "privasi_hanya_anak_terkait"
      ],
      "notification": [
        "pembayaran_berhasil",
        "pembayaran_jatuh_tempo",
        "voucher_tersedia",
        "pengumuman",
        "laporan_perkembangan_baru",
        "daily_story_tersedia",
        "aktivitas_baru",
        "check_in",
        "check_out"
      ],
      "payment": [
        "pilih_paket",
        "invoice",
        "voucher",
        "pembayaran_manual_upload_bukti",
        "status_pending_paid_failed_expired_cancelled"
      ],
      "invoice": [
        "nomor_invoice",
        "detail_anak_paket_harga_voucher_diskon_total",
        "tanggal_jatuh_tempo",
        "status",
        "riwayat_pembayaran"
      ],
      "announcement": [
        "buat_pengumuman_admin",
        "lihat_pengumuman_parent"
      ],
      "schedule_calendar": [
        "jadwal_daycare",
        "event_daycare",
        "calendar_parent",
        "tanggal_libur",
        "kegiatan_khusus"
      ],
      "pickup_management": [
        "authorized_pickup_list",
        "tambah_penjemput",
        "edit_penjemput",
        "aktif_nonaktif",
        "admin_melihat_daftar_penjemput"
      ],
      "dashboard_admin": [
        "total_anak",
        "hadir_hari_ini",
        "tidak_hadir",
        "pembayaran_pending",
        "attendance_chart",
        "payment_summary",
        "recent_activity",
        "latest_development_reports",
        "upcoming_events",
        "voucher_aktif"
      ],
      "dashboard_parent": [
        "status_hadir_hari_ini",
        "hari_ini_di_daycare",
        "aktivitas_hari_ini",
        "perkembangan_terbaru",
        "tagihan_dan_tombol_bayar",
        "paket_anak",
        "voucher_tersedia",
        "notifikasi"
      ]
    },
    "premium_features_after_v1": {
      "weekly_child_report": "Rangkuman mingguan otomatis: kehadiran, jumlah aktivitas, Daily Story, dan perkembangan",
      "monthly_development_report": "Laporan bulanan yang bisa dilihat/download orang tua",
      "digital_certificate": "Sertifikat partisipasi kegiatan",
      "parent_feedback": "Orang tua memberi feedback ke daycare",
      "event_calendar": [
        "field_trip",
        "class_activity",
        "holiday",
        "parent_meeting"
      ],
      "pickup_management": "Pengelolaan pickup lanjutan dan verifikasi",
      "qr_attendance": "Check-in/check-out anak menggunakan QR yang dikelola daycare",
      "parent_admin_communication": "Komunikasi sederhana dengan moderasi daycare",
      "advanced_analytics": "Analitik operasional dan perkembangan"
    },
    "excluded_features": [
      "AI diagnosis anak",
      "AI medical assessment",
      "Video call",
      "Live CCTV",
      "Marketplace",
      "Multi-daycare",
      "Payment gateway kompleks di awal",
      "Chat real-time kompleks",
      "Role teacher terpisah pada V1"
    ],
    "priority_ranking": [
      {
        "feature": "Hari Ini di Daycare / Today's Story",
        "priority": 5
      },
      {
        "feature": "Child Development",
        "priority": 5
      },
      {
        "feature": "Parent App",
        "priority": 5
      },
      {
        "feature": "Payment & Invoice",
        "priority": 5
      },
      {
        "feature": "Package Management",
        "priority": 5
      },
      {
        "feature": "Attendance",
        "priority": 4
      },
      {
        "feature": "Child Activity",
        "priority": 4
      },
      {
        "feature": "Notifications",
        "priority": 4
      },
      {
        "feature": "Documentation",
        "priority": 4
      },
      {
        "feature": "Voucher",
        "priority": 4
      },
      {
        "feature": "Schedule & Calendar",
        "priority": 4
      },
      {
        "feature": "Authorized Pickup",
        "priority": 3
      },
      {
        "feature": "Weekly Report",
        "priority": 3
      },
      {
        "feature": "QR Attendance",
        "priority": 3
      },
      {
        "feature": "Advanced Analytics",
        "priority": 3
      }
    ]
  },
  "today_at_daycare_experience": {
    "name": "Hari Ini di Daycare",
    "english_name": "Today's Story",
    "purpose": "Menjadi satu pengalaman utama bagi orang tua untuk memahami apa yang terjadi pada anak selama berada di daycare.",
    "principle": "Daily Report, aktivitas, makan, tidur, mood, catatan admin, dokumentasi, dan perkembangan yang relevan tidak terasa seperti fitur terpisah. Data tetap terstruktur di backend tetapi disajikan kepada parent sebagai satu cerita harian yang mudah dipahami.",
    "example_content": {
      "summary": "Hari ini anak mengikuti kegiatan menggambar dan bermain bersama. Anak makan dengan baik dan mengikuti waktu tidur siang. Pada kegiatan sore, anak mengikuti permainan kelompok dengan baik.",
      "sections": [
        "Makan",
        "Tidur",
        "Mood",
        "Aktivitas",
        "Catatan Admin",
        "Dokumentasi",
        "Perkembangan Hari Ini"
      ]
    },
    "data_flow": [
      "Attendance",
      "Activity",
      "Meal",
      "Sleep",
      "Mood",
      "Admin Note",
      "Documentation",
      "Development Assessment",
      "Today's Story"
    ],
    "parent_experience": "Orang tua membuka dashboard dan dapat memahami kondisi serta kegiatan anak hari itu dalam beberapa detik tanpa harus membuka banyak menu.",
    "development_integration": "Jika pada hari tersebut terdapat catatan perkembangan yang relevan, Daily Story menampilkan ringkasan dan mengarahkan orang tua ke Development Timeline.",
    "design_rule": "Jangan membuat Daily Story menjadi sekadar tabel. Gunakan hierarchy informasi, timeline, card, ringkasan naratif, icon yang relevan, dan dokumentasi visual secara profesional."
  },
  "ui_ux_guidelines": {
    "theme_name": "Soft Green Daycare",
    "color_palette": {
      "primary": "soft green",
      "secondary": "white",
      "tertiary": "light gray",
      "text": "dark green text"
    },
    "style_principles": [
      "rounded cards",
      "soft shadows",
      "friendly illustrations seperlunya",
      "clean typography",
      "large touch target",
      "responsive",
      "accessible",
      "modern",
      "trustworthy",
      "friendly",
      "jangan terlalu childish",
      "jangan seperti aplikasi anak-anak yang penuh warna-warni",
      "professional SaaS appearance"
    ],
    "target_feel": "Terasa seperti produk SaaS daycare profesional yang dapat ditawarkan kepada daycare lain, tetapi tetap hangat dan mudah digunakan oleh orang tua.",
    "parent_navigation_principle": "Parent harus dapat menemukan anak, Hari Ini di Daycare, paket, tagihan, perkembangan, dokumentasi, jadwal, dan notifikasi tanpa navigasi yang membingungkan.",
    "reference_screens": {
      "login": "Logo TinyCare, pilihan masuk tidak diperlukan sebagai role picker jika role dapat diketahui dari account; form email & password, tombol MASUK",
      "parent_dashboard": "Sapaan personal, kartu anak, status hadir hari ini, ringkasan Hari Ini di Daycare, perkembangan terbaru, paket aktif, tagihan + tombol bayar, voucher tersedia, notifikasi",
      "today_at_daycare": "Ringkasan naratif hari ini, timeline kegiatan, makan, tidur, mood, catatan admin, foto, dan perkembangan relevan",
      "child_profile": "Profil anak, orang tua, paket aktif, status, riwayat paket, attendance, development, documentation",
      "admin_dashboard": "Kartu ringkasan total anak, hadir hari ini, tidak hadir, pembayaran pending, attendance chart, payment summary, recent activity, latest development reports, upcoming events"
    },
    "component_guidelines": {
      "cards": "rounded, soft shadow, padding cukup untuk touch target besar",
      "charts": "gunakan progress bar/percentage untuk perkembangan anak, chart batang/garis untuk attendance & payment",
      "notifications": "icon + judul singkat + timestamp",
      "forms": "validasi inline, pesan error jelas, mobile-friendly",
      "timeline": "gunakan timeline untuk aktivitas dan Development Timeline agar informasi lintas waktu mudah dipahami",
      "today_story": "gunakan ringkasan naratif + detail cards + timeline + media gallery"
    },
    "accessibility": [
      "kontras warna cukup untuk teks di atas soft green",
      "ukuran font minimal nyaman dibaca di mobile",
      "target sentuh minimal sesuai standar mobile (44x44pt)",
      "label form harus jelas",
      "status tidak hanya dibedakan dengan warna"
    ]
  },
  "security_rules": {
    "mandatory_controls": [
      "Laravel Sanctum untuk autentikasi API",
      "Role-based authorization pada setiap route",
      "Laravel Policies untuk otorisasi per-resource",
      "Request validation pada semua input",
      "Password hashing (bcrypt/argon2 bawaan Laravel)",
      "Secure file upload dengan validasi MIME type",
      "Validasi ukuran file upload",
      "API authentication wajib untuk semua endpoint privat",
      "Ownership validation di setiap query data anak/invoice/orang tua",
      "Audit log untuk aksi penting (create/update/delete data sensitif)",
      "Rate limiting pada endpoint autentikasi dan publik",
      "Konfigurasi CORS yang ketat",
      "Konfigurasi environment terpisah untuk production",
      "Debug mode tidak aktif di production"
    ],
    "data_access_rules": {
      "parent": {
        "allowed": "Hanya data anak yang terhubung melalui parent_child",
        "forbidden": [
          "Melihat anak lain",
          "Melihat invoice orang tua lain",
          "Melihat development report anak lain",
          "Melihat Daily Story anak lain",
          "Mengakses endpoint admin",
          "Mengubah paket anak secara langsung",
          "Mengubah status pembayaran"
        ]
      },
      "admin": {
        "principle": "Admin dapat mengelola operasional daycare sesuai permission dan tetap wajib melewati validation serta audit trail."
      }
    },
    "prohibited_practices": [
      "Hardcode credentials di source code",
      "Hardcode production secrets",
      "Menganggap build sukses berarti fitur aman/selesai",
      "Mengubah database tanpa migration",
      "Membuat endpoint tanpa authorization check",
      "Membocorkan data anak/orang tua lain melalui response API",
      "Menyimpan bukti pembayaran pada storage publik tanpa kontrol",
      "Menggunakan data dari request parent_id sebagai sumber ownership"
    ],
    "sensitive_data_handling": [
      "Info kesehatan dasar anak hanya untuk keperluan operasional daycare dan akses dibatasi",
      "Foto dan dokumentasi anak hanya ditampilkan ke parent yang berkaitan langsung",
      "Bukti pembayaran disimpan di storage yang tidak dapat diakses publik secara langsung",
      "Data authentication dan token tidak boleh masuk ke log biasa"
    ]
  },
  "validation_rules": {
    "general_principles": [
      "Semua input dari client divalidasi di backend Laravel Form Request",
      "Validasi frontend hanya untuk UX, bukan security boundary",
      "Gunakan pesan error yang jelas dan konsisten dalam bahasa Indonesia untuk user-facing",
      "Validasi ownership dilakukan setelah validasi format data",
      "Business rule harus divalidasi di backend"
    ],
    "field_level_rules": {
      "email": "format email valid, unique sesuai kebutuhan pada users",
      "password": "minimal 8 karakter, kombinasi huruf dan angka direkomendasikan",
      "child_birthdate": "wajib tanggal valid, tidak boleh di masa depan",
      "phone_number": "format nomor telepon Indonesia yang valid",
      "voucher_code": "unique, alfanumerik, tanpa spasi",
      "voucher_discount": "nominal atau persentase harus > 0; persentase maksimal 100",
      "package_price": "harus angka positif",
      "invoice_amount": "harus sama dengan hasil perhitungan package - discount, dihitung dan divalidasi di backend",
      "attendance_status": "harus salah satu dari: hadir, izin, sakit, tidak_hadir",
      "file_upload": "validasi MIME type sesuai konteks dan maksimal ukuran file",
      "daily_story_date": "tanggal valid dan tidak boleh menghasilkan duplicate story untuk child yang sama",
      "development_progress": "harus berada pada range yang ditentukan oleh desain domain, jika menggunakan numeric progress"
    },
    "business_validation": [
      "Anak hanya bisa didaftarkan ke satu paket aktif pada satu waktu",
      "Voucher tidak dapat digunakan jika sudah melewati masa berlaku atau melebihi batas penggunaan",
      "Invoice tidak dapat dibuat untuk anak yang tidak memiliki paket aktif",
      "Status invoice hanya dapat berubah mengikuti alur yang diizinkan",
      "Daily Story hanya dapat dibuat satu kali per anak per tanggal; selanjutnya update",
      "Development assessment wajib memiliki development_category_id yang valid",
      "Parent hanya dapat membaca child yang terhubung melalui parent_child",
      "Parent tidak dapat mengubah assignment package",
      "Parent hanya dapat mengelola authorized pickup milik anaknya sendiri"
    ],
    "error_response_format": {
      "success": false,
      "message": "string ringkasan error",
      "errors": {
        "field_name": [
          "pesan error spesifik"
        ]
      }
    }
  },
  "file_structure": {
    "root": "tinycare/",
    "structure": {
      "ai/": {
        "description": "Kumpulan file JSON acuan/konteks untuk AI coding agent",
        "files": [
          "MASTER_PROMPT.json",
          "PROJECT_OVERVIEW.json",
          "ROLES_PERMISSIONS.json",
          "BUSINESS_RULES.json",
          "DATABASE_SCHEMA.json",
          "API_SPECIFICATION.json",
          "FEATURES.json",
          "TODAY_AT_DAYCARE.json",
          "UI_UX_GUIDELINES.json",
          "SECURITY_RULES.json",
          "VALIDATION_RULES.json",
          "FILE_STRUCTURE.json",
          "DEVELOPMENT_PHASES.json",
          "CODING_RULES.json",
          "TESTING_STRATEGY.json",
          "DEPLOYMENT_RULES.json"
        ]
      },
      "backend/": {
        "description": "Laravel REST API",
        "suggested_structure": [
          "app/Models/",
          "app/Http/Controllers/Api/",
          "app/Http/Requests/",
          "app/Http/Middleware/",
          "app/Policies/",
          "app/Services/",
          "database/migrations/",
          "database/seeders/",
          "routes/api.php",
          "tests/Feature/",
          "tests/Unit/"
        ]
      },
      "web/": {
        "description": "React + Tailwind admin dashboard",
        "suggested_structure": [
          "src/pages/",
          "src/components/",
          "src/routes/",
          "src/services/api/",
          "src/hooks/",
          "src/context/ atau src/store/",
          "src/assets/",
          "tests/"
        ]
      },
      "mobile/": {
        "description": "Flutter app orang tua",
        "suggested_structure": [
          "lib/screens/",
          "lib/widgets/",
          "lib/services/",
          "lib/models/",
          "lib/providers/ atau lib/state/",
          "lib/utils/",
          "test/"
        ]
      }
    },
    "principle": "Struktur ini adalah acuan awal. AI coding agent WAJIB melakukan audit struktur existing project sebelum menambah/mengubah folder, dan tidak boleh membuat duplicate struktur."
  },
  "development_phases": {
    "workflow": [
      "AUDIT",
      "PLAN",
      "IMPLEMENT",
      "TEST",
      "VERIFY",
      "REPORT"
    ],
    "phases": [
      {
        "phase": 0,
        "name": "AUDIT",
        "description": "Audit Laravel, React, Flutter, MySQL, authentication, API, database, existing UI, existing features, deployment configuration. TIDAK BOLEH CODING pada fase ini.",
        "output": "TINYCARE PROJECT AUDIT REPORT"
      },
      {
        "phase": 1,
        "name": "FOUNDATION",
        "scope": [
          "authentication",
          "roles",
          "permissions",
          "user management",
          "parent",
          "admin",
          "child"
        ]
      },
      {
        "phase": 2,
        "name": "DAYCARE MANAGEMENT",
        "scope": [
          "packages",
          "child enrollment",
          "vouchers",
          "attendance",
          "schedule",
          "calendar",
          "daycare settings"
        ]
      },
      {
        "phase": 3,
        "name": "FINANCE",
        "scope": [
          "invoices",
          "payments",
          "payment proof",
          "payment status",
          "payment history",
          "payment reminders",
          "notifications"
        ]
      },
      {
        "phase": 4,
        "name": "TODAY AT DAYCARE",
        "scope": [
          "daily story",
          "activities",
          "meal",
          "sleep",
          "mood",
          "admin notes",
          "documentation",
          "timeline harian"
        ]
      },
      {
        "phase": 5,
        "name": "CHILD DEVELOPMENT",
        "scope": [
          "development categories",
          "assessments",
          "progress",
          "notes",
          "development timeline",
          "monthly report"
        ],
        "note": "Salah satu fitur utama/differentiator TinyCare."
      },
      {
        "phase": 6,
        "name": "COMMUNICATION",
        "scope": [
          "announcements",
          "notifications",
          "schedule",
          "event calendar",
          "parent feedback"
        ]
      },
      {
        "phase": 7,
        "name": "PREMIUM FEATURES",
        "scope": [
          "weekly report",
          "monthly report",
          "QR attendance",
          "pickup verification",
          "digital certificate",
          "parent-admin communication",
          "advanced analytics"
        ]
      },
      {
        "phase": 8,
        "name": "PRODUCTION",
        "scope": [
          "security audit",
          "CORS",
          "environment",
          "database",
          "API",
          "file storage",
          "build",
          "deployment",
          "domain",
          "HTTPS",
          "backup",
          "logging"
        ]
      }
    ],
    "detailed_step_order": [
      "STEP 1: Audit Project",
      "STEP 2: Authentication + Role",
      "STEP 3: Parent + Child",
      "STEP 4: Package + Enrollment",
      "STEP 5: Attendance",
      "STEP 6: Invoice + Payment",
      "STEP 7: Hari Ini di Daycare / Today's Story",
      "STEP 8: Child Development",
      "STEP 9: Documentation",
      "STEP 10: Notification",
      "STEP 11: Voucher",
      "STEP 12: Schedule + Calendar",
      "STEP 13: Authorized Pickup",
      "STEP 14: Reports",
      "STEP 15: Premium Features",
      "STEP 16: Security Audit",
      "STEP 17: Production Deployment"
    ],
    "per_feature_process": [
      "Jelaskan tujuan fitur",
      "Identifikasi file yang akan diubah",
      "Identifikasi database changes",
      "Identifikasi API changes",
      "Implementasikan",
      "Jalankan test",
      "Jalankan build jika relevan",
      "Verifikasi authorization",
      "Verifikasi ownership",
      "Verifikasi edge cases",
      "Berikan laporan perubahan"
    ]
  },
  "coding_rules": {
    "vibe_coding_rules": [
      "Jangan langsung mengubah banyak file sekaligus tanpa rencana",
      "Audit project terlebih dahulu sebelum coding",
      "Baca struktur existing project sebelum menambah kode",
      "Identifikasi fitur yang sudah ada sebelum membuat fitur baru",
      "Jangan membuat duplicate implementation",
      "Jangan menghapus fitur yang sudah bekerja tanpa persetujuan",
      "Jangan mengubah API contract tanpa alasan dan dokumentasi",
      "Jangan mengubah database sembarangan tanpa migration",
      "Setiap perubahan harus bisa diverifikasi",
      "Jalankan test/build setelah setiap perubahan signifikan",
      "Laporkan file yang berubah pada setiap iterasi",
      "Laporkan masalah/risiko yang ditemukan selama implementasi",
      "Jangan mengklaim fitur berhasil jika belum diverifikasi dengan test",
      "Jangan menghidupkan kembali role teacher kecuali diminta secara eksplisit"
    ],
    "prohibited_actions": [
      "Membuat endpoint tanpa authorization",
      "Membocorkan data anak lain kepada parent",
      "Hardcode credentials atau production secrets",
      "Mengasumsikan build sukses = fitur selesai",
      "Mengubah database tanpa migration",
      "Mengubah API contract tanpa update dokumentasi",
      "Membuat duplicate model/controller/service/component",
      "Menghapus fitur yang sudah bekerja tanpa alasan dan persetujuan"
    ],
    "workflow": "AUDIT -> PLAN -> IMPLEMENT -> TEST -> VERIFY -> REPORT",
    "commit_and_reporting_expectation": "Setiap perubahan besar dilaporkan dalam format: fitur yang dikerjakan, file yang diubah, perubahan database/API (jika ada), hasil test, dan risiko/catatan tambahan."
  },
  "testing_strategy": {
    "principle": "Build sukses tidak berarti fitur selesai. Setiap fitur wajib diverifikasi dengan test sebelum dilaporkan selesai.",
    "backend_testing": {
      "framework": "PHPUnit / Pest (Laravel)",
      "levels": [
        "Unit test untuk service/business logic",
        "Feature test untuk setiap endpoint API",
        "Test happy path + edge case + unauthorized access",
        "Test khusus ownership: parent tidak bisa akses data anak lain",
        "Test khusus role: parent tidak bisa mengakses endpoint admin",
        "Test invoice calculation",
        "Test voucher validation",
        "Test Daily Story unique per child per date"
      ]
    },
    "web_testing": {
      "framework": "React Testing Library / Vitest atau Jest",
      "levels": [
        "Component test untuk form, table, dashboard card",
        "Integration test untuk login",
        "Integration test untuk tambah anak",
        "Integration test untuk assign package",
        "Integration test untuk invoice",
        "Integration test untuk voucher",
        "Integration test untuk Daily Story admin flow"
      ]
    },
    "mobile_testing": {
      "framework": "Flutter test (widget test + unit test)",
      "levels": [
        "Unit test untuk service layer",
        "Unit test untuk parsing response",
        "Widget test untuk dashboard",
        "Widget test untuk Child Profile",
        "Widget test untuk Today's Story",
        "Widget test untuk invoice",
        "Widget test untuk development timeline"
      ]
    },
    "manual_qa_checklist": [
      "Parent login hanya melihat anak miliknya sendiri",
      "Parent dapat melihat paket aktif anak",
      "Parent tidak dapat melihat paket anak lain",
      "Admin dapat mengelola child",
      "Admin dapat assign package ke child",
      "Admin dapat membuat Daily Story",
      "Parent dapat melihat Daily Story anak",
      "Parent tidak dapat mengubah Daily Story",
      "Teacher role tidak muncul pada V1",
      "Voucher tidak bisa dipakai melebihi batas atau setelah kadaluarsa",
      "Upload bukti pembayaran memvalidasi tipe dan ukuran file",
      "Notifikasi terkirim untuk event yang relevan",
      "Dokumentasi anak tidak bocor ke parent lain",
      "Development timeline hanya menampilkan data child yang dimiliki parent"
    ],
    "regression_policy": "Setiap fitur baru pada fase berikutnya wajib menjalankan ulang test suite dari fase sebelumnya untuk memastikan tidak ada fitur lama yang rusak."
  },
  "deployment_rules": {
    "phase": "PHASE 8 - PRODUCTION",
    "pre_deployment_audit_checklist": [
      "Security: validasi authorization di semua endpoint",
      "Ownership validation di semua endpoint parent",
      "Konfigurasi CORS untuk domain production",
      "Konfigurasi environment terpisah dari development",
      "Debug mode nonaktif",
      "Migrasi database sudah final dan sudah diuji di staging",
      "API sudah terdokumentasi sesuai API_SPECIFICATION",
      "Konfigurasi file storage public/private sesuai kebutuhan",
      "Bukti pembayaran menggunakan private storage",
      "Build frontend React berjalan tanpa error",
      "Build mobile Flutter berjalan tanpa error",
      "Domain dan HTTPS/SSL sudah dikonfigurasi",
      "Backup database terjadwal",
      "Logging dan monitoring error aktif"
    ],
    "environments": {
      "local": "Untuk development sehari-hari",
      "staging": "Untuk QA dan verifikasi sebelum rilis production",
      "production": "Environment final yang diakses daycare dan orang tua"
    },
    "backend_deployment_notes": [
      "Gunakan queue/scheduler Laravel jika ada proses notifikasi terjadwal",
      "Pastikan Sanctum dikonfigurasi sesuai domain frontend",
      "Jalankan migration dengan hati-hati",
      "Hindari perintah destructive di production"
    ],
    "web_deployment_notes": [
      "Build production dengan Vite (npm run build)",
      "Pastikan API base URL sesuai environment"
    ],
    "mobile_deployment_notes": [
      "Konfigurasi base URL API sesuai environment build",
      "Siapkan proses build APK/AAB untuk Android dan sesuai kebutuhan untuk iOS"
    ],
    "rollback_policy": "Setiap deployment ke production harus memiliki rencana rollback, termasuk backup database sebelum migration dan versi kode sebelumnya yang siap di-deploy ulang."
  },
  "mandatory_first_step": {
    "instruction": "JANGAN LANGSUNG CODING. Langkah pertama wajib: AUDIT PROJECT EXISTING.",
    "audit_scope": [
      "struktur folder",
      "Laravel version",
      "React version",
      "Flutter version",
      "database & migrations",
      "models, controllers, services",
      "API routes",
      "authentication & middleware & policies",
      "React pages & state management",
      "Flutter screens & API service layer",
      "existing tests",
      "environment configuration",
      "deployment configuration"
    ],
    "output_required": {
      "name": "TINYCARE PROJECT AUDIT REPORT",
      "sections": [
        "Existing Architecture",
        "Existing Features",
        "Existing Database",
        "Existing API",
        "Existing Authentication",
        "Existing Frontend",
        "Existing Mobile",
        "Broken Features",
        "Security Risks",
        "Duplicate Implementations",
        "Missing Features",
        "Recommended Architecture",
        "Recommended Development Order"
      ]
    },
    "rule": "JANGAN mengubah file apa pun pada tahap audit. Tunggu persetujuan sebelum implementasi fitur."
  },
  "mandatory_workflow": [
    "AUDIT",
    "PLAN",
    "IMPLEMENT",
    "TEST",
    "VERIFY",
    "REPORT"
  ],
  "per_feature_process": [
    "Jelaskan tujuan fitur",
    "Identifikasi file yang akan diubah",
    "Identifikasi database changes",
    "Identifikasi API changes",
    "Implementasikan",
    "Jalankan test",
    "Jalankan build jika relevan",
    "Verifikasi authorization",
    "Verifikasi ownership",
    "Verifikasi edge cases",
    "Berikan laporan perubahan"
  ],
  "hard_prohibitions": [
    "Menghapus fitur yang sudah bekerja",
    "Membuat duplicate model/controller/API",
    "Membuat endpoint tanpa authorization",
    "Membocorkan data anak lain kepada parent",
    "Hardcode credentials",
    "Hardcode production secrets",
    "Menganggap build sukses berarti fitur selesai",
    "Mengubah database tanpa migration",
    "Mengubah API contract tanpa dokumentasi",
    "Mengklaim fitur berhasil tanpa testing",
    "Menambahkan role teacher pada V1 tanpa persetujuan eksplisit"
  ],
  "security_rule_summary": "Parent hanya dapat mengakses child yang terhubung dengan account tersebut. Admin dapat mengelola operasional sesuai permission. Semua input dan file upload divalidasi. Semua endpoint privat wajib authenticated. Gunakan Laravel Policies/Authorization dan audit log untuk aksi penting.",
  "ui_design_summary": "Tema Soft Green Daycare: modern, clean, friendly, professional, trustworthy, responsive, accessible, rounded cards, soft green accents, background putih. Jangan membuat UI penuh warna-warni seperti aplikasi anak-anak. Hari Ini di Daycare harus menjadi pengalaman utama parent untuk melihat aktivitas, makan, tidur, mood, catatan, dokumentasi, dan perkembangan anak dalam satu alur.",
  "target_outcome": "TinyCare harus terasa seperti produk SaaS daycare profesional yang dapat ditawarkan kepada daycare lain, sekaligus menjadi jembatan digital yang membuat orang tua mudah mengetahui apa yang terjadi pada anak selama berada di daycare.",
  "immediate_task": "Untuk sekarang, JANGAN membuat fitur baru. Lakukan AUDIT PROJECT TERLEBIH DAHULU dan berikan TINYCARE PROJECT AUDIT REPORT sesuai format pada mandatory_first_step.",
  "final_operating_principle": {
    "simple_summary": "TinyCare memiliki dua role utama: Admin dan Parent. Admin mengelola seluruh operasional daycare. Parent menggunakan Flutter untuk melihat dan berinteraksi dengan data milik anaknya sendiri.",
    "core_relationship": "Admin -> Laravel API -> MySQL <- Laravel API <- Parent Flutter",
    "main_parent_experience": "Parent membuka aplikasi dan dapat melihat anak, status kehadiran, Hari Ini di Daycare, paket aktif, tagihan, perkembangan, dokumentasi, jadwal, voucher, dan notifikasi.",
    "main_admin_experience": "Admin menggunakan React dashboard untuk mengelola anak, orang tua, paket, pembayaran, attendance, Hari Ini di Daycare, perkembangan, dokumentasi, voucher, pengumuman, jadwal, pickup, dan laporan.",
    "golden_rule": "Jangan membuat sistem lebih kompleks dari kebutuhan V1. Prioritaskan pengalaman parent, operasional admin, keamanan data anak, dan fitur yang benar-benar memberikan nilai."
  }
}