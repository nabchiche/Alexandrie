-- =========================
-- TOM — Catalogue documentaire
-- =========================

-- Tom / Catalogue documentaire / Lister tous les ouvrages
SELECT id_ouvrage, titre, isbn
FROM ouvrage
ORDER BY titre;


-- Tom / Catalogue documentaire / Rechercher un ouvrage par titre
SELECT id_ouvrage, titre, isbn
FROM ouvrage
WHERE titre LIKE '%1984%' --A modifier selon la recherche
ORDER BY titre;


-- Tom / Catalogue documentaire / Rechercher un ouvrage par ISBN

SELECT id_ouvrage, titre, isbn
FROM ouvrage
WHERE isbn LIKE '9780451524935'; --A modifier selon la recherche

-- Tom / Catalogue documentaire / Lister les ouvrages par auteur
SELECT o.id_ouvrage, o.titre, a.nom AS nom_auteur, a.prenom AS prenom_auteur
FROM ouvrage o
JOIN liaison_ouvrage_auteur loa ON loa.id_ouvrage = o.id_ouvrage
JOIN auteur a ON a.id_auteur = loa.id_auteur
WHERE a.nom LIKE '%Orwell%'
ORDER BY o.titre;


-- Tom / Catalogue documentaire / Lister les ouvrages par catégorie

SELECT o.id_ouvrage, o.titre, c.libelle as categorie
FROM ouvrage o
JOIN categorie c ON c.id_categorie = o.id_categorie
WHERE c.libelle = 'Roman'
ORDER BY o.titre;


-- Tom / Catalogue documentaire / Lister les ouvrages par collection
SELECT o.id_ouvrage, o.titre, col.nom AS collection
FROM ouvrage o
JOIN liaison_ouvrage_collection loc ON loc.id_ouvrage = o.id_ouvrage
JOIN collection col ON col.id_collection = loc.id_collection
WHERE col.nom = 'Classiques'
ORDER BY o.titre;


-- Tom / Catalogue documentaire / Consulter le détail complet d’un ouvrage (selon son id)
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


-- Tom / Catalogue documentaire / Identifier les ouvrages consultables uniquement
SELECT id_ouvrage, titre
FROM ouvrage
WHERE consultable_seulement = TRUE
ORDER BY titre;

-- =========================
-- TOM — Exemplaires & disponibilité
-- =========================

-- Tom / Exemplaires & disponibilité / Lister les exemplaires d’un ouvrage
SELECT e.code_barres, e.statut, b.nom AS bibliotheque
FROM exemplaire e
JOIN bibliotheque b ON b.id_bibliotheque = e.id_bibliotheque
WHERE e.id_ouvrage = 1
ORDER BY b.nom;

-- Tom / Exemplaires & disponibilité / Lister les exemplaires par bibliothèque
SELECT e.code_barres, o.titre, e.statut
FROM exemplaire e
JOIN ouvrage o ON o.id_ouvrage = e.id_ouvrage
WHERE e.id_bibliotheque = 1
ORDER BY o.titre;


-- Tom / Exemplaires & disponibilité / Identifier les exemplaires disponibles dans le réseau
SELECT e.code_barres, o.titre, b.nom
FROM exemplaire e
JOIN ouvrage o ON o.id_ouvrage = e.id_ouvrage
JOIN bibliotheque b ON b.id_bibliotheque = e.id_bibliotheque
WHERE e.statut = 'disponible'
ORDER BY o.titre;

-- Tom / Exemplaires & disponibilité / Identifier les exemplaires disponibles localement
SELECT e.code_barres, o.titre
FROM exemplaire e
JOIN ouvrage o ON o.id_ouvrage = e.id_ouvrage
WHERE e.statut = 'disponible'
AND e.id_bibliotheque = 1
ORDER BY o.titre;

-- Tom / Exemplaires & disponibilité / Identifier les exemplaires transférables pour un abonné
SELECT e.code_barres, o.titre, b.nom
FROM exemplaire e
JOIN ouvrage o ON o.id_ouvrage = e.id_ouvrage
JOIN bibliotheque b ON b.id_bibliotheque = e.id_bibliotheque
JOIN abonne a ON a.id_abonne = 1
WHERE e.statut = 'disponible'
AND e.id_bibliotheque <> a.id_bibliotheque_reference
ORDER BY o.titre;

-- Tom / Exemplaires & disponibilité / Localiser un exemplaire (bibliothèque et emplacement)
SELECT b.nom AS bibliotheque, em.etage, em.rayon, em.numero_rayon
FROM exemplaire e
JOIN bibliotheque b ON b.id_bibliotheque = e.id_bibliotheque
LEFT JOIN emplacement em ON em.id_emplacement = e.id_emplacement
WHERE e.id_exemplaire = 1;


-- Tom / Exemplaires & disponibilité / Identifier les exemplaires sans emplacement
SELECT e.code_barres, o.titre
FROM exemplaire e
JOIN ouvrage o ON o.id_ouvrage = e.id_ouvrage
WHERE e.id_emplacement IS NULL
ORDER BY o.titre;


-- Tom / Exemplaires & disponibilité / Ouvrages disponibles dans le réseau et transférables pour un abonné donné
SELECT DISTINCT o.titre
FROM exemplaire e
JOIN ouvrage o ON o.id_ouvrage = e.id_ouvrage
JOIN abonne a ON a.id_abonne = 1
WHERE e.statut = 'disponible'
AND e.id_bibliotheque <> a.id_bibliotheque_reference
ORDER BY o.titre;

-- Tom / Retards & sanctions / Identifier les prêts en retard
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


-- Tom / Retards & sanctions / Calculer le nombre de retards par abonné
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


-- Tom / Retards & sanctions / Identifier les abonnés en infraction
SELECT DISTINCT
    a.id_abonne,
    a.nom,
    a.prenom
FROM pret p
JOIN abonne a ON a.id_abonne = p.id_abonne
WHERE p.date_retour_effective IS NOT NULL
AND p.date_retour_effective > p.date_retour_prevue
ORDER BY a.nom;


-- Tom / Retards & sanctions / Identifier les abonnés dépassant un seuil de retards
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


-- Tom / Retards & sanctions / Calculer la durée moyenne des prêts
SELECT
    ROUND(
        AVG(EXTRACT(EPOCH FROM (p.date_retour_effective - p.date_pret)) / 86400),
        2
    ) AS duree_moyenne_jours
FROM pret p
WHERE p.date_retour_effective IS NOT NULL;



-- Tom / Retards & sanctions / Abonnés en infraction et fréquence de retards
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



