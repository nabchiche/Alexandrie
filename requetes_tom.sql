-- =========================
-- TOM — Catalogue documentaire
-- =========================

-- Lister tous les ouvrages
-- Cette requête récupère l’ensemble des ouvrages enregistrés dans la base.
-- Elle affiche l’identifiant de l’ouvrage, son titre et son ISBN.
-- Les résultats sont triés par ordre alphabétique sur le titre.
SELECT id_ouvrage, titre, isbn
FROM ouvrage
ORDER BY titre;

-- Rechercher un ouvrage par titre
-- Cette requête permet de rechercher un ouvrage à partir d’une partie de son titre.
-- L’opérateur LIKE associé aux % autorise une recherche partielle.
-- Le tri par titre améliore la lisibilité des résultats.
SELECT id_ouvrage, titre, isbn
FROM ouvrage
WHERE titre LIKE '%1984%' -- À modifier selon la recherche
ORDER BY titre;

-- Rechercher un ouvrage par ISBN
-- Cette requête permet de retrouver précisément un ouvrage grâce à son ISBN.
-- L’ISBN étant unique, elle identifie un seul ouvrage.
SELECT id_ouvrage, titre, isbn
FROM ouvrage
WHERE isbn LIKE '9780451524935'; -- À modifier selon la recherche

-- Lister les ouvrages par auteur
-- Cette requête affiche les ouvrages écrits par un auteur donné.
-- Elle s’appuie sur une table de liaison pour gérer la relation plusieurs-à-plusieurs.
-- Le filtrage est effectué sur le nom de l’auteur.
SELECT o.id_ouvrage, o.titre, a.nom AS nom_auteur, a.prenom AS prenom_auteur
FROM ouvrage o
JOIN liaison_ouvrage_auteur loa ON loa.id_ouvrage = o.id_ouvrage
JOIN auteur a ON a.id_auteur = loa.id_auteur
WHERE a.nom LIKE '%Orwell%'
ORDER BY o.titre;

-- Lister les ouvrages par catégorie
-- Cette requête permet d’obtenir les ouvrages appartenant à une catégorie donnée.
-- Elle relie la table ouvrage à la table categorie.
SELECT o.id_ouvrage, o.titre, c.libelle AS categorie
FROM ouvrage o
JOIN categorie c ON c.id_categorie = o.id_categorie
WHERE c.libelle = 'Roman'
ORDER BY o.titre;

-- Lister les ouvrages par collection
-- Cette requête affiche les ouvrages associés à une collection spécifique.
-- Une table de liaison est utilisée car un ouvrage peut appartenir à plusieurs collections.
SELECT o.id_ouvrage, o.titre, col.nom AS collection
FROM ouvrage o
JOIN liaison_ouvrage_collection loc ON loc.id_ouvrage = o.id_ouvrage
JOIN collection col ON col.id_collection = loc.id_collection
WHERE col.nom = 'Classiques'
ORDER BY o.titre;

-- Consulter le détail complet d’un ouvrage
-- Cette requête fournit toutes les informations disponibles sur un ouvrage donné.
-- Les LEFT JOIN permettent d’inclure les informations même si certaines relations sont absentes.
-- Le filtrage se fait à partir de l’identifiant de l’ouvrage.
SELECT
o.titre,
o.isbn,
c.libelle AS categorie,
o.consultable_seulement,
a.nom AS auteur_nom,
a.prenom AS auteur_prenom,
col.nom AS collection
FROM ouvrage o
LEFT JOIN categorie c ON c.id_categorie = o.id_categorie
LEFT JOIN liaison_ouvrage_auteur loa ON loa.id_ouvrage = o.id_ouvrage
LEFT JOIN auteur a ON a.id_auteur = loa.id_auteur
LEFT JOIN liaison_ouvrage_collection loc ON loc.id_ouvrage = o.id_ouvrage
LEFT JOIN collection col ON col.id_collection = loc.id_collection
WHERE o.id_ouvrage = 1;

