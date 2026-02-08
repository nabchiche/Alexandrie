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

INSERT INTO region (nom) VALUES
('PACA'),
('Île-de-France'),
('Auvergne-Rhône-Alpes');

INSERT INTO adresse (ligne1, ligne2, code_postal, ville, pays, id_region) VALUES
('10 rue Victor Hugo', NULL, '06000', 'Nice', 'France', 1),
('5 avenue Jean Médecin', NULL, '06000', 'Nice', 'France', 1),
('12 rue de Rivoli', NULL, '75001', 'Paris', 'France', 2),
('8 place Bellecour', NULL, '69002', 'Lyon', 'France', 3);

INSERT INTO bibliotheque (nom, id_adresse, date_integration, latitude, longitude) VALUES
('Bibliothèque Nice Centre', 1, '2020-01-10', 43.703400, 7.266300),
('Bibliothèque Nice Est', 2, '2021-06-15', 43.710000, 7.280000),
('Bibliothèque Paris Centre', 3, '2019-09-01', 48.856600, 2.352200),
('Bibliothèque Lyon Centre', 4, '2022-03-20', 45.764000, 4.835700);

INSERT INTO emplacement (id_bibliotheque, etage, rayon, numero_rayon) VALUES
(1, 'RDC', 'Romans', 'R1'),
(1, '1er', 'Informatique', 'I1'),
(2, 'RDC', 'Histoire', 'H1'),
(3, '2e', 'Sciences', 'S1'),
(4, '1er', 'Littérature', 'L1');

INSERT INTO categorie (libelle) VALUES
('Informatique'),
('Roman'),
('Histoire');

INSERT INTO collection (nom, description) VALUES
('Classiques', 'Œuvres majeures de la littérature'),
('Tech', 'Ouvrages techniques et informatiques');

INSERT INTO auteur (nom, prenom) VALUES
('Orwell', 'George'),
('Tanenbaum', 'Andrew'),
('Asimov', 'Isaac');

INSERT INTO ouvrage (isbn, titre, id_categorie, consultable_seulement) VALUES
('9780451524935', '1984', 2, FALSE),
('9780133594140', 'Computer Networks', 1, FALSE),
('9780553293357', 'Foundation', 2, FALSE);

INSERT INTO liaison_ouvrage_auteur (id_ouvrage, id_auteur) VALUES
(1, 1),
(2, 2),
(3, 3);

INSERT INTO liaison_ouvrage_collection (id_ouvrage, id_collection) VALUES
(1, 1),
(2, 2),
(3, 1);

INSERT INTO type_abonnement (libelle, quota_max, duree_pret_jours) VALUES
('Etudiant', 3, 21),
('Adulte', 5, 28);

INSERT INTO abonne (numero_carte, nom, prenom, email, telephone, date_inscription, id_type_abonnement, id_bibliotheque_reference, statut, suspendu_jusqua) VALUES
('A001', 'Martin', 'Lucas', 'lucas.martin@mail.com', '0600000001', '2023-01-10', 1, 1, 'actif', NULL),
('A002', 'Durand', 'Emma', 'emma.durand@mail.com', '0600000002', '2022-05-18', 2, 3, 'actif', NULL),
('A003', 'Bernard', 'Chloé', 'chloe.bernard@mail.com', '0600000003', '2024-01-05', 1, 2, 'actif', NULL),
('A004', 'Petit', 'Nicolas', 'nicolas.petit@mail.com', '0600000004', '2021-11-22', 2, 4, 'actif', NULL);

INSERT INTO exemplaire (code_barres, id_ouvrage, id_bibliotheque, id_emplacement, statut, etat, date_acquisition) VALUES
('EX001', 1, 1, 1, 'disponible', 'bon', '2020-02-01'),
('EX002', 1, 2, 3, 'emprunte', 'bon', '2021-03-01'),
('EX003', 2, 1, 2, 'disponible', 'bon', '2022-04-10'),
('EX004', 3, 3, NULL, 'en_transfert', 'bon', '2019-10-05'),
('EX005', 3, 4, 5, 'disponible', 'bon', '2022-04-10'),
('EX006', 2, 3, 4, 'disponible', 'bon', '2020-06-15'),
('EX007', 1, 3, NULL, 'perdu', 'perdu', '2020-05-20');

