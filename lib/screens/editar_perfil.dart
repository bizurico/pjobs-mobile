// ignore_for_file: use_build_context_synchronously

import 'login.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;

class EditarPerfilScreen extends StatefulWidget {
  final bool isProfissional;
  const EditarPerfilScreen({super.key, required this.isProfissional});

  @override
  State<EditarPerfilScreen> createState() => EditarPerfilScreenState();
}

class EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final formKey = GlobalKey<FormState>();

  // Controladores dos campos cadastrais
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController enderecoController = TextEditingController();

  // Controladores exclusivos para a troca de senha
  final TextEditingController senhaAntigaController = TextEditingController();
  final TextEditingController senhaNovaController = TextEditingController();
  final TextEditingController confirmarSenhaController =
      TextEditingController();

  final User? _user = FirebaseAuth.instance.currentUser;
  bool _carregando = false;
  bool _queroAlterarSenha = false;

  // 📸 VARIÁVEL DA FOTO PADRONIZADA COM UNDERSCORE
  Uint8List? _imageBytes;
  bool _fotoFoiAlterada = false;

  String? _categoriaSelecionada;
  late List<String> _categorias;

  @override
  void initState() {
    super.initState();
    _categorias = List<String>.from(AppConstants.categorias);
    _carregarDadosAtuais();
  }

  Future<List<String>> buscarSugestoesGoogle(String textoDigitado) async {
    if (textoDigitado.isEmpty || textoDigitado.length < 3) {
      return [];
    }
    const String apiKey = "AIzaSyCP1210ZIzVG0LjWZWy_JEhvaluSW3MVJA";
    final String url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        "?input=${Uri.encodeComponent(textoDigitado)}"
        "&key=$apiKey"
        "&components=country:br"
        "&language=pt-BR";
    try {
      final response = await http.get(Uri.parse(url));
      debugPrint("DEBUG GOOGLE: ${response.body}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List predictions = data['predictions'] ?? [];
        return predictions.map((p) => p['description'].toString()).toList();
      }
    } catch (e) {
      debugPrint("Erro no Google Places do Perfil: $e");
    }
    return [];
  }

  Future<void> _carregarDadosAtuais() async {
    if (_user == null) return;
    setState(() => _carregando = true);
    emailController.text = _user.email ?? '';
    try {
      var doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        var dados = doc.data()!;
        setState(() {
          _nomeController.text = dados['nome'] ?? '';
          telefoneController.text = dados['telefone'] ?? '';
          enderecoController.text = dados['endereco'] ?? '';

          String? fotoBanco = dados['fotoPerfil'];
          if (fotoBanco != null && fotoBanco.isNotEmpty) {
            _imageBytes = base64Decode(fotoBanco);
          }

          if (widget.isProfissional) {
            String? profissaoDoBanco = dados['profissao'];
            if (profissaoDoBanco != null && profissaoDoBanco.isNotEmpty) {
              if (!_categorias.contains(profissaoDoBanco)) {
                _categorias.add(profissaoDoBanco);
              }
              _categoriaSelecionada = profissaoDoBanco;
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar dados: $e");
    } finally {
      setState(() => _carregando = false);
    }
  }

  // 📷 FUNÇÃO DE CAPTURA TOTALMENTE PADRONIZADA
  Future<void> _escolherFoto(ImageSource fonte) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: fonte,
      imageQuality: 20,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _fotoFoiAlterada = true;
      });
    }
  }

  // 🗺️ MENU INFERIOR DE ESCOLHA (CÂMERA OU GALERIA) BEM WIREDO!
  void _mostrarOpcoesFoto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text(
                'Tirar Foto (Câmera)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _escolherFoto(ImageSource.camera); // Dispara a câmera
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.teal),
              title: const Text(
                'Escolher da Galeria',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _escolherFoto(ImageSource.gallery); // Dispara a galeria
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> salvarAlteracoes() async {
    if (!formKey.currentState!.validate()) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      String uid = _user!.uid;
      Map<String, dynamic> dadosAtualizados = {
        'nome': _nomeController.text.trim(),
        'telefone': telefoneController.text.trim(),
        'endereco': enderecoController.text.trim(),
      };
      if (widget.isProfissional) {
        dadosAtualizados['profissao'] = _categoriaSelecionada;
      }
      if (_fotoFoiAlterada && _imageBytes != null) {
        dadosAtualizados['fotoPerfil'] = base64Encode(_imageBytes!);
      }
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .update(dadosAtualizados);

      if (context.mounted) Navigator.pop(context); // Fecha loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Perfil atualizado!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Fecha loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao salvar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        backgroundColor: Colors.blue,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _mostrarOpcoesFoto(context),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: _imageBytes != null
                                ? MemoryImage(_imageBytes!)
                                : null,
                            child: _imageBytes == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          const Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.blue,
                              radius: 18,
                              child: Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: "Nome Completo",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Preencha este campo" : null,
                    ),
                    const SizedBox(height: 15),
                    if (widget.isProfissional) ...[
                      DropdownButtonFormField<String>(
                        initialValue: _categoriaSelecionada,
                        decoration: const InputDecoration(
                          labelText: "Categoria de Serviço",
                          border: OutlineInputBorder(),
                        ),
                        items: _categorias.map((String cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _categoriaSelecionada = newValue;
                          });
                        },
                        validator: (value) =>
                            value == null ? "Selecione uma categoria" : null,
                      ),
                      const SizedBox(height: 15),
                    ],
                    TextFormField(
                      controller: emailController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "E-mail",
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.black12,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: telefoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Telefone / WhatsApp",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Preencha este campo" : null,
                    ),
                    const SizedBox(height: 15),
                    TypeAheadField<String>(
                      controller: enderecoController,
                      builder: (context, typeAheadController, focusNode) {
                        return TextFormField(
                          controller: typeAheadController,
                          focusNode: focusNode,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: "Endereço Completo",
                            prefixIcon: Icon(
                              Icons.location_on,
                              color: Colors.red,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => (value == null || value.isEmpty)
                              ? "Preencha este campo"
                              : null,
                        );
                      },
                      suggestionsCallback: (search) async {
                        return await buscarSugestoesGoogle(search);
                      },
                      itemBuilder: (context, String sugestaoEndereco) {
                        return ListTile(
                          leading: const Icon(
                            Icons.place,
                            color: Colors.blueGrey,
                          ),
                          title: Text(
                            sugestaoEndereco,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      },
                      onSelected: (String sugestaoSelecionada) {
                        setState(() {
                          enderecoController.text = sugestaoSelecionada;
                        });
                      },
                      loadingBuilder: (context) => const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      emptyBuilder: (context) => const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "Nenhum endereço encontrado.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.lock_reset,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      "Deseja alterar sua senha?",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: _queroAlterarSenha,
                                  onChanged: (value) {
                                    setState(() {
                                      _queroAlterarSenha = value;
                                      if (!value) {
                                        senhaAntigaController.clear();
                                        senhaNovaController.clear();
                                        confirmarSenhaController.clear();
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (_queroAlterarSenha) ...[
                              const Divider(height: 20),
                              TextFormField(
                                controller: senhaAntigaController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: "Senha Atual",
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    _queroAlterarSenha && value!.isEmpty
                                    ? "Informe a senha atual"
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: senhaNovaController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: "Nova Senha",
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    _queroAlterarSenha && value!.length < 6
                                    ? "Senha muito curta"
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: confirmarSenhaController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: "Confirme a Nova Senha",
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    _queroAlterarSenha && value!.isEmpty
                                    ? "Confirme a nova senha"
                                    : null,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: salvarAlteracoes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        "Salvar Alterações",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.exit_to_app, color: Colors.white),
                      label: const Text(
                        "Sair da Conta",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
