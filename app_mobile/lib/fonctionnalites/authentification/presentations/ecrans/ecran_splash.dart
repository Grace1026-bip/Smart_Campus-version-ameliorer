import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../../systeme_conception/couleurs.dart';
// CET IMPORT EST CRUCIAL POUR QUE LA NAVIGATION SATCHE OÙ ALLER :
import 'ecran_connexion.dart'; 

class EcranSplash extends StatefulWidget {
  const EcranSplash({Key? key}) : super(key: key);

  @override
  State<EcranSplash> createState() => _EcranSplashState();
}

class _EcranSplashState extends State<EcranSplash> with SingleTickerProviderStateMixin {
  late AnimationController _controleurAnimation;
  late Animation<double> _animationOpacite;
  late Animation<double> _animationEchelle;

  @override
  void initState() {
    super.initState();

    _controleurAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _animationOpacite = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controleurAnimation, curve: Curves.easeIn),
    );

    _animationEchelle = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controleurAnimation, curve: Curves.easeOutBack),
    );

    _controleurAnimation.forward();

    // ICI : On attend 3 secondes puis on force le changement d'écran vers le Login
    Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const EcranConnexion()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controleurAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tailleEcran = MediaQuery.of(context).size;
    final estModeDesktop = tailleEcran.width > 800;

    return Scaffold(
      backgroundColor: CouleursSmartCampus.fondPrincipal,
      body: Center(
        child: AnimatedBuilder(
          animation: _controleurAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _animationOpacite.value,
              child: Transform.scale(scale: _animationEchelle.value, child: child),
            );
          },
          child: Container(
            width: estModeDesktop ? 450 : double.infinity,
            height: estModeDesktop ? 800 : double.infinity,
            padding: const EdgeInsets.all(40.0),
            decoration: estModeDesktop
                ? BoxDecoration(
                    color: CouleursSmartCampus.fondSurface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  )
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // LOGO PREMIUM
                Container(
                  height: 96,
                  width: 96,
                  decoration: BoxDecoration(
                    color: CouleursSmartCampus.principal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: CouleursSmartCampus.principal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      Positioned(
                        right: 18,
                        bottom: 18,
                        child: Container(
                          height: 20,
                          width: 20,
                          decoration: BoxDecoration(
                            color: CouleursSmartCampus.secondaire,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'SMART CAMPUS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: CouleursSmartCampus.textePrincipal,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: CouleursSmartCampus.secondaire.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'MODULE BIOMÉTRIQUE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: CouleursSmartCampus.secondaire,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Bulãli ID',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CouleursSmartCampus.texteSecondaire,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: const SizedBox(
                    width: 140,
                    height: 3,
                    child: LinearProgressIndicator(
                      backgroundColor: Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(CouleursSmartCampus.principal),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Écosystème Universitaire Sécurisé',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: CouleursSmartCampus.texteSecondaire,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}