INSERT INTO pret (id_exemplaire, id_abonne, id_bibliotheque_pret, date_pret, date_retour_prevue, date_retour_effective, statut) VALUES
(2, 1, 2, '2023-12-01 10:00:00', '2023-12-20 10:00:00', '2023-12-30 15:00:00', 'rendu'),
(3, 2, 1, '2024-01-10 09:30:00', '2024-01-31 09:30:00', NULL, 'en_cours'),
(6, 3, 3, '2024-01-05 14:00:00', '2024-01-26 14:00:00', '2024-01-26 13:00:00', 'rendu'),
(5, 4, 4, '2023-11-10 16:00:00', '2023-12-08 16:00:00', '2023-12-20 11:00:00', 'rendu');

INSERT INTO reservation (id_exemplaire, id_abonne, date_reservation, statut) VALUES
(4, 1, '2024-01-05 12:00:00', 'active'),
(1, 2, '2024-01-12 08:00:00', 'active');

INSERT INTO transporteur (nom) VALUES
('La Poste'),
('Chronopost');

INSERT INTO envoi_transfert (id_bibliotheque_source, id_bibliotheque_destination, id_transporteur, date_demande, date_depart, date_arrivee, statut, distance_km, cout_estime, note) VALUES
(3, 1, 1, '2024-01-06 09:00:00', '2024-01-07 09:00:00', '2024-01-10 11:30:00', 'arrive', 930.00, 45.00, NULL),
(3, 2, 2, '2024-01-08 10:00:00', '2024-01-09 10:00:00', NULL, 'en_cours', 928.00, 39.90, 'Groupage prévu');

INSERT INTO liaison_envoi_exemplaire (id_envoi, id_exemplaire, id_reservation) VALUES
(1, 4, 1),
(2, 6, NULL);

INSERT INTO type_evenement (libelle) VALUES
('Conference'),
('Exposition'),
('Atelier');

INSERT INTO evenement (id_bibliotheque, id_type_evenement, titre, description, debut, fin, gratuit, capacite) VALUES
(1, 1, 'Conférence IA', 'Panorama des usages IA', '2024-02-01 18:00:00', '2024-02-01 20:00:00', TRUE, 100),
(3, 2, 'Expo Science-Fiction', 'Auteurs et œuvres majeures', '2024-03-10 10:00:00', '2024-03-20 18:00:00', TRUE, 200),
(2, 1, 'Conférence Cybersécurité', 'Bonnes pratiques et prévention', '2024-02-15 18:30:00', '2024-02-15 20:00:00', TRUE, 80),
(4, 3, 'Atelier Réseaux', 'Initiation réseaux', '2024-04-05 14:00:00', '2024-04-05 16:00:00', TRUE, 30);

INSERT INTO liaison_participation_evenement (id_evenement, id_abonne, nom_participant, prenom_participant, email_participant, date_inscription, statut, note) VALUES
(1, 1, NULL, NULL, NULL, '2024-01-20 10:00:00', 'present', NULL),
(2, 2, NULL, NULL, NULL, '2024-02-15 11:00:00', 'inscrit', NULL),
(3, 3, NULL, NULL, NULL, '2024-02-01 09:00:00', 'present', NULL),
(4, NULL, 'Moreau', 'Julie', 'julie.moreau@mail.com', '2024-03-25 17:00:00', 'inscrit', 'Participant externe');

INSERT INTO rachat (id_ouvrage, id_bibliotheque, date_rachat, quantite, raison) VALUES
(1, 1, '2024-01-15', 5, 'stock_insuffisant'),
(2, 2, '2024-01-18', 2, 'stock_nul');

-- ---------------------------------------------------------------------------
-- Données complémentaires pour couvrir les requêtes de raph.sql
-- ---------------------------------------------------------------------------

INSERT INTO adresse (ligne1, ligne2, code_postal, ville, pays, id_region) VALUES
('25 rue de la République', NULL, '13001', 'Marseille', 'France', 1);

INSERT INTO bibliotheque (nom, id_adresse, date_integration, latitude, longitude) VALUES
('Bibliothèque Marseille Vieux-Port', 5, '2023-07-01', 43.296400, 5.369800);

INSERT INTO emplacement (id_bibliotheque, etage, rayon, numero_rayon) VALUES
(5, 'RDC', 'Romans', 'R1');

INSERT INTO auteur (nom, prenom) VALUES
('Herbert', 'Frank'),
('Zola', 'Émile');

INSERT INTO ouvrage (isbn, titre, id_categorie, consultable_seulement) VALUES
('9780441172719', 'Dune', 2, FALSE),
('9782070409228', 'Germinal', 2, FALSE),
('9780618640157', 'The Lord of the Rings', 2, FALSE);

