import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

class HomeProfissional extends StatefulWidget {
  const HomeProfissional({super.key});

  @override
  State<HomeProfissional> createState() => _HomeProfissionalState();
}

class _HomeProfissionalState extends State<HomeProfissional> {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint("=== HomeProfissional BUILD ===");
    debugPrint("Current User UID: $currentUid");
    debugPrint("Widget UID: $uid");

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text("Carregando...");
            }
            if (snapshot.hasData && snapshot.data!.exists) {
              var dados = snapshot.data!.data() as Map<String, dynamic>;
              return Text("Olá, ${dados['nome']}");
            }
            return const Text("Painel do Profissional");
          },
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
              if (!context.mounted) return;
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Erro ao carregar perfil."));
          }

          var dados = snapshot.data!.data() as Map<String, dynamic>;
          bool isOnline = dados['isOnline'] ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(
                  dados['nome'],
                  isOnline,
                ), // Agora este método existe abaixo!
                const SizedBox(height: 24),
                const Text(
                  "Resumo de Hoje",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildStatGrid(),
                const SizedBox(height: 24),
                const Text(
                  "Sua Especialidade",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  dados['profissao'] ?? "Não informada",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Próximos Pedidos",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _buildOrderList(), // Usando o método que estava "esquecido"
              ],
            ),
          );
        },
      ),
    );
  }

  // MÉTODO QUE ESTAVA FALTANDO:
  Widget _buildStatusCard(String nome, bool isOnline) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOnline ? Colors.green : Colors.grey,
          radius: 8,
        ),
        title: Text("$nome, você está ${isOnline ? 'Online' : 'Offline'}"),
        subtitle: Text(
          isOnline ? "Visível para novos clientes" : "Invisível para buscas",
        ),
        trailing: Switch(
          value: isOnline,
          onChanged: (val) async {
            debugPrint("Switch acionado! Novo valor: $val");

            try {
              debugPrint("Atualizando Firestore para UID: $uid");
              await FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(uid)
                  .update({'isOnline': val});
              debugPrint("Firestore atualizado com sucesso!");
            } catch (e) {
              debugPrint("ERRO ao atualizar Firestore: $e");
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Erro ao atualizar status: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
            if (!mounted) return;
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid() {
    return Column(
      children: [
        // Primeira Linha de Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Total de Pedidos",
                "0",
                Icons.assignment,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16), // Espaçamento horizontal entre os cards
            Expanded(
              child: _buildStatCard(
                "Avaliação",
                "N/A",
                Icons.star,
                Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16), // Espaçamento vertical entre as linhas
        // Segunda Linha de Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Ganhos (Mês)",
                "R\$ 0,00",
                Icons.payments,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Pendentes",
                "0",
                Icons.pending_actions,
                Colors.red, // Use a cor que preferir aqui
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderList() {
    debugPrint("Procurando pedidos para profissional: $uid");

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pedidos')
          .where('profissionalId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        debugPrint(
          "StreamBuilder status: ${snapshot.connectionState}, "
          "Tem dados: ${snapshot.hasData}, Docs: ${snapshot.data?.docs.length ?? 0}",
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Erro no banco: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "Nenhum pedido recebido ainda.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        var pedidos = snapshot.data!.docs;
        debugPrint("Carregados ${pedidos.length} pedidos para o profissional");

        return Column(
          children: pedidos.map((doc) {
            try {
              var pedido = doc.data() as Map<String, dynamic>? ?? {};
              String pedidoId = doc.id;

              String status = pedido['status']?.toString() ?? 'pendente';
              String servico = pedido['servico']?.toString() ?? 'Geral';
              String clienteNome =
                  pedido['clienteNome']?.toString() ?? 'Usuário';

              Color statusColor = Colors.orange;
              if (status == 'aceito') statusColor = Colors.green;
              if (status == 'recusado') statusColor = Colors.red;

              debugPrint(
                "Pedido $pedidoId: Cliente=$clienteNome, "
                "Serviço=$servico, Status=$status",
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.assignment,
                          color: statusColor,
                          size: 30,
                        ),
                        title: Text(
                          "Serviço: $servico",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Cliente: $clienteNome\nStatus: ${status.toUpperCase()}",
                        ),
                      ),
                      if (status == 'pendente') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () =>
                                    _alterarStatusPedido(pedidoId, 'recusado'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text("Recusar"),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    _alterarStatusPedido(pedidoId, 'aceito'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text(
                                  "Aceitar",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            } catch (e) {
              return Card(
                color: Colors.red.shade50,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.error, color: Colors.red),
                  title: const Text("Erro nos dados do card"),
                  subtitle: Text(e.toString()),
                ),
              );
            }
          }).toList(),
        );
      },
    );
  }

  Future<void> _alterarStatusPedido(String pedidoId, String novoStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(pedidoId)
          .update({'status': novoStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Pedido $novoStatus com sucesso!"),
            backgroundColor: novoStatus == 'aceito' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro ao atualizar pedido."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
