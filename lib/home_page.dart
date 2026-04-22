import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'ai_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  final AiService _aiService = AiService();
  bool _cargando = false;

  Future<void> _guardarTarea() async {
    if (_controller.text.isEmpty) return;
    setState(() => _cargando = true);
    try {
      final datosIA = await _aiService.procesarTarea(_controller.text);
      await FirebaseFirestore.instance.collection('tareas').add({
        'titulo': datosIA['titulo'],
        'prioridad': datosIA['prioridad'],
        'categoria': datosIA['categoria'],
        'fecha': DateTime.now(),
      });
      _controller.clear();
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("¡IA ha organizado tu tarea!")),
      );
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Enfoque Inteligente", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 100.0, left: 20, right: 20),
          child: Column(
            children: [
              //SECCIÓN DE ENTRADA
              FadeInDown(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "¿Qué tienes pendiente hoy?",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.auto_awesome, color: Colors.deepPurpleAccent),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _cargando
                  ? const CircularProgressIndicator(color: Colors.deepPurpleAccent)
                  : FadeInUp(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _guardarTarea,
                          icon: const Icon(Icons.bolt),
                          label: const Text("ANALIZAR CON INTELIGENCIA ARTIFICIAL"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurpleAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 25),

              //DASHBOARD DE RESUMEN
              StreamBuilder(
                stream: FirebaseFirestore.instance.collection('tareas').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  int total = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return FadeIn(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn("Pendientes", total.toString(), Icons.format_list_bulleted),
                          const VerticalDivider(color: Colors.white24, thickness: 1),
                          _buildStatColumn("Estado", total > 0 ? "Activo" : "Libre", Icons.bolt),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),
              const Row(
                children: [
                  Text("LISTA ORGANIZADA", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
                  Expanded(child: Divider(indent: 10, color: Colors.white10)),
                ],
              ),
              const SizedBox(height: 15),

              //LISTA DE TAREAS
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance.collection('tareas').orderBy('fecha', descending: true).snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        String prioridad = doc['prioridad'] ?? 'Media';
                        Color colorPrio = prioridad == 'Alta' ? Colors.redAccent : (prioridad == 'Media' ? Colors.orangeAccent : (prioridad == 'Baja' ? Colors.greenAccent : Colors.grey));
                        return FadeInRight(
                          delay: Duration(milliseconds: 100 * index),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(15),
                              border: Border(left: BorderSide(color: colorPrio, width: 6)),
                            ),
                            child: ListTile(
                              title: Text(doc['titulo'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text("${doc['categoria']} • $prioridad", style: const TextStyle(color: Colors.white38)),
                              trailing: IconButton(
                                icon: const Icon(Icons.check_circle_outline, color: Colors.white24),
                                onPressed: () => doc.reference.delete(),
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
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurpleAccent, size: 20),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }
}