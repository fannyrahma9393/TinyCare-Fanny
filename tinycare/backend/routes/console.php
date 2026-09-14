<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Expire finished child packages and send H-3 FCM reminders to parents.
// Requires a server cron entry running `php artisan schedule:run` every minute.
Schedule::command('process:child-packages')->dailyAt('00:05');
