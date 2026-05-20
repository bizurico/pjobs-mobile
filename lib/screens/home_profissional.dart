import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lista_conversas.dart'; // Importe a tela de lista de conversas que criamos
import 'editar_perfil.dart'; // Importe a tela de edição de perfil
import 'chat_screen.dart'; // Importe a tela de chat para abrir a conversa diretamente do card de pedido
import 'dart:convert'; // <--- Adicione este import para usar o base64Encode

class HomeProfissional extends StatefulWidget {
  const HomeProfissional({super.key});

  @override
  State<HomeProfissional> createState() => _HomeProfissionalState();
}

class _HomeProfissionalState extends State<HomeProfissional> {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  bool _statusCarregado = false;
  bool _isOnline = false;

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
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.account_circle,
              color: Colors.white,
              size: 30,
            ),
            tooltip: "Perfil",
            onSelected: (value) async {
              if (value == 'pedidos') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Você já está na tela de pedidos!"),
                  ),
                );
              } else if (value == 'mensagens') {
                // <--- O TAPA ESTÁ AQUI!
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Passamos true porque aqui estamos na visão do Profissional
                    builder: (context) =>
                        const ListaConversasScreen(isProfissional: true),
                  ),
                );
              } else if (value == 'sair') {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } else if (value == 'editar_perfil') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const EditarPerfilScreen(isProfissional: true),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'editar_perfil',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.black54),
                    SizedBox(width: 10),
                    Text('Editar Perfil'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'pedidos',
                child: Row(
                  children: [
                    Icon(Icons.dashboard, color: Colors.black54),
                    SizedBox(width: 10),
                    Text('Dashboard de Pedidos'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'mensagens',
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Colors.black54),
                    SizedBox(width: 10),
                    Text('Mensagens'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'sair',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Sair', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text("Erro ao carregar perfil."));
          }

          var dados = userSnapshot.data!.data() as Map<String, dynamic>;

          if (!_statusCarregado) {
            _isOnline = dados['isOnline'] ?? false;
            _statusCarregado = true;
          }

          // LISTANDO OS PEDIDOS EM TEMPO REAL PARA TODA A TELA
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pedidos')
                .where('profissionalId', isEqualTo: uid)
                .snapshots(),
            builder: (context, orderSnapshot) {
              // Captura a lista de documentos (se não houver nada, retorna uma lista vazia)
              var pedidosDocs = orderSnapshot.data?.docs ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(dados['nome'], _isOnline),
                    const SizedBox(height: 24),
                    const Text(
                      "Resumo de Hoje",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // PASSANDO A LISTA DE PEDIDOS PARA O GRID CALCULAR OS NÚMEROS
                    _buildStatGrid(pedidosDocs),

                    const SizedBox(height: 24),
                    const Text(
                      "Sua Especialidade",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dados['profissao'] ?? "Não informada",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Próximos Pedidos",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // REAPROVEITANDO OS DADOS NA LISTA
                    _buildOrderList(),
                  ],
                ),
              );
            },
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

  Widget _buildStatGrid(List<QueryDocumentSnapshot> pedidos) {
    // 1. Total de Pedidos
    int totalPedidos = pedidos.length;

    // 2. Quantidade de Pendentes
    int totalPendentes = pedidos.where((doc) {
      var p = doc.data() as Map<String, dynamic>;
      return p['status'] == 'pendente';
    }).length;

    // 3. Ganhos Estimados (Multiplicando cada serviço aceito por um valor base, ex: R$ 80)
    // Se no futuro você adicionar o campo 'preco' no pedido, poderá somá-lo aqui de forma real
    int totalAceitos = pedidos.where((doc) {
      var p = doc.data() as Map<String, dynamic>;
      return p['status'] == 'aceito';
    }).length;
    double ganhosEstimados = totalAceitos * 80.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Total de Pedidos",
                totalPedidos.toString(),
                Icons.assignment,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Avaliação",
                "N/A",
                Icons.star,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Ganhos Estimados",
                "R\$ ${ganhosEstimados.toStringAsFixed(2)}",
                Icons.payments,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Pendentes",
                totalPendentes.toString(),
                Icons.pending_actions,
                Colors.red,
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
              var dados = doc.data() as Map<String, dynamic>? ?? {};
              String pedidoId = doc.id;

              // Trazendo as novas chaves do banco de dados
              String status = dados['status']?.toString() ?? 'pendente';
              String descricao =
                  dados['descricaoProblema']?.toString() ?? 'Serviço Geral';
              String clienteNome =
                  dados['clienteNome']?.toString() ?? 'Usuário';
              String clienteId = dados['clienteId']?.toString() ?? '';
              String profissionalId = FirebaseAuth.instance.currentUser!.uid;

              Color statusColor = Colors.orange;
              if (status == 'aceito' || status == 'em_andamento') {
                statusColor = Colors.green;
              }
              if (status == 'recusado') statusColor = Colors.red;

              return GestureDetector(
                onTap: () => _mostrarDetalhesPedido(context, dados),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // O Título agora é a descrição do problema
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.assignment,
                              color: statusColor,
                              size: 30,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                descricao,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Cliente: $clienteNome",
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        Text(
                          "Status: ${status.toUpperCase()}",
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Só mostra os botões se o status for aguardando_orcamento (ou pendente, dependendo de como você salvou antes)
                        // Só mostra os botões se o status for aguardando_orcamento ou pendente
                        if (status == 'aguardando_orcamento' ||
                            status == 'pendente') ...[
                          const Divider(height: 25),
                          Row(
                            children: [
                              // BOTÃO 1: ENVIAR MENSAGEM (Agora seguro com Expanded)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    String chatRoomId =
                                        "${clienteId}_$profissionalId";
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          chatRoomId: chatRoomId,
                                          profissionalId: profissionalId,
                                          nomeContato: clienteNome,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 18,
                                  ),
                                  label: const Text("Mensagem"),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.blue),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // BOTÃO 2: ENVIAR ORÇAMENTO (Agora seguro com Expanded)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _mostrarDialogOrcamento(context, pedidoId);
                                  },
                                  icon: const Icon(
                                    Icons.attach_money,
                                    size: 18,
                                  ),
                                  label: const Text("Orçamento"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
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

  void _mostrarDialogOrcamento(BuildContext context, String pedidoId) {
    final TextEditingController precoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enviar Orçamento"),
        content: TextField(
          controller: precoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "Valor do Serviço (R\$)",
            prefixText: "R\$ ",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (precoController.text.trim().isEmpty) return;

              double preco =
                  double.tryParse(
                    precoController.text.trim().replaceAll(',', '.'),
                  ) ??
                  0.0;

              // Atualiza o banco com o preço e muda o status
              await FirebaseFirestore.instance
                  .collection('pedidos')
                  .doc(pedidoId)
                  .update({
                    'valorProposto': preco,
                    'status': 'aguardando_aprovacao_cliente',
                  });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Orçamento enviado com sucesso!"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              "Enviar Preço",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalhesPedido(
    BuildContext context,
    Map<String, dynamic> pedido,
  ) {
    // Recupera a lista de fotos enviadas pelo cliente
    List<String> fotos = List<String>.from(pedido['fotos'] ?? []);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Detalhes da Solicitação",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 400, // Limita a largura no navegador
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Descrição do Problema:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pedido['descricaoProblema'] ?? 'Nenhuma descrição fornecida.',
                ),
                const SizedBox(height: 20),

                if (fotos.isNotEmpty) ...[
                  const Text(
                    "Fotos Anexadas:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: fotos.length,
                    itemBuilder: (context, i) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          // O base64Decode transforma o texto do Firestore de volta em imagem instantaneamente
                          base64Decode(fotos[i]),
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ] else ...[
                  const Text(
                    "Nenhuma foto anexada para este serviço.",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar"),
          ),
        ],
      ),
    );
  }
}
