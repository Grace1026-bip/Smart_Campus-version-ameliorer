from fastapi import status


class ErreurApplication(Exception):
    def __init__(
        self,
        message: str,
        code_http: int = status.HTTP_400_BAD_REQUEST,
        erreurs: list | None = None,
    ) -> None:
        self.message = message
        self.code_http = code_http
        self.erreurs = erreurs or []
        super().__init__(message)


class AuthentificationRequise(ErreurApplication):
    def __init__(self, message: str = "Authentification requise") -> None:
        super().__init__(message=message, code_http=status.HTTP_401_UNAUTHORIZED)


class AccesInterdit(ErreurApplication):
    def __init__(self, message: str = "Acces interdit") -> None:
        super().__init__(message=message, code_http=status.HTTP_403_FORBIDDEN)


class RessourceIntrouvable(ErreurApplication):
    def __init__(self, message: str = "Ressource introuvable") -> None:
        super().__init__(message=message, code_http=status.HTTP_404_NOT_FOUND)


class ConflitDonnees(ErreurApplication):
    def __init__(self, message: str = "Conflit de donnees") -> None:
        super().__init__(message=message, code_http=status.HTTP_409_CONFLICT)


class MoteurBiometriqueIndisponible(ErreurApplication):
    def __init__(self, message: str = "Le moteur de reconnaissance faciale est indisponible dans cet environnement") -> None:
        super().__init__(message=message, code_http=status.HTTP_503_SERVICE_UNAVAILABLE)
