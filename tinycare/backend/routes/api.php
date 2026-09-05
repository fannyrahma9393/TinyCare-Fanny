<?php

use App\Http\Controllers\Api\ActivityController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\AnnouncementController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ChildController;
use App\Http\Controllers\Api\ChildInformationController;
use App\Http\Controllers\Api\DailyStoryController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\DevelopmentController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\FeedbackController;
use App\Http\Controllers\Api\FcmTokenController;
use App\Http\Controllers\Api\InvoiceController;
use App\Http\Controllers\Api\MediaController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PackageController;
use App\Http\Controllers\Api\ParentController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\PickupController;
use App\Http\Controllers\Api\RegistrationController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\UserManagementController;
use App\Http\Controllers\Api\VoucherController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| TinyCare REST API Routes
| Prefix: /api/v1/
|
*/

// Public routes with rate limiting
Route::prefix('v1/auth')->middleware('throttle:10,1')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/register-parent', [RegistrationController::class, 'registerParent']);
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('/reset-password', [AuthController::class, 'resetPassword']);
});

// Public stats (no auth required)
Route::get('/v1/public/stats', [DashboardController::class, 'publicStats'])->middleware('throttle:30,1');

// Payment webhook (no auth required)
Route::post('/v1/payments/webhook', [PaymentController::class, 'webhook']);

