<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\TechnicianReminder;
use App\Services\NotificationService;
use Carbon\Carbon;

class SendTechnicianRemindersCommand extends Command
{
    protected $signature = 'app:send-technician-reminders';

    protected $description = 'Envoie les rappels personnels aux techniciens (J-1, J-2 ou J-3 avant la date limite)';

    public function handle(NotificationService $notificationService): int
    {
        $today = Carbon::today();

        $reminders = TechnicianReminder::pending()
            ->with(['client', 'user'])
            ->get()
            ->filter(function (TechnicianReminder $r) use ($today) {
                $reminderDate = $r->due_date->copy()->subDays((int) $r->remind_days_before);
                return $reminderDate->isSameDay($today);
            });

        $count = 0;
        foreach ($reminders as $reminder) {
            try {
                $notificationService->notifyTechnicianPersonalReminder($reminder, (int) $reminder->remind_days_before);
                $reminder->update(['reminder_sent_at' => now()]);
                $count++;
            } catch (\Throwable $e) {
                $this->warn("Rappel technicien #{$reminder->id}: " . $e->getMessage());
            }
        }

        if ($count > 0) {
            $this->info("{$count} rappel(s) personnel(s) technicien envoyé(s).");
        }
        return 0;
    }
}
