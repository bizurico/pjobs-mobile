// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

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
                    (pedido['valorProposto'] ?? 0.0).toDouble();

                    // Cores dinâmicas baseadas no status
                    Color corStatus = status == 'concluido'
                        ? Colors.green
                        : Colors.red.shade400;
                    IconData iconeStatus = status == 'concluido'
                        ? Icons.check_circle
                        : Icons.cancel;

                    return GestureDetector(
                      // 🔥 GATILHO DE CLIQUE: Chama a função global passando o mapa 'pedido' atual
                      onTap: () =>
                          mostrarDetalhesCompletosPedido(context, pedido),
                      child: Card(
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

                          // 🔥 ALTERAÇÃO DE OURO: O título vira uma Row para alinhar horizontalmente nos cantos
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Lado Esquerdo: Descrição do serviço
                              Expanded(
                                child: Text(
                                  descricao,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Lado Direito: A dica visual discreta empurrada para a extremidade
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Toque para saber mais",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Seu subtitle antigo continua intacto aqui embaixo, perfeitamente preservado
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

                              // --- GATILHO DA AVALIAÇÃO DE MÃO DUPLA ---
                              if (status == 'concluido') ...[
                                // Se for profissional logado olhando o histórico, checa se ele já avaliou o cliente
                                // Se for cliente logado olhando o histórico, checa se ele já avaliou o profissional
                                if ((isProfissional &&
                                        (pedido['avaliadoPeloProfissional'] ??
                                                false) ==
                                            false) ||
                                    (!isProfissional &&
                                        (pedido['avaliadoPeloCliente'] ??
                                                false) ==
                                            false)) ...[
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      mostrarDialogAvaliacao(
                                        context,
                                        pedidoId: historico[index]
                                            .id, // Pega o ID do documento do pedido
                                        usuarioAlvoId: isProfissional
                                            ? (pedido['clienteId'] ?? '')
                                            : (pedido['profissionalId'] ?? ''),
                                        isProfissionalAvaliando: isProfissional,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.star_purple500_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      "Avaliar",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber.shade700,
                                      minimumSize: const Size(100, 32),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
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

  // Certifique-se de ter o import do convert no topo do arquivo
}

void mostrarDetalhesCompletosPedido(
  BuildContext context,
  Map<String, dynamic> pedido,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled:
        true, // Permite que a tela suba se o conteúdo for grande
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      String status = pedido['status'] ?? 'Pendente';
      double valor = (pedido['valorProposto'] ?? 0.0).toDouble();

      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Indicador de arrastar do modal
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Detalhes do Serviço",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'concluido'
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: status == 'concluido'
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),

                const Text(
                  "Descrição do Problema:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pedido['descricaoProblema'] ?? 'Não informada',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),

                if (valor > 0) ...[
                  const Text(
                    "Preço do Serviço:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "R\$ ${valor.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // --- FOTO INICIAL DA SOLICITAÇÃO ---
                if (pedido['fotoSolicitacao'] != null &&
                    pedido['fotoSolicitacao'].toString().isNotEmpty) ...[
                  const Text(
                    "Foto Anexada pelo Cliente:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: MemoryImage(
                          base64Decode(pedido['fotoSolicitacao']),
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // --- SEÇÃO: EVIDÊNCIAS DE ENTREGA (SÓ APARECE SE TIVER CONCLUÍDO) ---
                if (status == 'concluido' &&
                    pedido['fotoAntes'] != null &&
                    pedido['fotoDepois'] != null) ...[
                  const Divider(height: 30),
                  const Text(
                    "Comprovação de Entrega:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              "Antes",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: MemoryImage(
                                    base64Decode(pedido['fotoAntes']),
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              "Depois",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: MemoryImage(
                                    base64Decode(pedido['fotoDepois']),
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      );
    },
  );
}

void mostrarDialogAvaliacao(
  BuildContext context, {
  required String pedidoId,
  required String usuarioAlvoId,
  required bool isProfissionalAvaliando,
}) {
  int notaSelecionada = 0;
  final TextEditingController comentarioController = TextEditingController();
  bool enviando =
      false; // 🔥 VARIÁVEL DE CONTROLE: Evita o segundo popup de loading

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      // Usamos o contexto do dialog de forma segura
      return StatefulBuilder(
        builder: (context, setPopupState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              isProfissionalAvaliando
                  ? "Avaliar Comportamento do Cliente"
                  : "Avaliar Serviço Prestado",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Escolha de 1 a 5 estrelas (Obrigatório):",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    int estrelaEstilo = index + 1;
                    return IconButton(
                      icon: Icon(
                        estrelaEstilo <= notaSelecionada
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                      // Desabilita o clique se estiver enviando os dados
                      onPressed: enviando
                          ? null
                          : () {
                              setPopupState(() {
                                notaSelecionada = estrelaEstilo;
                              });
                            },
                    );
                  }),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: comentarioController,
                  maxLines: 3,
                  enabled: !enviando, // Desabilita o campo enquanto envia
                  decoration: const InputDecoration(
                    labelText: "Deixe um comentário (Opcional)",
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              // Se estiver enviando, esconde os botões normais e mostra o indicador de progresso
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
                    "Cancelar",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: notaSelecionada == 0
                      ? null
                      : () async {
                          // 1. Ativa o estado de carregamento interno no popup
                          setPopupState(() {
                            enviando = true;
                          });

                          try {
                            // 2. Referência e cálculo da nota média
                            var userRef = FirebaseFirestore.instance
                                .collection('usuarios')
                                .doc(usuarioAlvoId);
                            var userDoc = await userRef.get();

                            double mediaAtual = 0.0;
                            int totalAvaliacoes = 0;

                            if (userDoc.exists && userDoc.data() != null) {
                              var dadosUser = userDoc.data()!;
                              mediaAtual = (dadosUser['notaMedia'] ?? 0.0)
                                  .toDouble();
                              totalAvaliacoes =
                                  (dadosUser['totalAvaliacoes'] ?? 0);
                            }

                            int novoTotal = totalAvaliacoes + 1;
                            double novaMedia =
                                ((mediaAtual * totalAvaliacoes) +
                                    notaSelecionada) /
                                novoTotal;

                            // 3. Atualiza o perfil do avaliado
                            await userRef.update({
                              'notaMedia': novaMedia,
                              'totalAvaliacoes': novoTotal,
                            });

                            // 4. Trava o pedido para não ser reavaliado
                            String campoTrava = isProfissionalAvaliando
                                ? 'avaliadoPeloProfissional'
                                : 'avaliadoPeloCliente';
                            String campoComentario = isProfissionalAvaliando
                                ? 'comentarioDoProfissional'
                                : 'comentarioDoCliente';
                            String campoNota = isProfissionalAvaliando
                                ? 'notaDoCliente'
                                : 'notaDoServico';

                            await FirebaseFirestore.instance
                                .collection('pedidos')
                                .doc(pedidoId)
                                .update({
                                  campoTrava: true,
                                  campoComentario: comentarioController.text
                                      .trim(),
                                  campoNota: notaSelecionada,
                                });

                            // 5. Fecha o diálogo usando o contexto seguro
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Avaliação enviada com sucesso!",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            // Se der erro, desativa o carregamento para o usuário tentar de novo
                            setPopupState(() {
                              enviando = false;
                            });

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Erro ao salvar. Verifique as regras do Firebase. Detalhes: $e",
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text(
                    "Enviar",
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
