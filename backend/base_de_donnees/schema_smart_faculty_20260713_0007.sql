
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `smart_faculty` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `smart_faculty`;
DROP TABLE IF EXISTS `alembic_version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `alembic_version` (
  `version_num` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`version_num`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `annees_academiques`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `annees_academiques` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `libelle` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `date_debut` date NOT NULL,
  `date_fin` date NOT NULL,
  `est_active` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_annees_academiques_libelle` (`libelle`),
  KEY `ix_annees_academiques_est_active` (`est_active`),
  CONSTRAINT `ck_annees_academiques_ck_annees_academiques_dates` CHECK ((`date_fin` > `date_debut`))
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `cours`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cours` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `intitule` varchar(180) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `nombre_heures` int unsigned NOT NULL,
  `nombre_credits` int unsigned NOT NULL,
  `semestre_id` bigint unsigned NOT NULL,
  `promotion_id` bigint unsigned NOT NULL,
  `est_actif` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cours_code_promotion_semestre` (`code`,`promotion_id`,`semestre_id`),
  KEY `ix_cours_semestre_id` (`semestre_id`),
  KEY `ix_cours_promotion_id` (`promotion_id`),
  KEY `ix_cours_est_actif` (`est_actif`),
  CONSTRAINT `ck_cours_ck_cours_nombre_credits_positif` CHECK ((`nombre_credits` > 0)),
  CONSTRAINT `ck_cours_ck_cours_nombre_heures_positif` CHECK ((`nombre_heures` > 0))
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `cours_enseignants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cours_enseignants` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `cours_id` bigint unsigned NOT NULL,
  `enseignant_id` bigint unsigned NOT NULL,
  `type_intervenant` enum('professeur','assistant','charge_de_cours') COLLATE utf8mb4_unicode_ci NOT NULL,
  `est_responsable` tinyint(1) NOT NULL,
  `attribue_le` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cours_enseignants_intervention` (`cours_id`,`enseignant_id`,`type_intervenant`),
  KEY `ix_cours_enseignants_enseignant_id` (`enseignant_id`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `decisions_jury`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `decisions_jury` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `session_id` bigint unsigned NOT NULL,
  `etudiant_id` bigint unsigned NOT NULL,
  `decision` enum('ADM','COMP','DEF','AJ') COLLATE utf8mb4_unicode_ci NOT NULL,
  `motif` text COLLATE utf8mb4_unicode_ci,
  `enregistre_par_utilisateur_id` bigint unsigned NOT NULL,
  `cree_le` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_decisions_jury_session_etudiant` (`session_id`,`etudiant_id`),
  KEY `fk_decisions_jury_etudiant_id_etudiants` (`etudiant_id`),
  KEY `fk_decisions_jury_enregistre_par_utilisateur_id_utilisateurs` (`enregistre_par_utilisateur_id`),
  CONSTRAINT `fk_decisions_jury_enregistre_par_utilisateur_id_utilisateurs` FOREIGN KEY (`enregistre_par_utilisateur_id`) REFERENCES `utilisateurs` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_decisions_jury_etudiant_id_etudiants` FOREIGN KEY (`etudiant_id`) REFERENCES `etudiants` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_decisions_jury_session_id_sessions_deliberation` FOREIGN KEY (`session_id`) REFERENCES `sessions_deliberation` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `demandes_inscription`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `demandes_inscription` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `reference` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `type_demande` enum('etudiant','enseignant') COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(190) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nom` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `postnom` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `prenom` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `telephone` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mot_de_passe_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `matricule` varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `promotion_id` bigint unsigned DEFAULT NULL,
  `matricule_agent` varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `grade` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `departement` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `statut` enum('en_attente','approuvee','rejetee') COLLATE utf8mb4_unicode_ci NOT NULL,
  `utilisateur_id` bigint unsigned DEFAULT NULL,
  `traite_par_utilisateur_id` bigint unsigned DEFAULT NULL,
  `motif_rejet` text COLLATE utf8mb4_unicode_ci,
  `cree_le` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `traite_le` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_demandes_inscription_reference` (`reference`),
  KEY `fk_demandes_inscription_promotion_id_promotions` (`promotion_id`),
  KEY `fk_demandes_inscription_traite_par_utilisateur_id_utilisateurs` (`traite_par_utilisateur_id`),
  KEY `fk_demandes_inscription_utilisateur_id_utilisateurs` (`utilisateur_id`),
  KEY `ix_demandes_inscription_email` (`email`),
  KEY `ix_demandes_inscription_statut` (`statut`),
  KEY `ix_demandes_inscription_type_statut` (`type_demande`,`statut`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `encadrements_projet`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `encadrements_projet` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `projet_id` bigint unsigned NOT NULL,
  `enseignant_id` bigint unsigned NOT NULL,
  `attribue_par_utilisateur_id` bigint unsigned NOT NULL,
  `role_encadrement` enum('principal','coencadreur') COLLATE utf8mb4_unicode_ci NOT NULL,
  `date_attribution` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actif` tinyint(1) NOT NULL,
  `date_fin` datetime DEFAULT NULL,
  `desactive_par_utilisateur_id` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_encadrements_projet_enseignant` (`projet_id`,`enseignant_id`),
  KEY `fk_encadrements_projet_attribue_par_utilisateur_id_utilisateurs` (`attribue_par_utilisateur_id`),
  KEY `ix_encadrements_projet_enseignant_actif` (`enseignant_id`,`actif`),
  KEY `ix_encadrements_projet_projet_actif` (`projet_id`,`actif`),
  KEY `fk_encadrements_projet_desactive_par_utilisateur` (`desactive_par_utilisateur_id`),
  CONSTRAINT `fk_encadrements_projet_attribue_par_utilisateur_id_utilisateurs` FOREIGN KEY (`attribue_par_utilisateur_id`) REFERENCES `utilisateurs` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_encadrements_projet_desactive_par_utilisateur` FOREIGN KEY (`desactive_par_utilisateur_id`) REFERENCES `utilisateurs` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_encadrements_projet_enseignant_id_enseignants` FOREIGN KEY (`enseignant_id`) REFERENCES `enseignants` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_encadrements_projet_projet_id_projets_academiques` FOREIGN KEY (`projet_id`) REFERENCES `projets_academiques` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `enrolements_academiques`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `enrolements_academiques` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `etudiant_id` bigint unsigned NOT NULL,
  `promotion_id` bigint unsigned NOT NULL,
  `annee_academique_id` bigint unsigned NOT NULL,
  `date_enrolement` date NOT NULL,
  `statut` enum('en_attente','valide','annule') COLLATE utf8mb4_unicode_ci NOT NULL,
  `cree_par_utilisateur_id` bigint unsigned NOT NULL,
  `valide_par_utilisateur_id` bigint unsigned DEFAULT NULL,
  `annule_par_utilisateur_id` bigint unsigned DEFAULT NULL,
  `reference_fiche` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `date_validation` datetime DEFAULT NULL,
  `date_annulation` datetime DEFAULT NULL,
  `motif_annulation` text COLLATE utf8mb4_unicode_ci,
  `date_creation` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `date_modification` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `cle_doublon_actif` varchar(180) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_enrolements_academiques_reference` (`reference_fiche`),
  UNIQUE KEY `uq_enrolements_academiques_cle_active` (`cle_doublon_actif`),
  KEY `fk_enrolements_academiques_annee_academique_id_annees_ac_e7e1` (`annee_academique_id`),
  KEY `fk_enrolements_academiques_cree_par_utilisateur_id_utilisateurs` (`cree_par_utilisateur_id`),
  KEY `fk_enrolements_academiques_valide_par_utilisateur_id_uti_dbc6` (`valide_par_utilisateur_id`),
  KEY `fk_enrolements_academiques_annule_par_utilisateur_id_uti_a58a` (`annule_par_utilisateur_id`),
  KEY `ix_enrolements_academiques_etudiant_annee` (`etudiant_id`,`annee_academique_id`),
  KEY `ix_enrolements_academiques_promotion_statut` (`promotion_id`,`statut`),
  KEY `ix_enrolements_academiques_statut` (`statut`),
  CONSTRAINT `fk_enrolements_academiques_annee_academique_id_annees_ac_e7e1` FOREIGN KEY (`annee_academique_id`) REFERENCES `annees_academiques` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_enrolements_academiques_annule_par_utilisateur_id_uti_a58a` FOREIGN KEY (`annule_par_utilisateur_id`) REFERENCES `utilisateurs` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_enrolements_academiques_cree_par_utilisateur_id_utilisateurs` FOREIGN KEY (`cree_par_utilisateur_id`) REFERENCES `utilisateurs` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_enrolements_academiques_etudiant_id_etudiants` FOREIGN KEY (`etudiant_id`) REFERENCES `etudiants` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_enrolements_academiques_promotion_id_promotions` FOREIGN KEY (`promotion_id`) REFERENCES `promotions` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_enrolements_academiques_valide_par_utilisateur_id_uti_dbc6` FOREIGN KEY (`valide_par_utilisateur_id`) REFERENCES `utilisateurs` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `enseignants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `enseignants` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `utilisateur_id` bigint unsigned NOT NULL,
  `matricule_agent` varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `grade` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `departement` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `statut` enum('actif','suspendu','archive') COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_enseignants_utilisateur_id` (`utilisateur_id`),
  UNIQUE KEY `uq_enseignants_matricule_agent` (`matricule_agent`),
  KEY `ix_enseignants_statut` (`statut`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `etudiants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `etudiants` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `utilisateur_id` bigint unsigned NOT NULL,
  `matricule` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `promotion_id` bigint unsigned NOT NULL,
  `date_inscription` date NOT NULL,
  `statut_academique` enum('actif','suspendu','diplome','abandon','archive') COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_etudiants_utilisateur_id` (`utilisateur_id`),
  UNIQUE KEY `uq_etudiants_matricule` (`matricule`),
  KEY `ix_etudiants_statut_academique` (`statut_academique`),
  KEY `ix_etudiants_promotion_id` (`promotion_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `evaluations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `evaluations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `cours_id` bigint unsigned NOT NULL,
  `type_evaluation_id` bigint unsigned NOT NULL,
  `titre` varchar(180) COLLATE utf8mb4_unicode_ci NOT NULL,
  `note_maximale` decimal(5,2) NOT NULL,
  `ponderation` decimal(5,2) NOT NULL,
  `statut` enum('brouillon','publiee','archivee') COLLATE utf8mb4_unicode_ci NOT NULL,
  `cree_par` bigint unsigned NOT NULL,
  `date_evaluation` date DEFAULT NULL,
  `date_publication` datetime DEFAULT NULL,
  `est_verrouillee` tinyint(1) NOT NULL,
  `cree_le` datetime NOT NULL DEFAULT (now()),
  `modifie_le` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`id`),
  KEY `fk_evaluations_cree_par_utilisateurs` (`cree_par`),
  KEY `ix_evaluations_cours_id` (`cours_id`),
  KEY `ix_evaluations_statut` (`statut`),
  KEY `ix_evaluations_type_evaluation_id` (`type_evaluation_id`),
  CONSTRAINT `ck_evaluations_ck_evaluations_note_maximale_positive` CHECK ((`note_maximale` > 0)),
  CONSTRAINT `ck_evaluations_ck_evaluations_ponderation_positive` CHECK ((`ponderation` > 0))
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `evaluations_risque`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `evaluations_risque` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `etudiant_id` bigint unsigned NOT NULL,
  `cours_id` bigint unsigned DEFAULT NULL,
  `score_risque` decimal(5,2) NOT NULL,
  `niveau_risque` enum('faible','moyen','eleve') COLLATE utf8mb4_unicode_ci NOT NULL,
  `raisons` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `calcule_le` datetime NOT NULL DEFAULT (now()),
  `est_active` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_evaluations_risque_niveau` (`niveau_risque`),
  KEY `ix_evaluations_risque_etudiant_id` (`etudiant_id`),
  KEY `ix_evaluations_risque_active` (`est_active`),
  KEY `ix_evaluations_risque_cours_id` (`cours_id`),
  CONSTRAINT `ck_evaluations_risque_ck_evaluations_risque_score_max` CHECK ((`score_risque` <= 100)),
  CONSTRAINT `ck_evaluations_risque_ck_evaluations_risque_score_min` CHECK ((`score_risque` >= 0))
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `historiques_reclamations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `historiques_reclamations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `reclamation_id` bigint unsigned NOT NULL,
  `ancien_statut` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nouveau_statut` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `modifie_par` bigint unsigned NOT NULL,
  `commentaire` text COLLATE utf8mb4_unicode_ci,
  `modifie_le` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`id`),
  KEY `ix_historiques_reclamations_modifie_par` (`modifie_par`),
  KEY `ix_historiques_reclamations_reclamation_id` (`reclamation_id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `inscriptions_cours`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inscriptions_cours` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `etudiant_id` bigint unsigned NOT NULL,
  `cours_id` bigint unsigned NOT NULL,
  `annee_academique_id` bigint unsigned NOT NULL,
  `date_inscription` date NOT NULL,
  `statut` enum('active','retiree','validee','archivee') COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_inscriptions_cours_etudiant_cours_annee` (`etudiant_id`,`cours_id`,`annee_academique_id`),
  KEY `ix_inscriptions_cours_cours_id` (`cours_id`),
  KEY `ix_inscriptions_cours_statut` (`statut`),
  KEY `ix_inscriptions_cours_annee_academique_id` (`annee_academique_id`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `jetons_actualisation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jetons_actualisation` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `utilisateur_id` bigint unsigned NOT NULL,
  `jeton_hash` varchar(190) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` datetime NOT NULL,
  `est_revoque` tinyint(1) NOT NULL,
  `cree_le` datetime NOT NULL DEFAULT (now()),
  `revoque_le` datetime DEFAULT NULL,
  `appareil` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `adresse_ip` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_jetons_actualisation_jeton_hash` (`jeton_hash`),
  KEY `ix_jetons_actualisation_expiration` (`expiration`),
  KEY `ix_jetons_actualisation_utilisateur_id` (`utilisateur_id`)
) ENGINE=MyISAM AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `journaux_audit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `journaux_audit` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `utilisateur_id` bigint unsigned DEFAULT NULL,
  `action` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `entite` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `entite_id` bigint unsigned DEFAULT NULL,
  `details_json` json DEFAULT NULL,
  `cree_le` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`id`),
  KEY `ix_journaux_audit_entite` (`entite`,`entite_id`),
  KEY `ix_journaux_audit_utilisateur_id` (`utilisateur_id`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `lectures_publications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `lectures_publications` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `publication_id` bigint unsigned NOT NULL,
  `utilisateur_id` bigint unsigned NOT NULL,
  `lu_le` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_lectures_publications_publication_utilisateur` (`publication_id`,`utilisateur_id`),
  KEY `ix_lectures_publications_utilisateur_id` (`utilisateur_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `membres_jury`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `membres_jury` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `session_id` bigint unsigned NOT NULL,
  `utilisateur_id` bigint unsigned NOT NULL,
  `qualite` enum('president','membre','secretaire') COLLATE utf8mb4_unicode_ci NOT NULL,
  `present` tinyint(1) NOT NULL,
  `date_ajout` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_membres_jury_session_utilisateur` (`session_id`,`utilisateur_id`),
  KEY `ix_membres_jury_utilisateur_id` (`utilisateur_id`),
  CONSTRAINT `fk_membres_jury_session_id_sessions_deliberation` FOREIGN KEY (`session_id`) REFERENCES `sessions_deliberation` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_membres_jury_utilisateur_id_utilisateurs` FOREIGN KEY (`utilisateur_id`) REFERENCES `utilisateurs` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `messages_reclamations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `messages_reclamations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `reclamation_id` bigint unsigned NOT NULL,
  `auteur_id` bigint unsigned NOT NULL,
  `message` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `cree_le` datetime NOT NULL DEFAULT (now()),
  `est_interne` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_messages_reclamations_reclamation_id` (`reclamation_id`),
  KEY `ix_messages_reclamations_auteur_id` (`auteur_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `notes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `evaluation_id` bigint unsigned NOT NULL,
  `etudiant_id` bigint unsigned NOT NULL,
  `note_obtenue` decimal(5,2) NOT NULL,
  `commentaire` text COLLATE utf8mb4_unicode_ci,
  `encodee_par` bigint unsigned NOT NULL,
  `cree_le` datetime NOT NULL DEFAULT (now()),
  `modifie_le` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_notes_evaluation_etudiant` (`evaluation_id`,`etudiant_id`),
  KEY `ix_notes_encodee_par` (`encodee_par`),
  KEY `ix_notes_etudiant_id` (`etudiant_id`),
  CONSTRAINT `ck_notes_ck_notes_note_obtenue_positive` CHECK ((`note_obtenue` >= 0))
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `utilisateur_id` bigint unsigned NOT NULL,
  `type_notification` enum('nouvelle_note','nouvelle_publication','reclamation_mise_a_jour','alerte_academique','information_systeme') COLLATE utf8mb4_unicode_ci NOT NULL,
  `titre` varchar(180) COLLATE utf8mb4_unicode_ci NOT NULL,
  `contenu` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `donnees_json` json DEFAULT NULL,
  `est_lue` tinyint(1) NOT NULL,
  `cree_le` datetime NOT NULL DEFAULT (now()),
  `lue_le` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_notifications_utilisateur_id` (`utilisateur_id`),
  KEY `ix_notifications_est_lue` (`est_lue`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `permissions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_permissions_code` (`code`)
) ENGINE=MyISAM AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `pieces_jointes_publications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pieces_jointes_publications` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `publication_id` bigint unsigned NOT NULL,
  `nom_original` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nom_stockage` varchar(190) COLLATE utf8mb4_unicode_ci NOT NULL,
  `chemin` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `type_mime` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `taille` bigint unsigned NOT NULL,
  `ajoute_le` datetime NOT NULL DEFAULT (now()),
  `est_archivee` tinyint(1) NOT NULL DEFAULT '0',
  `archivee_le` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pieces_jointes_publications_nom_stockage` (`nom_stockage`),
  KEY `ix_pieces_jointes_publications_publication_id` (`publication_id`),
  KEY `ix_pieces_jointes_publications_est_archivee` (`est_archivee`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `presences`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `presences` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `etudiant_id` bigint unsigned NOT NULL,
  `cours_id` bigint unsigned NOT NULL,
  `date_seance` date NOT NULL,
  `statut` enum('present','absent','retard','justifie') COLLATE utf8mb4_unicode_ci NOT NULL,
  `enregistre_par` bigint unsigned NOT NULL,
  `cree_le` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_presences_etudiant_cours_seance` (`etudiant_id`,`cours_id`,`date_seance`),
  KEY `ix_presences_cours_id` (`cours_id`),
  KEY `ix_presences_enregistre_par` (`enregistre_par`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `projets_academiques`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `projets_academiques` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `etudiant_id` bigint unsigned NOT NULL,
  `titre` varchar(180) COLLATE utf8mb4_unicode_ci NOT NULL,
  `type_projet` enum('reseaux','systemes_embarques','intelligence_artificielle','genie_logiciel') COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `promotion_id` bigint unsigned NOT NULL,
  `annee_academique_id` bigint unsigned NOT NULL,
  `statut` enum('propose','en_cours','suspendu','termine','archive') COLLATE utf8mb4_unicode_ci NOT NULL,
  `cree_le` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `modifie_le` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_projets_academiques_annee_academique_id_annees_academiques` (`annee_academique_id`),
  KEY `ix_projets_academiques_etudiant_id` (`etudiant_id`),
  KEY `ix_projets_academiques_promotion_annee` (`promotion_id`,`annee_academique_id`),
  KEY `ix_projets_academiques_type_statut` (`type_projet`,`statut`),
  CONSTRAINT `fk_projets_academiques_annee_academique_id_annees_academiques` FOREIGN KEY (`annee_academique_id`) REFERENCES `annees_academiques` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_projets_academiques_etudiant_id_etudiants` FOREIGN KEY (`etudiant_id`) REFERENCES `etudiants` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_projets_academiques_promotion_id_promotions` FOREIGN KEY (`promotion_id`) REFERENCES `promotions` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `promotions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `promotions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `nom` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `niveau` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `annee_academique_id` bigint unsigned NOT NULL,
  `est_active` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_promotions_nom_annee` (`nom`,`annee_academique_id`),
  KEY `ix_promotions_annee_academique_id` (`annee_academique_id`),
  KEY `ix_promotions_est_active` (`est_active`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `publications_valve`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `publications_valve` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `cours_id` bigint unsigned NOT NULL,
  `auteur_id` bigint unsigned NOT NULL,
  `type_publication` enum('annonce','communique','devoir','support_de_cours','changement_horaire','consigne_examen','rappel','publication_notes') COLLATE utf8mb4_unicode_ci NOT NULL,
  `titre` varchar(180) COLLATE utf8mb4_unicode_ci NOT NULL,
  `contenu` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `est_importante` tinyint(1) NOT NULL,
  `statut` enum('brouillon','publiee','archivee') COLLATE utf8mb4_unicode_ci NOT NULL,
  `publie_le` datetime DEFAULT NULL,
  `modifie_le` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`id`),
  KEY `ix_publications_valve_cours_id` (`cours_id`),
  KEY `ix_publications_valve_statut` (`statut`),
  KEY `ix_publications_valve_auteur_id` (`auteur_id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `reclamations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reclamations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `etudiant_id` bigint unsigned NOT NULL,
  `cours_id` bigint unsigned DEFAULT NULL,
  `note_id` bigint unsigned DEFAULT NULL,
  `categorie` enum('erreur_note','inscription','cours','document_academique','autre') COLLATE utf8mb4_unicode_ci NOT NULL,
  `objet` varchar(180) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `statut` enum('en_attente','en_cours','resolue','rejetee') COLLATE utf8mb4_unicode_ci NOT NULL,
  `priorite` enum('faible','normale','elevee','urgente') COLLATE utf8mb4_unicode_ci NOT NULL,
  `assignee_a` bigint unsigned DEFAULT NULL,
  `cree_le` datetime NOT NULL DEFAULT (now()),
  `modifie_le` datetime NOT NULL DEFAULT (now()),
  `resolue_le` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_reclamations_assignee_a` (`assignee_a`),
  KEY `ix_reclamations_note_id` (`note_id`),
  KEY `ix_reclamations_etudiant_id` (`etudiant_id`),
  KEY `ix_reclamations_cours_id` (`cours_id`),
  KEY `ix_reclamations_statut` (`statut`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `resultats_cours`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resultats_cours` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `etudiant_id` bigint unsigned NOT NULL,
  `cours_id` bigint unsigned NOT NULL,
  `moyenne` decimal(5,2) NOT NULL,
  `credits_obtenus` bigint unsigned NOT NULL,
  `statut_resultat` enum('en_attente','reussi','echoue') COLLATE utf8mb4_unicode_ci NOT NULL,
  `calcule_le` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_resultats_cours_etudiant_cours` (`etudiant_id`,`cours_id`),
  KEY `ix_resultats_cours_statut_resultat` (`statut_resultat`),
  KEY `ix_resultats_cours_cours_id` (`cours_id`),
  CONSTRAINT `ck_resultats_cours_ck_resultats_cours_moyenne_positive` CHECK ((`moyenne` >= 0))
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `resultats_semestre_officiels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resultats_semestre_officiels` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `session_id` bigint unsigned NOT NULL,
  `etudiant_id` bigint unsigned NOT NULL,
  `annee_academique_id` bigint unsigned NOT NULL,
  `semestre_id` bigint unsigned NOT NULL,
  `moyenne_ponderee` decimal(5,2) NOT NULL,
  `credits_prevus` int NOT NULL,
  `credits_capitalises` int NOT NULL,
  `credits_non_capitalises` int NOT NULL,
  `decision` enum('ADM','COMP','DEF','AJ') COLLATE utf8mb4_unicode_ci NOT NULL,
  `statut_publication` enum('non_publie','publie','remplace') COLLATE utf8mb4_unicode_ci NOT NULL,
  `formule_version` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `valide_par_jury` tinyint(1) NOT NULL,
  `president_jury_id` bigint unsigned DEFAULT NULL,
  `date_validation` datetime NOT NULL,
  `publie_par_utilisateur_id` bigint unsigned DEFAULT NULL,
  `date_publication` datetime DEFAULT NULL,
  `version` int NOT NULL,
  `est_actif` tinyint(1) NOT NULL,
  `motif_correction` text COLLATE utf8mb4_unicode_ci,
  `cree_le` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_snapshots_session_etudiant` (`session_id`,`etudiant_id`),
  UNIQUE KEY `uq_snapshots_etudiant_perimetre_version` (`etudiant_id`,`annee_academique_id`,`semestre_id`,`version`),
  KEY `fk_resultats_semestre_officiels_annee_academique_id_anne_52b4` (`annee_academique_id`),
  KEY `fk_resultats_semestre_officiels_semestre_id_semestres` (`semestre_id`),
  KEY `fk_resultats_semestre_officiels_president_jury_id_utilisateurs` (`president_jury_id`),
  KEY `fk_resultats_semestre_officiels_publie_par_utilisateur_i_aab8` (`publie_par_utilisateur_id`),
  KEY `ix_snapshots_etudiant_actif` (`etudiant_id`,`est_actif`),
  CONSTRAINT `fk_resultats_semestre_officiels_annee_academique_id_anne_52b4` FOREIGN KEY (`annee_academique_id`) REFERENCES `annees_academiques` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_resultats_semestre_officiels_etudiant_id_etudiants` FOREIGN KEY (`etudiant_id`) REFERENCES `etudiants` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_resultats_semestre_officiels_president_jury_id_utilisateurs` FOREIGN KEY (`president_jury_id`) REFERENCES `utilisateurs` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_resultats_semestre_officiels_publie_par_utilisateur_i_aab8` FOREIGN KEY (`publie_par_utilisateur_id`) REFERENCES `utilisateurs` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_resultats_semestre_officiels_semestre_id_semestres` FOREIGN KEY (`semestre_id`) REFERENCES `semestres` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_resultats_semestre_officiels_session_id_sessions_deliberation` FOREIGN KEY (`session_id`) REFERENCES `sessions_deliberation` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `role_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role_permissions` (
  `role_id` bigint unsigned NOT NULL,
  `permission_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`role_id`,`permission_id`),
  UNIQUE KEY `uq_role_permissions_role_permission` (`role_id`,`permission_id`),
  KEY `ix_role_permissions_permission_id` (`permission_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `nom` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_roles_nom` (`nom`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `semestres`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `semestres` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `nom` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `numero` int unsigned NOT NULL,
  `annee_academique_id` bigint unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_semestres_annee_numero` (`annee_academique_id`,`numero`),
  CONSTRAINT `ck_semestres_ck_semestres_numero_positif` CHECK ((`numero` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `sessions_deliberation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sessions_deliberation` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `promotion_id` bigint unsigned NOT NULL,
  `annee_academique_id` bigint unsigned NOT NULL,
  `semestre_id` bigint unsigned NOT NULL,
  `statut` enum('preparation','ouverte','cloturee','publiee','annulee') COLLATE utf8mb4_unicode_ci NOT NULL,
  `cree_par_utilisateur_id` bigint unsigned NOT NULL,
  `president_utilisateur_id` bigint unsigned DEFAULT NULL,
  `date_ouverture` datetime DEFAULT NULL,
  `date_cloture` datetime DEFAULT NULL,
  `version` int NOT NULL,
  `motif_reouverture` text COLLATE utf8mb4_unicode_ci,
  `cree_le` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `modifie_le` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_sessions_deliberation_perimetre_version` (`promotion_id`,`annee_academique_id`,`semestre_id`,`version`),
  KEY `fk_sessions_deliberation_annee_academique_id_annees_academiques` (`annee_academique_id`),
  KEY `fk_sessions_deliberation_semestre_id_semestres` (`semestre_id`),
  KEY `fk_sessions_deliberation_cree_par_utilisateur_id_utilisateurs` (`cree_par_utilisateur_id`),
  KEY `fk_sessions_deliberation_president_utilisateur_id_utilisateurs` (`president_utilisateur_id`),
  KEY `ix_sessions_deliberation_statut` (`statut`),
  CONSTRAINT `fk_sessions_deliberation_annee_academique_id_annees_academiques` FOREIGN KEY (`annee_academique_id`) REFERENCES `annees_academiques` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_sessions_deliberation_cree_par_utilisateur_id_utilisateurs` FOREIGN KEY (`cree_par_utilisateur_id`) REFERENCES `utilisateurs` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_sessions_deliberation_president_utilisateur_id_utilisateurs` FOREIGN KEY (`president_utilisateur_id`) REFERENCES `utilisateurs` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_sessions_deliberation_promotion_id_promotions` FOREIGN KEY (`promotion_id`) REFERENCES `promotions` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_sessions_deliberation_semestre_id_semestres` FOREIGN KEY (`semestre_id`) REFERENCES `semestres` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `specialites_encadrement_enseignant`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `specialites_encadrement_enseignant` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `enseignant_id` bigint unsigned NOT NULL,
  `type_projet` enum('reseaux','systemes_embarques','intelligence_artificielle','genie_logiciel') COLLATE utf8mb4_unicode_ci NOT NULL,
  `actif` tinyint(1) NOT NULL,
  `date_creation` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `date_desactivation` datetime DEFAULT NULL,
  `cree_par_utilisateur_id` bigint unsigned NOT NULL,
  `cle_doublon_active` varchar(120) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_specialites_encadrement_cle_active` (`cle_doublon_active`),
  KEY `fk_specialites_encadrement_enseignant_cree_par_utilisate_175a` (`cree_par_utilisateur_id`),
  KEY `ix_specialites_encadrement_enseignant_actif` (`enseignant_id`,`actif`),
  KEY `ix_specialites_encadrement_type_actif` (`type_projet`,`actif`),
  CONSTRAINT `fk_specialites_encadrement_enseignant_cree_par_utilisate_175a` FOREIGN KEY (`cree_par_utilisateur_id`) REFERENCES `utilisateurs` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_specialites_encadrement_enseignant_enseignant_id_enseignants` FOREIGN KEY (`enseignant_id`) REFERENCES `enseignants` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `types_evaluations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `types_evaluations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `nom` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_types_evaluations_nom` (`nom`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `utilisateur_roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `utilisateur_roles` (
  `utilisateur_id` bigint unsigned NOT NULL,
  `role_id` bigint unsigned NOT NULL,
  `attribue_le` datetime NOT NULL DEFAULT (now()),
  `attribue_par` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`utilisateur_id`,`role_id`),
  UNIQUE KEY `uq_utilisateur_roles_utilisateur_role` (`utilisateur_id`,`role_id`),
  KEY `fk_utilisateur_roles_attribue_par_utilisateurs` (`attribue_par`),
  KEY `ix_utilisateur_roles_role_id` (`role_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `utilisateurs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `utilisateurs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `nom` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `postnom` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `prenom` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(190) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mot_de_passe_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `telephone` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `photo` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `statut` enum('en_attente','actif','bloque','rejete','archive') COLLATE utf8mb4_unicode_ci NOT NULL,
  `derniere_connexion` datetime DEFAULT NULL,
  `cree_le` datetime NOT NULL DEFAULT (now()),
  `modifie_le` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`id`),
  UNIQUE KEY `ix_utilisateurs_email` (`email`),
  KEY `ix_utilisateurs_statut` (`statut`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