INSERT INTO liaison_ouvrage_auteur (id_ouvrage, id_auteur) VALUES
(4, 4),
(5, 5),
(6, 1);

INSERT INTO liaison_ouvrage_collection (id_ouvrage, id_collection) VALUES
(4, 1),
(5, 1),
(6, 1);

INSERT INTO exemplaire (code_barres, id_ouvrage, id_bibliotheque, id_emplacement, statut, etat, date_acquisition) VALUES
('EX_TEST_01', 4, 1, 1, 'disponible', 'bon', '2023-06-01'),
('EX_TEST_02', 4, 2, 3, 'en_transfert', 'bon', '2023-06-15'),
('EX_TEST_03', 6, 1, 1, 'disponible', 'bon', '2023-07-10'),
('EX_TEST_04', 5, 3, 4, 'reserve', 'bon', '2023-08-20'),
('EX_TEST_05', 4, 3, 4, 'disponible', 'bon', '2023-09-01'),
('EX_TEST_06', 6, 4, 5, 'disponible', 'bon', '2023-09-15'),
('EX_TEST_07', 5, 5, 6, 'disponible', 'bon', '2023-10-01');

INSERT INTO reservation (id_exemplaire, id_abonne, date_reservation, statut) VALUES
(12, 1, '2024-01-20 10:00:00', 'active');

INSERT INTO pret (id_exemplaire, id_abonne, id_bibliotheque_pret, date_pret, date_retour_prevue, date_retour_effective, statut) VALUES
(8, 1, 1, '2024-01-08 10:00:00', '2024-01-29 10:00:00', '2024-01-25 14:00:00', 'rendu'),
(13, 4, 4, '2023-11-20 11:00:00', '2023-12-18 11:00:00', '2023-12-15 09:00:00', 'rendu'),
(10, 2, 1, '2024-01-12 09:00:00', '2024-02-02 09:00:00', NULL, 'en_cours');

INSERT INTO envoi_transfert (id_bibliotheque_source, id_bibliotheque_destination, id_transporteur, date_demande, date_depart, date_arrivee, statut, distance_km, cout_estime, note) VALUES
(2, 4, 1, '2024-01-11 08:00:00', '2024-01-12 09:00:00', '2024-01-15 14:00:00', 'arrive', 470.00, 23.50, 'Transfert Nice Est vers Lyon'),
(1, 3, 2, '2024-01-20 10:00:00', NULL, NULL, 'demande', 930.00, 46.50, 'Demande groupage A lot 1'),
(1, 3, 2, '2024-01-21 11:00:00', NULL, NULL, 'demande', 930.00, 46.50, 'Demande groupage A lot 2');

INSERT INTO liaison_envoi_exemplaire (id_envoi, id_exemplaire, id_reservation) VALUES
(3, 9, NULL),
(4, 8, NULL),
(5, 10, NULL);

INSERT INTO evenement (id_bibliotheque, id_type_evenement, titre, description, debut, fin, gratuit, capacite) VALUES
(4, 3, 'Atelier SQL Avancé', 'Requêtes avancées et optimisation', NOW() + INTERVAL '10 days', NOW() + INTERVAL '10 days' + INTERVAL '2 hours', TRUE, 25),
(1, 1, 'Conférence Littérature', 'Panorama littérature contemporaine', NOW() + INTERVAL '20 days', NOW() + INTERVAL '20 days' + INTERVAL '2 hours', TRUE, 60);

INSERT INTO liaison_participation_evenement (id_evenement, id_abonne, nom_participant, prenom_participant, email_participant, date_inscription, statut, note) VALUES
((SELECT id_evenement FROM evenement WHERE titre = 'Atelier SQL Avancé'), 1, NULL, NULL, NULL, NOW() - INTERVAL '5 days', 'inscrit', NULL),
((SELECT id_evenement FROM evenement WHERE titre = 'Atelier SQL Avancé'), 4, NULL, NULL, NULL, NOW() - INTERVAL '3 days', 'inscrit', NULL),
((SELECT id_evenement FROM evenement WHERE titre = 'Conférence Littérature'), 1, NULL, NULL, NULL, NOW() - INTERVAL '2 days', 'inscrit', NULL),
((SELECT id_evenement FROM evenement WHERE titre = 'Conférence Littérature'), 4, NULL, NULL, NULL, NOW() - INTERVAL '1 day', 'inscrit', NULL);

INSERT INTO reservation (id_exemplaire, id_abonne, date_reservation, statut) VALUES
(12, 1, '2024-01-20 10:00:00', 'active');