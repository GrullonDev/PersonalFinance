import 'package:flutter/material.dart';

/// Bloque de una respuesta de la IA ya interpretado.
sealed class AiBlock {
  const AiBlock();
}

class AiHeading extends AiBlock {
  const AiHeading(this.text);
  final String text;
}

class AiParagraph extends AiBlock {
  const AiParagraph(this.text);
  final String text;
}

class AiListItem extends AiBlock {
  const AiListItem(this.text, {this.marker = '•'});
  final String text;
  final String marker;
}

/// Convierte el Markdown sencillo que devuelve la IA (títulos, listas,
/// **negritas**) en bloques, para no mostrar asteriscos ni almohadillas.
List<AiBlock> parseAiMessage(String raw) {
  final blocks = <AiBlock>[];
  final bullet = RegExp(r'^\s*[-*•]\s+(.*)$');
  final numbered = RegExp(r'^\s*(\d+)[.)]\s+(.*)$');
  final heading = RegExp(r'^\s*#{1,6}\s+(.*)$');
  final paragraph = StringBuffer();

  void flush() {
    if (paragraph.isEmpty) return;
    blocks.add(AiParagraph(paragraph.toString().trim()));
    paragraph.clear();
  }

  for (final line in raw.replaceAll('\r', '').split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      flush();
      continue;
    }
    final h = heading.firstMatch(line);
    final b = bullet.firstMatch(line);
    final n = numbered.firstMatch(line);
    if (h != null) {
      flush();
      blocks.add(AiHeading(_stripBold(h.group(1)!)));
    } else if (b != null) {
      flush();
      blocks.add(AiListItem(b.group(1)!.trim()));
    } else if (n != null) {
      flush();
      blocks.add(AiListItem(n.group(2)!.trim(), marker: '${n.group(1)}.'));
    } else if (RegExp(r'^\*\*[^*]+\*\*:?$').hasMatch(trimmed)) {
      // Línea completa en negrita → título.
      flush();
      blocks.add(AiHeading(_stripBold(trimmed)));
    } else {
      if (paragraph.isNotEmpty) paragraph.write(' ');
      paragraph.write(trimmed);
    }
  }
  flush();
  return blocks;
}

String _stripBold(String s) =>
    s.replaceAll('**', '').replaceAll('__', '').trim();

/// Texto con `**negritas**` convertido a spans.
List<TextSpan> parseInlineBold(String text, TextStyle base) {
  final spans = <TextSpan>[];
  final pattern = RegExp(r'\*\*(.+?)\*\*|__(.+?)__');
  var last = 0;
  for (final m in pattern.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start), style: base));
    }
    spans.add(
      TextSpan(
        text: m.group(1) ?? m.group(2),
        style: base.copyWith(fontWeight: FontWeight.w700),
      ),
    );
    last = m.end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: base));
  }
  return spans;
}

/// Muestra una respuesta de la IA con títulos, viñetas y negritas.
class AiMessageText extends StatelessWidget {
  const AiMessageText({
    required this.text,
    required this.color,
    required this.accent,
    super.key,
  });

  final String text;
  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontSize: 14.5, height: 1.45, color: color);
    final blocks = parseAiMessage(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : _gapBefore(blocks, i)),
            child: _buildBlock(blocks[i], base),
          ),
      ],
    );
  }

  double _gapBefore(List<AiBlock> blocks, int i) {
    if (blocks[i] is AiHeading) return 12;
    if (blocks[i] is AiListItem && blocks[i - 1] is AiListItem) return 4;
    return 8;
  }

  Widget _buildBlock(AiBlock block, TextStyle base) => switch (block) {
    AiHeading(:final text) => Text(
      text,
      style: base.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: accent,
      ),
    ),
    AiParagraph(:final text) => Text.rich(
      TextSpan(children: parseInlineBold(text, base)),
    ),
    AiListItem(:final text, :final marker) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: marker.length > 1 ? 22 : 16,
          child: Text(
            marker,
            style: base.copyWith(color: accent, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Text.rich(TextSpan(children: parseInlineBold(text, base))),
        ),
      ],
    ),
  };
}
