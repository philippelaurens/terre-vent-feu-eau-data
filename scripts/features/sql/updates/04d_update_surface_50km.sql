WITH calcul_surface AS (
    SELECT 
        v.ref_commune,
        SUM(i.surface_parcourue / NULLIF(v.distance * v.distance, 0)) AS surface
    FROM mv_communes_voisines_50km v
    LEFT JOIN incendie i ON i.code_insee = v.code_insee
        AND i.date_premiere_alerte >= (:date_jour - INTERVAL '30 day')
        AND i.date_premiere_alerte <  :date_jour 
    GROUP BY v.ref_commune
)
UPDATE commune_jour cj
SET surface_50km = COALESCE(calc.surface, 0)
FROM calcul_surface calc
WHERE cj.id_commune = calc.ref_commune
AND cj.date_jour  = :date_jour;