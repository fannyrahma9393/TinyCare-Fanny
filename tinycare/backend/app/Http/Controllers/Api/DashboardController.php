<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Announcement;
use App\Models\Attendance;
use App\Models\Child;
use App\Models\DailyStory;
use App\Models\DevelopmentAssessment;
use App\Models\Event;
use App\Models\Feedback;
use App\Models\Invoice;
use App\Models\Package;
use App\Models\ParentModel;
use App\Models\User;
use App\Models\Voucher;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    /**
     * Public: stats for landing page (no auth required).
     */
    public function publicStats(): JsonResponse
    {
        $totalChildren = Child::count();
        $totalParents = ParentModel::count();
        $totalDailyStories = \App\Models\DailyStory::count();
        $totalRevenue = Invoice::where('status', 'paid')->sum('total');
        $todayAttendance = Attendance::whereDate('date', Carbon::today())->count();
        $todayPresent = Attendance::whereDate('date', Carbon::today())->where('status', 'hadir')->count();

        // Additional stats for landing page
        $activePackages = Package::where('status', 'active')->count();
        $totalAnnouncements = Announcement::where('is_published', true)->count();
        $totalEvents = Event::where('date', '>=', Carbon::today())->count();
        $totalActivities = \App\Models\Activity::where('status', 'active')->count();
        $totalFeedback = Feedback::count();
        $totalAssessments = \App\Models\DevelopmentAssessment::count();
        $totalMedia = \App\Models\Media::count();
        $totalVouchers = Voucher::where('status', 'active')
            ->where('start_date', '<=', now())
            ->where('end_date', '>=', now())
            ->count();

        // Average satisfaction from feedback ratings
        $avgRating = Feedback::whereNotNull('rating')->avg('rating');
        $avgSatisfaction = $avgRating ? round(($avgRating / 5) * 100) : 0;

        // Testimonials from feedback (high rated, with parent name)
        $testimonials = Feedback::with(['parent.user', 'child'])
            ->whereNotNull('rating')
            ->where('rating', '>=', 4)
            ->where('status', 'responded')
            ->orderBy('rating', 'desc')
            ->orderBy('created_at', 'desc')
            ->limit(6)
            ->get()
            ->map(fn ($f) => [
                'name' => $f->parent?->user?->name ?: 'Anonim',
                'role' => 'Orang Tua',
                'text' => $f->message,
                'rating' => $f->rating,
                'child_name' => $f->child?->name,
            ]);

        // Published announcements (public page: broadcast-only, so targeted
        // announcements never leak to visitors)
        $announcements = Announcement::where('is_published', true)
            ->withinActiveWindow()
            ->whereDoesntHave('children')
            ->whereDoesntHave('parents')
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get()
            ->map(fn ($a) => [
                'id' => $a->id,
                'title' => $a->title,
                'content' => $a->content,
                'priority' => $a->priority,
                'publish_date' => $a->publish_date?->toDateString(),
            ]);

        // Upcoming events
        $events = Event::where('date', '>=', Carbon::today())
            ->orderBy('date', 'asc')
            ->limit(5)
            ->get()
            ->map(fn ($e) => [
                'id' => $e->id,
                'title' => $e->title,
                'description' => $e->description,
                'date' => $e->date->toDateString(),
                'start_time' => $e->start_time,
                'end_time' => $e->end_time,
                'location' => $e->location,
                'type' => $e->type,
            ]);

        // Active activities
        $activities = \App\Models\Activity::where('status', 'active')
            ->limit(6)
            ->get()
            ->map(fn ($a) => [
                'id' => $a->id,
                'name' => $a->name,
                'description' => $a->description,
                'category' => $a->category,
            ]);

        // Active packages
        $packages = Package::where('status', 'active')
            ->limit(4)
            ->get()
            ->map(fn ($p) => [
                'id' => $p->id,
                'name' => $p->name,
                'description' => $p->description,
                'price' => $p->price,
                'duration_days' => $p->duration_days,
            ]);

        return response()->json([
            'success' => true,
            'data' => [
                'total_children' => $totalChildren,
                'total_parents' => $totalParents,
                'total_reports' => $totalDailyStories,
                'total_revenue' => $totalRevenue,
                'today_attendance' => $todayAttendance,
                'today_present' => $todayPresent,
                'active_packages' => $activePackages,
                'total_announcements' => $totalAnnouncements,
                'total_events' => $totalEvents,
                'total_activities' => $totalActivities,
                'total_feedback' => $totalFeedback,
                'total_assessments' => $totalAssessments,
                'total_media' => $totalMedia,
                'total_vouchers' => $totalVouchers,
                'avg_satisfaction' => $avgSatisfaction,
                'testimonials' => $testimonials,
                'announcements' => $announcements,
                'events' => $events,
                'activities' => $activities,
                'packages' => $packages,
            ],
        ]);
    }

    /**
     * Admin: dashboard with real statistics from database.
     */
    public function adminDashboard(Request $request): JsonResponse
    {
        $totalChildren = Child::count();
        $activeChildren = Child::where('status', 'active')->count();
        $totalParents = ParentModel::count();
        $totalPackages = Package::count();
        $activePackages = Package::where('status', 'active')->count();
        $activeVouchers = Voucher::where('status', 'active')
            ->where('start_date', '<=', now())
            ->where('end_date', '>=', now())
            ->count();

        $todayAttendance = Attendance::whereDate('date', Carbon::today())->count();
        $todayPresent = Attendance::whereDate('date', Carbon::today())
            ->where('status', 'hadir')
            ->count();

        $pendingInvoices = Invoice::where('status', 'pending')->count();
        $paidInvoices = Invoice::where('status', 'paid')->count();
        $pendingAmount = Invoice::where('status', 'pending')->sum('total');
        $totalRevenue = Invoice::where('status', 'paid')->sum('total');
        $pendingParents = User::whereHas('role', fn ($q) => $q->where('name', 'parent'))
            ->where('status', 'pending')
            ->count();

        $recentDailyStories = DailyStory::with('child')
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get();

        $upcomingEvents = Event::where('date', '>=', Carbon::today())
            ->orderBy('date', 'asc')
            ->limit(5)
            ->get();

        $recentFeedback = Feedback::with(['parent.user', 'child'])
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'statistics' => [
                    'total_children' => $totalChildren,
                    'active_children' => $activeChildren,
                    'total_parents' => $totalParents,
                    'total_packages' => $totalPackages,
                    'active_packages' => $activePackages,
                    'active_vouchers' => $activeVouchers,
                    'today_attendance' => $todayAttendance,
                    'today_present' => $todayPresent,
                    'pending_invoices' => $pendingInvoices,
                    'paid_invoices' => $paidInvoices,
                    'pending_amount' => $pendingAmount,
                    'total_revenue' => $totalRevenue,
                    'pending_parents' => $pendingParents,
                ],
                'recent_daily_stories' => $recentDailyStories,
                'upcoming_events' => $upcomingEvents,
                'recent_feedback' => $recentFeedback,
            ],
        ]);
    }

    /**
     * Parent: comprehensive dashboard with own children data.
     */
    public function parentDashboard(Request $request): JsonResponse
    {
        $user = $request->user();
        $parent = $user->parent;

        if (! $parent) {
            return response()->json([
                'success' => true,
                'data' => [
                    'parent' => null,
                    'children' => [],
                    'today_attendance' => [],
                    'today_stories' => [],
                    'pending_invoices' => [],
                    'recent_assessments' => [],
                    'announcements' => [],
                ],
            ]);
        }

        // Parent profile info
        $parentData = [
            'id' => $parent->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $parent->phone,
        ];

        // Get parent's children with active packages
        $children = $parent->children()
            ->with(['childPackages' => function ($q) {
                $q->with('package')->where('status', 'active');
            }])
            ->get();

        // Enrich children with today's data
        $childrenEnriched = $children->map(function ($child) {
            $todayAttendance = $child->attendance()
                ->whereDate('date', Carbon::today())
                ->first();

            $todayStory = $child->dailyStories()
                ->whereDate('date', Carbon::today())
                ->first();

            $activePackage = $child->childPackages()
                ->with('package')
                ->where('status', 'active')
                ->first();

            return [
                'id' => $child->id,
                'name' => $child->name,
                'photo' => $child->photo,
                'photo_url' => $child->photo_url,
                'image_url' => $child->image_url,
                'birth_date' => $child->birth_date?->toDateString(),
                'gender' => $child->gender,
                'status' => $child->status,
                'active_package' => $activePackage ? [
                    'id' => $activePackage->package->id,
                    'name' => $activePackage->package->name,
                    'price' => $activePackage->package->price,
                    'start_date' => $activePackage->start_date?->toDateString(),
                    'end_date' => $activePackage->end_date?->toDateString(),
                ] : null,
                'today_attendance' => $todayAttendance ? [
                    'status' => $todayAttendance->status,
                    'check_in_time' => $todayAttendance->check_in_time,
                    'check_out_time' => $todayAttendance->check_out_time,
                ] : null,
                'today_story' => $todayStory ? [
                    'mood' => $todayStory->mood,
                    'summary' => $todayStory->summary,
                    'meal_rating' => $todayStory->meal_rating,
                    'sleep_hours' => $todayStory->sleep_hours,
                ] : null,
            ];
        });

        // Pending invoices for parent's children
        $childIds = $children->pluck('id');
        $pendingInvoices = Invoice::whereIn('child_id', $childIds)
            ->where('status', 'pending')
            ->with(['child', 'package'])
            ->orderBy('due_date', 'asc')
            ->get();

        // Recent development assessments
        $recentAssessments = DevelopmentAssessment::whereIn('child_id', $childIds)
            ->with('child', 'category')
            ->orderBy('observation_date', 'desc')
            ->limit(10)
            ->get();

        // Active announcements visible to this parent (broadcast + targeted)
        $parentChildIds = $children->pluck('id')->map(fn ($id) => (int) $id)->all();
        $announcements = Announcement::visibleToParent($parent->id, $parentChildIds)
            ->orderBy('created_at', 'desc')
            ->limit(10)
            ->get();

        // Upcoming events
        $upcomingEvents = Event::where('date', '>=', Carbon::today())
            ->orderBy('date', 'asc')
            ->limit(5)
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'parent' => $parentData,
                'children' => $childrenEnriched,
                'pending_invoices' => $pendingInvoices,
                'recent_assessments' => $recentAssessments,
                'announcements' => $announcements,
                'upcoming_events' => $upcomingEvents,
            ],
        ]);
    }
}
