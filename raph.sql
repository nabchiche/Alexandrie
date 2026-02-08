-- RAPHAËL — Requêtes SQL pour Alexandrie (PostgreSQL)
-- Sections : 1. Réservations  2. Transferts  3. Événements & analyses


-- =============================================================
-- ███  SECTION 1 — RÉSERVATIONS
-- =============================================================


-- 1.1 Enregistrer une réservation
-- INSERT dans reservation : exemplaire, abonné, NOW(), statut 'active'.
-- Résultat : nouvelle entrée dans la table reservation.

INSERT INTO reservation (id_exemplaire, id_abonne, date_reservation, statut)
VALUES (
    5, -- id_exemplaire : exemplaire EX005 (Foundation, Lyon)
    3, -- id_abonne     : Chloé Bernard
    NOW(),      -- date_reservation : horodatage courant
    'active'    -- statut initial
);


-- 1.2 Lister les réservations actives
-- Jointures reservation → exemplaire → ouvrage → abonne, filtre statut = 'active'.
-- Résultat attendu : au minimum la réservation de EX_TEST_04 (Germinal).

SELECT
    r.id_reservation,
    e.code_barres,
    o.titre AS titre_ouvrage,
    a.nom || ' ' || a.prenom AS abonne,
    r.date_reservation,
    r.statut
FROM reservation r
    JOIN exemplaire e ON e.id_exemplaire = r.id_exemplaire
    JOIN ouvrage    o ON o.id_ouvrage    = e.id_ouvrage
    JOIN abonne     a ON a.id_abonne     = r.id_abonne
WHERE r.statut = 'active'
ORDER BY r.date_reservation;


-- 1.3 Lister les réservations d'un abonné
-- Filtre sur id_abonne, jointures vers exemplaire/ouvrage.
-- RANK() OVER(...) calcule le rang dans la file d'attente par exemplaire.
-- Résultat : réservations de l'abonné 1 avec titre et position.

SELECT
    r.id_reservation,
    o.titre  AS titre_ouvrage,
    e.code_barres,
    r.date_reservation,
    r.statut,
    RANK() OVER (
 PARTITION BY r.id_exemplaire
 ORDER BY r.date_reservation
    ) AS rang_file_attente
FROM reservation r
    JOIN exemplaire e ON e.id_exemplaire = r.id_exemplaire
    JOIN ouvrage    o ON o.id_ouvrage    = e.id_ouvrage
WHERE r.id_abonne = 1       -- ← paramètre : id de l'abonné
ORDER BY r.date_reservation;


-- 1.4 Lister les réservations d'un exemplaire
-- Filtre par code_barres ('EX_TEST_04'), jointure vers abonne.
-- Résultat : infos de l'abonné ayant réservé cet exemplaire (Germinal).

SELECT
    r.id_reservation,
    e.code_barres,
    o.titre  AS titre_ouvrage,
    a.id_abonne,
    a.nom || ' ' || a.prenom AS abonne,
    a.email,
    r.date_reservation,
    r.statut
FROM reservation r
    JOIN exemplaire e ON e.id_exemplaire = r.id_exemplaire
    JOIN ouvrage    o ON o.id_ouvrage    = e.id_ouvrage
    JOIN abonne     a ON a.id_abonne     = r.id_abonne
WHERE e.code_barres = 'EX_TEST_05'       -- ← paramètre : code-barres
ORDER BY r.date_reservation;


-- 1.5 Identifier les réservations déclenchant un transfert
-- Compare exemplaire.id_bibliotheque ≠ abonne.id_bibliotheque_reference.
-- Si différents → transfert nécessaire.
-- Résultat : réservations où les deux bibliothèques diffèrent.

SELECT
    r.id_reservation,
    a.nom || ' ' || a.prenom AS abonne,
    bib_abonne.nom AS biblio_abonne,
    bib_exemp.nom  AS biblio_exemplaire,
    o.titre  AS titre_ouvrage,
    e.code_barres
FROM reservation r
    JOIN exemplaire    e ON e.id_exemplaire = r.id_exemplaire
    JOIN ouvrage       o ON o.id_ouvrage = e.id_ouvrage
    JOIN abonne a ON a.id_abonne = r.id_abonne
    JOIN bibliotheque  bib_abonne ON bib_abonne.id_bibliotheque = a.id_bibliotheque_reference
    JOIN bibliotheque  bib_exemp  ON bib_exemp.id_bibliotheque  = e.id_bibliotheque
