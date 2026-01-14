import os
import sqlite3
from contextlib import contextmanager
from pathlib import Path


DB_PATH = Path(os.getenv("BOLUSBUDDY_DB", "backend_storage.db"))


def init_db() -> None:
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS foods (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              fdc_id INTEGER,
              description TEXT NOT NULL,
              data_type TEXT,
              brand_owner TEXT,
              ingredients TEXT
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS nutrients (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              food_id INTEGER NOT NULL,
              nutrient_name TEXT NOT NULL,
              unit TEXT NOT NULL,
              amount_per_100g REAL NOT NULL,
              FOREIGN KEY(food_id) REFERENCES foods(id)
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS serving_units (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              food_id INTEGER NOT NULL,
              unit TEXT NOT NULL,
              grams_per_unit REAL NOT NULL,
              FOREIGN KEY(food_id) REFERENCES foods(id)
            )
            """
        )
        conn.commit()


@contextmanager
def db_session():
    conn = sqlite3.connect(DB_PATH)
    try:
        yield conn
    finally:
        conn.close()
