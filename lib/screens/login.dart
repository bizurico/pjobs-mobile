import 'package:flutter/material.dart';
import 'package:myapp/screens/cadastro.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isCliente = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF1976D2),
                child: Icon(Icons.work, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                "PJobs Express",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
              const Text("Conecte-se com profissionais próximos"),
              const SizedBox(height: 40),
              _buildLoginCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Profissional",
                  style: TextStyle(
                    color: !isCliente ? Colors.blue : Colors.grey,
                  ),
                ),
                Switch(
                  value: isCliente,
                  onChanged: (val) => setState(() => isCliente = val),
                ),
                Text(
                  "Cliente",
                  style: TextStyle(
                    color: isCliente ? Colors.blue : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField("E-mail"),
            const SizedBox(height: 16),
            _buildTextField("Senha", obscureText: true),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {}, // Aqui faremos a navegação depois
              child: Text(
                "Entrar como ${isCliente ? 'Cliente' : 'Profissional'}",
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CadastroScreen(),
                  ),
                );
              },
              child: const Text("Criar nova conta"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, {bool obscureText = false}) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
