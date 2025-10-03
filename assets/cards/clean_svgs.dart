import 'dart:io';

void main() async {
  final svgDir = Directory('svgs');
  if (!await svgDir.exists()) {
    stdout.writeln('SVG directory not found!');
    return;
  }

  final files = svgDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.svg'));

  for (final file in files) {
  stdout.writeln('Processing ${file.path}...');
    String content = await file.readAsString();
    
    // Remove sodipodi and inkscape namespace declarations
    content = content.replaceAll(RegExp(r'\s+xmlns:sodipodi="[^"]*"'), '');
    content = content.replaceAll(RegExp(r'\s+xmlns:inkscape="[^"]*"'), '');
    
    // Remove sodipodi and inkscape attributes from svg tag
    content = content.replaceAll(RegExp(r'\s+inkscape:[^=]+="[^"]*"'), '');
    content = content.replaceAll(RegExp(r'\s+sodipodi:[^=]+="[^"]*"'), '');
    
    // Remove sodipodi:namedview element (both self-closing and with content)
    content = content.replaceAll(
      RegExp(
        r'<sodipodi:namedview[^>]*/>',
        multiLine: true,
      ),
      '',
    );
    content = content.replaceAll(
      RegExp(
        r'<sodipodi:namedview[^>]*>[\s\S]*?</sodipodi:namedview>', 
        multiLine: true,
      ),
      '',
    );
    
    // Remove empty defs element (both self-closing and with content)
    content = content.replaceAll(
      RegExp(r'<defs[^>]*/>', multiLine: true),
      '',
    );
    content = content.replaceAll(
      RegExp(r'<defs[^>]*>\s*</defs>', multiLine: true),
      '',
    );
    
    // Remove metadata element and its content
    content = content.replaceAll(
      RegExp(r'<metadata[^>]*>[\s\S]*?</metadata>', multiLine: true),
      '',
    );
    
    // Clean up extra whitespace
    content = content.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
    
    await file.writeAsString(content);
    stdout.writeln('  ✓ Cleaned');
  }

  stdout.writeln('\nDone! Cleaned ${files.length} SVG files.');
}
