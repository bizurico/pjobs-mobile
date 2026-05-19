import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart'; // Importe o arquivo de constantes para acessar as categorias

class EditarPerfilScreen extends StatefulWidget {
  final bool isProfissional;

  const EditarPerfilScreen({super.key, required this.isProfissional});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores dos campos cadastrais
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();

  // Controladores exclusivos para a troca segura de senha
  final TextEditingController _senhaAntigaController = TextEditingController();
  final TextEditingController _senhaNovaController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();

  final User? _user = FirebaseAuth.instance.currentUser;
  bool _carregando = false;
  bool _queroAlterarSenha = false; // Controla a exibição dos campos de senha

  String? _currentPhotoUrl;
  Uint8List? _imageBytes;

  // Configuração de categorias para profissionais
  String? _categoriaSelecionada;

  late List<String> _categorias;
  @override
  void initState() {
    super.initState();
    _categorias = List<String>.from(
      AppConstants.categorias,
    ); // Carrega as categorias do arquivo de constantes
    _carregarDadosAtuais();
  }

  Future<void> _carregarDadosAtuais() async {
    if (_user == null) return;
    setState(() => _carregando = true);

    _emailController.text = _user.email ?? '';

    try {
      var doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        var dados = doc.data()!;
        setState(() {
          _nomeController.text = dados['nome'] ?? '';
          _telefoneController.text = dados['telefone'] ?? '';
          _enderecoController.text = dados['endereco'] ?? '';
          _currentPhotoUrl = dados['fotoPerfil'];

          if (widget.isProfissional) {
            String? profissaoDoBanco = dados['profissao'];

            // SEGURANÇA: Se a profissão do banco existir e não estiver na nossa lista,
            // nós adicionamos ela na lista na hora para o Dropdown não quebrar!
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

  Future<void> _escolherImagem(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (image != null) {
      var bytes = await image.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<String?> _uploadFoto() async {
    if (_imageBytes == null) return _currentPhotoUrl;
    try {
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('perfis')
          .child('${_user!.uid}.jpg');
      UploadTask uploadTask = ref.putData(_imageBytes!);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Erro no upload da imagem: $e");
      return null;
    }
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate() || _user == null) return;

    setState(() => _carregando = true);
    String colecao = widget.isProfissional ? 'profissionais' : 'usuarios';

    try {
      // 1. Se o usuário optou por alterar a senha, valida e reautentica primeiro
      if (_queroAlterarSenha) {
        if (_senhaNovaController.text.trim() !=
            _confirmarSenhaController.text.trim()) {
          throw Exception("A nova senha e a confirmação não coincidem.");
        }

        // Cria a credencial com a senha antiga informada para validar a identidade
        AuthCredential credential = EmailAuthProvider.credential(
          email: _user.email!,
          password: _senhaAntigaController.text.trim(),
        );

        // Reautentica no Firebase (essencial para operações sensíveis)
        await _user.reauthenticateWithCredential(credential);

        // Atualiza para a nova senha
        await _user.updatePassword(_senhaNovaController.text.trim());
      }

      // 2. Upload da foto de perfil
      String? fotoUrl = await _uploadFoto();

      // 3. Monta o mapa de dados para atualizar no Firestore
      Map<String, dynamic> dadosAtualizados = {
        'nome': _nomeController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'endereco': _enderecoController.text.trim(),
      };

      if (fotoUrl != null) {
        dadosAtualizados['fotoPerfil'] = fotoUrl;
      }

      // Adiciona a categoria apenas se for conta de profissional
      if (widget.isProfissional) {
        dadosAtualizados['profissao'] =
            _categoriaSelecionada; // Usando a SUA chave
      }

      await FirebaseFirestore.instance
          .collection(colecao)
          .doc(_user.uid)
          .set(dadosAtualizados, SetOptions(merge: true));

      // 4. Atualiza o e-mail se necessário
      if (_emailController.text.trim() != _user.email) {
        await _user.verifyBeforeUpdateEmail(_emailController.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Perfil atualizado com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erro ao atualizar: ${e.toString().replaceAll("Exception:", "")}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _carregando = false);
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
                key: _formKey,
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
                                : (_currentPhotoUrl != null
                                          ? NetworkImage(_currentPhotoUrl!)
                                          : null)
                                      as ImageProvider?,
                            child:
                                _imageBytes == null && _currentPhotoUrl == null
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

                    // Exibe a seleção de categoria apenas para Profissionais
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
                          setState(() => _categoriaSelecionada = newValue);
                        },
                        validator: (value) =>
                            value == null ? "Selecione uma categoria" : null,
                      ),
                      const SizedBox(height: 15),
                    ],

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "E-mail",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Preencha este campo" : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _telefoneController,
                      decoration: const InputDecoration(
                        labelText: "Telefone / WhatsApp",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Preencha este campo" : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _enderecoController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: "Endereço Completo",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Preencha este campo" : null,
                    ),
                    const SizedBox(height: 20),

                    // Área de segurança para alteração de senha
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
                                const Row(
                                  children: [
                                    Icon(Icons.lock_reset, color: Colors.blue),
                                    SizedBox(width: 10),
                                    Text(
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
                                        _senhaAntigaController.clear();
                                        _senhaNovaController.clear();
                                        _confirmarSenhaController.clear();
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (_queroAlterarSenha) ...[
                              const Divider(height: 20),
                              TextFormField(
                                controller: _senhaAntigaController,
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
                                controller: _senhaNovaController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: "Nova Senha (mínimo 6 caracteres)",
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    _queroAlterarSenha && value!.length < 6
                                    ? "Senha muito curta"
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmarSenhaController,
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
                      onPressed: _salvarPerfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        "Salvar Alterações",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _mostrarOpcoesFoto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tirar Foto (Câmera)'),
              onTap: () {
                Navigator.pop(context);
                _escolherImagem(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da Galeria'),
              onTap: () {
                Navigator.pop(context);
                _escolherImagem(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
