WITH calcul_incendies AS (
    SELECT
        c.id_commune,
        COUNT(*) FILTER (
            WHERE i.date_premiere_alerte::date >= :date_jour - INTERVAL '30 days'
        ) AS nb_30j,
        COUNT(*) FILTER (
            WHERE i.date_premiere_alerte::date >= :date_jour - INTERVAL '90 days'
        ) AS nb_90j,
        COUNT(*) AS nb_365j
    FROM v_commune_paca c
    JOIN incendie i ON i.code_insee = c.code_insee
        AND i.date_premiere_alerte::date >= :date_jour - INTERVAL '365 days'
        AND i.date_premiere_alerte::date < :date_jour 
    GROUP BY c.id_commune
)
UPDATE commune_jour cj
SET 
    nb_incendies_30j  = COALESCE(calc.nb_30j, 0),
    nb_incendies_90j  = COALESCE(calc.nb_90j, 0),
    nb_incendies_365j = COALESCE(calc.nb_365j, 0)
FROM v_commune_paca c
LEFT JOIN calcul_incendies calc ON c.id_commune = calc.id_commune
WHERE cj.id_commune = c.id_commune
AND cj.date_jour  = :date_jour;