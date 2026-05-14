import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'screens/login.dart';
import 'firebase_options.dart';
import 'screens/home_cliente.dart';
import 'screens/home_profissional.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PJobsApp());
}

class PJobsApp extends StatelessWidget {
  const PJobsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PJobs Express',
      debugShowCheckedModeBanner: false,
      // Aplica o tema personalizado que você criou
      theme: AppTheme.lightTheme,

      // A Home aponta para a tela de Login por enquanto
      home: const LoginScreen(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Se não estiver logado, vai para a tela de Login
        if (!snapshot.hasData) return const LoginScreen();

        // 2. Se estiver logado, precisamos saber o tipo de usuário
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (snapshot.hasError) {
              print("ERRO DO FIRESTORE: ${snapshot.error}");
              return Center(child: Text("Erro: ${snapshot.error}"));
            }
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final dados = userSnapshot.data!.data() as Map<String, dynamic>;
              return dados['isCliente'] == true
                  ? const HomeCliente()
                  : const HomeProfissional();
            }

            return const LoginScreen();
          },
        );
      },
    );
  }
}
