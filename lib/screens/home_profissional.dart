// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lista_conversas.dart'; // Importe a tela de lista de conversas que criamos
import 'editar_perfil.dart'; // Importe a tela de edição de perfil
import 'chat_screen.dart'; // Importe a tela de chat para abrir a conversa diretamente do card de pedido
import 'dart:convert'; // <--- Adicione este import para usar o base64Encode
import 'historico_screen.dart'; // Importe a tela de histórico do profissional
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';

class HomeProfissional extends StatefulWidget {
  const HomeProfissional({super.key});

  @override
  State<HomeProfissional> createState() => _HomeProfissionalState();
}

class _HomeProfissionalState extends State<HomeProfissional> {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  bool _statusCarregado = false;
  bool _isOnline = false;
  int _indiceAtual = 0;

  void _mostrarDialogConclusao(
    BuildContext context, {
    required String pedidoId,
  }) {
    Uint8List? fotoDepoisBytes;
    bool enviando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Finalizar Serviço",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Tire a foto do serviço concluído para comprovação de entrega:",
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: enviando
                        ? null
                        : () async {
                            final picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.camera,
                              imageQuality: 20,
                            );
                            if (image != null) {
                              final bytes = await image.readAsBytes();
                              setPopupState(() {
                                fotoDepoisBytes = bytes;
                              });
                            }
                          },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        image: fotoDepoisBytes != null
                            ? DecorationImage(
                                image: MemoryImage(fotoDepoisBytes!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: fotoDepoisBytes == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  color: Colors.green,
                                  size: 40,
                                ),
                                Text(
                                  "Registrar Foto do 'Depois'",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              actions: [
                if (enviando)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      "Voltar",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: fotoDepoisBytes == null
                        ? null
                        : () async {
                            setPopupState(() => enviando = true);
                            try {
                              String strDepois = base64Encode(fotoDepoisBytes!);

                              await FirebaseFirestore.instance
                                  .collection('pedidos')
                                  .doc(pedidoId)
                                  .update({
                                    'status': 'concluido',
                                    'fotoDepois': strDepois,
                                    'dataConclusao':
                                        FieldValue.serverTimestamp(),
                                  });

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Serviço concluído com sucesso!",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              setPopupState(() => enviando = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Erro ao finalizar: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      "Confirmar Entrega",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lista das telas do Profissional
    final List<Widget> abas = [
      _buildAbaInicio(),
      const ListaConversasScreen(isProfissional: true),
      const HistoricoScreen(isProfissional: true), // <--- TELA PLUGADA AQUI
      const EditarPerfilScreen(isProfissional: true),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Painel do Profissional"), elevation: 0),
      body: abas[_indiceAtual],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: (index) {
          setState(() {
            _indiceAtual = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors
            .green, // Dica: Mudar a cor para o profissional ajuda a diferenciar do cliente visualmente
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: "Demandas",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: "Mensagens",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: "Meus Serviços",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Perfil",
          ),
        ],
      ),
    );
  }

  Widget _buildAbaInicio() {
    return StreamBuilder<DocumentSnapshot>(
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // PASSANDO A LISTA DE PEDIDOS PARA O GRID CALCULAR OS NÚMEROS
                  buildStatGrid(pedidosDocs),

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
                  const SizedBox(height: 12),

                  // REAPROVEITANDO OS DADOS NA LISTA
                  _buildOrderList(),
                ],
              ),
            );
          },
        );
      },
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

