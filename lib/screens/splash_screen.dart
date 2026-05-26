import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_cliente.dart';
import 'home_profissional.dart';
import 'login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    // ⏱️ Aguarda 3 segundos segurando a logo na tela
    await Future.delayed(const Duration(seconds: 3));

    // Verifica se existe um usuário autenticado no Firebase Auth
    final currentUser = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (currentUser == null) {
      // 🚫 Caso não esteja logado, vai para a sua tela de Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ), // Substitua pelo nome da sua tela de login
      );
    } else {
      try {
        // 🔍 Se estiver logado, busca no Firestore para saber o tipo de usuário
        var docUsuario = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(currentUser.uid)
            .get();

        if (!mounted) return;

        if (docUsuario.exists) {
          // Lê a flag que diferencia cliente de profissional
          bool isCliente = docUsuario.data()?['isCliente'] ?? true;

          if (isCliente) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeCliente()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              // Substitua pelo nome real da sua classe de Home do Profissional
              MaterialPageRoute(builder: (context) => const HomeProfissional()),
            );
          }
        } else {
          // Se o doc não existir por algum motivo, manda para o Login por segurança
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } catch (e) {
        // Se der erro na busca do banco, força o Login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // 🎨 Fundo Elegante: Um gradiente sutil usando tons escuros ou o azul do seu app
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade900, Colors.blueGrey.shade900],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 📦 Ícone/Logo do Aplicativo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons
                      .work_rounded, // Troque pela sua imagem se tiver: Image.asset('assets/logo.png')
                  size: 80,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 24),
              // 🏷️ Texto da Logo
              const Text(
                "PJobs",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),
              // 🔄 Indicador de carregamento discreto
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  color: Colors.white70,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
