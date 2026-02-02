-- =========================
-- RAPHAËL — Réservations
-- =========================

-- Raphaël / Réservations / Enregistrer une réservation
-- Note : On insère l'ID de l'exemplaire et de l'abonné. Le statut est mis à 'active' par défaut.
INSERT INTO reservation (id_exemplaire, id_abonne, date_reservation, statut)
VALUES (2, 3, NOW(), 'active');

-- Raphaël / Réservations / Lister les réservations actives
-- Note : On joint les tables pour avoir le nom de l'abonné et le titre de l'ouvrage au lieu des IDs.
SELECT 
    r.id_reservation,
    a.nom AS nom_abonne,
    a.prenom AS prenom_abonne,
    o.titre AS titre_ouvrage,
    r.date_reservation
FROM reservation r
JOIN abonne a ON r.id_abonne = a.id_abonne
JOIN exemplaire e ON r.id_exemplaire = e.id_exemplaire
JOIN ouvrage o ON e.id_ouvrage = o.id_ouvrage
WHERE r.statut = 'active';

-- Raphaël / Réservations / Lister les réservations d’un abonné
-- Note : Remplacez '1' par l'ID de l'abonné recherché.
SELECT 
    o.titre, 
    r.date_reservation, 
    r.statut 
FROM reservation r
JOIN exemplaire e ON r.id_exemplaire = e.id_exemplaire
JOIN ouvrage o ON e.id_ouvrage = o.id_ouvrage
WHERE r.id_abonne = 1;

-- Raphaël / Réservations / Lister les réservations d’un exemplaire
-- Note : Utile pour voir la file d'attente sur un livre spécifique (ex: id 1).
SELECT 
    a.nom, 
    a.prenom, 
    r.date_reservation 
FROM reservation r
JOIN abonne a ON r.id_abonne = a.id_abonne
WHERE r.id_exemplaire = 1
ORDER BY r.date_reservation ASC;

-- Raphaël / Réservations / Identifier les réservations déclenchant un transfert
-- Note : On cherche les réservations qui sont explicitement liées à un envoi via la table de liaison.
SELECT 
    r.id_reservation,
    o.titre,
    et.id_envoi,
    et.statut AS statut_transfert
FROM reservation r
JOIN liaison_envoi_exemplaire lee ON r.id_reservation = lee.id_reservation
JOIN envoi_transfert et ON lee.id_envoi = et.id_envoi
JOIN exemplaire e ON r.id_exemplaire = e.id_exemplaire
JOIN ouvrage o ON e.id_ouvrage = o.id_ouvrage;


-- =========================
-- RAPHAËL — Transferts inter-bibliothèques
-- =========================

-- Raphaël / Transferts inter-bibliothèques / Créer une demande de transfert
INSERT INTO envoi_transfert 
(id_bibliotheque_source, id_bibliotheque_destination, id_transporteur, date_demande, statut)
VALUES (1, 2, 1, NOW(), 'demande');

-- Raphaël / Transferts inter-bibliothèques / Lister les transferts en cours
SELECT 
    et.id_envoi,
    b1.nom AS source,
    b2.nom AS destination,
    et.date_demande,
    et.statut
FROM envoi_transfert et
JOIN bibliotheque b1 ON et.id_bibliotheque_source = b1.id_bibliotheque
JOIN bibliotheque b2 ON et.id_bibliotheque_destination = b2.id_bibliotheque
WHERE et.statut IN ('en_cours', 'demande');

-- Raphaël / Transferts inter-bibliothèques / Suivre l’état d’un transfert
SELECT statut, date_depart, date_arrivee, note
FROM envoi_transfert
WHERE id_envoi = 1;

-- Raphaël / Transferts inter-bibliothèques / Lister les exemplaires d’un transfert
SELECT 
    e.code_barres,
    o.titre,
    e.etat
FROM liaison_envoi_exemplaire lee
JOIN exemplaire e ON lee.id_exemplaire = e.id_exemplaire
JOIN ouvrage o ON e.id_ouvrage = o.id_ouvrage
WHERE lee.id_envoi = 1;

-- Raphaël / Transferts inter-bibliothèques / Identifier les transferts par bibliothèque source
SELECT * FROM envoi_transfert WHERE id_bibliotheque_source = 3;

-- Raphaël / Transferts inter-bibliothèques / Identifier les transferts par bibliothèque destination
SELECT * FROM envoi_transfert WHERE id_bibliotheque_destination = 1;

-- Raphaël / Transferts inter-bibliothèques / Calculer la distance entre bibliothèques
-- Note : Utilisation de la formule de Haversine pour calculer la distance en KM à partir des latitudes/longitudes.
-- 6371 est le rayon de la Terre en km.
SELECT 
    b1.nom AS depart,
    b2.nom AS arrivee,
    (6371 * acos(
        cos(radians(b1.latitude)) * cos(radians(b2.latitude)) * cos(radians(b2.longitude) - radians(b1.longitude)) + 
        sin(radians(b1.latitude)) * sin(radians(b2.latitude))
    )) AS distance_km
