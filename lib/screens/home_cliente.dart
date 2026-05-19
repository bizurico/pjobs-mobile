import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'detalhes_profissional.dart';
import 'meus_pedidos.dart'; // Se estiverem na mesma pasta. Se não, ajuste o caminho relativo.
import 'lista_conversas.dart';
import 'editar_perfil.dart';

class HomeCliente extends StatefulWidget {
  const HomeCliente({super.key});

  @override
  State<HomeCliente> createState() => _HomeClienteState();
}

class _HomeClienteState extends State<HomeCliente> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
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
      body: Column(
        children: [
          // 1. BARRA DE PESQUISA UNIFICADA
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Busque por nome ou especialidade...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. LISTAGEM DINÂMICA COM FILTRO LOCAL
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .where('isCliente', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Erro: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filtramos a lista baseada no texto da pesquisa
                final docs = snapshot.data!.docs.where((doc) {
                  final dados = doc.data() as Map<String, dynamic>;
                  final nome = (dados['nome'] ?? "").toString().toLowerCase();
                  final profissao = (dados['profissao'] ?? "")
                      .toString()
                      .toLowerCase();

                  // Retorna verdadeiro se o termo de busca estiver no nome OU na profissão
                  return nome.contains(_searchQuery) ||
                      profissao.contains(_searchQuery);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text("Nenhum profissional encontrado."),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final dados = docs[index].data() as Map<String, dynamic>;
                    dados['uid'] = docs[index]
                        .id; // Adiciona o UID aos dados para uso futuro
                    final bool isOnline = dados['isOnline'] ?? false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.blue.shade50,
                          child: const Icon(Icons.person, color: Colors.blue),
                        ),
                        title: Text(
                          dados['nome'] ?? "Profissional",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dados['profissao'] ?? "Serviços Gerais"),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: isOnline ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOnline ? "Disponível" : "Offline",
                                  style: TextStyle(
                                    color: isOnline
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          debugPrint(
                            "Clicou no profissional: ${dados['nome']} (UID: ${dados['uid']})",
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetalhesProfissional(profissional: dados),
                            ),
                          );
                        },
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
