<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Reporting extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'report_date',
        'metrics',
        'status',
        'submitted_at',
        'approved_at',
        'approved_by',
        'comments',
        'patron_note',
        // Notes pour les métriques commerciales
        'notes_clients_prospectes',
        'notes_rdv_obtenus',
        'notes_devis_crees',
        'notes_devis_acceptes',
        'notes_nouveaux_clients',
        'notes_appels_effectues',
        'notes_emails_envoyes',
        'notes_visites_realisees',
        // Notes pour les métriques comptables
        'notes_factures_emises',
        'notes_factures_payees',
        'notes_montant_facture',
        'notes_montant_encaissement',
        'notes_bordereaux_traites',
        'notes_bons_commande_traites',
        'notes_clients_factures',
        'notes_relances_effectuees',
        'notes_encaissements',
        // Notes pour les métriques techniques
        'notes_interventions_planifiees',
        'notes_interventions_realisees',
        'notes_interventions_annulees',
        'notes_clients_visites',
        'notes_problemes_resolus',
        'notes_problemes_en_cours',
        'notes_temps_travail',
        'notes_deplacements',
        'notes_techniques',
        // Notes générales
        'notes_generales'
    ];

    protected $casts = [
        'report_date' => 'date',
        'metrics' => 'array',
        'submitted_at' => 'datetime',
        'approved_at' => 'datetime'
    ];

    // Relations
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    // Scopes
    public function scopeDraft($query)
    {
        return $query->where('status', 'draft');
    }

    public function scopeSubmitted($query)
    {
        return $query->where('status', 'submitted');
    }

    public function scopeApproved($query)
    {
        return $query->where('status', 'approved');
    }

    public function scopeByUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function scopeByDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('report_date', [$startDate, $endDate]);
    }

    // Méthodes utilitaires
    public function canBeEdited()
    {
        // Permettre l'édition des reportings soumis (non approuvés)
        // Plus de draft, donc on peut éditer les reportings soumis
        return in_array($this->status, ['draft', 'submitted']);
    }

    public function canBeSubmitted()
    {
        return $this->status === 'draft';
    }

    public function canBeApproved()
    {
        return $this->status === 'submitted';
    }

    public function submit()
    {
        if ($this->canBeSubmitted()) {
            $this->update([
                'status' => 'submitted',
                'submitted_at' => now()
            ]);
            return true;
        }
        return false;
    }

    public function approve($approvedBy, $comments = null)
    {
        if ($this->canBeApproved()) {
            $this->update([
                'status' => 'approved',
                'approved_at' => now(),
                'approved_by' => $approvedBy,
                'comments' => $comments
            ]);
            return true;
        }
        return false;
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
            'draft' => 'Brouillon',
            'submitted' => 'Soumis',
            'approved' => 'Approuvé'
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    // Méthodes pour gérer les notes par colonne
    public function getNotesForColumn($columnName)
    {
        $notesField = 'notes_' . $columnName;
        return $this->$notesField ?? null;
    }

    public function setNotesForColumn($columnName, $notes)
    {
        $notesField = 'notes_' . $columnName;
        $this->$notesField = $notes;
        return $this;
    }

    public function getAllNotes()
    {
        $notes = [];
        $fillableFields = $this->getFillable();
        
        foreach ($fillableFields as $field) {
            if (str_starts_with($field, 'notes_') && $field !== 'notes_generales') {
                $columnName = str_replace('notes_', '', $field);
                $notes[$columnName] = $this->$field;
            }
        }
        
        $notes['generales'] = $this->notes_generales;
        return $notes;
    }

    public function updateNotes($notesData)
    {
        foreach ($notesData as $columnName => $notes) {
            if ($columnName === 'generales') {
                $this->notes_generales = $notes;
            } else {
                $notesField = 'notes_' . $columnName;
                if (in_array($notesField, $this->getFillable())) {
                    $this->$notesField = $notes;
                }
            }
        }
        return $this;
    }

    // Méthodes pour générer les métriques selon le rôle
    public function generateCommercialMetrics($startDate, $endDate)
    {
        $userId = $this->user_id;
        
        // Récupérer les données du commercial
        $clientsProspectes = Client::where('user_id', $userId)
            ->whereBetween('created_at', [$startDate, $endDate])
            ->count();

        $devisCrees = Devis::where('user_id', $userId)
            ->whereBetween('created_at', [$startDate, $endDate])
            ->count();

        $devisAcceptes = Devis::where('user_id', $userId)
            ->where('status', 2) // Accepté
            ->whereBetween('created_at', [$startDate, $endDate])
            ->count();

        return [
            'clients_prospectes' => $clientsProspectes,
            'rdv_obtenus' => rand(5, 15), // À implémenter avec une vraie table RDV
            'rdv_list' => [], // À implémenter
            'devis_crees' => $devisCrees,
            'devis_acceptes' => $devisAcceptes,
            'nouveaux_clients' => $clientsProspectes,
            'appels_effectues' => rand(20, 50),
            'emails_envoyes' => rand(30, 80),
            'visites_realisees' => rand(10, 25)
        ];
    }

    public function generateComptableMetrics($startDate, $endDate)
    {
        $userId = $this->user_id;
        
        $facturesEmises = Facture::where('user_id', $userId)
            ->whereBetween('created_at', [$startDate, $endDate])
            ->count();

        $facturesPayees = Facture::where('user_id', $userId)
            ->where('statut', 'payee')
            ->whereBetween('created_at', [$startDate, $endDate])
            ->count();

        $montantFacture = Facture::where('user_id', $userId)
            ->whereBetween('created_at', [$startDate, $endDate])
            ->sum('montant_ttc');

        $bordereauxTraites = Bordereau::where('commercial_id', $userId)
            ->whereBetween('created_at', [$startDate, $endDate])
            ->count();

        $bonsCommandeTraites = BonDeCommande::where('user_id', $userId)
            ->whereBetween('created_at', [$startDate, $endDate])
            ->count();

        return [
            'factures_emises' => $facturesEmises,
            'factures_payees' => $facturesPayees,
            'montant_facture' => $montantFacture,
            'montant_encaissement' => $montantFacture * 0.8, // 80% encaissé
            'bordereaux_traites' => $bordereauxTraites,
            'bons_commande_traites' => $bonsCommandeTraites,
            'clients_factures' => $facturesEmises,
            'relances_effectuees' => rand(5, 15),
            'encaissements' => $montantFacture * 0.8
        ];
    }

    public function generateTechnicienMetrics($startDate, $endDate)
    {
        $userId = $this->user_id;
        
        // Récupérer les pointages du technicien
        $pointages = Pointage::where('user_id', $userId)
            ->whereBetween('date', [$startDate, $endDate])
            ->get();

        $interventionsPlanifiees = rand(15, 30);
        $interventionsRealisees = rand(10, 25);
        $interventionsAnnulees = $interventionsPlanifiees - $interventionsRealisees;

        return [
            'interventions_planifiees' => $interventionsPlanifiees,
            'interventions_realisees' => $interventionsRealisees,
            'interventions_annulees' => $interventionsAnnulees,
            'interventions_list' => [], // À implémenter avec une vraie table interventions
            'clients_visites' => rand(8, 20),
            'problemes_resolus' => rand(15, 30),
            'problemes_en_cours' => rand(2, 8),
            'temps_travail' => $pointages->count() * 8, // 8h par jour
            'deplacements' => rand(20, 40),
            'notes_techniques' => 'Rapport technique détaillé'
        ];
    }
}