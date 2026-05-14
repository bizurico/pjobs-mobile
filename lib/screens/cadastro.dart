// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:myapp/screens/home_cliente.dart';
import 'package:myapp/screens/home_profissional.dart';
import '../core/constants.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  // Chave para validar o formulário
  final _formKey = GlobalKey<FormState>();

  // Controllers para capturar os dados
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _cpfController = TextEditingController();
  final _bioController = TextEditingController();

  bool isCliente = true;
  String? categoriaSelecionada;

  // Lógica para salvar no Firebase
  Future<void> _cadastrarUsuario() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // 1. Cria o usuário no Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _senhaController.text.trim(),
            );

        // 2. Salva os dados extras no Firestore
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .set({
              'nome': _nomeController.text,
              'email': _emailController.text,
              'isCliente': isCliente,
              'cpf': _cpfController.text,
              if (!isCliente) 'profissao': categoriaSelecionada,
              if (!isCliente) 'bio': _bioController.text,
              'createdAt': DateTime.now(),
            });

        print("Sucesso! Usuário salvo no banco de dados.");

        // 3. Redireciona
        _redirecionarUsuario();
      } catch (e) {
        print("Erro no cadastro: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao cadastrar: ${e.toString()}")),
        );
      }
    }
  }

  // Método de navegação centralizado
  void _redirecionarUsuario() {
    if (isCliente) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeCliente()),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeProfissional()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Criar Nova Conta")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTipoUsuarioToggle(),
              const SizedBox(height: 24),
              _buildCamposComuns(),
              if (!isCliente) ...[
                const SizedBox(height: 16),
                _buildDropdownProfissoes(),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _cadastrarUsuario,
                child: const Text("Finalizar Cadastro"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipoUsuarioToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Profissional",
          style: TextStyle(
            fontWeight: !isCliente ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Switch(
          value: isCliente,
          onChanged: (val) => setState(() => isCliente = val),
        ),
        Text(
          "Cliente",
          style: TextStyle(
            fontWeight: isCliente ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildCamposComuns() {
    return Column(
      children: [
        _buildTextField("Nome Completo", controller: _nomeController),
        const SizedBox(height: 16),
        _buildTextField(
          "CPF",
          controller: _cpfController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) return "CPF é obrigatório";
            if (value.length < 11) return "O CPF deve ter 11 dígitos";
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          "E-mail",
          controller: _emailController,
          validator: (value) {
            if (value == null || value.isEmpty) return "O e-mail é obrigatório";
            if (!value.contains("@")) return "Digite um e-mail válido";
            return null;
          },
        ),
        const SizedBox(height: 16),
        if (!isCliente)
          _buildTextField(
            "Breve Biografia",
            controller: _bioController,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Conte um pouco sobre seu trabalho";
              }
              return null;
            },
          ),
        const SizedBox(height: 16),
        _buildTextField(
          "Senha",
          controller: _senhaController,
          obscureText: true,
          validator: (value) {
            if (value == null || value.length < 6) {
              return "Mínimo de 6 caracteres";
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdownProfissoes() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: "Sua Especialidade",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: categoriaSelecionada,
      items: AppConstants.categorias.map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: (val) => setState(() => categoriaSelecionada = val),
      validator: (value) =>
          value == null ? "Selecione uma especialidade" : null,
    );
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController controller,
    bool obscureText = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _cpfController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
