import logging
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from app.db import SessionLocal, init_db
from app.ingestion.pipeline import run_ingestion
from app.ingestion.scheduler import shutdown_scheduler, start_scheduler
from app.routers import ingest, items, meta, sources, translate

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
logger = logging.getLogger("news_aggregator.main")

STATIC_DIR = Path(__file__).resolve().parent / "static"


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    db = SessionLocal()
    try:
        stats = run_ingestion(db)
        logger.info("Initial ingestion run: %s", stats)
    except Exception:
        logger.exception("Initial ingestion run failed; server will still start")
    finally:
        db.close()

    start_scheduler()
    yield
    shutdown_scheduler()


app = FastAPI(title="Bilingual Signal-First News Aggregator", lifespan=lifespan)

app.include_router(items.router)
app.include_router(translate.router)
app.include_router(sources.router)
app.include_router(meta.router)
app.include_router(ingest.router)


@app.get("/api/health")
def health():
    return {"status": "ok"}


app.mount("/", StaticFiles(directory=str(STATIC_DIR), html=True), name="static")
