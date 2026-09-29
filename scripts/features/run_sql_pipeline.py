import os
import pandas as pd
from sqlalchemy import create_engine, text
from pipeline_conf import SQL_STEPS
from pathlib import Path
from functools import lru_cache
from dotenv import load_dotenv

SQL_DIR = Path(__file__).resolve().parent / "sql" / "updates"

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

def load_sql(name: str) -> str:
    path = SQL_DIR /name
    if not path.exists():
        print(path)
        raise FileNotFoundError(path)
    return path.read_text(encoding="utf-8").strip()

@lru_cache(maxsize=1)
def get_dates(engine):
    return pd.read_sql(
        "SELECT DISTINCT date_jour FROM commune_jour ORDER BY date_jour",
        engine,
    )

engine = get_engine()

with engine.begin() as conn:

    for name, cfg in SQL_STEPS.items():
        if not cfg.get("enabled"):
            continue

        sql = text(load_sql(name))
        print(f"→ {name} ({cfg['mode']})")

        if cfg["mode"] == "once":
            conn.execute(sql)

        elif cfg["mode"] == "by_day":
            for jour in get_dates(engine)["date_jour"]:
                conn.execute(sql, {"date_jour": jour})

        else:
            raise ValueError(cfg["mode"])

print("pipeline OK")