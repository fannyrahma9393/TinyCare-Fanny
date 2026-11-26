<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * A single translated string.
 *
 * `key` is a stable identifier (the Indonesian source text for UI strings, or
 * a dot-notation key such as `notif.invoice.created` for system-generated
 * notification text). `locale` is restricted to `id` / `en` at the API layer.
 * Rows act as a remote OVERLAY on top of the static client catalogs — the
 * clients always keep their own static fallback, so a missing row never
 * breaks the UI.
 */
class Translation extends Model
{
    protected $fillable = [
        'key',
        'locale',
        'value',
    ];
}
