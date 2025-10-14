<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DevisItem extends Model
{
    use HasFactory;
    protected $fillable = [
        'devis_id',
        'designation',
        'quantite',
        'prix_unitaire',
        'remise',
    ];

    public function devis() {
        return $this->belongsTo(Devis::class);
    }

}
