<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Child;
use App\Models\DevelopmentAssessment;
use App\Models\DevelopmentCategory;
use App\Models\DevelopmentNote;
use App\Services\FcmNotificationService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DevelopmentController extends Controller
{
    /**
     * Admin: list development categories.
     */
    public function categories(Request $request): JsonResponse
    {
        $categories = DevelopmentCategory::where('status', 'active')
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $categories,
        ]);
    }

    /**
     * Admin: create development category.
     */
    public function storeCategory(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:500',
            'icon' => 'nullable|string|max:50',
            'sort_order' => 'nullable|integer|min:0',
        ]);

        $category = DevelopmentCategory::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Kategori perkembangan berhasil ditambahkan.',
            'data' => $category,
        ], 201);
    }

    // ==================== ADMIN: CHILD DEVELOPMENT ====================

    /**
     * Admin: view child's development by category.
     */
    public function adminChildDevelopment(Request $request, Child $child): JsonResponse
    {
        $categories = DevelopmentCategory::where('status', 'active')
            ->with(['assessments' => function ($query) use ($child) {
                $query->where('child_id', $child->id)
                    ->orderBy('observation_date', 'desc')
                    ->limit(5);
            }])
            ->orderBy('sort_order')
            ->get();

        $summary = $categories->map(function ($category) {
            $latestAssessment = $category->assessments->first();
            $allAssessments = $category->assessments;

            $avgProgress = $allAssessments->count() > 0
                ? $allAssessments->avg(fn ($a) => match ($a->progress) {
                    'belum' => 0, 'mulai' => 25, 'berkembang' => 50,
                    'baik' => 75, 'sangat_baik' => 100, default => 0,
                })
                : 0;

            return [
                'id' => $category->id,
                'name' => $category->name,
                'icon' => $category->icon,
                'latest_assessment' => $latestAssessment ? [
                    'id' => $latestAssessment->id,
                    'progress' => $latestAssessment->progress,
                    'progress_label' => $latestAssessment->progress_label,
                    'indicator' => $latestAssessment->indicator,
                    'notes' => $latestAssessment->notes,
                    'observation_date' => $latestAssessment->observation_date->toDateString(),
                ] : null,
                'average_progress' => round($avgProgress, 1),
                'total_assessments' => $allAssessments->count(),
                'recent_assessments' => $allAssessments->take(3)->map(fn ($a) => [
                    'id' => $a->id,
                    'indicator' => $a->indicator,
                    'progress' => $a->progress,
                    'progress_label' => $a->progress_label,
                    'observation_date' => $a->observation_date->toDateString(),
                    'notes' => $a->notes,
                ]),
            ];
        });

        return response()->json([
            'success' => true,
            'data' => [
                'child' => [
                    'id' => $child->id,
                    'name' => $child->name,
                ],
                'categories' => $summary,
            ],
        ]);
    }

    /**
     * Admin: store development assessment for a child.
     */
    public function storeAssessment(Request $request, Child $child): JsonResponse
    {
        $validated = $request->validate([
            'development_category_id' => 'required|exists:development_categories,id',
            'indicator' => 'required|string|max:255',
            'notes' => 'nullable|string|max:1000',
            'progress' => 'required|in:belum,mulai,berkembang,baik,sangat_baik',
            'observation_date' => 'required|date',
        ]);

        $assessment = DevelopmentAssessment::create([
            'child_id' => $child->id,
            'development_category_id' => $validated['development_category_id'],
            'indicator' => $validated['indicator'],
            'notes' => $validated['notes'] ?? null,
            'progress' => $validated['progress'],
            'observation_date' => $validated['observation_date'],
            'assessed_by' => $request->user()->id,
        ]);

        $assessment->load(['child', 'category', 'assessor:id,name']);

        // Notify parent(s) of this child (DB + FCM push). FCM failure must NOT
        // abort the assessment save.
        $notify = app(FcmNotificationService::class)->notifyChildParents(
            $child,
            [
                'type' => 'development',
                'title' => 'Perkembangan '.($child->name ?? 'Anak'),
                'message' => 'Penilaian perkembangan baru: '.$validated['indicator'],
                'link' => '/parent/children/'.$child->id.'/development',
                'data' => [
                    'type' => 'development',
                    'child_id' => $child->id,
                ],
            ],
            'Perkembangan Anak',
            'Ada perkembangan baru untuk '.($child->name ?? 'anak Anda').'.',
            '/parent/development',
            [
                'type' => 'development',
                'child_id' => (string) $child->id,
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Penilaian perkembangan berhasil dicatat.',
            'notify' => $notify,
            'data' => $assessment,
        ], 201);
    }

    /**
     * Admin: update development assessment.
     */
    public function updateAssessment(Request $request, DevelopmentAssessment $assessment): JsonResponse
    {
        $validated = $request->validate([
            'indicator' => 'sometimes|string|max:255',
            'notes' => 'nullable|string|max:1000',
            'progress' => 'sometimes|in:belum,mulai,berkembang,baik,sangat_baik',
            'observation_date' => 'sometimes|date',
        ]);

        $assessment->update($validated);
        $assessment->load(['child', 'category', 'assessor:id,name']);

        return response()->json([
            'success' => true,
            'message' => 'Penilaian perkembangan berhasil diperbarui.',
            'data' => $assessment,
        ]);
    }

    /**
     * Admin: delete development assessment.
     */
    public function destroyAssessment(DevelopmentAssessment $assessment): JsonResponse
    {
        $assessment->delete();

        return response()->json([
            'success' => true,
            'message' => 'Penilaian perkembangan berhasil dihapus.',
        ]);
    }

    // ==================== PARENT: CHILD DEVELOPMENT ====================

    /**
     * Parent: view child's development by category.
     */
    public function parentChildDevelopment(Request $request, Child $child): JsonResponse
    {
        if (! $request->user()->parent?->children->contains('id', $child->id)) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses ke data anak ini.',
            ], 403);
        }

        $categories = DevelopmentCategory::where('status', 'active')
            ->with(['assessments' => function ($query) use ($child) {
                $query->where('child_id', $child->id)
                    ->orderBy('observation_date', 'desc')
                    ->limit(5);
            }])
            ->orderBy('sort_order')
            ->get();

        $summary = $categories->map(function ($category) {
            $latestAssessment = $category->assessments->first();
            $allAssessments = $category->assessments;

            $avgProgress = $allAssessments->count() > 0
                ? $allAssessments->avg(fn ($a) => match ($a->progress) {
                    'belum' => 0, 'mulai' => 25, 'berkembang' => 50,
                    'baik' => 75, 'sangat_baik' => 100, default => 0,
                })
                : 0;

            return [
                'id' => $category->id,
                'name' => $category->name,
                'icon' => $category->icon,
                'latest_assessment' => $latestAssessment ? [
                    'progress' => $latestAssessment->progress,
                    'progress_label' => $latestAssessment->progress_label,
                    'observation_date' => $latestAssessment->observation_date->toDateString(),
                ] : null,
                'average_progress' => round($avgProgress, 1),
                'total_assessments' => $allAssessments->count(),
                'recent_assessments' => $allAssessments->take(3)->map(fn ($a) => [
                    'indicator' => $a->indicator,
                    'progress' => $a->progress,
                    'progress_label' => $a->progress_label,
                    'observation_date' => $a->observation_date->toDateString(),
                    'notes' => $a->notes,
                ]),
            ];
        });

        return response()->json([
            'success' => true,
            'data' => [
                'child' => [
                    'id' => $child->id,
                    'name' => $child->name,
                ],
                'categories' => $summary,
            ],
        ]);
    }

    /**
     * Parent: view child's development timeline.
     */
    public function parentChildTimeline(Request $request, Child $child): JsonResponse
    {
        if (! $request->user()->parent?->children->contains('id', $child->id)) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses ke data anak ini.',
            ], 403);
        }

        $assessments = DevelopmentAssessment::where('child_id', $child->id)
            ->with(['category:id,name,icon', 'assessor:id,name'])
            ->orderBy('observation_date', 'desc')
            ->orderBy('created_at', 'desc')
            ->paginate($request->per_page ?? 20);

        $notes = DevelopmentNote::where('child_id', $child->id)
            ->with(['category:id,name,icon', 'creator:id,name'])
            ->orderBy('date', 'desc')
            ->limit(10)
            ->get();

        $timeline = $assessments->getCollection()->groupBy(fn ($a) => $a->observation_date->format('Y-m'))
            ->map(function ($items, $month) {
                return [
                    'month' => $month,
                    'month_label' => Carbon::parse($month.'-01')->locale('id')->isoFormat('MMMM YYYY'),
                    'assessments' => $items->map(fn ($a) => [
                        'id' => $a->id,
                        'category' => $a->category->name,
                        'category_icon' => $a->category->icon,
                        'indicator' => $a->indicator,
                        'progress' => $a->progress,
                        'progress_label' => $a->progress_label,
                        'progress_percentage' => $a->progress_percentage,
                        'notes' => $a->notes,
                        'date' => $a->observation_date->toDateString(),
                        'assessor' => $a->assessor?->name,
                    ]),
                ];
            })->values();

        return response()->json([
            'success' => true,
            'data' => [
                'child' => ['id' => $child->id, 'name' => $child->name],
                'timeline' => $timeline,
                'notes' => $notes->map(fn ($n) => [
                    'id' => $n->id,
                    'category' => $n->category?->name,
                    'note' => $n->note,
                    'date' => $n->date->toDateString(),
                    'created_by' => $n->creator?->name,
                ]),
            ],
        ]);
    }
}
