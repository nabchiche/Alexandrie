-- =========================
-- SWANN — Abonnés
-- =========================

-- Swann / Abonnés / Lister tous les abonnés
-- Vérifie que tous les abonnés sont correctement enregistrés et accessibles dans la base.
SELECT a.id_abonne, a.nom, a.prenom
FROM abonne a
ORDER BY a.id_abonne;

-- Swann / Abonnés / Consulter la fiche d’un abonné
-- Permet de contrôler l’intégrité des informations détaillées d’un abonné et de ses relations.
SELECT
a.id_abonne, a.numero_carte, a.nom, a.prenom, a.email, a.telephone, a.date_inscription, a.statut, a.suspendu_jusqua,
ta.id_type_abonnement, ta.libelle AS type_abonnement, ta.quota_max, ta.duree_pret_jours,
b.id_bibliotheque, b.nom AS bibliotheque_reference
FROM abonne a
JOIN type_abonnement ta ON ta.id_type_abonnement = a.id_type_abonnement
JOIN bibliotheque b ON b.id_bibliotheque = a.id_bibliotheque_reference
WHERE a.id_abonne = 1;

-- Swann / Abonnés / Lister les abonnés par bibliothèque de référence
-- Valide le rattachement correct des abonnés à leur bibliothèque principale.
SELECT
a.id_abonne,
a.nom,
a.prenom,
ta.libelle AS type_abonnement,
b.nom AS bibliotheque_reference
FROM abonne a
JOIN type_abonnement ta ON ta.id_type_abonnement = a.id_type_abonnement
JOIN bibliotheque b ON b.id_bibliotheque = a.id_bibliotheque_reference
WHERE a.id_bibliotheque_reference = 1
ORDER BY a.id_abonne;

-- Swann / Abonnés / Lister les abonnés par type d’abonnement
-- Permet de vérifier l’application correcte des types d’abonnement dans la base.
SELECT
a.id_abonne,
a.nom,
a.prenom,
ta.libelle AS type_abonnement,
b.nom AS bibliotheque_reference
FROM abonne a
JOIN type_abonnement ta ON ta.id_type_abonnement = a.id_type_abonnement
JOIN bibliotheque b ON b.id_bibliotheque = a.id_bibliotheque_reference
WHERE a.id_type_abonnement = 1
ORDER BY a.id_abonne;

-- Swann / Abonnés / Identifier les abonnés suspendus
-- Sert à contrôler la gestion des sanctions et des périodes de suspension.
SELECT
a.id_abonne,
a.numero_carte,
a.nom,
a.prenom,
a.statut,
a.suspendu_jusqua
FROM abonne a
WHERE a.statut = 'suspendu'
ORDER BY a.suspendu_jusqua DESC NULLS LAST, a.nom, a.prenom;

-- Swann / Abonnés / Vérifier l’éligibilité d’un abonné à l’emprunt
-- Centralise les règles métier pour tester automatiquement l’éligibilité à l’emprunt.
CREATE OR REPLACE VIEW v_stats_abonne AS
SELECT
a.id_abonne,
a.statut,
a.suspendu_jusqua,
ta.quota_max,
COUNT(p.id_pret) AS nb_prets_en_cours,
SUM(CASE WHEN p.date_retour_prevue < NOW() THEN 1 ELSE 0 END) AS nb_prets_en_retard
FROM abonne a
JOIN type_abonnement ta ON ta.id_type_abonnement = a.id_type_abonnement
LEFT JOIN pret p
ON p.id_abonne = a.id_abonne
AND p.statut = 'en_cours'
AND p.date_retour_effective IS NULL
GROUP BY a.id_abonne, a.statut, a.suspendu_jusqua, ta.quota_max;

SELECT
id_abonne,
(statut = 'actif')
AND (suspendu_jusqua IS NULL OR suspendu_jusqua < CURRENT_DATE)
AND (nb_prets_en_retard = 0)
AND (nb_prets_en_cours < quota_max) AS est_eligible,
nb_prets_en_cours,
quota_max,
nb_prets_en_retard,
statut,
suspendu_jusqua
FROM v_stats_abonne
WHERE id_abonne = 1;


-- Swann / Abonnés / Événements programmés et abonnés ayant participé à des événements similaires
-- Vérifie la cohérence entre événements à venir et l’historique de participation des abonnés.
CREATE OR REPLACE VIEW v_evenements_a_venir AS
SELECT
e.id_evenement,
e.id_bibliotheque,
b.nom AS bibliotheque,
e.id_type_evenement,
te.libelle AS type_evenement,
e.titre,
e.debut,
e.fin
FROM evenement e
JOIN bibliotheque b ON b.id_bibliotheque = e.id_bibliotheque
JOIN type_evenement te ON te.id_type_evenement = e.id_type_evenement
WHERE e.debut >= NOW();
-- Permet de relier les événements futurs aux abonnés ayant déjà participé à des événements du même type
WITH evenements_biblio AS (
SELECT *
FROM v_evenements_a_venir
WHERE id_bibliotheque = 1
),
abonnes_similaires AS (
SELECT DISTINCT
eb.id_evenement,
lpe.id_abonne
FROM evenements_biblio eb
JOIN evenement e2 ON e2.id_type_evenement = eb.id_type_evenement
JOIN liaison_participation_evenement lpe ON lpe.id_evenement = e2.id_evenement
WHERE lpe.id_abonne IS NOT NULL
)
SELECT
eb.titre,
eb.debut,
eb.fin,
a.id_abonne,
a.nom,
a.prenom
FROM evenements_biblio eb
LEFT JOIN abonnes_similaires s ON s.id_evenement = eb.id_evenement
LEFT JOIN abonne a ON a.id_abonne = s.id_abonne
ORDER BY eb.debut, eb.id_evenement, a.nom, a.prenom;