WHERE e.id_bibliotheque <> a.id_bibliotheque_reference
ORDER BY r.id_reservation;


-- =============================================================
-- ███  SECTION 2 — TRANSFERTS INTER-BIBLIOTHÈQUES
-- =============================================================


-- 2.1 Créer une demande de transfert
-- INSERT dans envoi_transfert : source, destination, transporteur, statut 'demande'.
-- Coût estimé = distance_km × 0.05 €/km.
-- Résultat : nouvel enregistrement dans envoi_transfert.

INSERT INTO envoi_transfert (
    id_bibliotheque_source,
    id_bibliotheque_destination,
    id_transporteur,
    date_demande,
    statut,
    distance_km,
    cout_estime,
    note
)
VALUES (
    1, -- source      : Nice Centre
    3, -- destination  : Paris Centre
    1, -- transporteur : La Poste
    NOW(), -- date de la demande
    'demande',      -- statut initial
    930.00,  -- distance calculée Nice → Paris
    930.00 * 0.05,  -- coût estimé (= 46.50 €)
    'Demande créée via requête raph.sql'
);


-- 2.2 Lister les transferts en cours
-- Filtre statut IN ('demande', 'en_cours'), jointures vers bibliothèques et transporteur.
-- Résultat : transferts du Scénario A (Nice → Paris) + tout transfert 'en_cours'.

SELECT
    et.id_envoi,
    bib_src.nom AS bibliotheque_source,
    bib_dst.nom AS bibliotheque_destination,
    t.nom   AS transporteur,
    et.date_demande,
    et.statut,
    et.distance_km,
    et.cout_estime
FROM envoi_transfert et
    JOIN bibliotheque bib_src ON bib_src.id_bibliotheque = et.id_bibliotheque_source
    JOIN bibliotheque bib_dst ON bib_dst.id_bibliotheque = et.id_bibliotheque_destination
    JOIN transporteur t       ON t.id_transporteur       = et.id_transporteur
WHERE et.statut IN ('demande', 'en_cours')
ORDER BY et.date_demande;


-- 2.3 Suivre l'état d'un transfert
-- Filtre sur id_envoi, affiche statut, date_depart, date_arrivee.
-- Résultat (Scénario B) : statut 'arrive' avec dates renseignées.

SELECT
    et.id_envoi,
    bib_src.nom   AS bibliotheque_source,
    bib_dst.nom   AS bibliotheque_destination,
    et.statut,
    et.date_demande,
    et.date_depart,
    et.date_arrivee
FROM envoi_transfert et
    JOIN bibliotheque bib_src ON bib_src.id_bibliotheque = et.id_bibliotheque_source
    JOIN bibliotheque bib_dst ON bib_dst.id_bibliotheque = et.id_bibliotheque_destination
WHERE et.id_envoi = 3;      -- ← paramètre : id de l'envoi
   -- (Scénario B = transfert Nice Est → Lyon)


-- 2.4 Lister les exemplaires d'un transfert
-- Jointure via liaison_envoi_exemplaire → exemplaire → ouvrage.
-- Résultat (Scénario B) : EX_TEST_02 (Dune) doit être listé.

SELECT
    lee.id_envoi,
    e.code_barres,
    o.titre AS titre_ouvrage,
    e.statut  AS statut_exemplaire,
    e.etat  AS etat_exemplaire
FROM liaison_envoi_exemplaire lee
    JOIN exemplaire e ON e.id_exemplaire = lee.id_exemplaire
    JOIN ouvrage    o ON o.id_ouvrage    = e.id_ouvrage
WHERE lee.id_envoi = (      -- ← on cible le transfert du Scénario B
    SELECT id_envoi
    FROM envoi_transfert
    WHERE id_bibliotheque_source = 2
      AND id_bibliotheque_destination = 4
      AND statut = 'arrive'
    ORDER BY date_demande DESC
    LIMIT 1
);


-- 2.5 Identifier les transferts par bibliothèque SOURCE
-- GROUP BY id_bibliotheque_source + COUNT(*) pour compter les envois.
-- Résultat : Nice Centre (ID 1) en tête (Scénario A).

SELECT
    bib_src.id_bibliotheque,
    bib_src.nom AS bibliotheque_source,
    COUNT(*) AS nombre_transferts
