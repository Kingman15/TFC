DROP DATABASE IF EXISTS `consultation_travaux_bibliotheque_isp`;

CREATE DATABASE IF NOT EXISTS `consultation_travaux_bibliotheque_isp` CHARACTER SET 'utf8';

USE `consultation_travaux_bibliotheque_isp`;

CREATE TABLE `lecteur` (
	`identifiant` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`nom` VARCHAR(30) NOT NULL,
	`prenom` VARCHAR(15) NOT NULL,
	`genre` CHAR(1) NOT NULL,
	`pseudonyme` VARCHAR(25) NOT NULL UNIQUE,
	`email` VARCHAR(50) NOT NULL UNIQUE,
	`mot_de_passe` VARCHAR(100) NOT NULL,
	`date_creation_cpte` DATETIME NOT NULL,
	PRIMARY KEY(`identifiant`)
) ENGINE = InnoDB;

CREATE TABLE `option` (
	`code` VARCHAR(10) NOT NULL UNIQUE,
	`nom` VARCHAR(100) NOT NULL UNIQUE,
	`abrege` VARCHAR(15) UNIQUE NOT NULL,
	PRIMARY KEY(`code`)
) ENGINE = InnoDB;

CREATE TABLE `etudiant` (
	`code` VARCHAR(20) NOT NULL,
	`nom` VARCHAR(30) NOT NULL,
	`prenom` VARCHAR(15) DEFAULT NULL,
	`genre` CHAR(1) NOT NULL,
	`code_option` VARCHAR(10) NOT NULL,
	PRIMARY KEY(`code`),
	CONSTRAINT `fk_option_code_tab_etudiant` FOREIGN KEY(`code_option`) REFERENCES `option`(`code`) ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE `domaine_expertise` (
	`reference` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`intitule` VARCHAR(50) NOT NULL UNIQUE,
	PRIMARY KEY(`reference`),
	INDEX `ind_intitule`(`intitule`)
) ENGINE = InnoDB;

CREATE TABLE `travail` (
	`matricule` INT UNSIGNED NOT NULL AUTO_INCREMENT,
	`sujet` VARCHAR(255) NOT NULL, 
	`cas_etude` VARCHAR(100) DEFAULT NULL,
	`categorie` CHAR(3) NOT NULL,
	`annee_academique` YEAR NOT NULL,
	`code_classification` VARCHAR(30) DEFAULT NULL,
	`nbre_pages` TINYINT UNSIGNED DEFAULT NULL,
	`code_etudiant` VARCHAR(20) NOT NULL,
	`ref_dom_exp` TINYINT UNSIGNED NOT NULL,
	PRIMARY KEY(`matricule`),
	UNIQUE INDEX `ind_uni_etudiant_categorie_option`(`code_etudiant`, `categorie`),
	INDEX `ind_code_classification`(`code_classification`),
	INDEX `ind_cas_etude`(`cas_etude`),
	CONSTRAINT `fk_dom_exp_ref_tab_travail` FOREIGN KEY(`ref_dom_exp`) REFERENCES `domaine_expertise`(`reference`),
	CONSTRAINT `fk_etudiant_code_tab_travail` FOREIGN KEY(`code_etudiant`) REFERENCES `etudiant`(`code`) ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE `consultation` (
	`numero` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	`date_consultation` DATETIME NOT NULL,
	`id_lecteur` BIGINT UNSIGNED NOT NULL,
	`matr_trav` INT UNSIGNED NOT NULL,
	PRIMARY KEY(`numero`),
	CONSTRAINT `fk_lecteur_id_tab_consultation` FOREIGN KEY(`id_lecteur`) REFERENCES `lecteur`(`identifiant`) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT `fk_travail_id_tab_consultation` FOREIGN KEY(`matr_trav`) REFERENCES `travail`(`matricule`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- /// RECHERCHE 

CREATE TABLE mots_ignores_recherche (
    value VARCHAR(30) NOT NULL UNIQUE
) ENGINE = INNODB;

INSERT IGNORE INTO mots_ignores_recherche VALUES
('mise'), ('en'), ('place'), ('application'), ('gestion'), ('informatisé'), ('une'), ('etude'), ('conception'), ('site'), ('web'), 
('suivi'), ('critique'), ('point'), ('plateforme'), ('de'), ('dans'), ('realisation'), ('projet'), ('avant'), ('les'), ('chez'), ('chez'),
('et'), ('au'), ('sur'), ('la'), ('systeme'), ('implementation'), ('histoire');

SET GLOBAL innodb_ft_server_stopword_table = 'consultation_travaux_bibliotheque_isp/mots_ignores_recherche';

ALTER TABLE travail 
ADD FULLTEXT INDEX `ind_full_sujet`(`sujet`);

-- /// TRIGGERS 

DELIMITER |

-- "travail" =====

CREATE TRIGGER `before_insert_travail` BEFORE INSERT 
ON `travail` FOR EACH ROW 
BEGIN
	IF CHAR_LENGTH(NEW.sujet) < 10 OR CHAR_LENGTH(NEW.sujet) > 244 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le sujet d''un travail doit entre 10 et 244 caractères';
	ELSEIF (NEW.cas_etude IS NOT NULL) && (CHAR_LENGTH(NEW.cas_etude) < 2 OR CHAR_LENGTH(NEW.cas_etude) > 99) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le cas d''étude d''un travail doit avoir un nombre de caractères compris entre 2 et 99';
	ELSEIF (NEW.code_classification IS NOT NULL) && (CHAR_LENGTH(NEW.code_classification) < 14 OR CHAR_LENGTH(NEW.code_classification) > 29) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le code de classification d''un travail doit avoir un nombre de caractères compris entre 14 et 29';
	ELSEIF NEW.categorie != 'TFC' AND NEW.categorie != 'TFE' THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : la catégorie du travail doit valoir "TFC" ou "TFE"';
	ELSEIF NEW.annee_academique < 1960 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : l''année académique du travail doit être supérieur à 1960';
	END IF;
END |

CREATE TRIGGER `before_update_travail` BEFORE UPDATE 
ON `travail` FOR EACH ROW 
BEGIN
	IF CHAR_LENGTH(NEW.sujet) < 10 OR CHAR_LENGTH(NEW.sujet) > 244 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le sujet d''un travail doit entre 10 et 244 caractères';
	ELSEIF (NEW.cas_etude IS NOT NULL) && (CHAR_LENGTH(NEW.cas_etude) < 2 OR CHAR_LENGTH(NEW.cas_etude) > 99) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le cas d''étude d''un travail doit avoir un nombre de caractères compris entre 2 et 99';
	ELSEIF (NEW.code_classification IS NOT NULL) && (CHAR_LENGTH(NEW.code_classification) < 14 OR CHAR_LENGTH(NEW.code_classification) > 29) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le code de classification d''un travail doit avoir un nombre de caractères compris entre 14 et 29';
	ELSEIF NEW.categorie != 'TFC' AND NEW.categorie != 'TFE' THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : la catégorie du travail doit valoir "TFC" ou "TFE"';
	ELSEIF NEW.annee_academique < 1960 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : l''année académique du travail doit être supérieur à 1960';
	END IF;
END |

-- "travail" #####

-- "lecteur" =====

CREATE TRIGGER `before_insert_lecteur` BEFORE INSERT
ON `lecteur` FOR EACH ROW 
BEGIN 
	IF NEW.genre != 'M' AND NEW.genre != 'F' THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le genre du lecteur doit valoir "M" ou "F"';
	ELSEIF CHAR_LENGTH(NEW.nom) < 2 OR CHAR_LENGTH(NEW.nom) > 29 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le nom du lecteur doit avoir de 2 à 29 caractères';
	ELSEIF CHAR_LENGTH(NEW.prenom) < 2 OR CHAR_LENGTH(NEW.prenom) > 14 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le prénom du lecteur doit avoir de 2 à 14 caractères';
	ELSEIF CHAR_LENGTH(NEW.pseudonyme) < 2 OR CHAR_LENGTH(NEW.pseudonyme) > 14 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le pseudonyme du lecteur doit avoir de 2 à 14 caractères';
	ELSEIF CHAR_LENGTH(NEW.email) < 2 OR CHAR_LENGTH(NEW.email) > 49 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : l''adresse e-mail du lecteur doit avoir de 2 à 49 caractères';
	ELSEIF NEW.email NOT REGEXP '^[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9._-]@[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9]\\.[a-zA-Z]{2,49}$' THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : l''adresse e-mail n''est pas correcte';
	ELSEIF CHAR_LENGTH(NEW.mot_de_passe) < 4 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le mot de passe du lecteur doit avoir au minimum 4 caractères';
	END IF;
END |

CREATE TRIGGER `before_update_lecteur` BEFORE UPDATE
ON `lecteur` FOR EACH ROW 
BEGIN 
	IF NEW.genre != 'M' AND NEW.genre != 'F' THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le genre du lecteur doit valoir "M" ou "F"';
	ELSEIF CHAR_LENGTH(NEW.nom) < 2 OR CHAR_LENGTH(NEW.nom) > 29 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le nom du lecteur doit avoir de 2 à 29 caractères';
	ELSEIF CHAR_LENGTH(NEW.prenom) < 2 OR CHAR_LENGTH(NEW.prenom) > 14 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le prénom du lecteur doit avoir de 2 à 14 caractères';
	ELSEIF CHAR_LENGTH(NEW.pseudonyme) < 2 OR CHAR_LENGTH(NEW.pseudonyme) > 14 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le pseudonyme du lecteur doit avoir de 2 à 14 caractères';
	ELSEIF CHAR_LENGTH(NEW.email) < 2 OR CHAR_LENGTH(NEW.email) > 49 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : l''adresse e-mail du lecteur doit avoir de 2 à 49 caractères';
	ELSEIF NEW.email NOT REGEXP '^[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9._-]@[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9]\\.[a-zA-Z]{2,49}$' THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : l''adresse e-mail n''est pas correcte';
	ELSEIF CHAR_LENGTH(NEW.mot_de_passe) < 4 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le mot de passe du lecteur doit avoir au minimum 4 caractères';
	END IF;
END |

-- "lecteur" #####

-- "etudiant" =====

CREATE TRIGGER `before_insert_etudiant` BEFORE INSERT
ON `etudiant` FOR EACH ROW 
BEGIN 
	IF NEW.genre != 'M' AND NEW.genre != 'F' THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le genre de l''étudiant doit valoir "M" ou "F"';
	ELSEIF CHAR_LENGTH(NEW.code) < 2 OR CHAR_LENGTH(NEW.code) > 19 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le matricule de l''étudiant doit avoir de 2 à 19 caractères';
	ELSEIF CHAR_LENGTH(NEW.nom) < 2 OR CHAR_LENGTH(NEW.nom) > 29 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le nom de l''étudiant doit avoir de 2 à 29 caractères';
	ELSEIF NEW.prenom IS NOT NULL AND (CHAR_LENGTH(NEW.prenom) < 2 OR CHAR_LENGTH(NEW.prenom) > 14) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le prénom de l''étudiant doit avoir de 2 à 14 caractères';
	END IF;
END |

CREATE TRIGGER `before_update_etudiant` BEFORE UPDATE
ON `etudiant` FOR EACH ROW 
BEGIN 
	IF NEW.genre != 'M' AND NEW.genre != 'F' THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le genre de l''étudiant doit valoir "M" ou "F"';
	ELSEIF CHAR_LENGTH(NEW.code) < 2 OR CHAR_LENGTH(NEW.code) > 19 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le matricule de l''étudiant doit avoir de 2 à 19 caractères';
	ELSEIF CHAR_LENGTH(NEW.nom) < 2 OR CHAR_LENGTH(NEW.nom) > 29 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le nom de l''étudiant doit avoir de 2 à 29 caractères';
	ELSEIF NEW.prenom IS NOT NULL AND (CHAR_LENGTH(NEW.prenom) < 2 OR CHAR_LENGTH(NEW.prenom) > 14) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le prénom de l''étudiant doit avoir de 2 à 14 caractères';
	END IF;
END |

-- "etudiant" #####

-- "domaine_expertise" =====

CREATE TRIGGER `before_insert_domaine_expertise` BEFORE INSERT 
ON `domaine_expertise` FOR EACH ROW 
BEGIN
	IF CHAR_LENGTH(NEW.intitule) < 2 OR CHAR_LENGTH(NEW.intitule) > 49 THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : l''intitulé d''un domaine d''experise doit faire plus de 2 caractères jusqu''à maximum 50 caractères';
	END IF;
END |

CREATE TRIGGER `before_update_domaine_expertise` BEFORE UPDATE 
ON `domaine_expertise` FOR EACH ROW 
BEGIN
	IF CHAR_LENGTH(NEW.intitule) < 2 OR CHAR_LENGTH(NEW.intitule) > 49 THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : l''intitulé d''un domaine d''experise doit faire plus de 2 caractères jusqu''à maximum 50 caractères';
	END IF;
END |

-- "domaine_expertise" #####

-- "option" =====

CREATE TRIGGER `before_insert_option` BEFORE INSERT 
ON `option` FOR EACH ROW 
BEGIN
	IF CHAR_LENGTH(NEW.code) < 2 OR CHAR_LENGTH(NEW.code) > 9 THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le code d''une option d''étude doit avoir entre 2 et 9 caractères';
	ELSEIF CHAR_LENGTH(NEW.nom) < 2 OR CHAR_LENGTH(NEW.nom) > 99 THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le nom d''une option d''étude doit avoir entre 2 et 99 caractères';
	ELSEIF CHAR_LENGTH(NEW.abrege) < 2 OR CHAR_LENGTH(NEW.abrege) > 24 THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : l''abrégé d''une option d''étude doit avoir entre 2 et 14 caractères';
	END IF;
END |

CREATE TRIGGER `before_update_option` BEFORE UPDATE 
ON `option` FOR EACH ROW 
BEGIN
	IF CHAR_LENGTH(NEW.code) < 2 OR CHAR_LENGTH(NEW.code) > 9 THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le code d''une option d''étude doit avoir entre 2 et 9 caractères';
	ELSEIF CHAR_LENGTH(NEW.nom) < 2 OR CHAR_LENGTH(NEW.nom) > 24 THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : le nom d''une option d''étude doit avoir entre 2 et 99 caractères';
	ELSEIF CHAR_LENGTH(NEW.abrege) < 2 OR CHAR_LENGTH(NEW.abrege) > 24 THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erreur : l''abrégé d''une option d''étude doit avoir entre 2 et 14 caractères';
	END IF;
END |

-- "option" #####

DELIMITER ;
