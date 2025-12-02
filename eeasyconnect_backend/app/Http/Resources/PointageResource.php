<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PointageResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'date_pointage' => $this->date_pointage?->format('Y-m-d'),
            'heure_arrivee' => $this->heure_arrivee,
            'heure_depart' => $this->heure_depart,
            'type_pointage' => $this->type_pointage,
            'statut' => $this->statut,
            'commentaire' => $this->commentaire,
            'lieu' => $this->lieu,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
            // Relations
            'user' => $this->whenLoaded('user', function () {
                return [
                    'id' => $this->user->id,
                    'nom' => $this->user->nom,
                    'prenom' => $this->user->prenom,
                    'email' => $this->user->email,
                ];
            }),
        ];
    }
}
