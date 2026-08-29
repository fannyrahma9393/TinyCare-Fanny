<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Event;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EventController extends Controller
{
    /**
     * Admin: list all events.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Event::with('creator:id,name');

        // Filter by date range
        if ($request->from_date) {
            $query->where('date', '>=', $request->from_date);
        }
        if ($request->to_date) {
            $query->where('date', '<=', $request->to_date);
        }

        // Filter by type
        if ($request->type) {
            $query->where('type', $request->type);
        }

        // Filter by status
        if ($request->status) {
            $query->where('status', $request->status);
        }

        $events = $query->orderBy('date', 'asc')
            ->orderBy('start_time', 'asc')
            ->paginate($request->per_page ?? 30);

        return response()->json([
            'success' => true,
            'data' => $events,
        ]);
    }

    /**
     * Admin: create event.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'date' => 'required|date',
            'start_time' => 'nullable|date_format:H:i',
            'end_time' => 'nullable|date_format:H:i|after_or_equal:start_time',
            'location' => 'nullable|string|max:255',
            'type' => 'sometimes|in:activity,holiday,special,meeting',
            'status' => 'sometimes|in:scheduled,ongoing,completed,cancelled',
        ]);

        $validated['created_by'] = $request->user()->id;

        $event = Event::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Event berhasil dibuat.',
            'data' => $event,
        ], 201);
    }

    /**
     * Admin: update event.
     */
    public function update(Request $request, Event $event): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'description' => 'nullable|string|max:1000',
            'date' => 'sometimes|date',
            'start_time' => 'nullable|date_format:H:i',
            'end_time' => 'nullable|date_format:H:i|after_or_equal:start_time',
            'location' => 'nullable|string|max:255',
            'type' => 'sometimes|in:activity,holiday,special,meeting',
            'status' => 'sometimes|in:scheduled,ongoing,completed,cancelled',
        ]);

        $event->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Event berhasil diperbarui.',
            'data' => $event,
        ]);
    }

    /**
     * Admin: delete event.
     */
    public function destroy(Event $event): JsonResponse
    {
        $event->delete();

        return response()->json([
            'success' => true,
            'message' => 'Event berhasil dihapus.',
        ]);
    }

    /**
     * Parent: view events (calendar).
     */
    public function parentIndex(Request $request): JsonResponse
    {
        $query = Event::query();

        // Filter by month/year
        if ($request->month && $request->year) {
            $query->whereMonth('date', $request->month)
                ->whereYear('date', $request->year);
        } else {
            // Default: show upcoming events
            $query->where('date', '>=', Carbon::today()->subDays(30));
        }

        // Filter by type
        if ($request->type) {
            $query->where('type', $request->type);
        }

        $events = $query->orderBy('date', 'asc')
            ->orderBy('start_time', 'asc')
            ->get();

        // Group by date for calendar view
        $calendar = $events->groupBy(function ($event) {
            return $event->date->toDateString();
        })->map(function ($items, $date) {
            return [
                'date' => $date,
                'events' => $items->map(fn ($e) => [
                    'id' => $e->id,
                    'title' => $e->title,
                    'description' => $e->description,
                    'start_time' => $e->start_time,
                    'end_time' => $e->end_time,
                    'location' => $e->location,
                    'type' => $e->type,
                    'type_label' => $e->type_label,
                    'type_icon' => $e->type_icon,
                    'status' => $e->status,
                ]),
            ];
        })->values();

        return response()->json([
            'success' => true,
            'data' => [
                'events' => $events,
                'calendar' => $calendar,
            ],
        ]);
    }
}
