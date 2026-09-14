<?php

namespace App\Console\Commands;

use App\Models\ChildPackage;
use App\Models\Notification;
use App\Services\FcmNotificationService;
use Carbon\Carbon;
use Illuminate\Console\Command;

class ProcessChildPackages extends Command
{
    protected $signature = 'process:child-packages';

    protected $description = 'Expire child packages whose period has ended and send H-3 FCM reminders to parents';

    private const REMINDER_TYPE = 'package_expiring_reminder';

    public function handle(FcmNotificationService $fcm): int
    {
        $this->expirePackages();
        $this->sendH3Reminders($fcm);

        return self::SUCCESS;
    }

    /**
     * Mark packages whose end_date has passed (before today) as expired.
     * Idempotent: already-expired rows are ignored by the status filter.
     */
    private function expirePackages(): void
    {
        $today = Carbon::today();
        $updated = ChildPackage::where('status', 'active')
            ->where('end_date', '<', $today->toDateString())
            ->update(['status' => 'expired']);

        $this->info("Expired {$updated} package(s).");
    }

    /**
     * Send a one-time reminder to the parents of children whose active package
     * ends exactly 3 days from today. Follows the existing parent link, never
     * broadcasts to unrelated parents, and never sends a duplicate reminder.
     */
    private function sendH3Reminders(FcmNotificationService $fcm): void
    {
        $target = Carbon::today()->addDays(3)->toDateString();

        $packages = ChildPackage::with(['child.parents.user', 'package'])
            ->where('status', 'active')
            ->whereDate('end_date', '=', $target)
            ->get();

        foreach ($packages as $childPackage) {
            $this->remindForPackage($childPackage, $fcm);
        }
    }

    private function remindForPackage(ChildPackage $childPackage, FcmNotificationService $fcm): void
    {
        $child = $childPackage->child;

        if (! $child) {
            return;
        }

        if ($this->alreadyNotified($childPackage)) {
            $this->line("Reminder already sent for child package #{$childPackage->id}, skipping.");

            return;
        }

        $endLabel = Carbon::parse($childPackage->end_date)
            ->locale('id')
            ->isoFormat('D MMMM YYYY');

        $title = 'Paket Anak Akan Segera Berakhir';
        $body = "Paket {$child->name} akan berakhir pada {$endLabel}. Silakan lakukan perpanjangan paket jika diperlukan.";
        $link = '/parent/children/'.$child->id.'/package';

        $fcm->notifyChildParents(
            $child,
            [
                'type' => self::REMINDER_TYPE,
                'title' => $title,
                'message' => $body,
                'link' => $link,
                'data' => [
                    'type' => self::REMINDER_TYPE,
                    'child_package_id' => (string) $childPackage->id,
                    'child_id' => (string) $child->id,
                ],
            ],
            $title,
            $body,
            $link,
            [
                'type' => self::REMINDER_TYPE,
                'child_package_id' => (string) $childPackage->id,
                'child_id' => (string) $child->id,
            ]
        );

        $this->info("H-3 reminder sent for child package #{$childPackage->id}.");
    }

    private function alreadyNotified(ChildPackage $childPackage): bool
    {
        return Notification::query()
            ->where('type', self::REMINDER_TYPE)
            ->get()
            ->contains(fn (Notification $notification) => (int) ($notification->data['child_package_id'] ?? null) === (int) $childPackage->id);
    }
}