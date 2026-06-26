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
        $dsn = sprintf(
            '%s:host=%s;port=%d;dbname=%s;charset=%s',
            $configuration['pilote'],
            $configuration['hote'],
            $configuration['port'],
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
        } catch (PDOException $exception) {
            throw new RuntimeException('Connexion a la base de donnees impossible.', 0, $exception);
        }

        return self::$connexion;
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
}
