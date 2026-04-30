import 'package:flutter/material.dart';

class ProfissionalPage extends StatelessWidget {
  const ProfissionalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar com efeito de expansão (bom para fotos)
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                "João Silva",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
              background: Image.network(
                "https://images.unsplash.com/photo-1581578731522-745505146317?q=80&w=500", // Foto de exemplo
                fit: BoxFit.cover,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(),
                  const Divider(height: 40),
                  _buildSectionTitle("Sobre o Profissional"),
                  const SizedBox(height: 8),
                  const Text(
                    "Eletricista residencial e industrial com mais de 10 anos de experiência. "
                    "Especialista em instalações de quadros, manutenção de fiação e automação básica.",
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Serviços"),
                  _buildServiceChips(),
                  const SizedBox(height: 24),
                  _buildSectionTitle("Avaliações"),
                  _buildRatingItem(
                    "Maria Oliveira",
                    "Excelente profissional, muito pontual!",
                  ),
                  _buildRatingItem(
                    "Carlos Souza",
                    "Resolveu o problema da fiação rapidamente.",
                  ),
                  const SizedBox(
                    height: 100,
                  ), // Espaço para não cobrir pelo botão
                ],
              ),
            ),
          ),
        ],
      ),
      // Botão flutuante para contratar ou chat
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: () {
            // Aqui abriria o chat (RF12)
            print("Abrindo chat com o profissional...");
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "Entrar em contato",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Eletricista",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                const Text(
                  "4.9",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  " (45 avaliações)",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        const Column(
          children: [
            Text(
              "R\$ 80",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              "visita técnica",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildServiceChips() {
    final servicos = ["Instalação", "Manutenção", "Quadros", "Automação"];
    return Wrap(
      spacing: 8,
      children: servicos.map((s) => Chip(label: Text(s))).toList(),
    );
  }

  Widget _buildRatingItem(String nome, String comentario) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(comentario, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
