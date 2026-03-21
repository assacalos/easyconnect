<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

class ContactSetting extends Model
{
    protected $fillable = [
        'key',
        'value',
        'label',
        'sort_order',
    ];

    public static function getByKey(string $key, $default = null)
    {
        return Cache::remember("contact_setting:{$key}", 3600, function () use ($key, $default) {
            $setting = static::where('key', $key)->first();
            return $setting ? $setting->value : $default;
        });
    }

    public static function getAllAsArray(): array
    {
        return static::orderBy('sort_order')->get()->mapWithKeys(function ($item) {
            return [$item->key => [
                'value' => $item->value,
                'label' => $item->label ?? $item->key,
            ]];
        })->toArray();
    }
}
