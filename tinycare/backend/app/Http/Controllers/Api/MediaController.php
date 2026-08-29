<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Child;
use App\Models\Media;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class MediaController extends Controller
{
    /**
     * Admin: upload media documentation.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'file' => 'required|file|mimes:jpg,jpeg,png,gif,mp4,mov,avi|max:10240', // max 10MB
            'caption' => 'nullable|string|max:500',
            'mediable_type' => 'required|in:child,daily_story',
            'mediable_id' => 'required|integer',
        ]);

        // Determine file type
        $file = $request->file('file');
        $mimeType = $file->getMimeType();
        $fileType = str_starts_with($mimeType, 'image/') ? 'image' : 'video';

        // Store file in private storage
        $path = $file->store('media', 'local');

        $media = Media::create([
            'file_path' => $path,
            'file_type' => $fileType,
            'file_name' => $file->getClientOriginalName(),
            'file_size' => $file->getSize(),
            'caption' => $validated['caption'] ?? null,
            'mediable_type' => 'App\\Models\\'.ucfirst($validated['mediable_type']),
            'mediable_id' => $validated['mediable_id'],
            'uploaded_by' => $request->user()->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Dokumentasi berhasil diunggah.',
            'data' => $media,
        ], 201);
    }

    /**
     * Admin: delete media.
     */
    public function destroy(Media $media): JsonResponse
    {
        // Delete file from storage
        if (Storage::disk('local')->exists($media->file_path)) {
            Storage::disk('local')->delete($media->file_path);
        }

        $media->delete();

        return response()->json([
            'success' => true,
            'message' => 'Dokumentasi berhasil dihapus.',
        ]);
    }

    /**
     * Parent: view child's media documentation.
     */
    public function parentChildMedia(Request $request, Child $child): JsonResponse
    {
        // Verify ownership
        if (! $request->user()->parent->children->contains('id', $child->id)) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak memiliki akses ke data anak ini.',
            ], 403);
        }

        $query = Media::where(function ($query) use ($child) {
            // Media directly attached to child
            $query->where('mediable_type', 'App\\Models\\Child')
                ->where('mediable_id', $child->id)
                  // OR media attached to child's daily stories
                ->orWhere(function ($q) use ($child) {
                    $q->where('mediable_type', 'App\\Models\\DailyStory')
                        ->whereIn('mediable_id', $child->dailyStories()->pluck('id'));
                });
        });

        // Filter by type
        if ($request->type) {
            $query->where('file_type', $request->type);
        }

        $media = $query->orderBy('created_at', 'desc')
            ->paginate($request->per_page ?? 20);

        return response()->json([
            'success' => true,
            'data' => $media,
        ]);
    }

    /**
     * Admin/Parent: view media file (temporary URL).
     */
    public function show(Media $media): JsonResponse
    {
        if (! Storage::disk('local')->exists($media->file_path)) {
            return response()->json([
                'success' => false,
                'message' => 'File tidak ditemukan.',
            ], 404);
        }

        $url = Storage::disk('local')->temporaryUrl(
            $media->file_path,
            now()->addMinutes(30)
        );

        return response()->json([
            'success' => true,
            'data' => [
                'url' => $url,
                'file_type' => $media->file_type,
                'file_name' => $media->file_name,
                'caption' => $media->caption,
                'expires_at' => now()->addMinutes(30)->toIso8601String(),
            ],
        ]);
    }
}