-- Identifier les ouvrages consultables uniquement
-- Cette requête liste les ouvrages qui ne peuvent être consultés que sur place.
-- Elle s’appuie sur un champ booléen indiquant cette contrainte.
SELECT id_ouvrage, titre
FROM ouvrage
WHERE consultable_seulement = TRUE
ORDER BY titre;

-- =========================
-- TOM — Exemplaires & disponibilité
-- =========================

-- Lister les exemplaires d’un ouvrage
-- Cette requête affiche tous les exemplaires d’un ouvrage donné.
-- Elle indique leur statut et la bibliothèque dans laquelle ils se trouvent.
SELECT e.code_barres, e.statut, b.nom AS bibliotheque
FROM exemplaire e
JOIN bibliotheque b ON b.id_bibliotheque = e.id_bibliotheque
WHERE e.id_ouvrage = 1
ORDER BY b.nom;

-- Lister les exemplaires par bibliothèque
-- Cette requête permet de visualiser tous les exemplaires présents dans une bibliothèque donnée.
-- Le titre de l’ouvrage est affiché pour plus de clarté.
SELECT e.code_barres, o.titre, e.statut
FROM exemplaire e
JOIN ouvrage o ON o.id_ouvrage = e.id_ouvrage
WHERE e.id_bibliotheque = 1
ORDER BY o.titre;

-- Identifier les exemplaires disponibles dans le réseau
-- Cette requête liste tous les exemplaires dont le statut est « disponible »
-- dans l’ensemble du réseau de bibliothèques.
SELECT e.code_barres, o.titre, b.nom
FROM exemplaire e
JOIN ouvrage o ON o.id_ouvrage = e.id_ouvrage
JOIN bibliotheque b ON b.id_bibliotheque = e.id_bibliotheque
WHERE e.statut = 'disponible'
ORDER BY o.titre;

-- Identifier les exemplaires disponibles localement
-- Cette requête permet de connaître les exemplaires disponibles dans une bibliothèque précise.
SELECT e.code_barres, o.titre
FROM exemplaire e
JOIN ouvrage o ON o.id_ouvrage = e.id_ouvrage
WHERE e.statut = 'disponible'
AND e.id_bibliotheque = 1
ORDER BY o.titre;

-- Identifier les exemplaires transférables pour un abonné
-- Cette requête identifie les exemplaires disponibles situés dans une autre bibliothèque
-- que celle de référence de l’abonné.
SELECT e.code_barres, o.titre, b.nom
FROM exemplaire e
JOIN ouvrage o ON o.id_ouvrage = e.id_ouvrage
JOIN bibliotheque b ON b.id_bibliotheque = e.id_bibliotheque
JOIN abonne a ON a.id_abonne = 1
WHERE e.statut = 'disponible'
AND e.id_bibliotheque <> a.id_bibliotheque_reference
ORDER BY o.titre;

-- Localiser un exemplaire
-- Cette requête permet de localiser précisément un exemplaire dans une bibliothèque.
-- Elle affiche la bibliothèque et les informations d’emplacement physique.
SELECT b.nom AS bibliotheque, em.etage, em.rayon, em.numero_rayon
FROM exemplaire e
JOIN bibliotheque b ON b.id_bibliotheque = e.id_bibliotheque
LEFT JOIN emplacement em ON em.id_emplacement = e.id_emplacement
WHERE e.id_exemplaire = 1;

-- Identifier les exemplaires sans emplacement
-- Cette requête repère les exemplaires qui ne sont associés à aucun emplacement.
-- Elle est utile pour la gestion et l’inventaire.
SELECT e.code_barres, o.titre
FROM exemplaire e
JOIN ouvrage o ON o.id_ouvrage = e.id_ouvrage
WHERE e.id_emplacement IS NULL
ORDER BY o.titre;