  Widget buildStatGrid(List<QueryDocumentSnapshot> pedidos) {
    // 1. Total de Pedidos: Filtra para contar APENAS os concluídos
    int totalPedidos = pedidos.where((doc) {
      var p = doc.data() as Map<String, dynamic>;
      return p['status'] == 'concluido';
    }).length;

    // 2. Quantidade de Pendentes: Tudo que não for concluído ou recusado é um trabalho ativo
    int totalPendentes = pedidos.where((doc) {
      var p = doc.data() as Map<String, dynamic>;
      var status = p['status'] ?? 'pendente';
      return status != 'concluido' && status != 'recusado';
    }).length;

    // 3. Ganhos Estimados: Soma real baseada no campo 'valorProposto' dos serviços concluídos
    double ganhosEstimados = pedidos
        .where((doc) {
          var p = doc.data() as Map<String, dynamic>;
          return p['status'] == 'concluido';
        })
        .fold(0.0, (soma, doc) {
          var p = doc.data() as Map<String, dynamic>;
          // Puxa o valor do orçamento aprovado (valorProposto)
          var valor = p['valorProposto'] ?? 0.0;

          if (valor is num) return soma + valor.toDouble();
          return soma + (double.tryParse(valor.toString()) ?? 0.0);
        });

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
                "N/A", // Mantido conforme seu padrão atual do PDF
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
        var todosOsPedidos = snapshot.data!.docs;
        var pedidos = todosOsPedidos.where((doc) {
          var dados = doc.data() as Map<String, dynamic>;
          var status = dados['status'] ?? 'pendente';
          // Só deixa passar para a Home se NÃO estiver concluído e NÃO estiver recusado
          return status != 'concluido' && status != 'recusado';
        }).toList();

        debugPrint(
          "Carregados ${pedidos.length} pedidos ativos para a home do profissional",
        );
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
                onTap: () => mostrarDetalhesCompletosPedido(context, dados),
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
                            Text(
                              "Toque para saber mais",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Colors.grey,
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

                        if (status == 'em_andamento' ||
                            status == 'iniciado') ...[
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Pegamos o endereço real do cliente que está salvo no documento do pedido
                              String enderecoCliente =
                                  dados['enderecoCliente'] ?? '';

                              if (enderecoCliente.isNotEmpty) {
                                // Codifica o texto do endereço para formato de URL (remove espaços e caracteres especiais)
                                final query = Uri.encodeComponent(
                                  enderecoCliente,
                                );

                                // URL universal que força o telemóvel a abrir o app de GPS nativo em modo de navegação/rota
                                final googleMapsUrl = Uri.parse(
                                  "https://www.google.com/maps/search/?api=1&query=$query",
                                );

                                try {
                                  if (await canLaunchUrl(googleMapsUrl)) {
                                    await launchUrl(
                                      googleMapsUrl,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    throw 'Não foi possível abrir o mapa.';
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Erro ao abrir GPS: $e"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "O cliente não informou um endereço válido.",
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.navigation,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Ver Rota no GPS",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors
                                  .blueGrey
                                  .shade700, // Cor neutra para destacar dos botões de ação principal
                              minimumSize: const Size(double.infinity, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ), // Pequeno espaço antes do botão de Iniciar/Concluir
                        ],

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

                        // DENTRO DO SEU CARD DE DEMANDAS, NA ÁREA DE BOTÕES:
                        if (status == 'em_andamento') ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              _mostrarDialogInicioServico(
                                context,
                                pedidoId: pedidoId,
                                fotoSolicitacao: dados['fotoSolicitacao'],
                              );
                            },
                            icon: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Iniciar Serviço",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              minimumSize: const Size(double.infinity, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ]
                        // 2. SE O SERVIÇO JÁ FOI INICIADO: MOSTRA O BOTÃO DE "CONCLUIR"
                        else if (status == 'iniciado') ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              _mostrarDialogConclusao(
                                context,
                                pedidoId: pedidoId,
                              );
                            },
                            icon: const Icon(
                              Icons.assignment_turned_in,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Concluir Serviço",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: const Size(double.infinity, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
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
}

void _mostrarDialogInicioServico(
  BuildContext context, {
  required String pedidoId,
  String? fotoSolicitacao,
}) {
  Uint8List? fotoAntesBytes;
  bool reutilizouFotoCliente = false;
  bool enviando = false;

  // Preenche opcionalmente com a foto que o cliente mandou na abertura
  if (fotoSolicitacao != null && fotoSolicitacao.isNotEmpty) {
    fotoAntesBytes = base64Decode(fotoSolicitacao);
    reutilizouFotoCliente = true;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setPopupState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Iniciar Trabalho",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Tire uma foto do estado atual do local/objeto antes de começar o serviço:",
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: enviando
                      ? null
                      : () async {
                          final picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 20,
                          );
                          if (image != null) {
                            final bytes = await image.readAsBytes();
                            setPopupState(() {
                              fotoAntesBytes = bytes;
                              reutilizouFotoCliente = false;
                            });
                          }
                        },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      image: fotoAntesBytes != null
                          ? DecorationImage(
                              image: MemoryImage(fotoAntesBytes!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: fotoAntesBytes == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                color: Colors.blue,
                                size: 40,
                              ),
                              Text(
                                "Registrar Foto do 'Antes'",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              margin: const EdgeInsets.all(6),
                              color: Colors.black54,
                              child: Text(
                                reutilizouFotoCliente
                                    ? "Foto da solicitação"
                                    : "Nova foto capturada",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
            actions: [
              if (enviando)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    "Voltar",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: fotoAntesBytes == null
                      ? null
                      : () async {
                          setPopupState(() => enviando = true);
                          try {
                            String strAntes = base64Encode(fotoAntesBytes!);

                            await FirebaseFirestore.instance
                                .collection('pedidos')
                                .doc(pedidoId)
                                .update({
                                  'status': 'iniciado',
                                  'fotoAntes': strAntes,
                                  'dataInicioTrabalho':
                                      FieldValue.serverTimestamp(),
                                });

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Serviço iniciado! Bom trabalho.",
                                ),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          } catch (e) {
                            setPopupState(() => enviando = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Erro ao iniciar: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text(
                    "Iniciar Agora",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ],
          );
        },
      );
    },
  );
}
