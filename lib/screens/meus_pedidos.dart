import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MeusPedidosCliente extends StatelessWidget {
  const MeusPedidosCliente({super.key});

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meus Pedidos"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pedidos')
            .where(
              'clienteId',
              isEqualTo: uid,
            ) // Filtra pelos pedidos DESTE cliente
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Você ainda não fez nenhuma solicitação.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          var pedidos = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              var pedido = pedidos[index].data() as Map<String, dynamic>;
              String status = pedido['status'] ?? 'pendente';
              String servico = pedido['servico'] ?? 'Serviço';

              // Configuração de cores dinâmica baseada no status que o profissional escolheu
              Color statusColor = Colors.orange;
              String statusTexto = "Aguardando Resposta";

              if (status == 'aceito') {
                statusColor = Colors.green;
                statusTexto = "Pedido Aceito!";
              } else if (status == 'recusado') {
                statusColor = Colors.red;
                statusTexto = "Pedido Recusado";
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            servico,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusTexto,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Data: ${pedido['dataCriacao'] != null ? (pedido['dataCriacao'] as Timestamp).toDate().toString().substring(0, 16) : 'Agora mesmo'}",
                        style: const TextStyle(color: Colors.grey),
                      ),

                      // CEREJA DO BOLO: Se o profissional aceitou, libera o contato
                      if (status == 'aceito') ...[
                        const Divider(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Aqui depois podemos integrar o link direto para o WhatsApp do profissional
                            print("Abrindo conversa com o profissional...");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          icon: const Icon(Icons.chat, color: Colors.white),
                          label: const Text(
                            "Combinar via WhatsApp",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
