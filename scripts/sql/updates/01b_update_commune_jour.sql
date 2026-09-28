UPDATE commune_jour cj
SET has_fire = 1
FROM incendie i
JOIN v_commune_paca c ON c.code_insee = i.code_insee
WHERE cj.id_commune = c.id_commune 
    AND cj.date_jour = i.date_premiere_alerte::date;