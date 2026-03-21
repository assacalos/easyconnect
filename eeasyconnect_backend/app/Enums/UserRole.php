<?php

namespace App\Enums;

/**
 * Rôles alignés sur la colonne users.role (entier) et l’app mobile.
 * Toute nouvelle règle d’accès doit préférer ces constantes aux entiers magiques.
 */
enum UserRole: int
{
    case Admin = 1;
    case Commercial = 2;
    case Comptable = 3;
    case RH = 4;
    case Technicien = 5;
    case Patron = 6;
    case Client = 7;

    public function label(): string
    {
        return match ($this) {
            self::Admin => 'Admin',
            self::Commercial => 'Commercial',
            self::Comptable => 'Comptable',
            self::RH => 'RH',
            self::Technicien => 'Technicien',
            self::Patron => 'Patron',
            self::Client => 'Client',
        };
    }

    /**
     * Compare à la valeur stockée en base (users.role).
     */
    public function matchesColumn(mixed $columnValue): bool
    {
        if ($columnValue === null || $columnValue === '') {
            return false;
        }

        return (int) $columnValue === $this->value;
    }

    public static function tryFromColumn(mixed $value): ?self
    {
        if ($value === null || $value === '') {
            return null;
        }
        if (! is_numeric($value)) {
            return null;
        }

        return self::tryFrom((int) $value);
    }

    /**
     * @return list<int>
     */
    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
