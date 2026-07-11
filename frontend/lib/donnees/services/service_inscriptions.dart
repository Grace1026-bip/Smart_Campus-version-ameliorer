import 'service_api.dart';

enum TypeDemandeInscription {
  etudiant,
  enseignant,
}

extension TypeDemandeInscriptionApi on TypeDemandeInscription {
  String get apiValue {
    switch (this) {
      case TypeDemandeInscription.etudiant:
        return 'etudiant';
      case TypeDemandeInscription.enseignant:
        return 'enseignant';
    }
  }

  String get label {
    switch (this) {
      case TypeDemandeInscription.etudiant:
        return 'Etudiant';
      case TypeDemandeInscription.enseignant:
        return 'Enseignant';
    }
  }
}

class DemandeInscriptionPayload {
  const DemandeInscriptionPayload({
    required this.type,
    required this.email,
    required this.motDePasse,
    required this.nom,
    this.postnom,
    this.prenom,
    this.telephone,
    this.matricule,
    this.promotionId,
    this.matriculeAgent,
    this.grade,
    this.departement,
  });

  final TypeDemandeInscription type;
  final String email;
  final String motDePasse;
  final String nom;
  final String? postnom;
  final String? prenom;
  final String? telephone;
  final String? matricule;
  final int? promotionId;
  final String? matriculeAgent;
  final String? grade;
  final String? departement;

  Map<String, dynamic> toJson() {
    return {
      'type_demande': type.apiValue,
      'email': email.trim().toLowerCase(),
      'mot_de_passe': motDePasse,
      'nom': nom.trim(),
      if (_present(postnom)) 'postnom': postnom!.trim(),
      if (_present(prenom)) 'prenom': prenom!.trim(),
      if (_present(telephone)) 'telephone': telephone!.trim(),
      if (_present(matricule)) 'matricule': matricule!.trim(),
      if (promotionId != null) 'promotion_id': promotionId,
      if (_present(matriculeAgent)) 'matricule_agent': matriculeAgent!.trim(),
      if (_present(grade)) 'grade': grade!.trim(),
      if (_present(departement)) 'departement': departement!.trim(),
    };
  }

  bool _present(String? value) => value != null && value.trim().isNotEmpty;
}

class DemandeInscription {
  const DemandeInscription({
    required this.reference,
    required this.typeDemande,
    required this.email,
    required this.statut,
    this.motifRejet,
  });

  final String reference;
  final String typeDemande;
  final String email;
  final String statut;
  final String? motifRejet;

  factory DemandeInscription.fromJson(Map<String, dynamic> json) {
    return DemandeInscription(
      reference: json['reference']?.toString() ?? '',
      typeDemande: json['type_demande']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      statut: json['statut']?.toString() ?? '',
      motifRejet: json['motif_rejet']?.toString(),
    );
  }
}

abstract class InscriptionService {
  Future<DemandeInscription> creerDemande(DemandeInscriptionPayload payload);

  Future<DemandeInscription> consulterStatut({
    required String reference,
    required String email,
  });
}

class ApiInscriptionService implements InscriptionService {
  const ApiInscriptionService();

  @override
  Future<DemandeInscription> creerDemande(
    DemandeInscriptionPayload payload,
  ) async {
    final data = await ApiDataSource.client.post(
      '/inscriptions/demandes',
      body: payload.toJson(),
    );
    return DemandeInscription.fromJson(data);
  }

  @override
  Future<DemandeInscription> consulterStatut({
    required String reference,
    required String email,
  }) async {
    final data = await ApiDataSource.client.get(
      '/inscriptions/demandes/statut',
      query: {
        'reference': reference.trim(),
        'email': email.trim().toLowerCase(),
      },
    );
    return DemandeInscription.fromJson(data);
  }
}

class InscriptionDataSource {
  static InscriptionService service = const ApiInscriptionService();
}
