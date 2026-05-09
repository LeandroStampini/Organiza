import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import 'models.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

class AIChatScreen extends StatefulWidget {
  final List<Category> categories;

  const AIChatScreen({super.key, required this.categories});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  late final AIService _ai;
  final List<_ChatMessage> _messages = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _loading = false;

  static const _suggestions = [
    'Quantos produtos tenho no total?',
    'Qual categoria tem mais produtos?',
    'Qual a quantidade total em estoque?',
    'Qual produto tem menor estoque?',
    'Liste todas as categorias',
  ];

  @override
  void initState() {
    super.initState();
    if (AIService.isConfigured) {
      _ai = AIService(widget.categories);
    }
    _messages.add(_ChatMessage(
      text: 'Olá! Sou seu assistente de inventário.\nPosso responder perguntas sobre seus produtos e categorias. Como posso ajudar?',
      isUser: false,
    ));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loading) return;

    setState(() {
      _messages.add(_ChatMessage(text: trimmed, isUser: true));
      _loading = true;
    });
    _input.clear();
    _scrollToBottom();

    final response = await _ai.sendMessage(trimmed);

    setState(() {
      _messages.add(_ChatMessage(text: response, isUser: false));
      _loading = false;
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AIService.isConfigured) {
      return _buildNotConfiguredScreen(context);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy_outlined, color: Color(0xFF2B4479)),
            SizedBox(width: 8),
            Text(
              'Assistente IA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B4479),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2B4479),
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildSuggestions(),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (_loading && i == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildBubble(_messages[i]);
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildNotConfiguredScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Assistente IA',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B4479)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2B4479),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.key_outlined, size: 56, color: Color(0xFF2B4479)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Configure sua Chave API',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B4479),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'O assistente usa Google Gemini (gratuito).\nSiga os passos abaixo para ativar:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            _buildStep('1', 'Acesse ai.google.dev no navegador'),
            _buildStep('2', 'Faça login com sua conta Google'),
            _buildStep('3', 'Clique em "Get API key" → "Create API key"'),
            _buildStep('4', 'Copie a chave gerada'),
            _buildStep('5', 'Abra o arquivo:\nlib/services/ai_service.dart'),
            _buildStep('6', 'Substitua COLOQUE_SUA_CHAVE_AQUI\npela sua chave'),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDE7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFB8860B)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFB8860B), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Não é necessário cartão de crédito.\nO plano gratuito tem 15 req/min e 1M tokens/dia.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B5500)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF2B4479),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text, style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) => ActionChip(
          label: Text(_suggestions[i], style: const TextStyle(fontSize: 12)),
          backgroundColor: const Color(0xFFF0F4FF),
          side: const BorderSide(color: Color(0xFF2B4479), width: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          onPressed: _loading ? null : () => _sendMessage(_suggestions[i]),
        ),
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF2B4479),
              child: Icon(Icons.smart_toy_outlined, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFB8860B) : const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isUser ? Colors.white : const Color(0xFF1A1A2E),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF2B4479),
            child: Icon(Icons.smart_toy_outlined, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox(
              width: 48,
              child: LinearProgressIndicator(
                color: Color(0xFF2B4479),
                backgroundColor: Color(0xFFD0D8F0),
                minHeight: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              enabled: !_loading,
              decoration: InputDecoration(
                hintText: 'Faça uma pergunta...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (v) => _sendMessage(v),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _loading ? null : () => _sendMessage(_input.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _loading ? Colors.grey.shade300 : const Color(0xFF2B4479),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                color: _loading ? Colors.grey : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
