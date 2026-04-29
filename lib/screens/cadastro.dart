import 'package:flutter/material.dart';
import '../core/constants.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  bool isCliente = true;
  String? categoriaSelecionada;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Criar Nova Conta")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildTipoUsuarioToggle(),
            const SizedBox(height: 24),
            _buildCamposComuns(),

            // Campos que aparecem apenas para Profissionais
            if (!isCliente) ...[
              const SizedBox(height: 16),
              _buildDropdownProfissoes(),
              const SizedBox(height: 16),
              _buildTextField(
                "Breve Biografia",
                controller: _bioController,
                maxLines: 3,
              ),
            ],

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // A mágica acontece aqui:
                if (_formKey.currentState!.validate()) {
                  // Se for válido, aqui você enviará para o Firebase futuramente
                  print("Dados prontos para o banco: ${_emailController.text}");

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Processando cadastro...")),
                  );
                }
              },
              child: const Text("Finalizar Cadastro"),
            ),
          ],
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

        if (!isCliente) // Só aparece se for Profissional
          _buildTextField(
            "Breve Biografia",
            controller: _bioController,
            maxLines: 3, // Campo maior como no seu design
            validator: (value) {
              if (value == null || value.isEmpty)
                return ("Conte um pouco sobre seu trabalho");
              return null;
            },
          ),
        const SizedBox(height: 16),

        _buildTextField(
          "Senha",
          controller: _senhaController,
          obscureText: true,
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
      items: AppConstants.categorias.map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: (val) => setState(() => categoriaSelecionada = val),
    );
  }

  Widget _buildTextField(
    String label, {
    required TextEditingController
    controller, // Obrigatório para capturar o texto
    bool obscureText = false, // Para senhas
    int maxLines = 1, // Para a Bio, que é maior
    String? Function(String?)? validator, // A lógica de erro
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator, // O Flutter chama essa função automaticamente
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF1976D2),
        ), // Azul do seu design
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
      ),
    );
  }

  // Chave para validar o formulário
  final _formKey = GlobalKey<FormState>();

  // Controllers para capturar os dados
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _cpfController = TextEditingController();
  final _bioController = TextEditingController();

  // É boa prática limpar os controllers quando a tela fechar
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
