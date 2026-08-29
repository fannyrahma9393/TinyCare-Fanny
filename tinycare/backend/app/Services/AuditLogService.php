<?php

namespace App\Services;

use App\Models\AuditLog;
use Illuminate\Http\Request;

class AuditLogService
{
    /**
     * Log an action.
     */
    public static function log(
        string $action,
        $model,
        ?array $oldValues = null,
        ?array $newValues = null,
        ?Request $request = null
    ): AuditLog {
        return AuditLog::create([
            'user_id' => $request?->user()?->id ?? auth()->id(),
            'action' => $action,
            'auditable_type' => get_class($model),
            'auditable_id' => $model->id,
            'old_values' => $oldValues,
            'new_values' => $newValues,
            'ip_address' => $request?->ip(),
            'user_agent' => $request?->userAgent(),
        ]);
    }

    /**
     * Log create action.
     */
    public static function created($model, ?Request $request = null): AuditLog
    {
        return static::log('created', $model, null, $model->toArray(), $request);
    }

    /**
     * Log update action.
     */
    public static function updated($model, array $oldValues, ?Request $request = null): AuditLog
    {
        return static::log('updated', $model, $oldValues, $model->toArray(), $request);
    }

    /**
     * Log delete action.
     */
    public static function deleted($model, ?Request $request = null): AuditLog
    {
        return static::log('deleted', $model, $model->toArray(), null, $request);
    }
}
