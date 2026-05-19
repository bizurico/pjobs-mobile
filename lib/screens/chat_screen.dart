import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String profissionalId;
  final String nomeContato;

  const ChatScreen({
    super.key,
    required this.profissionalId,
    required this.nomeContato,
    required this.chatRoomId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();

    _criarSalaSeNaoExistir();
  }

  // Garante que o documento principal da conversa exista
  Future<void> _criarSalaSeNaoExistir() async {
    String idCliente = widget.chatRoomId.split('_')[0];
    String nomeDoCliente = "Usuário Cliente"; // Fallback caso dê erro

    try {
      // 1. Vai na coleção onde os clientes estão salvos e pega o nome dele.
      // ⚠️ ATENÇÃO: Se a sua coleção de usuários se chamar 'clientes' em vez de 'usuarios', altere a palavra abaixo!
      var docUsuario = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(idCliente)
          .get();

      if (docUsuario.exists && docUsuario.data()!.containsKey('nome')) {
        nomeDoCliente = docUsuario['nome'];
        debugPrint("Nome do cliente encontrado: $nomeDoCliente");
      }
    } catch (e) {
      debugPrint("Erro ao buscar nome do cliente: $e");
    }

    // 2. Agora sim, cria a sala salvando os DOIS nomes dentro do documento da conversa!
    await FirebaseFirestore.instance
        .collection('conversas')
        .doc(widget.chatRoomId)
        .set({
          'clienteId': idCliente,
          'profissionalId': widget.profissionalId,
          'profissionalNome':
              widget.nomeContato, // Nome de quem recebeu o clique
          'nome': nomeDoCliente, // <--- SALVANDO O NOME 'luis' AQUI!
          'ultimaAtualizacao': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _enviarMensagem() async {
    if (_msgController.text.trim().isEmpty) return;

    String textoEnviado = _msgController.text.trim();

    // Limpa o campo na hora para o usuário não clicar duas vezes
    _msgController.clear();

    try {
      // 1. Salva a mensagem na subcoleção do chat
      await FirebaseFirestore.instance
          .collection('conversas')
          .doc(
            widget.chatRoomId,
          ) // <-- Garantindo que estamos usando o widget.chatRoomId
          .collection('mensagens')
          .add({
            'texto': textoEnviado,
            'remetenteId': _currentUid,
            'dataEnvio': FieldValue.serverTimestamp(),
          });

      // 2. Atualiza a data da sala para ela subir na lista de conversas
      await FirebaseFirestore.instance
          .collection('conversas')
          .doc(widget.chatRoomId)
          .update({'ultimaAtualizacao': FieldValue.serverTimestamp()});
    } catch (e) {
      // SE DER ERRO, VAI APARECER AQUI E NA TELA DO APP!
      debugPrint("=== ERRO AO ENVIAR MENSAGEM: $e ===");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao enviar: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nomeContato),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Área de Mensagens Reativa
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('conversas')
                  .doc(widget.chatRoomId)
                  .collection('mensagens')
                  .orderBy(
                    'dataEnvio',
                    descending: true,
                  ) // Mostra as mais recentes embaixo
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text("Envie uma mensagem para iniciar a conversa!"),
                  );
                }

                return ListView.builder(
                  reverse: true, // Começa de baixo para cima
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var msg = docs[index].data() as Map<String, dynamic>;
                    bool minhaMsg = msg['remetenteId'] == _currentUid;

                    return Align(
                      alignment: minhaMsg
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: minhaMsg
                              ? Colors.blue.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['texto'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Campo de Input de Texto
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: "Digite sua mensagem...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _enviarMensagem,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