FROM envoi_transfert et
    JOIN bibliotheque bib_src ON bib_src.id_bibliotheque = et.id_bibliotheque_source
GROUP BY bib_src.id_bibliotheque, bib_src.nom
ORDER BY nombre_transferts DESC;


-- 2.6 Identifier les transferts par bibliothèque DESTINATION
-- Même logique que 2.5, groupée par destination.
-- Résultat : Paris Centre (ID 3) en tête (Scénario A).

SELECT
    bib_dst.id_bibliotheque,
    bib_dst.nom AS bibliotheque_destination,
    COUNT(*) AS nombre_transferts
FROM envoi_transfert et
    JOIN bibliotheque bib_dst ON bib_dst.id_bibliotheque = et.id_bibliotheque_destination
GROUP BY bib_dst.id_bibliotheque, bib_dst.nom
ORDER BY nombre_transferts DESC;


-- 2.7 Calculer la distance entre deux bibliothèques
-- Formule de Haversine (R=6371 km) à partir de latitude/longitude.
-- d = 6371 × ACOS(COS(lat1)×COS(lat2)×COS(lon2-lon1) + SIN(lat1)×SIN(lat2))
-- NOTION AVANCÉE : FONCTION (CREATE FUNCTION)
-- Résultat : Nice (ID 1) ↔ Paris (ID 3) ≈ 930 km.

