// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cadastro.dart';
import 'home_cliente.dart';
import 'home_profissional.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;

  Future<void> _logar() async {
    setState(() => _carregando = true);

    try {
      // 1. Autentica no Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _senhaController.text.trim(),
          );

      // 2. Busca o perfil no Firestore para saber o tipo de usuário
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> dados = userDoc.data() as Map<String, dynamic>;
        bool isCliente = dados['isCliente'] ?? true;

        // 3. Redireciona para a Home correta
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  isCliente ? const HomeCliente() : const HomeProfissional(),
            ),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String mensagem = "Erro ao entrar";
      if (e.code == 'user-not-found') {
        mensagem = "Usuário não encontrado";
      } else if (e.code == 'wrong-password') {
        mensagem = "Senha incorreta";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _recuperarSenha() async {
    // Pega o e-mail digitado no controller do seu input de e-mail
    String email = _emailController.text
        .trim(); // 👈 Verifique se o seu controller tem esse nome

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Por favor, digite seu e-mail no campo acima para redefinir a senha.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // 🔥 Comando Mágico do Firebase Auth
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "E-mail de recuperação enviado! Verifique sua caixa de entrada e o spam.",
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao enviar e-mail de recuperação: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "PJobs Express",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "E-mail",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _senhaController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Senha",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8), // Pequeno respiro
            // 🔥 LINK DE ESQUECI A SENHA
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _recuperarSenha, // Aciona a função que criamos acima
                child: Text(
                  "Esqueci a senha",
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _carregando
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _logar,
                    child: const Text("Entrar"),
                  ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CadastroScreen()),
              ),
              child: const Text("Não tem conta? Cadastre-se"),
            ),
          ],
        ),
      ),
    );
  }
}
