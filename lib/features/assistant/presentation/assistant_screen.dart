import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency.dart';
import '../../../core/formatting.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../budgets/data/budgets_repository.dart';
import '../../categories/data/categories_repository.dart';
import '../../goals/data/goals_repository.dart';
import '../../transactions/data/transactions_repository.dart';
import '../data/ai_chat_repository.dart';
import '../data/ai_settings.dart';
import '../data/chat_message.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _messages = <ChatMessage>[];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(aiSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettingsDialog(settings),
          ),
        ],
      ),
      body: settings.isConfigured ? _buildChat(context) : _buildSetupPrompt(),
    );
  }

  Widget _buildSetupPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smart_toy_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              'Conecta tu asistente de IA',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Pega tu API key para empezar a hacerle preguntas sobre tus '
              'finanzas (compatible con OpenAI o cualquier proveedor con la '
              'misma API).',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  _openSettingsDialog(ref.read(aiSettingsProvider)),
              child: const Text('Configurar API key'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChat(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Text(
                    'Pregúntame sobre tus gastos, presupuestos o metas.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) =>
                      _MessageBubble(message: _messages[index]),
                ),
        ),
        if (_sending) const LinearProgressIndicator(),
        SafeArea(
          minimum: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  enabled: !_sending,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu pregunta...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.send),
                onPressed: _sending ? null : _send,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _inputController.clear();
      _sending = true;
    });
    _scrollToBottom();

    try {
      final settings = ref.read(aiSettingsProvider);
      final systemPrompt = await _buildSystemPrompt();
      final reply = await ref
          .read(aiChatRepositoryProvider)
          .send(
            settings: settings,
            systemPrompt: systemPrompt,
            history: _messages,
          );
      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: reply));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: '⚠️ $e'));
      });
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  Future<String> _buildSystemPrompt() async {
    final currency = ref.read(currencyProvider);
    final accounts = await ref
        .read(accountsRepositoryProvider)
        .watchAll()
        .first;
    final transactions = await ref
        .read(transactionsRepositoryProvider)
        .watchAll()
        .first;
    final categories = await ref
        .read(categoriesRepositoryProvider)
        .watchAll()
        .first;
    final goals = await ref.read(goalsRepositoryProvider).watchAll().first;
    final now = DateTime.now();
    final budgets = await ref
        .read(budgetsRepositoryProvider)
        .watchForMonth(now.month, now.year)
        .first;
    final categoryById = {for (final c in categories) c.id: c};

    final balance = accounts.fold<double>(0, (s, a) => s + a.currentBalance);
    final monthTx = transactions.where(
      (t) => t.date.month == now.month && t.date.year == now.year,
    );
    final incomeMonth = monthTx
        .where((t) => t.type == 'income')
        .fold<double>(0, (s, t) => s + t.amount);
    final expenseMonth = monthTx
        .where((t) => t.type == 'expense')
        .fold<double>(0, (s, t) => s + t.amount);

    final spendByCategory = <String, double>{};
    for (final t in monthTx) {
      if (t.type != 'expense') continue;
      final name = categoryById[t.categoryId]?.name ?? 'Otro';
      spendByCategory[name] = (spendByCategory[name] ?? 0) + t.amount;
    }
    final topCategories = spendByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final buffer = StringBuffer()
      ..writeln(
        'Eres el asistente financiero dentro de la app Finanzas 360. '
        'Responde en español, de forma breve y concreta, usando los datos '
        'reales del usuario que se listan abajo cuando sean relevantes. '
        'No inventes cifras que no estén aquí.',
      )
      ..writeln('Moneda: ${currency.code} (${currency.symbol})')
      ..writeln('Balance total: ${formatCurrency(balance, currency)}')
      ..writeln('Ingresos del mes: ${formatCurrency(incomeMonth, currency)}')
      ..writeln('Gastos del mes: ${formatCurrency(expenseMonth, currency)}');

    if (topCategories.isNotEmpty) {
      buffer.writeln('Gastos del mes por categoría:');
      for (final e in topCategories.take(8)) {
        buffer.writeln('- ${e.key}: ${formatCurrency(e.value, currency)}');
      }
    }
    if (budgets.isNotEmpty) {
      buffer.writeln('Presupuestos del mes:');
      for (final b in budgets) {
        final spent = spendByCategory[categoryById[b.categoryId]?.name] ?? 0;
        buffer.writeln(
          '- ${categoryById[b.categoryId]?.name ?? 'Otro'}: '
          '${formatCurrency(spent, currency)} de ${formatCurrency(b.limitAmount, currency)}',
        );
      }
    }
    if (goals.isNotEmpty) {
      buffer.writeln('Metas de ahorro:');
      for (final g in goals) {
        buffer.writeln(
          '- ${g.name}: ${formatCurrency(g.currentAmount, currency)} de '
          '${formatCurrency(g.targetAmount, currency)}',
        );
      }
    }
    return buffer.toString();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openSettingsDialog(AiSettings current) async {
    final apiKeyController = TextEditingController(text: current.apiKey);
    final baseUrlController = TextEditingController(text: current.baseUrl);
    final modelController = TextEditingController(text: current.model);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configurar asistente de IA'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: apiKeyController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'API key'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'Base URL (opcional)',
                  hintText: AiSettings.defaultBaseUrl,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: 'Modelo (opcional)',
                  hintText: AiSettings.defaultModel,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(aiSettingsProvider.notifier)
                  .save(
                    apiKey: apiKeyController.text.trim(),
                    baseUrl: baseUrlController.text.trim(),
                    model: modelController.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final color = isUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final textColor = isUser ? Theme.of(context).colorScheme.onPrimary : null;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message.content, style: TextStyle(color: textColor)),
      ),
    );
  }
}
