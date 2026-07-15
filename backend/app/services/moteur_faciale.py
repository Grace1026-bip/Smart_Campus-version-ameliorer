from __future__ import annotations

from dataclasses import dataclass
from io import BytesIO
from math import sqrt
from typing import Protocol, Sequence

from PIL import Image

from app.exceptions.erreurs import MoteurBiometriqueIndisponible


@dataclass(frozen=True)
class AnalyseVisage:
    encodage: tuple[float, ...]


class MoteurReconnaissanceFaciale(Protocol):
    version: str

    def analyser(self, image_bytes: bytes) -> AnalyseVisage: ...


def distance_euclidienne(gauche: Sequence[float], droite: Sequence[float]) -> float:
    if len(gauche) != len(droite) or not gauche:
        raise ValueError("Les encodages faciaux ont des dimensions incompatibles")
    return sqrt(sum((float(a) - float(b)) ** 2 for a, b in zip(gauche, droite)))


def valider_image_dimensions(image_bytes: bytes, dimension_minimale: int) -> None:
    try:
        with Image.open(BytesIO(image_bytes)) as image:
            image.verify()
        with Image.open(BytesIO(image_bytes)) as image:
            if min(image.size) < dimension_minimale:
                raise ValueError("Les dimensions de l image sont insuffisantes")
    except Exception as exc:
        if isinstance(exc, ValueError):
            raise
        raise ValueError("L image est invalide ou indecodable") from exc


class MoteurFaceRecognition:
    version = "face_recognition-optionnel"

    def __init__(self) -> None:
        try:
            import face_recognition  # type: ignore
        except ImportError as exc:
            raise MoteurBiometriqueIndisponible(
                "face_recognition/dlib n est pas installe dans l environnement backend"
            ) from exc
        self._face_recognition = face_recognition

    def analyser(self, image_bytes: bytes) -> AnalyseVisage:
        image = self._face_recognition.load_image_file(BytesIO(image_bytes))
        locations = self._face_recognition.face_locations(image)
        if len(locations) != 1:
            raise ValueError("Chaque capture doit contenir exactement un visage")
        encodages = self._face_recognition.face_encodings(image, locations)
        if len(encodages) != 1:
            raise ValueError("L encodage facial est invalide")
        return AnalyseVisage(tuple(float(valeur) for valeur in encodages[0]))