-- =========================
-- SWANN — Prêts
-- =========================

-- Swann / Prêts / Lister les prêts en cours
-- Permet de tester la détection correcte des prêts actifs et non clôturés.
SELECT
p.id_pret,
p.date_pret,
p.date_retour_prevue,
a.nom,
a.prenom,
ex.code_barres,
o.titre,
b.nom AS bibliotheque
FROM pret p
JOIN abonne a ON a.id_abonne = p.id_abonne
JOIN exemplaire ex ON ex.id_exemplaire = p.id_exemplaire
JOIN ouvrage o ON o.id_ouvrage = ex.id_ouvrage
JOIN bibliotheque b ON b.id_bibliotheque = p.id_bibliotheque_pret
WHERE p.statut = 'en_cours'
AND p.date_retour_effective IS NULL
ORDER BY p.date_retour_prevue;

-- Swann / Prêts / Lister les prêts d’un abonné
-- Vérifie le suivi des emprunts actifs pour un abonné donné.
SELECT
p.id_pret,
p.date_pret,
p.date_retour_prevue,
o.titre,
ex.code_barres
FROM pret p
JOIN exemplaire ex ON ex.id_exemplaire = p.id_exemplaire
JOIN ouvrage o ON o.id_ouvrage = ex.id_ouvrage
WHERE p.id_abonne = 2
AND p.statut = 'en_cours'
AND p.date_retour_effective IS NULL
ORDER BY p.date_pret DESC;

-- Swann / Prêts / Consulter l’historique des prêts d’un abonné
-- Permet de tester la conservation complète de l’historique des prêts.
SELECT
p.id_pret,
p.date_pret,
p.date_retour_prevue,
p.date_retour_effective,
p.statut,
o.titre,
ex.code_barres
FROM pret p
JOIN exemplaire ex ON ex.id_exemplaire = p.id_exemplaire
JOIN ouvrage o ON o.id_ouvrage = ex.id_ouvrage
WHERE p.id_abonne = 1
ORDER BY p.date_pret DESC;

-- Swann / Prêts / Lister les prêts par bibliothèque
-- Vérifie la capacité à analyser l’activité d’une bibliothèque donnée.
SELECT
p.id_pret,
p.date_pret,
a.nom,
a.prenom,
o.titre,
ex.code_barres,
p.statut
FROM pret p
JOIN abonne a ON a.id_abonne = p.id_abonne
JOIN exemplaire ex ON ex.id_exemplaire = p.id_exemplaire
JOIN ouvrage o ON o.id_ouvrage = ex.id_ouvrage
WHERE p.id_bibliotheque_pret = 1
ORDER BY p.date_pret DESC;

-- Swann / Prêts / Ouvrages les plus fréquemment transférés et délais associés
-- Sert à tester les statistiques de transfert et le calcul des délais logistiques.
SELECT
o.id_ouvrage,
o.titre,
COUNT(*) AS nb_transferts,
AVG(et.date_arrivee - et.date_depart) AS delai_moyen
FROM envoi_transfert et
JOIN liaison_envoi_exemplaire lee ON lee.id_envoi = et.id_envoi
JOIN exemplaire ex ON ex.id_exemplaire = lee.id_exemplaire
JOIN ouvrage o ON o.id_ouvrage = ex.id_ouvrage
WHERE et.statut = 'arrive'
AND et.date_depart IS NOT NULL
AND et.date_arrivee IS NOT NULL
GROUP BY o.id_ouvrage, o.titre
ORDER BY nb_transferts DESC, delai_moyen ASC
LIMIT 5;

