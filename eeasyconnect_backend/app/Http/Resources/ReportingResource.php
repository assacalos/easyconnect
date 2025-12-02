<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ReportingResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $user = $request->user();
        $isPatronOrAdmin = $user && in_array($user->role, [1, 6]);

        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'user_name' => $this->user_name,
            'user_role' => $this->user_role,
            'report_date' => $this->report_date?->format('Y-m-d'),
            'metrics' => $this->metrics,
            'notes' => $this->getAllNotes(),
            'status' => $this->status,
            'submitted_at' => $this->submitted_at?->format('Y-m-d H:i:s'),
            'approved_at' => $this->approved_at?->format('Y-m-d H:i:s'),
            'comments' => $this->comments,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            // Ajouter patron_note uniquement pour Patron et Admin
            'patron_note' => $this->when($isPatronOrAdmin, $this->patron_note),
            // Relations
            'user' => $this->whenLoaded('user', function () {
                return [
                    'id' => $this->user->id,
                    'nom' => $this->user->nom,
                    'prenom' => $this->user->prenom,
                    'email' => $this->user->email,
                ];
            }),
            'approver' => $this->whenLoaded('approver', function () {
                return [
                    'id' => $this->approver->id,
                    'nom' => $this->approver->nom,
                    'prenom' => $this->approver->prenom,
                ];
            }),
        ];
    }
}
