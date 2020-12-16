enum AttributeScope {
  INLINE, // refer to https://quilljs.com/docs/formats/#inline
  BLOCK, // refer to https://quilljs.com/docs/formats/#block
  EMBEDS, // refer to https://quilljs.com/docs/formats/#embeds
}

class Attribute<T> {
  final String key;
  final AttributeScope scope;
  T value;

  Attribute(this.key, this.scope, this.value);

  static final Map<String, Attribute> _registry = {
    Attribute.bold.key: Attribute.bold,
    Attribute.italic.key: Attribute.italic,
    Attribute.underline.key: Attribute.underline,
    Attribute.strikeThrough.key: Attribute.strikeThrough,
    Attribute.link.key: Attribute.link,
    Attribute.header.key: Attribute.header,
    Attribute.list.key: Attribute.list,
    Attribute.codeBlock.key: Attribute.codeBlock,
    Attribute.blockQuote.key: Attribute.blockQuote,
  };

  static BoldAttribute bold = BoldAttribute();

  static ItalicAttribute italic = ItalicAttribute();

  static UnderlineAttribute underline = UnderlineAttribute();

  static StrikeThroughAttribute strikeThrough = StrikeThroughAttribute();

  static LinkAttribute link = LinkAttribute();

  static HeaderAttribute header = HeaderAttribute(1);

  static ListAttribute list = ListAttribute('ordered');

  static CodeBlockAttribute codeBlock = CodeBlockAttribute();

  static BlockQuoteAttribute blockQuote = BlockQuoteAttribute();

  static Attribute<int> get h1 => header.level1;

  static Attribute<int> get h2 => header.level2;

  static Attribute<int> get h3 => header.level3;

  static Attribute<String> get ul => list.bullet;

  static Attribute<String> get ol => list.ordered;

  bool get isInline => scope == AttributeScope.INLINE;

  static Attribute fromKeyValue(String key, dynamic value) {
    if (!_registry.containsKey(key)) {
      throw ArgumentError.value(key, 'key "$key" not found.');
    }
    Attribute attribute = _registry[key];
    if (value != null) {
      attribute.value = value;
    }
    return attribute;
  }
}

class BoldAttribute extends Attribute<bool> {
  BoldAttribute() : super('bold', AttributeScope.INLINE, true);
}

class ItalicAttribute extends Attribute<bool> {
  ItalicAttribute() : super('italic', AttributeScope.INLINE, true);
}

class UnderlineAttribute extends Attribute<bool> {
  UnderlineAttribute() : super('underline', AttributeScope.INLINE, true);
}

class StrikeThroughAttribute extends Attribute<bool> {
  StrikeThroughAttribute() : super('strike', AttributeScope.INLINE, true);
}

class LinkAttribute extends Attribute<String> {
  LinkAttribute() : super('link', AttributeScope.INLINE, '');
}

class HeaderAttribute extends Attribute<int> {
  HeaderAttribute(int level) : super('header', AttributeScope.BLOCK, level);

  // H1 in HTML
  Attribute<int> get level1 => Attribute<int>(key, scope, 1);

  // H2 in HTML
  Attribute<int> get level2 => Attribute<int>(key, scope, 2);

  // H3 in HTML
  Attribute<int> get level3 => Attribute<int>(key, scope, 3);
}

class ListAttribute extends Attribute<String> {
  ListAttribute(String val) : super('list', AttributeScope.BLOCK, val);

  // "attributes":{"list":"ordered"}
  Attribute<String> get ordered => Attribute<String>(key, scope, 'ordered');

  // "attributes":{"list":"bullet"}
  Attribute<String> get bullet => Attribute<String>(key, scope, 'bullet');
}

class CodeBlockAttribute extends Attribute<bool> {
  CodeBlockAttribute() : super('code-block', AttributeScope.BLOCK, true);
}

class BlockQuoteAttribute extends Attribute<bool> {
  BlockQuoteAttribute() : super('blockquote', AttributeScope.BLOCK, true);
}
