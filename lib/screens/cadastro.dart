// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:myapp/screens/home_cliente.dart';
import 'package:myapp/screens/home_profissional.dart';
import '../core/constants.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;

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
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();

  String? _fotoBase64; // Para armazenar a foto convertida em Base64

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _cpfController.dispose();
    _bioController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  bool isCliente = true;
  String? categoriaSelecionada;

  Future<List<String>> _buscarSugestoesGoogle(String textoDigitado) async {
    if (textoDigitado.isEmpty || textoDigitado.length < 3) return [];
    const String apiKey = "AIzaSyCPl210ZIzVG0LjWZWy_JEhvaluSW3MVJA";
    final String url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(textoDigitado)}&key=$apiKey&components=country:br&language=pt-BR";

    try {
      final response = await http.get(Uri.parse(url));
      print("DEBUG GOOGLE: ${response.body}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List predictions = data['predictions'] ?? [];
        return predictions.map((p) => p['description'].toString()).toList();
      }
    } catch (e) {
      print("Erro: $e");
    }
    return [];
  }

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
              'nome': _nomeController.text.trim(),
              'email': _emailController.text.trim(),
              'isCliente': isCliente,
              'cpf': _cpfController.text.trim(),
              'telefone': _telefoneController.text.trim(), // <-- NOVO
              'endereco': _enderecoController.text.trim(), // <-- NOVO
              'fotoPerfil': _fotoBase64,
              if (!isCliente) 'profissao': categoriaSelecionada,
              if (!isCliente) 'bio': _bioController.text.trim(),
              'createdAt':
                  FieldValue.serverTimestamp(), // Trocado para o horário oficial do servidor do Firebase
            });

        if (!context.mounted) return;
        print("Sucesso! Usuário salvo no banco de dados.");

        // 3. Redireciona
        _redirecionarUsuario();
      } catch (e) {
        if (!context.mounted) return;
        debugPrint("Erro no cadastro: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao cadastrar: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _escolherFoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 20,
    );

    if (image != null) {
      List<int> imageBytes = await image.readAsBytes();
      setState(() {
        _fotoBase64 = base64Encode(imageBytes);
      });
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
              const SizedBox(height: 24),
              // WIDGET DA FOTO DE PERFIL
              Center(
                child: GestureDetector(
                  onTap: _escolherFoto,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _fotoBase64 != null
                        ? MemoryImage(base64Decode(_fotoBase64!))
                        : null,
                    child: _fotoBase64 == null
                        ? const Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  "Adicionar Foto (Opcional)",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
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
        _buildTextField(
          "Nome Completo",
          controller: _nomeController,
          validator: (value) =>
              value == null || value.isEmpty ? "Nome é obrigatório" : null,
        ),
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

        // --- NOVOS CAMPOS NA TELA ---
        _buildTextField(
          "Telefone (WhatsApp)",
          controller: _telefoneController,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "O telefone é obrigatório";
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildAddressField(
          controller: _enderecoController,
          label: "Endereço Completo",
          validator: (value) =>
              value == null || value.isEmpty ? "Endereço é obrigatório" : null,
        ),
        const SizedBox(height: 16),

        // ----------------------------
        _buildTextField(
          "E-mail",
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
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
        if (!isCliente) const SizedBox(height: 16),
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
      initialValue: categoriaSelecionada,
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

  // 2. O SEU NOVO MOTOR EXCLUSIVO PARA ENDEREÇO (Com o Autocomplete do Google)
  Widget _buildAddressField({
    required TextEditingController controller,
    String label = "Endereço Completo",
    String? Function(String?)? validator,
  }) {
    return TypeAheadField<String>(
      controller: controller,
      builder: (context, typeAheadController, focusNode) {
        return TextFormField(
          controller: typeAheadController,
          focusNode: focusNode,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.location_on, color: Colors.red),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      suggestionsCallback: (search) async {
        return await _buscarSugestoesGoogle(search);
      },
      itemBuilder: (context, String sugestaoEndereco) {
        return ListTile(
          leading: const Icon(Icons.place, color: Colors.blueGrey),
          title: Text(sugestaoEndereco, style: const TextStyle(fontSize: 14)),
        );
      },
      onSelected: (String sugestaoSelecionada) {
        controller.text = sugestaoSelecionada;
      },
      loadingBuilder: (context) => const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      emptyBuilder: (context) => const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          "Nenhum endereço encontrado.",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
