import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'solicitar_servico.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class DetalhesProfissional extends StatefulWidget {
  final Map<String, dynamic> profissional;

  const DetalhesProfissional({super.key, required this.profissional});

  @override
  State<DetalhesProfissional> createState() => _DetalhesProfissionalState();
}

class _DetalhesProfissionalState extends State<DetalhesProfissional> {
  bool isOnline = false;
  String _opcaoOrdenacao = 'melhores';

  @override
  void initState() {
    super.initState();
    isOnline = widget.profissional['isOnline'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profissional['nome'] ?? "Detalhes"),
        backgroundColor: Colors.blue,
      ),
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
                    tag: widget.profissional['nome'] ?? "avatar",
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blue.shade50,
                      backgroundImage:
                          (widget.profissional['fotoPerfil'] != null &&
                              widget.profissional['fotoPerfil']
                                  .toString()
                                  .isNotEmpty)
                          ? MemoryImage(
                              base64Decode(widget.profissional['fotoPerfil']),
                            )
                          : null,
                      child:
                          (widget.profissional['fotoPerfil'] == null ||
                              widget.profissional['fotoPerfil']
                                  .toString()
                                  .isEmpty)
                          ? const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.blue,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.profissional['nome'] ?? "Profissional",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.profissional['profissao'] ?? "Serviços Gerais",
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  _buildStatusChip(isOnline),
                ],
              ),
            ),

            // Seção de Biografia e Ações
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sobre o Profissional",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.profissional['bio'] ??
                        "Este profissional ainda não preencheu uma biografia.",
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final String meuUid =
                                FirebaseAuth.instance.currentUser!.uid;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  chatRoomId:
                                      "${meuUid}_${widget.profissional['uid']}",
                                  profissionalId: widget.profissional['uid'],
                                  nomeContato: widget.profissional['nome'],
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey.shade600,
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.chat,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            "Conversar",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            backgroundColor: isOnline
                                ? Colors.blue
                                : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isOnline
                              ? () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    builder: (context) => SolicitarServicoModal(
                                      profissional: widget.profissional,
                                    ),
                                  );
                                }
                              : null,
                          child: Text(
                            isOnline ? "Contratar Agora" : "Indisponível",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // 📊 SEÇÃO FILTROS (ESTILO IFOOD)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Avaliações e Opiniões",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              // 🔥 Exibe dinamicamente a nota calculada
                              StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('usuarios')
                                    .doc(widget.profissional['uid'])
                                    .snapshots(),
                                builder: (context, userSnap) {
                                  var notaExibida =
                                      widget.profissional['avaliacao'] ?? '5.0';
                                  if (userSnap.hasData &&
                                      userSnap.data!.exists) {
                                    var d =
                                        userSnap.data!.data()
                                            as Map<String, dynamic>;
                                    notaExibida =
                                        d['avaliacao'] ??
                                        d['notaMedia'] ??
                                        notaExibida;
                                  }
                                  return Text(
                                    double.parse(
                                      notaExibida.toString(),
                                    ).toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _opcaoOrdenacao,
                          underline: const SizedBox(),
                          icon: const Icon(
                            Icons.filter_list,
                            color: Colors.blue,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'melhores',
                              child: Text("Melhores notas"),
                            ),
                            DropdownMenuItem(
                              value: 'piores',
                              child: Text("Piores notas"),
                            ),
                          ],
                          onChanged: (String? novoFiltro) {
                            if (novoFiltro != null) {
                              setState(() {
                                _opcaoOrdenacao = novoFiltro;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 🔄 BUSCA DINÂMICA DE COMENTÁRIOS DIRETO NA COLEÇÃO DE PEDIDOS FINALIZADOS
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('pedidos')
                        .where(
                          'profissionalId',
                          isEqualTo: widget.profissional['uid'],
                        )
                        .where('status', isEqualTo: 'concluido')
                        .where(
                          'avaliadoPeloCliente',
                          isEqualTo: true,
                        ) // 🔥 Só traz pedidos que já ganharam review
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              "Este profissional ainda não recebeu comentários.",
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        );
                      }

                      List<DocumentSnapshot> listaPedidos = snapshot.data!.docs;

                      // 🔥 ALINHAMENTO DA REORDENAÇÃO PELOS CAMPOS DE PEDIDOS
                      if (_opcaoOrdenacao == 'melhores') {
                        listaPedidos.sort((a, b) {
                          num notaA = a['notaDoServico'] ?? 0;
                          num notaB = b['notaDoServico'] ?? 0;
                          return notaB.compareTo(notaA); // Maior para menor
                        });
                      } else {
                        listaPedidos.sort((a, b) {
                          num notaA = a['notaDoServico'] ?? 0;
                          num notaB = b['notaDoServico'] ?? 0;
                          return notaA.compareTo(notaB); // Menor para maior
                        });
                      }

                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: listaPedidos.length,
                        itemBuilder: (context, index) {
                          var pedido =
                              listaPedidos[index].data()
                                  as Map<String, dynamic>;

                          String cliente = pedido['clienteNome'] ?? 'Usuário';
                          String comentario =
                              pedido['comentarioDoCliente'] ??
                              'Sem comentário escrito.';
                          double nota = (pedido['notaDoServico'] ?? 5.0)
                              .toDouble();

                          String dataFormatada = '';
                          if (pedido['dataSolicitacao'] != null) {
                            DateTime dt =
                                (pedido['dataSolicitacao'] as Timestamp)
                                    .toDate();
                            dataFormatada = DateFormat('dd/MM/yyyy').format(dt);
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      cliente,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      dataFormatada,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: starIndex < nota.floor()
                                          ? Colors.amber
                                          : Colors.grey.shade300,
                                    );
                                  }),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  comentario,
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 14,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool online) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: online ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: online ? Colors.green : Colors.grey),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 10,
            color: online ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            online ? "Disponível" : "Offline",
            style: TextStyle(
              color: online ? Colors.green.shade700 : Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
