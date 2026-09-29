import os
import pandas as pd
from sqlalchemy import create_engine, text
from dotenv import load_dotenv


load_dotenv()

def get_engine():
    return create_engine(
        "postgresql+psycopg2://{user}:{password}@{host}:{port}/{db}".format(
            user=os.environ["POSTGRES_USER"],
            password=os.environ["POSTGRES_PASSWORD"],
            host=os.environ["POSTGRES_HOST"],
            port=os.environ["POSTGRES_PORT"],
            db=os.environ["POSTGRES_DB"],
        ),
        connect_args={"options": "-csearch_path=incendies,public"},
    )


def get_communes(engine):
    with engine.connect() as conn:
        df_communes = pd.read_sql(
            text("""
                SELECT 
                    r.id as region,
                    l.id_localisation,
                    ST_X(l.geom_m) AS x,
                    ST_Y(l.geom_m) AS y
                FROM localisation l
                JOIN v_commune_paca c ON l.id_localisation = c.localisation
                JOIN region r ON c.region = r.id
                WHERE 
                    l.geom_m IS NOT NULL
                GROUP BY r.id, l.id_localisation
            """),conn)

    if df_communes.empty:
        raise ValueError("aucun incendie ou ville à clusteriser")
    else:
        # print(df_communes[["x", "y"]].describe())
        return df_communes
    

def update_cluster(engine, df, date_experiment, type_cluster):

    df_copy = df.copy()
    
    # date experiment
    df_copy["date_experiment"] = date_experiment
    # type_cluster
    df_copy["type_cluster"] = type_cluster

    # colonnes de la table cluster
    df_insert = df_copy[["id_localisation", "date_experiment", "cluster_id", "type_cluster"]]

    sql = text("""
        INSERT INTO cluster (
            id_localisation, date_experiment, cluster_id, type_cluster
        )
        VALUES (
            :id_localisation, :date_experiment, :cluster_id, :type_cluster
        )
    """)

    with engine.begin() as conn:
        conn.execute(sql, df_insert.to_dict(orient="records"))

def update_experiment(engine, date_experiment,type_cluster,region,eps,min_samples):
    sql = text("""
        INSERT INTO experiment (
            date_experiment, type_cluster, region, eps, min_samples
        )
        VALUES (
            :date_experiment, :type_cluster, :region, :eps, :min_samples
        )
    """)

    with engine.begin() as conn:
        conn.execute(sql, {
            "date_experiment": date_experiment,
            "type_cluster": type_cluster,
            "region": region,
            "eps": eps,
            "min_samples": min_samples,
        })