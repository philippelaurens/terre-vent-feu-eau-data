INSERT INTO commune_jour (id_commune, date_jour, has_fire)
SELECT 
    c.id_commune,
    d.jour::date,
    0
FROM 
    v_commune_paca c
CROSS JOIN 
    generate_series(
        '2016-01-01'::date, 
        '2025-12-31'::date, 
        '1 day'::interval
    ) AS d(jour)