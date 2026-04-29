import 'package:flutter/material.dart';
import 'package:myapp/screens/cliente.dart';
import '../core/constants.dart';
import 'package:flutter/services.dart';

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
        // ADICIONAMOS O FORM AQUI PARA ENVOLVER TODOS OS CAMPOS
        child: Form(
          key: _formKey, // Agora a chave está conectada ao formulário!
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
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // Botão largo
                ),
                onPressed: () {
                  // Agora o currentState não será mais nulo
                  if (_formKey.currentState?.validate() ?? false) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeCliente(),
                      ),
                      (route) => false,
                    );
                  } 
                },
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
          keyboardType:
              TextInputType.number, // Sugere teclado numérico no celular
          inputFormatters: [
            FilteringTextInputFormatter
                .digitsOnly, // BLOQUEIA letras e símbolos
            LengthLimitingTextInputFormatter(11), // Limita a 11 caracteres
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

        if (!isCliente) // Só aparece se for Profissional
          _buildTextField(
            "Breve Biografia",
            controller: _bioController,
            maxLines: 3, // Campo maior como no seu design
            validator: (value) {
              if (value == null || value.isEmpty) {
                return ("Conte um pouco sobre seu trabalho");
              }
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
    required TextEditingController controller,
    bool obscureText = false,
    int maxLines = 1,
    TextInputType? keyboardType, // Novo: define o tipo de teclado
    List<TextInputFormatter>? inputFormatters, // Novo: filtra o que entra
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType, // Aplica o tipo de teclado
      inputFormatters: inputFormatters, // Aplica o filtro de caracteres
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