-- Ouvrages disponibles dans le réseau et transférables pour un abonné
-- Cette requête liste les titres des ouvrages disponibles dans d’autres bibliothèques
-- que celle de référence de l’abonné.
-- DISTINCT évite les doublons lorsqu’un ouvrage possède plusieurs exemplaires.
SELECT DISTINCT o.titre
FROM exemplaire e
JOIN ouvrage o ON o.id_ouvrage = e.id_ouvrage
JOIN abonne a ON a.id_abonne = 1
WHERE e.statut = 'disponible'
AND e.id_bibliotheque <> a.id_bibliotheque_reference
ORDER BY o.titre;

-- =========================
-- TOM — Retards & sanctions
-- =========================

-- Identifier les prêts en retard
-- Cette requête identifie les prêts encore en cours dont la date de retour prévue est dépassée.
-- Elle permet de repérer les retards actuels.
SELECT
p.id_pret,
a.nom,
a.prenom,
o.titre,
p.date_retour_prevue
FROM pret p
JOIN exemplaire e ON e.id_exemplaire = p.id_exemplaire
JOIN ouvrage o ON o.id_ouvrage = e.id_ouvrage
JOIN abonne a ON a.id_abonne = p.id_abonne
WHERE p.statut = 'en_cours'
AND p.date_retour_prevue < NOW()
ORDER BY p.date_retour_prevue;

-- Calculer le nombre de retards par abonné
-- Cette requête compte le nombre de prêts rendus en retard pour chaque abonné.
-- Elle compare la date de retour effective à la date prévue.
SELECT
a.id_abonne,
a.nom,
a.prenom,
COUNT(*) AS nombre_retards
FROM pret p
JOIN abonne a ON a.id_abonne = p.id_abonne
WHERE p.date_retour_effective IS NOT NULL
AND p.date_retour_effective > p.date_retour_prevue
GROUP BY a.id_abonne, a.nom, a.prenom
ORDER BY nombre_retards DESC;

-- Identifier les abonnés en infraction
-- Cette requête affiche les abonnés ayant au moins un prêt rendu en retard.
-- DISTINCT évite les doublons.
SELECT DISTINCT
a.id_abonne,
a.nom,
a.prenom
FROM pret p
JOIN abonne a ON a.id_abonne = p.id_abonne
WHERE p.date_retour_effective IS NOT NULL
AND p.date_retour_effective > p.date_retour_prevue
ORDER BY a.nom;

-- Identifier les abonnés dépassant un seuil de retards
-- Cette requête sélectionne les abonnés ayant un nombre de retards supérieur ou égal à un seuil donné.
-- La clause HAVING permet de filtrer après l’agrégation.
SELECT
a.id_abonne,
a.nom,
a.prenom,
COUNT(*) AS nombre_retards
FROM pret p
JOIN abonne a ON a.id_abonne = p.id_abonne
WHERE p.date_retour_effective IS NOT NULL
AND p.date_retour_effective > p.date_retour_prevue
GROUP BY a.id_abonne, a.nom, a.prenom
HAVING COUNT(*) >= 2
ORDER BY nombre_retards DESC;

-- Calculer la durée moyenne des prêts
-- Cette requête calcule la durée moyenne d’un prêt en jours.
-- La différence entre les dates est convertie en jours puis arrondie.
SELECT
ROUND(
AVG(EXTRACT(EPOCH FROM (p.date_retour_effective - p.date_pret)) / 86400),
2
) AS duree_moyenne_jours
FROM pret p
WHERE p.date_retour_effective IS NOT NULL;

-- Abonnés en infraction et fréquence de retards
-- Cette requête permet d’identifier les abonnés ayant un nombre élevé de retards.
-- Elle est utile pour appliquer des sanctions ou restrictions.
SELECT
a.id_abonne,
a.nom,
a.prenom,
COUNT(*) AS nombre_retards
FROM pret p
JOIN abonne a ON a.id_abonne = p.id_abonne
WHERE p.date_retour_effective IS NOT NULL
AND p.date_retour_effective > p.date_retour_prevue
GROUP BY a.id_abonne, a.nom, a.prenom
HAVING COUNT(*) >= 2
ORDER BY nombre_retards DESC;
