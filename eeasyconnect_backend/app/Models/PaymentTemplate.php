<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PaymentTemplate extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'type',
        'default_amount',
        'default_payment_method',
        'default_frequency',
        'template',
        'is_default'
    ];

    protected $casts = [
        'default_amount' => 'decimal:2',
        'is_default' => 'boolean'
    ];

    // Scopes
    public function scopeDefault($query)
    {
        return $query->where('is_default', true);
    }

    public function scopeOneTime($query)
    {
        return $query->where('type', 'one_time');
    }

    public function scopeMonthly($query)
    {
        return $query->where('type', 'monthly');
    }

    // Méthodes utilitaires
    public function setAsDefault()
    {
        // Désactiver tous les autres templates par défaut
        self::where('is_default', true)->update(['is_default' => false]);
        
        // Activer ce template
        $this->update(['is_default' => true]);
    }

    public static function getDefaultTemplate($type = 'one_time')
    {
        return self::where('is_default', true)
            ->where('type', $type)
            ->first() ?? self::where('type', $type)->first();
    }

    // Méthode pour rendre le template avec des données
    public function render($payment, $client, $comptable)
    {
        $template = $this->template;
        
        // Variables disponibles dans le template
        $variables = [
            '{{payment_number}}' => $payment->payment_number,
            '{{payment_date}}' => $payment->payment_date->format('d/m/Y'),
            '{{due_date}}' => $payment->due_date ? $payment->due_date->format('d/m/Y') : '',
            '{{client_name}}' => $client->nom,
            '{{client_email}}' => $client->email,
            '{{client_address}}' => $client->adresse,
            '{{comptable_name}}' => $comptable->nom . ' ' . $comptable->prenom,
            '{{amount}}' => number_format($payment->amount, 2, ',', ' '),
            '{{currency}}' => $payment->currency,
            '{{payment_method}}' => $payment->payment_method_libelle,
            '{{description}}' => $payment->description ?? '',
            '{{notes}}' => $payment->notes ?? '',
            '{{reference}}' => $payment->reference ?? '',
        ];

        return str_replace(array_keys($variables), array_values($variables), $template);
    }
}