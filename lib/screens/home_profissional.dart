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
  bool _isOnline = false;
  bool _statusCarregado = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .get(),
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
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Erro ao carregar perfil."));
          }

          var dados = snapshot.data!.data() as Map<String, dynamic>;

          if (!_statusCarregado) {
            _isOnline = dados['isOnline'] ?? false;
            _statusCarregado = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(
                  dados['nome'],
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
  Widget _buildStatusCard(String nome) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _isOnline ? Colors.green : Colors.grey,
          radius: 8,
        ),
        title: Text("$nome, você está ${_isOnline ? 'Online' : 'Offline'}"),
        subtitle: Text(
          _isOnline ? "Visível para novos clientes" : "Invisível para buscas",
        ),
        trailing: Switch(
          value: _isOnline,
          onChanged: (val) async {
            setState(() => _isOnline = val);
            try {
              await FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(uid)
                  .update({'isOnline': val});
            } catch (e) {
              debugPrint("Erro ao atualizar status: $e");
            }
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
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard("Total de Pedidos", "0", Icons.assignment, Colors.blue),
        _buildStatCard("Avaliação", "N/A", Icons.star, Colors.orange),
        _buildStatCard(
          "Ganhos (Mês)",
          "R\$ 0,00",
          Icons.payments,
          Colors.green,
        ),
        _buildStatCard("Pendentes", "0", Icons.pending_actions, Colors.red),
      ],
    );
  }

  Widget _buildOrderList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 2,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(top: 12),
          child: ListTile(
            title: Text("Instalação Elétrica - Exemplo ${index + 1}"),
            subtitle: const Text("Bairro: Candelária • Hoje, 14:00"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        );
      },
    );
  }
}
