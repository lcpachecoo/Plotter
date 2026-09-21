import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/section_header.dart';

/// Tela de ajuda: explica ao usuário como a aplicação está organizada e
/// quais recursos de acessibilidade estão disponíveis.
///
/// Serve como "mapa de navegação" dentro do próprio aplicativo, acessível a
/// partir de Ajustes e do menu lateral em telas largas.
class AjudaScreen extends StatelessWidget {
  const AjudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isWide(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajuda e acessibilidade')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 700 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              SectionHeader(title: 'Como navegar'),
              SizedBox(height: 12),
              _ItemAjuda(
                icone: Icons.dashboard_outlined,
                titulo: 'Quatro seções principais',
                texto:
                    'Talhões, Histórico, Relatórios e Ajustes ficam sempre a um toque '
                    'de distância: na barra inferior no celular e no menu lateral em '
                    'telas maiores.',
              ),
              SizedBox(height: 12),
              _ItemAjuda(
                icone: Icons.touch_app_outlined,
                titulo: 'Abrir um talhão',
                texto:
                    'Toque em qualquer cartão de talhão no Dashboard para ver cultura, '
                    'estágio e aplicações. De lá é possível lançar um registro ou '
                    'editar o talhão.',
              ),
              SizedBox(height: 12),
              _ItemAjuda(
                icone: Icons.arrow_back,
                titulo: 'Voltar',
                texto:
                    'A seta na barra superior e o gesto/botão "voltar" do aparelho '
                    'retornam à tela anterior. Dentro das seções, voltar leva à aba '
                    'Talhões antes de fechar o aplicativo.',
              ),
              SizedBox(height: 12),
              _ItemAjuda(
                icone: Icons.add_circle_outline,
                titulo: 'Ações rápidas',
                texto:
                    'O botão verde flutuante, no canto inferior direito, cria um novo '
                    'talhão no Dashboard e um novo registro no Histórico.',
              ),
              SizedBox(height: 28),
              SectionHeader(title: 'Recursos de acessibilidade'),
              SizedBox(height: 12),
              _ItemAjuda(
                icone: Icons.record_voice_over_outlined,
                titulo: 'Leitores de tela',
                texto:
                    'Todos os botões, ícones e cartões possuem rótulo descritivo em '
                    'português. Mudanças de aba, filtros e confirmações são anunciadas '
                    'automaticamente pelo TalkBack (Android) e pelo VoiceOver (iOS).',
              ),
              SizedBox(height: 12),
              _ItemAjuda(
                icone: Icons.format_size,
                titulo: 'Tamanho do texto',
                texto:
                    'O aplicativo acompanha o tamanho de fonte configurado no sistema. '
                    'Os textos e cartões se reorganizam sem cortar conteúdo.',
              ),
              SizedBox(height: 12),
              _ItemAjuda(
                icone: Icons.contrast,
                titulo: 'Contraste e alvos de toque',
                texto:
                    'As cores de texto atendem ao contraste mínimo de 4,5:1 e todos os '
                    'elementos tocáveis têm ao menos 48 dp, facilitando o uso com luvas '
                    'ou sob sol forte.',
              ),
              SizedBox(height: 12),
              _ItemAjuda(
                icone: Icons.keyboard_alt_outlined,
                titulo: 'Teclado',
                texto:
                    'É possível percorrer os campos e botões com Tab e acionar com '
                    'Enter/Espaço. O item em foco recebe uma borda verde destacada.',
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemAjuda extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String texto;

  const _ItemAjuda({
    required this.icone,
    required this.titulo,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    // MergeSemantics faz o leitor de tela ler título e explicação como um
    // único bloco, em vez de dois fragmentos soltos.
    return MergeSemantics(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(icone, color: AppTheme.primaryGreen, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(texto, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
