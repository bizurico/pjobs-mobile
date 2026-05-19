import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class ListaConversasScreen extends StatelessWidget {
  final bool isProfissional;

  const ListaConversasScreen({super.key, required this.isProfissional});

  @override
  Widget build(BuildContext context) {
    final String myUid = FirebaseAuth.instance.currentUser!.uid;

    Query query = FirebaseFirestore.instance.collection('conversas');

    if (isProfissional) {
      query = query.where('profissionalId', isEqualTo: myUid);
    } else {
      query = query.where('clienteId', isEqualTo: myUid);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Minhas Mensagens"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Erro ao carregar chats: ${snapshot.error}"),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Nenhuma conversa encontrada.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          var conversas = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: conversas.length,
            itemBuilder: (context, index) {
              var conversaDoc = conversas[index];
              var dados = conversaDoc.data() as Map<String, dynamic>;
              String roomId = conversaDoc
                  .id; // O ID correto do documento (ex: clienteId_profId)

              // Identifica quem é o profissional e quem é o cliente na sala
              String proId = dados['profissionalId'] ?? '';
              String proNome = dados['profissionalNome'] ?? 'Profissional';

              // Se o display name do cliente for nulo, usamos um fallback melhor ou o ID reduzido
              String clienteNome = dados['nome'] ?? 'Usuário Cliente';
              String nomeExibicao = isProfissional ? clienteNome : proNome;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isProfissional
                        ? Colors.teal.shade100
                        : Colors.blue.shade100,
                    child: Text(
                      nomeExibicao.isNotEmpty
                          ? nomeExibicao[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isProfissional ? Colors.teal : Colors.blue,
                      ),
                    ),
                  ),
                  title: Text(
                    nomeExibicao,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: const Text(
                    "Clique para abrir o chat",
                    style: TextStyle(fontSize: 13),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatRoomId:
                              roomId, // Usando a variável que já existe na linha 52!
                          profissionalId:
                              proId, // Usando a variável que você definiu acima
                          nomeContato:
                              nomeExibicao, // Usando a variável que você definiu acima
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
