import 'package:google_generative_ai/google_generative_ai.dart';
import '../screens/models.dart';

class AIService {
  // Obtenha sua chave GRATUITA em: https://ai.google.dev/
  // Clique em "Get API key" → "Create API key" (não precisa de cartão)
  static const String apiKey = 'AIzaSyDdyL9rwq8bohkpLzLxQGyt6WBbzmGzMZA';

  static bool get isConfigured =>
      apiKey != 'COLOQUE_SUA_CHAVE_AQUI' && apiKey.trim().isNotEmpty;

  final ChatSession _chat;

  AIService._(this._chat);

  factory AIService(List<Category> categories) {
    final model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
      systemInstruction: Content.system(_buildContext(categories)),
    );
    return AIService._(model.startChat());
  }

  static String _buildContext(List<Category> categories) {
    final sb = StringBuffer();
    sb.writeln(
      'Você é um assistente inteligente do aplicativo Organiza+, um sistema de controle de estoque.',
    );
    sb.writeln(
      'Responda sempre em português brasileiro, de forma clara e objetiva.',
    );
    sb.writeln('Quando listar dados, use formatação legível.');
    sb.writeln('');
    sb.writeln('=== DADOS ATUAIS DO INVENTÁRIO ===');

    if (categories.isEmpty) {
      sb.writeln('Nenhuma categoria cadastrada ainda.');
      return sb.toString();
    }

    int totalItems = 0;
    int totalQty = 0;
    Category? mostProducts = categories.first;
    Category? leastProducts = categories.first;

    for (final cat in categories) {
      final catQty = cat.products.fold<int>(0, (s, p) => s + p.quantity);
      totalItems += cat.products.length;
      totalQty += catQty;

      if (cat.products.length > mostProducts!.products.length)
        mostProducts = cat;
      if (cat.products.length < leastProducts!.products.length)
        leastProducts = cat;

      sb.writeln('');
      sb.writeln('Categoria: "${cat.name}"');
      sb.writeln('  Produtos distintos: ${cat.products.length}');
      sb.writeln('  Total em estoque: $catQty unidades');

      if (cat.products.isNotEmpty) {
        sb.writeln('  Lista de produtos:');
        for (final p in cat.products) {
          sb.writeln('    - ${p.name}: ${p.quantity} unidades');
        }
      }
    }

    sb.writeln('');
    sb.writeln('=== RESUMO GERAL ===');
    sb.writeln('Total de categorias: ${categories.length}');
    sb.writeln('Total de tipos de produtos: $totalItems');
    sb.writeln('Quantidade total em estoque: $totalQty unidades');
    sb.writeln(
      'Categoria com mais produtos: "${mostProducts?.name}" (${mostProducts?.products.length} tipos)',
    );
    sb.writeln(
      'Categoria com menos produtos: "${leastProducts?.name}" (${leastProducts?.products.length} tipos)',
    );

    return sb.toString();
  }

  Future<String> sendMessage(String message) async {
    const maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _chat.sendMessage(Content.text(message));
        return response.text ?? 'Sem resposta da IA.';
      } catch (e) {
        final err = e.toString().toLowerCase();

        if (err.contains('api_key_invalid') ||
            err.contains('api key not valid')) {
          return 'Chave API inválida. Verifique a chave em lib/services/ai_service.dart';
        }

        final isRateLimit =
            err.contains('429') ||
            err.contains('resource_exhausted') ||
            err.contains('too many requests') ||
            err.contains('quota exceeded');

        if (isRateLimit && attempt < maxRetries) {
          // Espera crescente: 2s, 4s, 6s antes de tentar de novo
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }

        if (isRateLimit) {
          return 'Limite de requisições atingido. O serviço gratuito do Gemini permite 15 req/min. Aguarde alguns segundos e tente novamente.';
        }

        return 'Erro: ${e.toString()}';
      }
    }

    return 'Não foi possível processar. Tente novamente em instantes.';
  }
}
