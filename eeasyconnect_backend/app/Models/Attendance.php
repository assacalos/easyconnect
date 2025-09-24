<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Attendance extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'check_in_time',
        'check_out_time',
        'status',
        'location',
        'photo_path',
        'notes'
    ];

    protected $casts = [
        'check_in_time' => 'datetime',
        'check_out_time' => 'datetime',
        'location' => 'array'
    ];

    // Relations
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // Scopes
    public function scopeToday($query)
    {
        return $query->whereDate('check_in_time', today());
    }

    public function scopeThisWeek($query)
    {
        return $query->whereBetween('check_in_time', [
            now()->startOfWeek(),
            now()->endOfWeek()
        ]);
    }

    public function scopeThisMonth($query)
    {
        return $query->whereBetween('check_in_time', [
            now()->startOfMonth(),
            now()->endOfMonth()
        ]);
    }

    public function scopeByUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function scopePresent($query)
    {
        return $query->where('status', 'present');
    }

    public function scopeLate($query)
    {
        return $query->where('status', 'late');
    }

    public function scopeAbsent($query)
    {
        return $query->where('status', 'absent');
    }

    // Méthodes utilitaires
    public function isCheckedIn()
    {
        return !is_null($this->check_in_time) && is_null($this->check_out_time);
    }

    public function isCheckedOut()
    {
        return !is_null($this->check_in_time) && !is_null($this->check_out_time);
    }

    public function getWorkDuration()
    {
        if ($this->isCheckedOut()) {
            return $this->check_in_time->diffInMinutes($this->check_out_time);
        }
        return null;
    }

    public function getWorkDurationInHours()
    {
        $duration = $this->getWorkDuration();
        return $duration ? round($duration / 60, 2) : null;
    }

    public function isLate($workStartTime = '08:00')
    {
        $startTime = Carbon::parse($this->check_in_time->format('Y-m-d') . ' ' . $workStartTime);
        return $this->check_in_time->gt($startTime);
    }

    public function getLateMinutes($workStartTime = '08:00')
    {
        if (!$this->isLate($workStartTime)) {
            return 0;
        }
        
        $startTime = Carbon::parse($this->check_in_time->format('Y-m-d') . ' ' . $workStartTime);
        return $this->check_in_time->diffInMinutes($startTime);
    }

    // Accesseurs
    public function getUserNameAttribute()
    {
        return $this->user ? $this->user->nom . ' ' . $this->user->prenom : 'Utilisateur inconnu';
    }

    public function getUserRoleAttribute()
    {
        if (!$this->user) return 'Inconnu';
        
        $roles = [
            1 => 'Admin',
            2 => 'Commercial',
            3 => 'Comptable',
            4 => 'RH',
            5 => 'Technicien',
            6 => 'Patron'
        ];

        return $roles[$this->user->role] ?? 'Inconnu';
    }

    public function getStatusLibelleAttribute()
    {
        $statuses = [
            'present' => 'Présent',
            'absent' => 'Absent',
            'late' => 'En retard',
            'early_leave' => 'Départ anticipé'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getLocationInfoAttribute()
    {
        if (!$this->location) return null;

        return [
            'latitude' => $this->location['latitude'] ?? null,
            'longitude' => $this->location['longitude'] ?? null,
            'address' => $this->location['address'] ?? null,
            'accuracy' => $this->location['accuracy'] ?? null,
            'timestamp' => $this->location['timestamp'] ?? null
        ];
    }

    // Méthodes statiques pour les statistiques
    public static function getAttendanceStats($userId, $startDate = null, $endDate = null)
    {
        $query = self::where('user_id', $userId);
        
        if ($startDate && $endDate) {
            $query->whereBetween('check_in_time', [$startDate, $endDate]);
        }

        $attendances = $query->get();
        
        $totalDays = $attendances->count();
        $presentDays = $attendances->where('status', 'present')->count();
        $absentDays = $attendances->where('status', 'absent')->count();
        $lateDays = $attendances->where('status', 'late')->count();
        
        $totalHours = $attendances->whereNotNull('check_out_time')
            ->sum(function ($attendance) {
                return $attendance->getWorkDurationInHours() ?? 0;
            });
        
        $averageHours = $totalDays > 0 ? round($totalHours / $totalDays, 2) : 0;

        return [
            'total_days' => $totalDays,
            'present_days' => $presentDays,
            'absent_days' => $absentDays,
            'late_days' => $lateDays,
            'average_hours' => $averageHours,
            'attendance_rate' => $totalDays > 0 ? round(($presentDays / $totalDays) * 100, 2) : 0
        ];
    }

    public static function getMonthlyStats($userId, $year = null)
    {
        $year = $year ?? now()->year;
        
        $stats = [];
        for ($month = 1; $month <= 12; $month++) {
            $startDate = Carbon::create($year, $month, 1)->startOfMonth();
            $endDate = Carbon::create($year, $month, 1)->endOfMonth();
            
            $monthStats = self::getAttendanceStats($userId, $startDate, $endDate);
            $stats[$month] = $monthStats['present_days'];
        }
        
        return $stats;
    }

    // Méthode pour vérifier si l'utilisateur peut pointer
    public static function canCheckIn($userId)
    {
        $todayAttendance = self::where('user_id', $userId)
            ->whereDate('check_in_time', today())
            ->first();
            
        return !$todayAttendance || $todayAttendance->isCheckedOut();
    }

    public static function canCheckOut($userId)
    {
        $todayAttendance = self::where('user_id', $userId)
            ->whereDate('check_in_time', today())
            ->whereNull('check_out_time')
            ->first();
            
        return $todayAttendance && $todayAttendance->isCheckedIn();
    }
}