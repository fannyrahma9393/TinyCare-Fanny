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
use App\Models\Voucher;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
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

        // Active announcements
        $announcements = Announcement::where('is_published', true)
            ->where(function ($query) {
                $query->whereNull('publish_date')
                    ->orWhere('publish_date', '<=', now());
            })
            ->where(function ($query) {
                $query->whereNull('expire_date')
                    ->orWhere('expire_date', '>=', now());
            })
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
