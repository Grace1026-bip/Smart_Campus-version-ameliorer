from __future__ import annotations

from datetime import datetime
from io import BytesIO
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


def _texte(valeur: object | None) -> str:
    return escape("-" if valeur is None or str(valeur).strip() == "" else str(valeur))


def _date(valeur: object | None) -> str:
    if valeur is None:
        return "-"
    if hasattr(valeur, "strftime"):
        return valeur.strftime("%d/%m/%Y")
    return str(valeur)


def generer_fiche_enrolement_pdf(donnees: dict) -> bytes:
    buffer = BytesIO()
    document = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        rightMargin=16 * mm,
        leftMargin=16 * mm,
        topMargin=18 * mm,
        bottomMargin=18 * mm,
        title="Fiche d'enrolement academique",
        author="Smart Faculty",
    )
    styles = getSampleStyleSheet()
    titre = ParagraphStyle(
        "TitreFiche",
        parent=styles["Title"],
        alignment=TA_CENTER,
        fontName="Helvetica-Bold",
        fontSize=16,
        leading=20,
        textColor=colors.HexColor("#5D4037"),
        spaceAfter=4 * mm,
    )
    sous_titre = ParagraphStyle(
        "SousTitreFiche",
        parent=styles["Normal"],
        alignment=TA_CENTER,
        fontName="Helvetica",
        fontSize=10,
        leading=13,
        textColor=colors.HexColor("#6D625D"),
        spaceAfter=6 * mm,
    )
    texte = ParagraphStyle(
        "TexteFiche",
        parent=styles["Normal"],
        alignment=TA_LEFT,
        fontName="Helvetica",
        fontSize=9,
        leading=12,
    )
    petit = ParagraphStyle(
        "PetitFiche",
        parent=texte,
        fontSize=8,
        leading=10,
    )

    story = [
        Paragraph("SMART FACULTY", titre),
        Paragraph("FICHE D'ENROLEMENT ACADEMIQUE", sous_titre),
    ]

    promotion = donnees.get("promotion") or {}
    annee = donnees.get("annee_academique") or {}
    etudiant = donnees.get("etudiant") or {}
    informations = [
        [Paragraph("Reference", texte), Paragraph(_texte(donnees.get("reference_fiche")), texte)],
        [Paragraph("Etudiant", texte), Paragraph(_texte(etudiant.get("nom")), texte)],
        [Paragraph("Matricule", texte), Paragraph(_texte(etudiant.get("matricule")), texte)],
        [Paragraph("Promotion", texte), Paragraph(_texte(promotion.get("nom")), texte)],
        [Paragraph("Annee academique", texte), Paragraph(_texte(annee.get("libelle")), texte)],
        [Paragraph("Date d'enrolement", texte), Paragraph(_date(donnees.get("date_enrolement")), texte)],
        [Paragraph("Date de validation", texte), Paragraph(_date(donnees.get("date_validation")), texte)],
        [Paragraph("Statut", texte), Paragraph("Valide", texte)],
    ]
    identite = Table(informations, colWidths=[48 * mm, 126 * mm], hAlign="LEFT")
    identite.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#FAF4EA")),
                ("BOX", (0, 0), (-1, -1), 0.5, colors.HexColor("#D8C8B8")),
                ("INNERGRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#D8C8B8")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    story.extend([identite, Spacer(1, 7 * mm)])

    cours = donnees.get("programme") or []
    lignes = [
        [
            Paragraph("Code", petit),
            Paragraph("Intitule", petit),
            Paragraph("Semestre", petit),
            Paragraph("Credits", petit),
        ]
    ]
    for cours_item in cours:
        semestre = cours_item.get("semestre") or {}
        lignes.append(
            [
                Paragraph(_texte(cours_item.get("code")), petit),
                Paragraph(_texte(cours_item.get("intitule")), petit),
                Paragraph(_texte(semestre.get("nom") or semestre.get("numero")), petit),
                Paragraph(_texte(cours_item.get("credits")), petit),
            ]
        )

    tableau = Table(lignes, colWidths=[25 * mm, 91 * mm, 38 * mm, 20 * mm], repeatRows=1)
    tableau.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#5D4037")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("BOX", (0, 0), (-1, -1), 0.5, colors.HexColor("#D8C8B8")),
                ("INNERGRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#D8C8B8")),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#FAF4EA")]),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("ALIGN", (3, 1), (3, -1), "CENTER"),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    story.extend(
        [
            Paragraph("Programme academique", styles["Heading2"]),
            tableau,
            Spacer(1, 5 * mm),
            Paragraph(
                f"Nombre total de cours : {len(cours)} &nbsp;&nbsp;|&nbsp;&nbsp; "
                f"Total des credits : {_texte(donnees.get('credits_prevus', 0))}",
                texte,
            ),
            Spacer(1, 10 * mm),
            Paragraph(
                "Espace administratif : ________________________________________________",
                texte,
            ),
            Spacer(1, 6 * mm),
            Paragraph(
                f"Document genere le {_date(datetime.now())}. Cette fiche est produite "
                "a partir des donnees academiques enregistrees par Smart Faculty.",
                petit,
            ),
        ]
    )

    def pied_de_page(canvas, _document):
        canvas.saveState()
        canvas.setFont("Helvetica", 8)
        canvas.setFillColor(colors.HexColor("#6D625D"))
        canvas.drawString(16 * mm, 10 * mm, "Smart Faculty - Fiche d'enrolement academique")
        canvas.drawRightString(194 * mm, 10 * mm, f"Page {canvas.getPageNumber()}")
        canvas.restoreState()

    document.build(story, onFirstPage=pied_de_page, onLaterPages=pied_de_page)
    return buffer.getvalue()
