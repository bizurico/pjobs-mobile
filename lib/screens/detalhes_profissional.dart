import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'solicitar_servico.dart';

class DetalhesProfissional extends StatelessWidget {
  final Map<String, dynamic> profissional;

  const DetalhesProfissional({super.key, required this.profissional});

  @override
  Widget build(BuildContext context) {
    bool isOnline = profissional['isOnline'] ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(profissional['nome'] ?? "Detalhes")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabeçalho com Foto e Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              color: Colors.white,
              child: Column(
                children: [
                  Hero(
                    tag: profissional['nome'] ?? "avatar",
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(
                        Icons.person,
                        size: 80,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profissional['nome'] ?? "Profissional",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    profissional['profissao'] ?? "Serviços Gerais",
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  _buildStatusChip(isOnline),
                ],
              ),
            ),

            // Seção de Biografia
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sobre o Profissional",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profissional['bio'] ??
                        "Este profissional ainda não preencheu uma biografia.",
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () {
                      final String meuUid =
                          FirebaseAuth.instance.currentUser!.uid;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatRoomId: "${meuUid}_${profissional['uid']}",
                            // Passa os dados do profissional que você já tem nessa tela
                            profissionalId: profissional['uid'],
                            nomeContato: profissional['nome'],
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                    ),
                    icon: const Icon(Icons.chat, color: Colors.white),
                    label: const Text(
                      "Conversar com Profissional",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  // Botão de Contratação
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                      backgroundColor: isOnline ? Colors.blue : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: isOnline
                        ? () {
                            // Abre o modal de solicitação com formulário e fotos
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled:
                                  true, // Permite que o modal cresça com o teclado
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (context) => SolicitarServicoModal(
                                profissional: profissional,
                              ),
                            );
                          }
                        : null,
                    child: Text(
                      isOnline ? "Contratar Agora" : "Indisponível no Momento",
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isOnline ? Colors.green : Colors.grey),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 10,
            color: isOnline ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? "Disponível" : "Offline",
            style: TextStyle(
              color: isOnline ? Colors.green.shade700 : Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
