import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'detalhes_profissional.dart';
import 'meus_pedidos.dart'; // Se estiverem na mesma pasta. Se não, ajuste o caminho relativo.
import 'lista_conversas.dart';
import 'editar_perfil.dart';
import '../core/constants.dart'; // Importe o arquivo de constantes para usar as chaves definidas lá

class HomeCliente extends StatefulWidget {
  const HomeCliente({super.key});

  @override
  State<HomeCliente> createState() => _HomeClienteState();
}

class _HomeClienteState extends State<HomeCliente> {
  final TextEditingController _searchController = TextEditingController();
  String _textoPesquisa = "";
  late List<String> _categorias;

  @override
  void initState() {
    super.initState();
    // initState: Roda ANTES da tela aparecer. Lugar perfeito para inicializar o 'late'.
    _categorias = List<String>.from(AppConstants.categorias);
  }

  @override
  void dispose() {
    // dispose: Roda QUANDO a tela morre. Serve apenas para limpar a memória.
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("PJobs"),
        backgroundColor: Colors.blue,
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
                // Rota de pedidos que já funcionava
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MeusPedidosCliente(),
                  ),
                );
              } else if (value == 'mensagens') {
                // <--- NOVO CAMINHO DO CLIENTE
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Passamos false porque aqui estamos na visão do Cliente
                    builder: (context) =>
                        const ListaConversasScreen(isProfissional: false),
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
                        const EditarPerfilScreen(isProfissional: false),
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
                    Icon(Icons.assignment, color: Colors.black54),
                    SizedBox(width: 10),
                    Text('Meus Pedidos'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value:
                    'mensagens', // <--- ÍCONE DE MENSAGENS NO MENU DO CLIENTE
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. BARRA DE PESQUISA
            TextField(
              controller:
                  _searchController, // <--- Adicione o controller aqui para controlar o texto visual
              onChanged: (valor) {
                setState(() {
                  _textoPesquisa = _normalizarTexto(
                    valor,
                  ); // <--- Normaliza o que o usuário digita
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar por profissionais ou serviços...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                suffixIcon: _textoPesquisa.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _textoPesquisa = "";
                            _searchController
                                .clear(); // <--- Limpa a barra visualmente também
                          });
                        },
                      )
                    : null,
                // ... resto do seu design da barra
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ==========================================================
            // MODO 1: TELA INICIAL (QUANDO A PESQUISA ESTÁ VAZIA)
            // ==========================================================
            if (_textoPesquisa.isEmpty) ...[
              const Text(
                "Navegue por serviços",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // CARROSSEL DINÂMICO (Puxando do constants.dart)
              SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categorias.length,
                  itemBuilder: (context, index) {
                    String categoria = _categorias[index];
                    return _buildCategoryChip(
                      _pegarIconeCategoria(categoria),
                      categoria,
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                "Seus Pedidos e Orçamentos",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // LISTA DE PEDIDOS DO CLIENTE (Estática, não é afetada pela busca)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('pedidos')
                    .where(
                      'clienteId',
                      isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                    )
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text(
                      "Você não fez nenhuma solicitação ainda.",
                      style: TextStyle(color: Colors.grey),
                    );
                  }

                  var pedidos = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pedidos.length,
                    itemBuilder: (context, index) {
                      var pedidoDoc = pedidos[index];
                      var dados = pedidoDoc.data() as Map<String, dynamic>;
                      String descricao =
                          dados['descricaoProblema'] ?? 'Serviço Geral';
                      String proNome =
                          dados['profissionalNome'] ?? 'Profissional';
                      String status = dados['status'] ?? 'aguardando_orcamento';
                      double valor = (dados['valorProposto'] ?? 0.0).toDouble();

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
                              Text(
                                descricao,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Profissional: $proNome",
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              Text(
                                "Status: ${status.replaceAll('_', ' ').toUpperCase()}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blueGrey,
                                ),
                              ),

                              if (status == 'aguardando_aprovacao_cliente') ...[
                                const Divider(height: 20),
                                Text(
                                  "Orçamento Recebido: R\$ ${valor.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => FirebaseFirestore
                                            .instance
                                            .collection('pedidos')
                                            .doc(pedidoDoc.id)
                                            .update({'status': 'recusado'}),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Colors.red,
                                          ),
                                        ),
                                        child: const Text(
                                          "Recusar",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => FirebaseFirestore
                                            .instance
                                            .collection('pedidos')
                                            .doc(pedidoDoc.id)
                                            .update({'status': 'em_andamento'}),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        child: const Text(
                                          "Aceitar Preço",
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
                    },
                  );
                },
              ),

              // ==========================================================
              // MODO 2: RESULTADOS DA BUSCA (QUANDO O CLIENTE DIGITA ALGO)
              // ==========================================================
              // MODO 2: RESULTADOS DA BUSCA (QUANDO O CLIENTE DIGITA ALGO)
            ] else ...[
              Text(
                "Resultados para '$_textoPesquisa'",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),

              // LISTA DE PROFISSIONAIS FILTRADOS
              StreamBuilder<QuerySnapshot>(
                // 🔥 A MÁGICA ACONTECE AQUI: Mudamos para isCliente == false
                stream: FirebaseFirestore.instance
                    .collection('usuarios')
                    .where('isCliente', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text(
                      "Nenhum profissional cadastrado no sistema.",
                    );
                  }

                  var profissionaisFiltrados = snapshot.data!.docs.where((doc) {
                    var dados = doc.data() as Map<String, dynamic>;

                    String nome = _normalizarTexto(
                      (dados['nome'] ?? '').toString(),
                    );
                    String profissao = _normalizarTexto(
                      (dados['profissao'] ?? '').toString(),
                    );

                    return nome.contains(_textoPesquisa) ||
                        profissao.contains(_textoPesquisa);
                  }).toList();

                  if (profissionaisFiltrados.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "Nenhum profissional encontrado para esta busca.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: profissionaisFiltrados.length,
                    itemBuilder: (context, index) {
                      var profissional =
                          profissionaisFiltrados[index].data()
                              as Map<String, dynamic>;
                      profissional['uid'] = profissionaisFiltrados[index].id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage: profissional['fotoPerfil'] != null
                                ? NetworkImage(profissional['fotoPerfil'])
                                : null,
                            child: profissional['fotoPerfil'] == null
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.blue,
                                    size: 30,
                                  )
                                : null,
                          ),
                          title: Text(
                            profissional['nome'] ?? 'Sem nome',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                profissional['profissao'] ??
                                    'Profissão não informada',
                                style: const TextStyle(color: Colors.blue),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: profissional['isOnline'] == true
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    profissional['isOnline'] == true
                                        ? "Disponível agora"
                                        : "Offline",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetalhesProfissional(
                                  profissional: profissional,
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
            ],
          ],
        ),
      ),
    );
  }

  IconData _pegarIconeCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'eletricista':
        return Icons.flash_on;
      case 'encanador':
        return Icons.water_drop;
      case 'pintor':
        return Icons.format_paint;
      case 'diarista':
        return Icons.cleaning_services;
      case 'mecânico':
        return Icons.build;
      default:
        return Icons
            .work_outline; // Ícone padrão para 'Outros' ou novas profissões
    }
  }

  // Função que remove acentos e joga tudo para minúsculo
  String _normalizarTexto(String texto) {
    String comAcento =
        'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    String semAcento =
        'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
    String resultado = texto;

    for (int i = 0; i < comAcento.length; i++) {
      resultado = resultado.replaceAll(comAcento[i], semAcento[i]);
    }

    return resultado.toLowerCase().trim();
  }

  Widget _buildCategoryChip(IconData icone, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: ActionChip(
        avatar: Icon(icone, size: 18, color: Colors.blue),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () {
          setState(() {
            _textoPesquisa = _normalizarTexto(
              label,
            ); // Limpa o texto (Mecânico -> mecanico)
            _searchController.text =
                label; // Mantém a palavra bonita (com acento) na barra visual
          });
        },
      ),
    );
  }
}