-- Requête récursive : historique complet des transferts d’un exemplaire
-- Permet de vérifier la traçabilité complète d’un exemplaire à travers plusieurs transferts.
WITH RECURSIVE transferts_exemplaire AS (
SELECT
et.id_envoi,
lee.id_exemplaire,
et.date_demande,
et.date_depart,
et.date_arrivee,
et.statut,
1 AS etape
FROM envoi_transfert et
JOIN liaison_envoi_exemplaire lee ON lee.id_envoi = et.id_envoi
WHERE lee.id_exemplaire = 4
AND et.date_demande = (
SELECT MIN(et2.date_demande)
FROM envoi_transfert et2
JOIN liaison_envoi_exemplaire lee2 ON lee2.id_envoi = et2.id_envoi
WHERE lee2.id_exemplaire = 4
)

UNION ALL

SELECT
et_next.id_envoi,
te.id_exemplaire,
et_next.date_demande,
et_next.date_depart,
et_next.date_arrivee,
et_next.statut,
te.etape + 1
FROM transferts_exemplaire te
JOIN envoi_transfert et_next
ON et_next.date_demande = (
SELECT MIN(et3.date_demande)
FROM envoi_transfert et3
JOIN liaison_envoi_exemplaire lee3 ON lee3.id_envoi = et3.id_envoi
WHERE lee3.id_exemplaire = te.id_exemplaire
AND et3.date_demande > te.date_demande
)
JOIN liaison_envoi_exemplaire lee_next
ON lee_next.id_envoi = et_next.id_envoi
AND lee_next.id_exemplaire = te.id_exemplaire
)
SELECT
etape,
id_envoi,
id_exemplaire,
date_demande,
date_depart,
date_arrivee,
statut
FROM transferts_exemplaire
ORDER BY etape;



-- Vue commune pour les requêtes suivantes : prêts avec région
-- Centralise la relation entre prêts et régions pour simplifier les analyses statistiques.
CREATE OR REPLACE VIEW v_prets_avec_region AS
SELECT
p.id_pret,
p.date_pret,
r.nom AS region,
ex.id_ouvrage
FROM pret p
JOIN bibliotheque b ON b.id_bibliotheque = p.id_bibliotheque_pret
JOIN adresse ad ON ad.id_adresse = b.id_adresse
JOIN region r ON r.id_region = ad.id_region
JOIN exemplaire ex ON ex.id_exemplaire = p.id_exemplaire;

-- Swann / Prêts / Popularité des ouvrages/collections par région de la bibliothèque — nombre d’emprunts
-- Vérifie la capacité à analyser la popularité des ouvrages selon la localisation.
SELECT
v.region,
o.titre,
COUNT(*) AS nb_emprunts
FROM v_prets_avec_region v
JOIN ouvrage o ON o.id_ouvrage = v.id_ouvrage
GROUP BY v.region, o.titre
ORDER BY v.region, nb_emprunts DESC;


-- Swann / Prêts / Popularité des ouvrages/collections par région de la bibliothèque — période (30 jours)
-- Permet de tester l’analyse temporelle des emprunts.
SELECT
v.region,
o.titre,
COUNT(*) AS nb_emprunts_30j
FROM v_prets_avec_region v
JOIN ouvrage o ON o.id_ouvrage = v.id_ouvrage
WHERE v.date_pret >= NOW() - INTERVAL '30 days'
GROUP BY v.region, o.titre
ORDER BY v.region, nb_emprunts_30j DESC;


-- Swann / Prêts / Popularité des ouvrages/collections par région de la bibliothèque — période (12 mois)
SELECT
v.region,
o.titre,
COUNT(*) AS nb_emprunts_12m
FROM v_prets_avec_region v
JOIN ouvrage o ON o.id_ouvrage = v.id_ouvrage
WHERE v.date_pret >= NOW() - INTERVAL '12 months'
GROUP BY v.region, o.titre
ORDER BY v.region, nb_emprunts_12m DESC;


-- Swann / Prêts / Popularité des ouvrages/collections par région de la bibliothèque — période (total)
SELECT
v.region,
o.titre,
COUNT(*) AS nb_emprunts_12m
FROM v_prets_avec_region v
JOIN ouvrage o ON o.id_ouvrage = v.id_ouvrage
WHERE v.date_pret <= NOW()
GROUP BY v.region, o.titre
ORDER BY v.region, nb_emprunts_12m DESC;


-- Swann / Prêts / Popularité des ouvrages/collections par région de la bibliothèque — filtres (auteur)
-- Vérifie le bon fonctionnement des filtres analytiques sur les emprunts.
SELECT
v.region,
o.titre,
COUNT(*) AS nb_emprunts
FROM v_prets_avec_region v
JOIN ouvrage o ON o.id_ouvrage = v.id_ouvrage
JOIN liaison_ouvrage_auteur loa ON loa.id_ouvrage = o.id_ouvrage
WHERE loa.id_auteur = 1
GROUP BY v.region, o.titre
ORDER BY v.region, nb_emprunts DESC;


-- Swann / Prêts / Popularité des ouvrages/collections par région de la bibliothèque — filtres (catégorie)
SELECT
v.region,
o.titre,
COUNT(*) AS nb_emprunts
FROM v_prets_avec_region v
JOIN ouvrage o ON o.id_ouvrage = v.id_ouvrage
WHERE o.id_categorie = 2
GROUP BY v.region, o.titre
ORDER BY v.region, nb_emprunts DESC;



-- Swann / Prêts / Popularité des ouvrages/collections par région de la bibliothèque — filtres (collection)
SELECT
v.region,
c.nom AS collection,
COUNT(*) AS nb_emprunts
FROM v_prets_avec_region v
JOIN liaison_ouvrage_collection loc ON loc.id_ouvrage = v.id_ouvrage
JOIN collection c ON c.id_collection = loc.id_collection
GROUP BY v.region, c.nom
ORDER BY v.region, nb_emprunts DESC;

