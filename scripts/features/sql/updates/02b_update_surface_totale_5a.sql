WITH date_bornes AS (
    SELECT 
        CAST(:date_jour AS DATE) AS d_end,
        CAST(:date_jour AS DATE) - INTERVAL '1825 days' AS d_5a
),
calcul_surface AS (
    SELECT
        c.id_commune,
        SUM(i.surface_parcourue) AS surface_totale_5a
    FROM date_bornes b
    CROSS JOIN incendie i
    JOIN v_commune_paca c ON i.code_insee = c.code_insee
    WHERE i.date_premiere_alerte >= b.d_5a
    AND i.date_premiere_alerte < b.d_end
    GROUP BY c.id_commune
)
UPDATE commune_jour cj
SET surface_totale_5a = COALESCE(calc.surface_totale_5a, 0)
FROM v_commune_paca c
LEFT JOIN calcul_surface calc ON c.id_commune = calc.id_commune
WHERE cj.id_commune = c.id_commune
AND cj.date_jour  = :date_jour;