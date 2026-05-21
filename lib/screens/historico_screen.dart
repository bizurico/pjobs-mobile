import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoricoScreen extends StatelessWidget {
  final bool isProfissional;

  const HistoricoScreen({super.key, required this.isProfissional});

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // Se for profissional, busca onde o ID dele está no pedido. Se for cliente, busca pelo ID do cliente.
    String campoBusca = isProfissional ? 'profissionalId' : 'clienteId';

    return Scaffold(
      // Como essa tela vai ficar dentro da aba, não precisamos de AppBar duplicada,
      // mas coloquei um cabeçalho simples para ficar elegante.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              isProfissional
                  ? "Serviços Finalizados"
                  : "Histórico de Solicitações",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pedidos')
                  .where(campoBusca, isEqualTo: uid)
                  // .orderBy('dataCriacao', descending: true) // Se você tiver dataCriacao no banco, pode descomentar isso depois!
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Nenhum histórico encontrado.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // FILTRO LOCAL: Pega apenas os pedidos que NÃO estão em andamento ou aguardando
                var historico = snapshot.data!.docs.where((doc) {
                  var dados = doc.data() as Map<String, dynamic>;
                  String status = dados['status'] ?? '';
                  return status == 'concluido' ||
                      status == 'recusado' ||
                      status == 'cancelado';
                }).toList();

                if (historico.isEmpty) {
                  return const Center(
                    child: Text(
                      "Você ainda não possui serviços finalizados.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: historico.length,
                  itemBuilder: (context, index) {
                    var pedido =
                        historico[index].data() as Map<String, dynamic>;

                    String descricao =
                        pedido['descricaoProblema'] ?? 'Serviço Geral';
                    String nomeOutraParte = isProfissional
                        ? (pedido['clienteNome'] ?? 'Cliente')
                        : (pedido['profissionalNome'] ?? 'Profissional');
                    String status = pedido['status'] ?? 'desconhecido';
                    double valor = (pedido['valorProposto'] ?? 0.0).toDouble();

                    // Cores dinâmicas baseadas no status
                    Color corStatus = status == 'concluido'
                        ? Colors.green
                        : Colors.red.shade400;
                    IconData iconeStatus = status == 'concluido'
                        ? Icons.check_circle
                        : Icons.cancel;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: corStatus.withValues(alpha: 0.1),
                          child: Icon(iconeStatus, color: corStatus),
                        ),
                        title: Text(
                          descricao,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              "${isProfissional ? 'Para' : 'Com'}: $nomeOutraParte",
                            ),
                            const SizedBox(height: 4),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: corStatus,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: valor > 0
                            ? Text(
                                "R\$ ${valor.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )
                            : const Text(
                                "-",
                                style: TextStyle(color: Colors.grey),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