CREATE OR REPLACE FUNCTION calcul_distance_haversine(
    p_id_bib1 INT,
    p_id_bib2 INT
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_lat1  DOUBLE PRECISION;
    v_lon1  DOUBLE PRECISION;
    v_lat2  DOUBLE PRECISION;
    v_lon2  DOUBLE PRECISION;
    v_dist  NUMERIC;
BEGIN
    SELECT latitude, longitude INTO v_lat1, v_lon1
    FROM bibliotheque WHERE id_bibliotheque = p_id_bib1;

    SELECT latitude, longitude INTO v_lat2, v_lon2
    FROM bibliotheque WHERE id_bibliotheque = p_id_bib2;

    v_dist := ROUND(
        (6371 * ACOS(
            COS(RADIANS(v_lat1)) * COS(RADIANS(v_lat2))
            * COS(RADIANS(v_lon2) - RADIANS(v_lon1))
            + SIN(RADIANS(v_lat1)) * SIN(RADIANS(v_lat2))
        ))::NUMERIC,
        2
    );

    RETURN v_dist;
END;
$$;

SELECT
    b1.nom AS bibliotheque_1,
    b2.nom AS bibliotheque_2,
    calcul_distance_haversine(b1.id_bibliotheque, b2.id_bibliotheque) AS distance_km
FROM bibliotheque b1, bibliotheque b2
WHERE b1.id_bibliotheque = 1 -- Nice Centre
  AND b2.id_bibliotheque = 3;   -- Paris Centre


-- 2.8 Estimer le coût d'un transfert
-- Coût = distance_km × tarif_au_km (0.05 €/km ici).
-- Résultat : Nice → Paris (930 km) → 930 × 0.05 = 46.50 €.

SELECT
    et.id_envoi,
    bib_src.nom AS bibliotheque_source,
    bib_dst.nom AS bibliotheque_destination,
    et.distance_km,
    0.05 AS tarif_km, -- tarif unitaire (€/km)
    ROUND(et.distance_km * 0.05, 2) AS cout_estime_calcule,
    et.cout_estime AS cout_estime_enregistre
FROM envoi_transfert et
    JOIN bibliotheque bib_src ON bib_src.id_bibliotheque = et.id_bibliotheque_source
    JOIN bibliotheque bib_dst ON bib_dst.id_bibliotheque = et.id_bibliotheque_destination
ORDER BY et.id_envoi;


-- 2.9 Intégration d'une nouvelle bibliothèque
-- Jointure bibliotheque → adresse → region, filtre ILIKE '%Marseille%'.
-- Résultat : « Bibliothèque Marseille Vieux-Port » avec son adresse.

SELECT
    b.id_bibliotheque,
    b.nom AS nom_bibliotheque,
    a.ligne1,
    a.code_postal,
    a.ville,
    a.pays,
    r.nom AS region,
    b.date_integration,
    b.latitude,
    b.longitude
FROM bibliotheque b
    JOIN adresse a ON a.id_adresse = b.id_adresse
    JOIN region  r ON r.id_region  = a.id_region
WHERE b.nom ILIKE '%Marseille%';


-- 2.10 Optimisation logistique des transferts par groupage
-- GROUP BY (source, destination) + HAVING COUNT(*) > 1, filtre statut = 'demande'.
-- Identifie les trajets avec ≥ 2 demandes en attente pour groupage.
-- Résultat : Nice (1) → Paris (3) ressort (2 demandes du Scénario A).

SELECT
    bib_src.nom AS bibliotheque_source,
    bib_dst.nom AS bibliotheque_destination,
    COUNT(*) AS nombre_demandes,
    ROUND(AVG(et.distance_km), 2) AS distance_moyenne_km
FROM envoi_transfert et
    JOIN bibliotheque bib_src ON bib_src.id_bibliotheque = et.id_bibliotheque_source
    JOIN bibliotheque bib_dst ON bib_dst.id_bibliotheque = et.id_bibliotheque_destination
WHERE et.statut = 'demande'
GROUP BY bib_src.nom, bib_dst.nom
HAVING COUNT(*) > 1
ORDER BY nombre_demandes DESC;


-- =============================================================
-- ███  SECTION 3 — ÉVÉNEMENTS & ANALYSES
-- =============================================================


-- 3.1 Lister les événements à venir
-- Filtre debut > NOW(), jointures vers type_evenement et bibliotheque.
-- Résultat : « Atelier SQL Avancé » (Lyon, ID 4) programmé à NOW()+10j.

SELECT
    ev.id_evenement,
    ev.titre,
    te.libelle AS type_evenement,
    b.nom AS bibliotheque,
    ev.debut,
    ev.fin,
    ev.capacite,
    ev.gratuit
FROM evenement ev
    JOIN type_evenement te ON te.id_type_evenement = ev.id_type_evenement
    JOIN bibliotheque   b  ON b.id_bibliotheque    = ev.id_bibliotheque
WHERE ev.debut > NOW()
ORDER BY ev.debut;


-- 3.2 Lister les événements par bibliothèque
-- Filtre sur ev.id_bibliotheque (paramètre = 4, Lyon).

SELECT
    ev.id_evenement,
    ev.titre,
    te.libelle AS type_evenement,
    ev.debut,
    ev.fin,
    ev.capacite
FROM evenement ev
    JOIN type_evenement te ON te.id_type_evenement = ev.id_type_evenement
WHERE ev.id_bibliotheque = 4 -- ← paramètre : id bibliothèque
ORDER BY ev.debut;


-- 3.3 Lister les événements par type
-- Filtre sur type_evenement.libelle (paramètre = 'Atelier').

SELECT
    ev.id_evenement,
    ev.titre,
    b.nom AS bibliotheque,
    ev.debut,
    ev.fin,
    ev.capacite
FROM evenement ev
    JOIN type_evenement te ON te.id_type_evenement = ev.id_type_evenement
    JOIN bibliotheque   b  ON b.id_bibliotheque    = ev.id_bibliotheque
WHERE te.libelle = 'Atelier' -- ← paramètre : type d'événement
ORDER BY ev.debut;


-- 3.4 Lister les participants à un événement
-- LEFT JOIN abonne, CASE WHEN gère les participants externes sans id_abonne.
-- Résultat : abonnés 1 (Lucas Martin) et 4 (Nicolas Petit) pour « Atelier SQL Avancé ».


SELECT
    lpe.id_participation,
    ev.titre AS evenement,
    CASE WHEN a.id_abonne IS NOT NULL
  THEN a.nom
  ELSE lpe.nom_participant
    END AS nom,
    CASE WHEN a.id_abonne IS NOT NULL
  THEN a.prenom
  ELSE lpe.prenom_participant
    END AS prenom,
    CASE WHEN a.id_abonne IS NOT NULL
  THEN a.email
  ELSE lpe.email_participant
    END AS email,
    lpe.date_inscription,
    lpe.statut,
    CASE WHEN a.id_abonne IS NOT NULL
  THEN 'Abonné (ID ' || a.id_abonne || ')'
  ELSE 'Participant externe'
    END AS type_participant
FROM liaison_participation_evenement lpe
    JOIN evenement ev ON ev.id_evenement = lpe.id_evenement
    LEFT JOIN abonne a ON a.id_abonne   = lpe.id_abonne
WHERE ev.titre = 'Atelier SQL Avancé'    -- ← paramètre : titre ou id
ORDER BY lpe.date_inscription;


-- 3.5 Abonnés ayant participé à des événements similaires (même type)
-- GROUP BY (abonne, type_evenement) + HAVING COUNT(DISTINCT evenement) >= 2.
-- Résultat : abonnés 1 et 4 (participent chacun à ≥ 2 événements du même type).

SELECT
    a.id_abonne,
    a.nom || ' ' || a.prenom   AS abonne,
    te.libelle AS type_evenement,
    COUNT(DISTINCT ev.id_evenement) AS nb_participations
FROM liaison_participation_evenement lpe
    JOIN evenement ev ON ev.id_evenement = lpe.id_evenement
    JOIN type_evenement te ON te.id_type_evenement  = ev.id_type_evenement
    JOIN abonne a  ON a.id_abonne = lpe.id_abonne
GROUP BY a.id_abonne, a.nom, a.prenom, te.libelle
HAVING COUNT(DISTINCT ev.id_evenement) >= 2
ORDER BY nb_participations DESC, a.nom;


-- 3.6 Identifier les ouvrages les plus transférés
-- Jointure liaison_envoi_exemplaire → exemplaire → ouvrage, GROUP BY + COUNT(*).
-- Résultat : « Dune » en tête, « Foundation » aussi présent.

SELECT
    o.id_ouvrage,
    o.titre,
    COUNT(*) AS nombre_transferts
FROM liaison_envoi_exemplaire lee
    JOIN exemplaire e ON e.id_exemplaire = lee.id_exemplaire
    JOIN ouvrage    o ON o.id_ouvrage    = e.id_ouvrage
GROUP BY o.id_ouvrage, o.titre
ORDER BY nombre_transferts DESC;


-- 3.7 Calculer les délais moyens de transfert
-- AVG(date_arrivee - date_depart) sur les envois statut = 'arrive'.
-- Résultat : ≈ 3 jours 3h45 en moyenne (Scénario B : 3j5h, transfert initial : 3j2h30).

SELECT
    COUNT(*) AS nb_transferts_termines,
    AVG(date_arrivee - date_depart) AS delai_moyen,
    MIN(date_arrivee - date_depart) AS delai_min,
    MAX(date_arrivee - date_depart) AS delai_max
FROM envoi_transfert
WHERE statut = 'arrive'
  AND date_depart  IS NOT NULL
  AND date_arrivee IS NOT NULL;


-- 3.8 Analyser la popularité des ouvrages par région
-- Jointures pret → bibliotheque → adresse → region + exemplaire → ouvrage, GROUP BY.
-- Résultat : PACA → « Dune », « LOTR » ; Île-de-France → « Dune ».

SELECT
    reg.nom AS region,
    o.titre AS titre_ouvrage,
    COUNT(*) AS nombre_prets
FROM pret p
    JOIN bibliotheque b  ON b.id_bibliotheque = p.id_bibliotheque_pret
    JOIN adresse      a  ON a.id_adresse      = b.id_adresse
    JOIN region       reg ON reg.id_region    = a.id_region
    JOIN exemplaire   e  ON e.id_exemplaire   = p.id_exemplaire
    JOIN ouvrage      o  ON o.id_ouvrage      = e.id_ouvrage
GROUP BY reg.nom, o.titre
ORDER BY reg.nom, nombre_prets DESC;


-- 3.9 Analyser la popularité des ouvrages par période
-- TO_CHAR(date_pret, 'YYYY-MM') pour extraire le mois, GROUP BY mois + ouvrage.
-- Résultat : prêts répartis sur nov 2023, déc 2023, jan 2024.

SELECT
    TO_CHAR(p.date_pret, 'YYYY-MM')   AS periode_mois,
    o.titre  AS titre_ouvrage,
    COUNT(*)  AS nombre_prets
FROM pret p
    JOIN exemplaire e ON e.id_exemplaire = p.id_exemplaire
    JOIN ouvrage    o ON o.id_ouvrage    = e.id_ouvrage
GROUP BY TO_CHAR(p.date_pret, 'YYYY-MM'), o.titre
ORDER BY periode_mois, nombre_prets DESC;