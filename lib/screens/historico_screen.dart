// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:typed_data';

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
  Map<String, dynamic> dados,
) {
  // Pega a descrição correta salvando compatibilidade com o seu solicitar_servico
  String descricao =
      dados['descricaoProblema'] ??
      dados['descricao'] ??
      'Sem descrição informada.';
  String endereco = dados['enderecoCliente'] ?? 'Endereço não informado.';

  String preco = dados['valorProposto'] != null && dados['valorProposto'] > 0
      ? "R\$ ${dados['valorProposto']}"
      : "Aguardando orçamento";

  // 1. TRATAMENTO ULTRA SEGURO DAS FOTOS: Descobre se veio lista ou string antiga
  List<dynamic> fotosRaw = [];
  if (dados['fotos'] is List) {
    fotosRaw = dados['fotos'];
  } else if (dados['fotos'] is String && dados['fotos'].toString().isNotEmpty) {
    fotosRaw = [dados['fotos']];
  }

  // 2. PRÉ-DECODIFICAÇÃO DE SEGURANÇA (Evita a tela cinza por completo!)
  List<Uint8List> fotosDecodificadas = [];
  for (var foto in fotosRaw) {
    if (foto != null && foto.toString().trim().isNotEmpty) {
      try {
        // Limpa espaços em branco acidentais e converte com segurança fora do build
        Uint8List bytes = base64Decode(foto.toString().trim());
        if (bytes.isNotEmpty) {
          fotosDecodificadas.add(bytes);
        }
      } catch (e) {
        debugPrint(
          "⚠️ Erro ao decodificar imagem do chamado (Ignorando para não crashar): $e",
        );
      }
    }
  }

  // Formata o texto do status para exibição elegante
  String statusText = (dados['status'] ?? 'AGUARDANDO_ORCAMENTO')
      .toString()
      .replaceAll('_', ' ')
      .toUpperCase();

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        // 🔥 CORREÇÃO DO OVERFLOW: Trocado de Row para Wrap para quebrar linha se faltar espaço!
        title: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.assignment_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  "Detalhes do Serviço",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          // Força uma largura responsiva elegante para o modal não amassar
          width: MediaQuery.of(context).size.width * 0.85,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Descrição do Problema:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descricao,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 16),

                const Text(
                  "Local de Atendimento:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  endereco,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 16),

                const Text(
                  "Valor do Orçamento:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  preco,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),

                // 🔥 EXIBIÇÃO EM CARROSSEL DAS FOTOS DO PROBLEMA (Se existirem)
                if (fotosDecodificadas.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    "Evidências do Problema (${fotosDecodificadas.length}):",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height:
                        160, // Tamanho excelente para o profissional inspecionar a foto
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: fotosDecodificadas.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 160,
                              color: Colors.grey.shade100,
                              child: Image.memory(
                                fotosDecodificadas[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  // 🔥 AVISO DE SEM FOTOS: Fica guardado aqui dentro e só aparece no modal!
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "Nenhuma foto foi anexada a esta solicitação.",
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                            fontSize: 13,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "Fechar",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
        ],
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
                              mediaAtual =
                                  (dadosUser['avaliacao'] ??
                                          dadosUser['notaMedia'] ??
                                          0.0)
                                      .toDouble(); // 🔥 Lê de forma flexível
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
                              'avaliacao':
                                  novaMedia, // 🔥 AGORA SIM! Atualiza a nota que os cards de busca lêem
                              'notaMedia':
                                  novaMedia, // Mantém o seu campo original intacto
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
