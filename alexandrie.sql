DROP DATABASE IF EXISTS alexandrie;
CREATE DATABASE alexandrie;

\connect alexandrie;

SET client_encoding = 'UTF8';

CREATE TABLE region (
    id_region SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE adresse (
    id_adresse SERIAL PRIMARY KEY,
    ligne1 VARCHAR(255) NOT NULL,
    ligne2 VARCHAR(255),
    code_postal VARCHAR(20) NOT NULL,
    ville VARCHAR(120) NOT NULL,
    pays VARCHAR(120) NOT NULL,
    id_region INTEGER NOT NULL
);

CREATE TABLE bibliotheque (
    id_bibliotheque SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    id_adresse INTEGER NOT NULL,
    date_integration DATE NOT NULL,
    latitude NUMERIC(9,6) NOT NULL,
    longitude NUMERIC(9,6) NOT NULL
);

CREATE TABLE emplacement (
    id_emplacement SERIAL PRIMARY KEY,
    id_bibliotheque INTEGER NOT NULL,
    etage VARCHAR(50) NOT NULL,
    rayon VARCHAR(80) NOT NULL,
    numero_rayon VARCHAR(50) NOT NULL
);

CREATE TABLE categorie (
    id_categorie SERIAL PRIMARY KEY,
    libelle VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE collection (
    id_collection SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL UNIQUE,
    description VARCHAR(500)
);

CREATE TABLE auteur (
    id_auteur SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    prenom VARCHAR(255)
);

CREATE TABLE ouvrage (
    id_ouvrage SERIAL PRIMARY KEY,
    isbn VARCHAR(40) UNIQUE,
    titre VARCHAR(500) NOT NULL,
    id_categorie INTEGER,
    consultable_seulement BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE liaison_ouvrage_auteur (
    id_ouvrage INTEGER NOT NULL,
    id_auteur INTEGER NOT NULL,
    PRIMARY KEY (id_ouvrage,id_auteur)
);

CREATE TABLE liaison_ouvrage_collection (
    id_ouvrage INTEGER NOT NULL,
    id_collection INTEGER NOT NULL,
    PRIMARY KEY (id_ouvrage,id_collection)
);

CREATE TABLE type_abonnement (
    id_type_abonnement SERIAL PRIMARY KEY,
    libelle VARCHAR(120) NOT NULL UNIQUE,
    quota_max INTEGER NOT NULL,
    duree_pret_jours INTEGER NOT NULL
);

CREATE TABLE abonne (
    id_abonne SERIAL PRIMARY KEY,
    numero_carte VARCHAR(60) NOT NULL UNIQUE,
    nom VARCHAR(255) NOT NULL,
    prenom VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    telephone VARCHAR(50),
    date_inscription DATE NOT NULL,
    id_type_abonnement INTEGER NOT NULL,
    id_bibliotheque_reference INTEGER NOT NULL,
    statut VARCHAR(30) NOT NULL,
    suspendu_jusqua DATE
);

CREATE TABLE exemplaire (
    id_exemplaire SERIAL PRIMARY KEY,
    code_barres VARCHAR(80) NOT NULL UNIQUE,
    id_ouvrage INTEGER NOT NULL,
    id_bibliotheque INTEGER NOT NULL,
    id_emplacement INTEGER,
    statut VARCHAR(30) NOT NULL,
    etat VARCHAR(30) NOT NULL,
    date_acquisition DATE
);

CREATE TABLE pret (
    id_pret SERIAL PRIMARY KEY,
    id_exemplaire INTEGER NOT NULL,
    id_abonne INTEGER NOT NULL,
    id_bibliotheque_pret INTEGER NOT NULL,
    date_pret TIMESTAMP NOT NULL,
    date_retour_prevue TIMESTAMP NOT NULL,
    date_retour_effective TIMESTAMP,
    statut VARCHAR(30) NOT NULL
);

CREATE TABLE reservation (
    id_reservation SERIAL PRIMARY KEY,
    id_exemplaire INTEGER NOT NULL,
    id_abonne INTEGER NOT NULL,
    date_reservation TIMESTAMP NOT NULL,
    statut VARCHAR(30) NOT NULL
);

CREATE TABLE transporteur (
    id_transporteur SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE envoi_transfert (
    id_envoi SERIAL PRIMARY KEY,
    id_bibliotheque_source INTEGER NOT NULL,
    id_bibliotheque_destination INTEGER NOT NULL,
    id_transporteur INTEGER NOT NULL,
    date_demande TIMESTAMP NOT NULL,
    date_depart TIMESTAMP,
    date_arrivee TIMESTAMP,
    statut VARCHAR(30) NOT NULL,
    distance_km NUMERIC(10,2),
    cout_estime NUMERIC(10,2),
    note VARCHAR(500)
);

CREATE TABLE liaison_envoi_exemplaire (
    id_envoi INTEGER NOT NULL,
    id_exemplaire INTEGER NOT NULL,
    id_reservation INTEGER,
    PRIMARY KEY (id_envoi,id_exemplaire)
);

CREATE TABLE type_evenement (
    id_type_evenement SERIAL PRIMARY KEY,
    libelle VARCHAR(120) NOT NULL UNIQUE
);

CREATE TABLE evenement (
    id_evenement SERIAL PRIMARY KEY,
    id_bibliotheque INTEGER NOT NULL,
    id_type_evenement INTEGER NOT NULL,
    titre VARCHAR(255) NOT NULL,
    description TEXT,
    debut TIMESTAMP NOT NULL,
    fin TIMESTAMP NOT NULL,
    gratuit BOOLEAN NOT NULL DEFAULT TRUE,
    capacite INTEGER NOT NULL
);

CREATE TABLE liaison_participation_evenement (
    id_participation SERIAL PRIMARY KEY,
    id_evenement INTEGER NOT NULL,
    id_abonne INTEGER,
    nom_participant VARCHAR(255),
    prenom_participant VARCHAR(255),
    email_participant VARCHAR(255),
    date_inscription TIMESTAMP NOT NULL,
    statut VARCHAR(30) NOT NULL,
    note VARCHAR(500)
);

CREATE TABLE rachat (
    id_rachat SERIAL PRIMARY KEY,
    id_ouvrage INTEGER NOT NULL,
    id_bibliotheque INTEGER NOT NULL,
    date_rachat DATE NOT NULL,
    quantite INTEGER NOT NULL,
    raison VARCHAR(40) NOT NULL
);

ALTER TABLE emplacement
ADD CONSTRAINT uq_emplacement UNIQUE (id_bibliotheque,etage,rayon,numero_rayon);

ALTER TABLE abonne
ADD CONSTRAINT chk_abonne_statut CHECK (statut IN ('actif','suspendu','archive'));

ALTER TABLE exemplaire
ADD CONSTRAINT chk_exemplaire_statut CHECK (statut IN ('disponible','emprunte','reserve','en_transfert','perdu','deteriore'));

ALTER TABLE exemplaire
ADD CONSTRAINT chk_exemplaire_etat CHECK (etat IN ('bon','abime','perdu','deteriore'));

ALTER TABLE pret
ADD CONSTRAINT chk_pret_statut CHECK (statut IN ('en_cours','rendu','perdu','deteriore'));

ALTER TABLE reservation
ADD CONSTRAINT chk_reservation_statut CHECK (statut IN ('active','annulee','expiree','honoree'));

ALTER TABLE envoi_transfert
ADD CONSTRAINT chk_envoi_statut CHECK (statut IN ('demande','en_cours','arrive','annule','incident'));

ALTER TABLE evenement
ADD CONSTRAINT chk_evenement_dates CHECK (fin >= debut);

ALTER TABLE rachat
ADD CONSTRAINT chk_rachat_quantite CHECK (quantite > 0);

ALTER TABLE rachat
ADD CONSTRAINT chk_rachat_raison CHECK (raison IN ('stock_nul','stock_insuffisant'));

ALTER TABLE adresse
ADD CONSTRAINT fk_adresse_region FOREIGN KEY (id_region) REFERENCES region(id_region);

ALTER TABLE bibliotheque
ADD CONSTRAINT fk_bibliotheque_adresse FOREIGN KEY (id_adresse) REFERENCES adresse(id_adresse);

ALTER TABLE emplacement
ADD CONSTRAINT fk_emplacement_bibliotheque FOREIGN KEY (id_bibliotheque) REFERENCES bibliotheque(id_bibliotheque);

ALTER TABLE ouvrage
ADD CONSTRAINT fk_ouvrage_categorie FOREIGN KEY (id_categorie) REFERENCES categorie(id_categorie);

ALTER TABLE liaison_ouvrage_auteur
ADD CONSTRAINT fk_loa_ouvrage FOREIGN KEY (id_ouvrage) REFERENCES ouvrage(id_ouvrage);

ALTER TABLE liaison_ouvrage_auteur
ADD CONSTRAINT fk_loa_auteur FOREIGN KEY (id_auteur) REFERENCES auteur(id_auteur);

ALTER TABLE liaison_ouvrage_collection
ADD CONSTRAINT fk_loc_ouvrage FOREIGN KEY (id_ouvrage) REFERENCES ouvrage(id_ouvrage);

ALTER TABLE liaison_ouvrage_collection
ADD CONSTRAINT fk_loc_collection FOREIGN KEY (id_collection) REFERENCES collection(id_collection);

ALTER TABLE abonne
ADD CONSTRAINT fk_abonne_type FOREIGN KEY (id_type_abonnement) REFERENCES type_abonnement(id_type_abonnement);

ALTER TABLE abonne
ADD CONSTRAINT fk_abonne_biblio FOREIGN KEY (id_bibliotheque_reference) REFERENCES bibliotheque(id_bibliotheque);

ALTER TABLE exemplaire
ADD CONSTRAINT fk_exemplaire_ouvrage FOREIGN KEY (id_ouvrage) REFERENCES ouvrage(id_ouvrage);

ALTER TABLE exemplaire
ADD CONSTRAINT fk_exemplaire_biblio FOREIGN KEY (id_bibliotheque) REFERENCES bibliotheque(id_bibliotheque);

ALTER TABLE exemplaire
ADD CONSTRAINT fk_exemplaire_emplacement FOREIGN KEY (id_emplacement) REFERENCES emplacement(id_emplacement);

ALTER TABLE pret
ADD CONSTRAINT fk_pret_exemplaire FOREIGN KEY (id_exemplaire) REFERENCES exemplaire(id_exemplaire);

ALTER TABLE pret
ADD CONSTRAINT fk_pret_abonne FOREIGN KEY (id_abonne) REFERENCES abonne(id_abonne);

ALTER TABLE pret
ADD CONSTRAINT fk_pret_biblio FOREIGN KEY (id_bibliotheque_pret) REFERENCES bibliotheque(id_bibliotheque);

ALTER TABLE reservation
ADD CONSTRAINT fk_reservation_exemplaire FOREIGN KEY (id_exemplaire) REFERENCES exemplaire(id_exemplaire);

ALTER TABLE reservation
ADD CONSTRAINT fk_reservation_abonne FOREIGN KEY (id_abonne) REFERENCES abonne(id_abonne);

ALTER TABLE envoi_transfert
ADD CONSTRAINT fk_envoi_source FOREIGN KEY (id_bibliotheque_source) REFERENCES bibliotheque(id_bibliotheque);

ALTER TABLE envoi_transfert
ADD CONSTRAINT fk_envoi_destination FOREIGN KEY (id_bibliotheque_destination) REFERENCES bibliotheque(id_bibliotheque);

ALTER TABLE envoi_transfert
ADD CONSTRAINT fk_envoi_transporteur FOREIGN KEY (id_transporteur) REFERENCES transporteur(id_transporteur);

ALTER TABLE liaison_envoi_exemplaire
ADD CONSTRAINT fk_lia_envoi FOREIGN KEY (id_envoi) REFERENCES envoi_transfert(id_envoi);

ALTER TABLE liaison_envoi_exemplaire
ADD CONSTRAINT fk_lia_exemplaire FOREIGN KEY (id_exemplaire) REFERENCES exemplaire(id_exemplaire);

ALTER TABLE liaison_envoi_exemplaire
ADD CONSTRAINT fk_lia_reservation FOREIGN KEY (id_reservation) REFERENCES reservation(id_reservation);

ALTER TABLE evenement
ADD CONSTRAINT fk_evenement_biblio FOREIGN KEY (id_bibliotheque) REFERENCES bibliotheque(id_bibliotheque);

ALTER TABLE evenement
ADD CONSTRAINT fk_evenement_type FOREIGN KEY (id_type_evenement) REFERENCES type_evenement(id_type_evenement);

ALTER TABLE liaison_participation_evenement
ADD CONSTRAINT fk_participation_evenement FOREIGN KEY (id_evenement) REFERENCES evenement(id_evenement);

ALTER TABLE liaison_participation_evenement
ADD CONSTRAINT fk_participation_abonne FOREIGN KEY (id_abonne) REFERENCES abonne(id_abonne);

ALTER TABLE rachat
ADD CONSTRAINT fk_rachat_ouvrage FOREIGN KEY (id_ouvrage) REFERENCES ouvrage(id_ouvrage);

ALTER TABLE rachat
ADD CONSTRAINT fk_rachat_bibliotheque FOREIGN KEY (id_bibliotheque) REFERENCES bibliotheque(id_bibliotheque);
