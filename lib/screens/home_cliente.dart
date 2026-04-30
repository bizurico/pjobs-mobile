import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'profissional.dart'; // Importamos as categorias que você já criou

class HomeCliente extends StatelessWidget {
  const HomeCliente({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("PJobs Express"),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.person_outline)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSectionTitle("Categorias"),
            _buildCategoriesGrid(),
            _buildSectionTitle("Profissionais Próximos"),
            _buildProfessionalList(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF1976D2),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Início"),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: "Pedidos",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Chat",
          ),
        ],
      ),
    );
  }

  // Cabeçalho com Barra de Busca
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1976D2),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Olá, Luis!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            "De qual serviço você precisa hoje?",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              hintText: "Buscar encanador, suporte TI...",
              prefixIcon: const Icon(Icons.search),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Grid de categorias usando o que você definiu em constants.dart
  Widget _buildCategoriesGrid() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6, // Mostrando as 6 primeiras para o exemplo
        itemBuilder: (context, index) {
          return Container(
            width: 80,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(
                    Icons.work_outline,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.categorias[index],
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Lista de Cards dos Profissionais (Base para o RF07)
  Widget _buildProfessionalList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey,
            ),
            title: Text(
              "Profissional Exemplo ${index + 1}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Eletricista • ⭐ 4.9"),
                Text(
                  "A 2.5 km de distância",
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfissionalPage(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
