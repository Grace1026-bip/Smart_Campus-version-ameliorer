<?php

declare(strict_types=1);

namespace Application\Noyau;

use PDO;
use PDOException;
use RuntimeException;
use Throwable;

class BaseDeDonnees
{
    private static ?PDO $connexion = null;

    public static function connexion(): PDO
    {
        if (self::$connexion instanceof PDO) {
            return self::$connexion;
        }

        $configuration = require chemin_base('configuration/base_de_donnees.php');
        $ports = self::portsConnexion($configuration);
        $dernierEchec = null;

        foreach ($ports as $port) {
            $dsn = sprintf(
                '%s:host=%s;port=%d;dbname=%s;charset=%s',
                $configuration['pilote'],
                $configuration['hote'],
                $port,
                $configuration['base'],
                $configuration['encodage']
            );

            try {
                self::$connexion = new PDO(
                    $dsn,
                    $configuration['utilisateur'],
                    $configuration['mot_de_passe'],
                    $configuration['options']
                );

                return self::$connexion;
            } catch (PDOException $exception) {
                $dernierEchec = $exception;
            }
        }

        throw new RuntimeException(
            'Connexion a la base de donnees impossible sur les ports: ' . implode(', ', $ports) . '.',
            0,
            $dernierEchec
        );
    }

    public static function transaction(callable $traitement): mixed
    {
        $pdo = self::connexion();

        try {
            $pdo->beginTransaction();
            $resultat = $traitement($pdo);
            $pdo->commit();

            return $resultat;
        } catch (Throwable $exception) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }

            throw $exception;
        }
    }

    private static function portsConnexion(array $configuration): array
    {
        $ports = array_merge(
            [(int) $configuration['port']],
            array_map('intval', $configuration['ports_secours'] ?? [])
        );

        return array_values(array_unique(array_filter(
            $ports,
            static fn (int $port): bool => $port > 0
        )));
    }
}