// Authenticated routes
Route::prefix('v1')->middleware('auth:sanctum')->group(function () {
    // Auth
    Route::prefix('auth')->group(function () {
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::get('/me', [AuthController::class, 'me']);
        Route::put('/change-password', [AuthController::class, 'changePassword']);
    });

    // Notifications (shared between admin & parent)
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::put('/notifications/{notification}/read', [NotificationController::class, 'markAsRead']);
    Route::put('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);

    // FCM tokens (shared between admin & parent, authenticated only)
    Route::post('/fcm-tokens', [FcmTokenController::class, 'store']);
    Route::delete('/fcm-tokens', [FcmTokenController::class, 'destroy']);

    // Admin routes (admin + admin_master)
    Route::middleware('role:admin,admin_master')->prefix('admin')->group(function () {
        // User Management
        Route::get('/users', [UserManagementController::class, 'index']);
        Route::get('/users/pending', [UserManagementController::class, 'pending']);
        Route::post('/users/{user}/approve', [UserManagementController::class, 'approve']);
        Route::post('/users/{user}/reject', [UserManagementController::class, 'reject']);
        Route::post('/users/{user}/activate', [UserManagementController::class, 'activate']);
        Route::post('/users/{user}/deactivate', [UserManagementController::class, 'deactivate']);

        // Parents management
        Route::apiResource('parents', ParentController::class)->except(['show']);
        Route::get('/parents/{parent}', [ParentController::class, 'show']);

        // Admins management (admin_master only for create/delete)
        Route::apiResource('admins', AdminController::class)->except(['show']);
        Route::post('/admins/{admin}/activate', [AdminController::class, 'activate']);
        Route::post('/admins/{admin}/deactivate', [AdminController::class, 'deactivate']);

        // Children management
        Route::apiResource('children', ChildController::class)->except(['show']);
        Route::get('/children/{child}', [ChildController::class, 'show']);

        // Packages management
        Route::apiResource('packages', PackageController::class);
        Route::post('/children/{child}/packages', [PackageController::class, 'assignToChild']);
        Route::get('/children/{child}/packages', [PackageController::class, 'childPackages']);

        // Vouchers management
        Route::apiResource('vouchers', VoucherController::class);

        // Attendance management
        Route::post('/attendance', [AttendanceController::class, 'store']);
        Route::put('/attendance/{attendance}', [AttendanceController::class, 'update']);
        Route::get('/attendance', [AttendanceController::class, 'index']);

        // Invoices management
        Route::apiResource('invoices', InvoiceController::class)->except(['update', 'destroy']);
        Route::put('/invoices/{invoice}/status', [InvoiceController::class, 'updateStatus']);

        // Payments management
        Route::get('/payments', [PaymentController::class, 'index']);
        Route::post('/payments/{payment}/verify', [PaymentController::class, 'verify']);
        Route::post('/payments/{payment}/reject', [PaymentController::class, 'reject']);
        Route::get('/payments/{payment}/proof', [PaymentController::class, 'showProof']);

        // Daily Stories management
        Route::get('/daily-stories', [DailyStoryController::class, 'index']);
        Route::post('/children/{child}/daily-stories', [DailyStoryController::class, 'store']);
        Route::put('/daily-stories/{dailyStory}', [DailyStoryController::class, 'update']);

        // Activities management
        Route::apiResource('activities', ActivityController::class)->except(['show']);
        Route::post('/children/{child}/activities', [ActivityController::class, 'storeChildActivity']);

        // Media management
        Route::post('/media', [MediaController::class, 'store']);
        Route::delete('/media/{media}', [MediaController::class, 'destroy']);
        Route::get('/media/{media}', [MediaController::class, 'show']);

        // Development management
        Route::get('/development-categories', [DevelopmentController::class, 'categories']);
        Route::post('/development-categories', [DevelopmentController::class, 'storeCategory']);
        Route::get('/children/{child}/development', [DevelopmentController::class, 'adminChildDevelopment']);
        Route::post('/children/{child}/development-assessments', [DevelopmentController::class, 'storeAssessment']);
        Route::put('/development-assessments/{assessment}', [DevelopmentController::class, 'updateAssessment']);
        Route::delete('/development-assessments/{assessment}', [DevelopmentController::class, 'destroyAssessment']);

        // Announcements management
        Route::apiResource('announcements', AnnouncementController::class)->except(['show']);

        // Child Information management
        Route::apiResource('child-information', ChildInformationController::class);

        // Events management
        Route::apiResource('events', EventController::class)->except(['show']);

        // Feedback management
        Route::get('/feedback', [FeedbackController::class, 'index']);
        Route::post('/feedback/{feedback}/respond', [FeedbackController::class, 'respond']);
        Route::put('/feedback/{feedback}/status', [FeedbackController::class, 'updateStatus']);

        // Authorized Pickup management
        Route::get('/children/{child}/authorized-pickups', [PickupController::class, 'adminIndex']);

        // Dashboard
        Route::get('/dashboard', [DashboardController::class, 'adminDashboard']);

        // Reports management
        Route::get('/reports/weekly', [ReportController::class, 'weeklyIndex']);
        Route::get('/reports/monthly', [ReportController::class, 'monthlyIndex']);
        Route::post('/children/{child}/reports/weekly', [ReportController::class, 'generateWeekly']);
        Route::post('/children/{child}/reports/monthly', [ReportController::class, 'generateMonthly']);
    });

    // Parent routes
    Route::middleware('role:parent')->prefix('parent')->group(function () {
        // View own children
        Route::get('/children', [ChildController::class, 'index']);
        Route::get('/children/{child}', [ChildController::class, 'show']);

        // View child's package
        Route::get('/children/{child}/package', [PackageController::class, 'parentChildPackage']);
        Route::get('/children/{child}/package/history', [PackageController::class, 'parentChildPackageHistory']);

        // View child's attendance
        Route::get('/children/{child}/attendance', [AttendanceController::class, 'parentChildAttendance']);

        // Vouchers
        Route::get('/vouchers', [VoucherController::class, 'parentIndex']);
        Route::post('/vouchers/apply', [VoucherController::class, 'applyVoucher']);

        // Invoices
        Route::get('/invoices', [InvoiceController::class, 'parentIndex']);
        Route::get('/invoices/{invoice}', [InvoiceController::class, 'parentShow']);

        // Payments
        Route::post('/payments', [PaymentController::class, 'store']);
        Route::post('/invoices/{invoice}/pay', [PaymentController::class, 'initiate']);
        Route::get('/payments/{payment}/status', [PaymentController::class, 'checkStatus']);
        Route::get('/invoices/{invoice}/payments', [PaymentController::class, 'parentInvoicePayments']);

        // Daily Stories (Today at Daycare)
        Route::get('/children/{child}/daily-stories', [DailyStoryController::class, 'parentIndex']);
        Route::get('/children/{child}/daily-stories/{date}', [DailyStoryController::class, 'parentShowByDate']);

        // Child Activities
        Route::get('/children/{child}/activities', [ActivityController::class, 'parentChildActivities']);

        // Media Documentation
        Route::get('/children/{child}/media', [MediaController::class, 'parentChildMedia']);

        // Child Development
        Route::get('/children/{child}/development', [DevelopmentController::class, 'parentChildDevelopment']);
        Route::get('/children/{child}/development/timeline', [DevelopmentController::class, 'parentChildTimeline']);

        // Announcements
        Route::get('/announcements', [AnnouncementController::class, 'parentIndex']);

        // Child Information
        Route::get('/child-information', [ChildInformationController::class, 'parentIndex']);
        Route::get('/child-information/{childInformation}', [ChildInformationController::class, 'parentShow']);

        // Events (Calendar)
        Route::get('/events', [EventController::class, 'parentIndex']);

        // Feedback
        Route::get('/feedback', [FeedbackController::class, 'parentIndex']);
        Route::post('/feedback', [FeedbackController::class, 'store']);

        // Authorized Pickup management
        Route::get('/children/{child}/authorized-pickups', [PickupController::class, 'parentIndex']);
        Route::post('/children/{child}/authorized-pickups', [PickupController::class, 'parentStore']);
        Route::put('/authorized-pickups/{pickup}', [PickupController::class, 'parentUpdate']);
        Route::delete('/authorized-pickups/{pickup}', [PickupController::class, 'parentDestroy']);

        // Dashboard
        Route::get('/dashboard', [DashboardController::class, 'parentDashboard']);

        // Reports
        Route::get('/children/{child}/reports/weekly', [ReportController::class, 'parentWeekly']);
        Route::get('/children/{child}/reports/monthly', [ReportController::class, 'parentMonthly']);
    });
});
