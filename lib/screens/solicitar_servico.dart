import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert'; // <--- Adicione este import para usar o base64Encode

class SolicitarServicoModal extends StatefulWidget {
  final Map<String, dynamic> profissional;

  const SolicitarServicoModal({super.key, required this.profissional});

  @override
  State<SolicitarServicoModal> createState() => _SolicitarServicoModalState();
}

class _SolicitarServicoModalState extends State<SolicitarServicoModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descricaoController = TextEditingController();

  bool _enviando = false;
  final List<Uint8List> _fotosBytes =
      []; // Lista para guardar as fotos compatível com Web/Mobile

  // Função para abrir a galeria e escolher múltiplas fotos
  Future<void> _adicionarFotos() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 70);

    if (images.isNotEmpty) {
      for (var img in images) {
        var bytes = await img.readAsBytes();
        setState(() {
          _fotosBytes.add(bytes);
        });
      }
    }
  }

  // Faz o upload de todas as fotos para o Storage e retorna a lista de URLs
  List<String> _converterFotosParaBase64() {
    List<String> fotosBase64 = [];
    for (var bytes in _fotosBytes) {
      // Transforma os bytes brutos da imagem em uma String de texto
      String textoBase64 = base64Encode(bytes);
      fotosBase64.add(textoBase64);
    }
    return fotosBase64;
  }

  Future<void> _enviarSolicitacao() async {
    debugPrint("🚀 [BOTÃO] Clique detectado no botão de enviar!");

    if (!_formKey.currentState!.validate()) {
      debugPrint(
        "⚠️ [VALIDAÇÃO] O formulário barrou o envio. Verifique se a descrição está preenchida.",
      );
      return;
    }

    setState(() => _enviando = true);
    debugPrint("⏳ [STATUS] Mudou _enviando para TRUE");

    try {
      debugPrint("📸 [FOTOS] Convertendo lista de fotos locais para Base64...");
      List<String> fotosUrls = _converterFotosParaBase64();
      debugPrint(
        "✅ [FOTOS] Conversão concluída. Total de fotos: ${fotosUrls.length}",
      );

      // Verifica se o usuário do Firebase Auth está ativo
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("Usuário não está autenticado no Firebase.");
      }
      String meuUid = currentUser.uid;
      debugPrint("👤 [AUTH] UID do cliente obtido: $meuUid");

      debugPrint(
        "🔍 [FIRESTORE] Buscando o nome do cliente logado na coleção 'usuarios'...",
      );
      var docCliente = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(meuUid)
          .get();

      if (!docCliente.exists) {
        debugPrint(
          "⚠️ [AVISO] Documento do cliente não foi encontrado no Firestore!",
        );
      }

      String meuNome = docCliente.data()?['nome'] ?? 'Cliente';
      debugPrint("👤 [CLIENTE] Nome definido para o pedido: $meuNome");

      debugPrint(
        "📋 [DADOS MAP] Verificando dados do profissional que vieram da outra tela: ${widget.profissional}",
      );

      debugPrint(
        "📦 [FIRESTORE] Tentando gravar o documento na coleção 'pedidos'...",
      );
      await FirebaseFirestore.instance.collection('pedidos').add({
        'clienteId': meuUid,
        'clienteNome': meuNome,
        'profissionalId': widget.profissional['uid'] ?? '',
        'profissionalNome': widget.profissional['nome'] ?? 'Profissional',
        'profissao':
            widget.profissional['profissao'] ??
            'Geral', // Usando a sua chave 'profissao'
        'descricaoProblema': _descricaoController.text.trim(),
        'fotos': fotosUrls,
        'status': 'aguardando_orcamento',
        'valorProposto': 0.0,
        'dataSolicitacao': FieldValue.serverTimestamp(),
      });

      debugPrint(
        "🎉 [SUCESSO] Pedido salvo no Firestore com sucesso absoluto!",
      );

      if (mounted) {
        Navigator.pop(context); // Fecha o modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Solicitação enviada com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint("❌ [ERRO CRÍTICO] Falha ao executar o envio: $e");
      debugPrint("📑 [STACK TRACE] Detalhes do erro: $stackTrace");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao enviar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
        debugPrint("🔄 [STATUS] Mudou _enviando de volta para FALSE");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(
          context,
        ).viewInsets.bottom, // Evita que o teclado cubra o modal
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Solicitar serviço para ${widget.profissional['nome']}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // CAMPO OBRIGATÓRIO
              TextFormField(
                controller: _descricaoController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Descreva o que você precisa (Obrigatório)",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) =>
                    value!.trim().isEmpty ? "A descrição é obrigatória" : null,
              ),
              const SizedBox(height: 15),

              // CAMPO OPCIONAL (FOTOS)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Fotos do problema (Opcional)",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextButton.icon(
                    onPressed: _adicionarFotos,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text("Adicionar"),
                  ),
                ],
              ),

              // PREVIEW DAS FOTOS SELECIONADAS
              if (_fotosBytes.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _fotosBytes.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 10, top: 10),
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: MemoryImage(_fotosBytes[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _fotosBytes.removeAt(index));
                              },
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.red,
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              const SizedBox(height: 20),

              // BOTÃO DE ENVIO
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _enviarSolicitacao,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: _enviando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Enviar Solicitação",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
