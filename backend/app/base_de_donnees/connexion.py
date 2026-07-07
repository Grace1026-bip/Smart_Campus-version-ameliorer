from collections.abc import Generator

from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session, sessionmaker

from app.configuration.parametres import obtenir_parametres


parametres = obtenir_parametres()

moteur = create_engine(
    parametres.url_base_de_donnees,
    pool_pre_ping=True,
    pool_recycle=3600,
    future=True,
)

SessionLocale = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=moteur,
    class_=Session,
    expire_on_commit=False,
)


def obtenir_session() -> Generator[Session, None, None]:
    session = SessionLocale()
    try:
        yield session
    finally:
        session.close()


def verifier_connexion_mysql() -> bool:
    try:
        with moteur.connect() as connexion:
            connexion.execute(text("SELECT 1"))
        return True
    except SQLAlchemyError:
        return False
