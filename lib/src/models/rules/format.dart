import '../documents/attribute.dart';
import '../quill_delta.dart';
import 'rule.dart';

abstract class FormatRule extends Rule {
  const FormatRule();

  @override
  RuleType get type => RuleType.FORMAT;

  @override
  void validateArgs(int? len, Object? data, Attribute? attribute) {
    assert(len != null);
    assert(data == null);
    assert(attribute != null);
  }
}

/// Produces Delta with line-level attributes applied strictly to
/// newline characters.
class ResolveLineFormatRule extends FormatRule {
  const ResolveLineFormatRule();

  @override
  Delta? applyRule(Delta document, int index,
      {int? len, Object? data, Attribute? attribute}) {
    if (attribute!.scope != AttributeScope.BLOCK) {
      return null;
    }

    // Apply line styles to all newline characters within range of this
    // retain operation.
    var result = Delta()..retain(index);
    final itr = DeltaIterator(document)..skip(index);
    Operation op;
    for (var cur = 0; cur < len! && itr.hasNext; cur += op.length!) {
      op = itr.next(len - cur);
      final opText = op.data is String ? op.data as String : '';
      if (!opText.contains('\n')) {
        result.retain(op.length!);
        continue;
      }
      final text = op.data as String;
      final tmp = Delta();
      var offset = 0;

      final removedBlocks = _getRemovedBlocks(attribute, op);

      for (var lineBreak = text.indexOf('\n');
          lineBreak >= 0;
          lineBreak = text.indexOf('\n', offset)) {
        tmp
          ..retain(lineBreak - offset)
          ..retain(1, attribute.toJson()..addEntries(removedBlocks));
        offset = lineBreak + 1;
      }
      tmp.retain(text.length - offset);
      result = result.concat(tmp);
    }

    while (itr.hasNext) {
      op = itr.next();
      final text = op.data is String ? (op.data as String?)! : '';
      final lineBreak = text.indexOf('\n');
      if (lineBreak < 0) {
        result.retain(op.length!);
        continue;
      }

      final removedBlocks = _getRemovedBlocks(attribute, op);
      result
        ..retain(lineBreak)
        ..retain(1, attribute.toJson()..addEntries(removedBlocks));
      break;
    }
    return result;
  }

  Iterable<MapEntry<String, dynamic>> _getRemovedBlocks(
      Attribute<dynamic> attribute, Operation op) {
    // Enforce Block Format exclusivity by rule
    if (!Attribute.exclusiveBlockKeys.contains(attribute.key)) {
      return <MapEntry<String, dynamic>>[];
    }

    return op.attributes?.keys
            .where((key) =>
                Attribute.exclusiveBlockKeys.contains(key) &&
                attribute.key != key &&
                attribute.value != null)
            .map((key) => MapEntry<String, dynamic>(key, null)) ??
        [];
  }
}

/// Allows updating link format with collapsed selection.
class FormatLinkAtCaretPositionRule extends FormatRule {
  const FormatLinkAtCaretPositionRule();

  @override
  Delta? applyRule(Delta document, int index,
      {int? len, Object? data, Attribute? attribute}) {
    if (attribute!.key != Attribute.link.key || len! > 0) {
      return null;
    }

    final delta = Delta();
    final itr = DeltaIterator(document);
    final before = itr.skip(index), after = itr.next();
    int? beg = index, retain = 0;
    if (before != null && before.hasAttribute(attribute.key)) {
      beg -= before.length!;
      retain = before.length;
    }
    if (after.hasAttribute(attribute.key)) {
      if (retain != null) retain += after.length!;
    }
    if (retain == 0) {
      return null;
    }

    delta
      ..retain(beg)
      ..retain(retain!, attribute.toJson());
    return delta;
  }
}

/// Produces Delta with inline-level attributes applied too all characters
/// except newlines.
class ResolveInlineFormatRule extends FormatRule {
  const ResolveInlineFormatRule();

  @override
  Delta? applyRule(Delta document, int index,
      {int? len, Object? data, Attribute? attribute}) {
    if (attribute!.scope != AttributeScope.INLINE) {
      return null;
    }

    final delta = Delta()..retain(index);
    final itr = DeltaIterator(document)..skip(index);

    Operation op;
    for (var cur = 0; cur < len! && itr.hasNext; cur += op.length!) {
      op = itr.next(len - cur);
      final text = op.data is String ? (op.data as String?)! : '';
      var lineBreak = text.indexOf('\n');
      if (lineBreak < 0) {
        delta.retain(op.length!, attribute.toJson());
        continue;
      }
      var pos = 0;
      while (lineBreak >= 0) {
        delta
          ..retain(lineBreak - pos, attribute.toJson())
          ..retain(1);
        pos = lineBreak + 1;
        lineBreak = text.indexOf('\n', pos);
      }
      if (pos < op.length!) {
        delta.retain(op.length! - pos, attribute.toJson());
      }
    }

    return delta;
  }
}
