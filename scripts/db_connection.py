import os
from dotenv import load_dotenv
from sqlalchemy import create_engine

def get_engine():
    load_dotenv()

    user = os.getenv("POSTGRES_USER")
    password = os.getenv("POSTGRES_PASSWORD")
    database = os.getenv("POSTGRES_DB")
    host = os.getenv("POSTGRES_HOST", "localhost")
    port = os.getenv("POSTGRES_PORT", "5432")

    if not all([user, password, database]):
        raise ValueError("Database environment variables are missing")
    
    db_url = f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{database}"
    return create_engine(db_url)