WITH calcul_incendies AS (
    SELECT 
        v.ref_commune,
        COUNT(i.id_incendie) AS feux_du_jour
    FROM mv_communes_voisines_50km v
    LEFT JOIN incendie i ON i.code_insee = v.code_insee
        AND i.date_premiere_alerte >= (:date_jour - INTERVAL '30 day')
        AND i.date_premiere_alerte <  :date_jour 
    GROUP BY v.ref_commune
)
UPDATE commune_jour cj
SET buffer_50km = COALESCE(calc.feux_du_jour, 0)
FROM v_commune_paca c
LEFT JOIN calcul_incendies calc ON c.id_commune = calc.ref_commune
WHERE cj.id_commune = c.id_commune
AND cj.date_jour  = :date_jour;