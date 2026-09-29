import os
from datetime import date, datetime, timezone
import pandas as pd
from sqlalchemy import create_engine, text
from pathlib import Path
from pipeline_conf import DBSCAN_STEPS
from functools import lru_cache
from dotenv import load_dotenv
from sklearn.cluster import DBSCAN

from utils.dbscan_utils import suggest_eps_range, dbscan_grid_search, select_best_params, plot_clusters, db_scan
from utils.dbscan_db import get_engine, get_communes, update_cluster, update_experiment
    

def find_best(df, X):
    eps_values = suggest_eps_range(X, k=4, n_points=15)
    min_samples_values = [4, 6, 8, 10, 12]
    df_results = dbscan_grid_search(X, eps_values, min_samples_values)

    best = select_best_params(df_results, max_noise_ratio=0.35)
    if best is None:
        return df_results, best, None, None

    top = best.iloc[0]
    best_eps = top["eps"]
    best_min_samples = int(top["min_samples"])

    # print(best.head(10).to_string(index=False))
    return df_results, best, best_eps, best_min_samples


# Connexion
engine = get_engine();

for type_cluster, cfg in DBSCAN_STEPS.items():

    if not cfg.get("enabled"):
        continue

    # Communes
    df_communes = get_communes(engine)

    # Date experiment
    date_experiment = datetime.now()

    # Type_cluster
    sql = text("""
            SELECT id
            FROM type_cluster
            WHERE nom = :nom
        """)
    with engine.connect() as conn:
        type_cluster = conn.execute(sql,{"nom": type_cluster}).scalar_one_or_none()

    if not cfg.get("update"):
        continue
    
    for region, df_region in df_communes.groupby("region"):

        X = df_region[["x", "y"]].values

        df_results, best, best_eps, best_min_samples = find_best(df_region,X)

        df_scan = db_scan(df_communes, min_samples=best_min_samples, eps=best_eps, region=region)
        update_cluster(engine, df_scan, date_experiment, type_cluster)
        update_experiment(engine, date_experiment=date_experiment,type_cluster=type_cluster,region=region,eps=float(best_eps),min_samples=int(best_min_samples))