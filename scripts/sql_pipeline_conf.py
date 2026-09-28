STEPS = {
    "01a_insert_commune_jour.sql": {"enabled": 0, "mode": "once"},
    "01b_update_commune_jour.sql": {"enabled": 0, "mode": "once"},
    "02a_update_nb_incendies.sql": {"enabled": 0, "mode": "by_day"},
    "02b_update_surface_totale_5a.sql": {"enabled": 0, "mode": "by_day"},
    "03a_update_mv_10.sql": {"enabled": 0, "mode": "once"},
    "03b_update_mv_20.sql": {"enabled": 0, "mode": "once"},
    "03c_update_mv_50.sql": {"enabled": 0, "mode": "once"},
    "04a_update_buffer_10km.sql": {"enabled": 0, "mode": "by_day"},
    "04b_update_buffer_20km.sql": {"enabled": 0, "mode": "by_day"},
    "04c_update_buffer_50km.sql": {"enabled": 0, "mode": "by_day"},
    "04d_update_surface_50km.sql": {"enabled": 0, "mode": "by_day"},
}