FROM bibliotheque b1, bibliotheque b2
WHERE b1.id_bibliotheque = 1 AND b2.id_bibliotheque = 3;

-- Raphaël / Transferts inter-bibliothèques / Estimer le coût d’un transfert
-- Note : Exemple simple où l'on multiplie la distance stockée par un coût arbitraire (ex: 0.50€ / km).
SELECT 
    id_envoi,
    distance_km,
    (distance_km * 0.50) AS cout_estime_calcule
FROM envoi_transfert
WHERE id_envoi = 1;

-- Raphaël / Transferts inter-bibliothèques / Intégration et gestion des ressources d’une nouvelle bibliothèque
-- Exemple : Insertion d'une nouvelle bibliothèque à Marseille.
INSERT INTO bibliotheque (nom, id_adresse, date_integration, latitude, longitude)
VALUES ('Bibliothèque Marseille Vieux-Port', 1, '2024-02-01', 43.2965, 5.3698);

-- Raphaël / Transferts inter-bibliothèques / Optimisation logistique des transferts par groupage
-- Note : Identifie les paires Source/Destination qui ont plusieurs transferts au statut 'demande' pour les grouper.
SELECT 
    id_bibliotheque_source, 
    id_bibliotheque_destination, 
    COUNT(*) AS nombre_demandes
FROM envoi_transfert
WHERE statut = 'demande'
GROUP BY id_bibliotheque_source, id_bibliotheque_destination
HAVING COUNT(*) > 1;


-- =========================
-- RAPHAËL — Événements & analyses
-- =========================

-- Raphaël / Événements & analyses / Lister les événements à venir
SELECT * FROM evenement WHERE debut > NOW() ORDER BY debut ASC;

-- Raphaël / Événements & analyses / Lister les événements par bibliothèque
SELECT e.titre, e.debut, b.nom 
FROM evenement e
JOIN bibliotheque b ON e.id_bibliotheque = b.id_bibliotheque
WHERE b.id_bibliotheque = 1;

-- Raphaël / Événements & analyses / Lister les événements par type
SELECT e.titre, te.libelle
FROM evenement e
JOIN type_evenement te ON e.id_type_evenement = te.id_type_evenement
WHERE te.libelle = 'Conference';

-- Raphaël / Événements & analyses / Lister les participants à un événement
SELECT 
    lpe.nom_participant, 
    lpe.prenom_participant, 
    a.nom AS nom_abonne, -- Peut être NULL si participant externe
    lpe.statut
FROM liaison_participation_evenement lpe
LEFT JOIN abonne a ON lpe.id_abonne = a.id_abonne
WHERE lpe.id_evenement = 1;

-- Raphaël / Événements & analyses / Identifier les abonnés ayant participé à des événements similaires
-- Note : Trouve les abonnés ayant participé au même Type d'événement (ex: type 1).
SELECT DISTINCT a.nom, a.prenom
FROM liaison_participation_evenement lpe
JOIN evenement e ON lpe.id_evenement = e.id_evenement
JOIN abonne a ON lpe.id_abonne = a.id_abonne
WHERE e.id_type_evenement = 1;

-- Raphaël / Événements & analyses / Identifier les ouvrages les plus transférés
-- Note : Compte le nombre de fois qu'un ouvrage apparaît dans les liaisons d'envoi.
SELECT 
    o.titre, 
    COUNT(lee.id_exemplaire) AS nb_transferts
FROM liaison_envoi_exemplaire lee
JOIN exemplaire e ON lee.id_exemplaire = e.id_exemplaire
JOIN ouvrage o ON e.id_ouvrage = o.id_ouvrage
GROUP BY o.id_ouvrage, o.titre
ORDER BY nb_transferts DESC
LIMIT 5;

-- Raphaël / Événements & analyses / Calculer les délais moyens de transfert
-- Note : Fait la moyenne de la différence entre date d'arrivée et date de départ.
SELECT AVG(date_arrivee - date_depart) AS delai_moyen
FROM envoi_transfert
WHERE statut = 'arrive';

-- Raphaël / Événements & analyses / Analyser la popularité des ouvrages par région
-- Note : Jointure complexe remontant du prêt jusqu'à la région de la bibliothèque.
SELECT 
    reg.nom AS region,
    o.titre,
    COUNT(p.id_pret) AS total_prets
FROM pret p
JOIN bibliotheque b ON p.id_bibliotheque_pret = b.id_bibliotheque
JOIN adresse adr ON b.id_adresse = adr.id_adresse
JOIN region reg ON adr.id_region = reg.id_region
JOIN exemplaire e ON p.id_exemplaire = e.id_exemplaire
JOIN ouvrage o ON e.id_ouvrage = o.id_ouvrage
GROUP BY reg.nom, o.titre
ORDER BY reg.nom, total_prets DESC;

-- Raphaël / Événements & analyses / Analyser la popularité des ouvrages par période
-- Note : Extrait le mois et l'année de la date de prêt (format YYYY-MM).
SELECT 
    TO_CHAR(date_pret, 'YYYY-MM') AS periode,
    COUNT(*) AS nombre_prets
FROM pret
GROUP BY periode
ORDER BY periode DESC;