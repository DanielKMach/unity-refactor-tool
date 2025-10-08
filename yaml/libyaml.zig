const c = @import("c.zig");

pub const LibyamlError = error{LibyamlError};

const String = ?[*:0]u8;

pub const EncodingType = enum(c_int) {
    any = c.YAML_ANY_ENCODING,
    utf8 = c.YAML_UTF8_ENCODING,
    utf16_le = c.YAML_UTF16LE_ENCODING,
    utf16_be = c.YAML_UTF16BE_ENCODING,
};

pub const BreakType = enum(c_int) {
    any = c.YAML_ANY_BREAK,
    line = c.YAML_LINE_BREAK,
    space = c.YAML_SPACE_BREAK,
};

pub const ErrorType = enum(c_int) {
    no_error = c.YAML_NO_ERROR,
    memory = c.YAML_MEMORY_ERROR,
    reader = c.YAML_READER_ERROR,
    scanner = c.YAML_SCANNER_ERROR,
    parser = c.YAML_PARSER_ERROR,
    composer = c.YAML_COMPOSER_ERROR,
    writer = c.YAML_WRITER_ERROR,
    emitter = c.YAML_EMITTER_ERROR,
};

pub const ScalarStyle = enum(c_int) {
    any = c.YAML_ANY_SCALAR_STYLE,
    plain = c.YAML_PLAIN_SCALAR_STYLE,
    single_quoted = c.YAML_SINGLE_QUOTED_SCALAR_STYLE,
    double_quoted = c.YAML_DOUBLE_QUOTED_SCALAR_STYLE,
    literal = c.YAML_LITERAL_SCALAR_STYLE,
    folded = c.YAML_FOLDED_SCALAR_STYLE,
};

pub const SequenceStyle = enum(c_int) {
    any = c.YAML_ANY_SEQUENCE_STYLE,
    block = c.YAML_BLOCK_SEQUENCE_STYLE,
    flow = c.YAML_FLOW_SEQUENCE_STYLE,
};

pub const MappingStyle = enum(c_int) {
    any = c.YAML_ANY_MAPPING_STYLE,
    block = c.YAML_BLOCK_MAPPING_STYLE,
    flow = c.YAML_FLOW_MAPPING_STYLE,
};

pub const TokenType = enum(c_int) {
    no_token = c.YAML_NO_TOKEN,
    stream_start = c.YAML_STREAM_START_TOKEN,
    stream_end = c.YAML_STREAM_END_TOKEN,
    version_directive = c.YAML_VERSION_DIRECTIVE_TOKEN,
    tag_directive = c.YAML_TAG_DIRECTIVE_TOKEN,
    document_start = c.YAML_DOCUMENT_START_TOKEN,
    document_end = c.YAML_DOCUMENT_END_TOKEN,
    block_sequence_start = c.YAML_BLOCK_SEQUENCE_START_TOKEN,
    block_mapping_start = c.YAML_BLOCK_MAPPING_START_TOKEN,
    block_end = c.YAML_BLOCK_END_TOKEN,
    flow_sequence_start = c.YAML_FLOW_SEQUENCE_START_TOKEN,
    flow_sequence_end = c.YAML_FLOW_SEQUENCE_END_TOKEN,
    flow_mapping_start = c.YAML_FLOW_MAPPING_START_TOKEN,
    flow_mapping_end = c.YAML_FLOW_MAPPING_END_TOKEN,
    block_entry = c.YAML_BLOCK_ENTRY_TOKEN,
    flow_entry = c.YAML_FLOW_ENTRY_TOKEN,
    key = c.YAML_KEY_TOKEN,
    value = c.YAML_VALUE_TOKEN,
    alias = c.YAML_ALIAS_TOKEN,
    anchor = c.YAML_ANCHOR_TOKEN,
    tag = c.YAML_TAG_TOKEN,
    scalar = c.YAML_SCALAR_TOKEN,
};

pub const EventType = enum(c_int) {
    no_event = c.YAML_NO_EVENT,
    stream_start = c.YAML_STREAM_START_EVENT,
    stream_end = c.YAML_STREAM_END_EVENT,
    document_start = c.YAML_DOCUMENT_START_EVENT,
    document_end = c.YAML_DOCUMENT_END_EVENT,
    alias = c.YAML_ALIAS_EVENT,
    anchor = c.YAML_ANCHOR_EVENT,
    tag = c.YAML_TAG_EVENT,
    scalar = c.YAML_SCALAR_EVENT,
    sequence_start = c.YAML_SEQUENCE_START_EVENT,
    sequence_end = c.YAML_SEQUENCE_END_EVENT,
    mapping_start = c.YAML_MAPPING_START_EVENT,
    mapping_end = c.YAML_MAPPING_END_EVENT,
};

pub const NodeType = enum(c_int) {
    no_node = c.YAML_NO_NODE,
    scalar = c.YAML_SCALAR_NODE,
    sequence = c.YAML_SEQUENCE_NODE,
    mapping = c.YAML_MAPPING_NODE,
};

pub const ParserState = enum(c_int) {
    stream_start = c.YAML_STREAM_START_STATE,
    implicit_document_start = c.YAML_IMPLICIT_DOCUMENT_START_STATE,
    document_start = c.YAML_DOCUMENT_START_STATE,
    document_content = c.YAML_DOCUMENT_CONTENT_STATE,
    document_end = c.YAML_DOCUMENT_END_STATE,
    block_sequence_first_entry = c.YAML_BLOCK_SEQUENCE_FIRST_ENTRY_STATE,
    block_sequence_entry = c.YAML_BLOCK_SEQUENCE_ENTRY_STATE,
    block_mapping_first_key = c.YAML_BLOCK_MAPPING_FIRST_KEY_STATE,
    block_mapping_key = c.YAML_BLOCK_MAPPING_KEY_STATE,
    block_mapping_value = c.YAML_BLOCK_MAPPING_VALUE_STATE,
    flow_sequence_first_entry = c.YAML_FLOW_SEQUENCE_FIRST_ENTRY_STATE,
    flow_sequence_entry = c.YAML_FLOW_SEQUENCE_ENTRY_STATE,
    flow_sequence_entry_mapping_key = c.YAML_FLOW_SEQUENCE_ENTRY_MAPPING_KEY_STATE,
    flow_sequence_entry_mapping_value = c.YAML_FLOW_SEQUENCE_ENTRY_MAPPING_VALUE_STATE,
    flow_mapping_first_key = c.YAML_FLOW_MAPPING_FIRST_KEY_STATE,
    flow_mapping_key = c.YAML_FLOW_MAPPING_KEY_STATE,
    flow_mapping_empty_value = c.YAML_FLOW_MAPPING_EMPTY_VALUE_STATE,
    flow_mapping_value = c.YAML_FLOW_MAPPING_VALUE_STATE,
    block_scalar_first_line = c.YAML_BLOCK_SCALAR_FIRST_LINE_STATE,
    block_scalar_more_lines = c.YAML_BLOCK_SCALAR_MORE_LINES_STATE,
    plain_scalar_first_line = c.YAML_PLAIN_SCALAR_FIRST_LINE_STATE,
    plain_scalar_more_lines = c.YAML_PLAIN_SCALAR_MORE_LINES_STATE,
};

pub const Mark = extern struct {
    index: usize,
    line: usize,
    column: usize,
};

pub const StreamStartToken = extern struct {
    encoding: EncodingType,
};

pub const AliasToken = extern struct {
    value: String,
};

pub const AnchorToken = extern struct {
    value: String,
};

pub const TagToken = extern struct {
    handle: String,
    suffix: String,
};

pub const ScalarToken = extern struct {
    value: String,
    length: usize,
    style: ScalarStyle = .any,
};

pub const VersionDirective = extern struct {
    major: c_int,
    minor: c_int,
};

pub const TagDirective = extern struct {
    handle: String,
    prefix: String,
};

pub const TokenData = extern union {
    stream_start: StreamStartToken,
    alias: AliasToken,
    anchor: AnchorToken,
    tag: TagToken,
    scalar: ScalarToken,
    version_directive: VersionDirective,
    tag_directive: TagDirective,
};

pub const Token = extern struct {
    type: TokenType,
    data: TokenData,
    start_mark: Mark,
    end_mark: Mark,

    pub fn deinit(self: *Token) void {
        c.yaml_token_delete(self);
    }
};

pub const TagDirectiveList = extern struct {
    start: ?*TagDirective,
    end: ?*TagDirective,

    pub fn asSlice(self: TagDirectiveList) []TagDirective {
        return self.start.?[0..self.len()];
    }

    pub fn len(self: TagDirectiveList) usize {
        return self.end.? - self.start.?;
    }
};

pub const StreamStartEvent = extern struct {
    encoding: EncodingType,
};

pub const DocumentStartEvent = extern struct {
    version_directive: ?*VersionDirective,
    tag_directives: TagDirectiveList,
    implicit: c_int,
};
pub const DocumentEndEvent = extern struct {
    implicit: c_int,
};
pub const AliasEvent = extern struct {
    anchor: String,
};
pub const ScalarEvent = extern struct {
    anchor: String,
    tag: String,
    value: String,
    length: usize,
    plain_implicit: c_int,
    quoted_implicit: c_int,
    style: ScalarStyle = .any,
};
pub const SequenceStartEvent = extern struct {
    anchor: String,
    tag: String,
    implicit: c_int,
    style: SequenceStyle = .any,
};
pub const MappingStartEvent = extern struct {
    anchor: String,
    tag: String,
    implicit: c_int,
    style: MappingStyle = .any,
};
const EventData = extern union {
    stream_start: StreamStartEvent,
    document_start: DocumentStartEvent,
    document_end: DocumentEndEvent,
    alias: AliasEvent,
    scalar: ScalarEvent,
    sequence_start: SequenceStartEvent,
    mapping_start: MappingStartEvent,
};
pub const Event = extern struct {
    type: EventType,
    data: EventData,
    start_mark: Mark,
    end_mark: Mark,

    pub fn initStreamStart(encoding: EncodingType) LibyamlError!Event {
        var event: Event = undefined;
        return wrap(Event, event, c.yaml_stream_start_event_initialize(&event, encoding));
    }

    pub fn initStreamEnd() LibyamlError!Event {
        var event: Event = undefined;
        return wrap(Event, event, c.yaml_stream_end_event_initialize(&event));
    }

    pub fn initDocumentStart(
        version_directive: ?*VersionDirective,
        tag_directives: TagDirectiveList,
        implicit: bool,
    ) LibyamlError!Event {
        var event: Event = undefined;
        return wrap(Event, event, c.yaml_document_start_event_initialize(
            &event,
            version_directive,
            tag_directives.start,
            tag_directives.end,
            if (implicit) 1 else 0,
        ));
    }

    pub fn initDocumentEnd(implicit: bool) LibyamlError!Event {
        var event: Event = undefined;
        return wrap(Event, event, c.yaml_document_end_event_initialize(&event, if (implicit) 1 else 0));
    }

    pub fn initAlias(anchor: String) LibyamlError!Event {
        var event: Event = undefined;
        return wrap(Event, event, c.yaml_alias_event_initialize(&event, anchor));
    }

    pub fn initScalar(
        anchor: String,
        tag: String,
        value: String,
        length: usize,
        plain_implicit: bool,
        quoted_implicit: bool,
        style: ScalarStyle,
    ) LibyamlError!Event {
        var event: Event = undefined;
        return wrap(Event, event, c.yaml_scalar_event_initialize(
            &event,
            anchor,
            tag,
            value,
            length,
            if (plain_implicit) 1 else 0,
            if (quoted_implicit) 1 else 0,
            style,
        ));
    }

    pub fn initSequenceStart(
        anchor: String,
        tag: String,
        implicit: bool,
        style: SequenceStyle,
    ) LibyamlError!Event {
        var event: Event = undefined;
        return wrap(Event, event, c.yaml_sequence_start_event_initialize(
            &event,
            anchor,
            tag,
            if (implicit) 1 else 0,
            style,
        ));
    }

    pub fn initSequenceEnd() LibyamlError!Event {
        var event: Event = undefined;
        return wrap(Event, event, c.yaml_sequence_end_event_initialize(&event));
    }

    pub fn initMappingStart(
        anchor: String,
        tag: String,
        implicit: bool,
        style: MappingStyle,
    ) LibyamlError!Event {
        var event: Event = undefined;
        return wrap(Event, event, c.yaml_mapping_start_event_initialize(
            &event,
            anchor,
            tag,
            if (implicit) 1 else 0,
            style,
        ));
    }

    pub fn initMappingEnd() LibyamlError!Event {
        var event: Event = undefined;
        return wrap(Event, event, c.yaml_mapping_end_event_initialize(&event));
    }

    pub fn deinit(self: *Event) void {
        c.yaml_event_delete(self);
    }
};

const ScalarNode = extern struct {
    value: String,
    length: usize,
    style: ScalarStyle = .any,

    pub fn slice(self: ScalarNode) []const u8 {
        return self.value[0..self.length];
    }
};
const ItemStack = extern struct {
    start: ?*c_int,
    end: ?*c_int,
    top: ?*c_int,

    pub fn asSlice(self: ItemStack) []c_int {
        return self.start.?[0..self.len()];
    }

    pub fn len(self: ItemStack) usize {
        return self.top.? - self.start.?;
    }
};
const SequenceNode = extern struct {
    items: ItemStack,
    style: SequenceStyle = .any,
};
pub const NodePair = extern struct {
    key: c_int,
    value: c_int,

    pub fn keyNode(self: NodePair, doc: *Document) *Node {
        return doc.nodes.get(self.key) orelse unreachable;
    }

    pub fn valueNode(self: NodePair, doc: *Document) *Node {
        return doc.nodes.get(self.value) orelse unreachable;
    }
};
const NodePairStack = extern struct {
    start: ?*NodePair,
    end: ?*NodePair,
    top: ?*NodePair,

    pub fn asSlice(self: NodePairStack) []NodePair {
        return self.start.?[0..self.len()];
    }

    pub fn len(self: NodePairStack) usize {
        return self.top.? - self.start.?;
    }
};
const MappingNode = extern struct {
    pairs: NodePairStack,
    style: MappingStyle = .any,
};
const NodeData = extern union {
    scalar: ScalarNode,
    sequence: SequenceNode,
    mapping: MappingNode,
};
pub const Node = extern struct {
    type: NodeType,
    tag: String,
    data: NodeData,
    start_mark: Mark,
    end_mark: Mark,
};

const NodeStack = extern struct {
    start: ?*Node,
    end: ?*Node,
    top: ?*Node,

    pub fn asSlice(self: NodeStack) []Node {
        return self.start.?[0..self.len()];
    }

    pub fn get(self: NodeStack, id: c_int) ?*Node {
        if (id <= 0 or id > self.len()) return null;
        return &self.asSlice()[id - 1];
    }

    pub fn len(self: NodeStack) usize {
        return self.top.? - self.start.?;
    }
};
pub const Document = extern struct {
    nodes: NodeStack,
    version_directive: *VersionDirective,
    tag_directives: TagDirectiveList,
    start_implicit: c_int,
    end_implicit: c_int,
    start_mark: Mark,
    end_mark: Mark,

    pub fn init(version_directive: *VersionDirective, tag_directives: TagDirectiveList, start_implicit: bool, end_implicit: bool) LibyamlError!Document {
        var doc: Document = undefined;
        return wrap(Document, doc, c.yaml_document_initialize(
            &doc,
            version_directive,
            tag_directives.start,
            tag_directives.end,
            if (start_implicit) 1 else 0,
            if (end_implicit) 1 else 0,
        ));
    }

    pub fn deinit(self: *Document) void {
        c.yaml_document_delete(self);
    }

    pub fn rootNode(self: *Document) ?*Node {
        return c.yaml_document_get_root_node(self);
    }

    pub fn addScalar(self: *Document, tag: String, value: []const u8, style: ScalarStyle) LibyamlError!*Node {
        const id = try wrapGet(c.yaml_document_add_scalar(self, tag, value.ptr, value.len, style));
        return self.getNode(id);
    }

    pub fn addSequence(self: *Document, tag: String, style: SequenceStyle) LibyamlError!*Node {
        const id = try wrapGet(c.yaml_document_add_sequence(self, tag, style));
        return self.getNode(id);
    }

    pub fn addMapping(self: *Document, tag: String, style: MappingStyle) LibyamlError!*Node {
        const id = try wrapGet(c.yaml_document_add_mapping(self, tag, style));
        return self.getNode(id);
    }

    pub fn appendItem(self: *Document, sequence: *Node, item: *Node) LibyamlError!void {
        assert(sequence.type == .sequence);
        _ = try wrapGet(c.yaml_document_append_sequence_item(self, self.getId(sequence), self.getId(item)));
    }

    pub fn appendPair(self: *Document, mapping: *Node, key: *Node, value: *Node) LibyamlError!void {
        assert(mapping.type == .mapping);
        _ = try wrapGet(c.yaml_document_append_mapping_pair(self, self.getId(mapping), self.getId(key), self.getId(value)));
    }

    pub fn appendPairNamed(self: *Document, mapping: *Node, key: []const u8, value: *Node) LibyamlError!void {
        assert(mapping.type == .mapping);
        const key_node = try self.addScalar(null, key, .plain);
        try self.appendPair(mapping, key_node, value);
    }

    fn getId(self: *Document, node: *Node) c_int {
        assert(node >= self.nodes.start.? and node <= self.nodes.top.?);
        return node - self.nodes.start.? + 1;
    }
};

pub const ReadHandler = fn (?*anyopaque, [*c]u8, usize, [*c]usize) callconv(.c) c_int;

pub const SimpleKey = extern struct {
    possible: c_int,
    required: c_int,
    token_number: usize,
    mark: Mark,
};

pub const AliasData = extern struct {
    anchor: String,
    index: c_int,
    mark: Mark,
};
const StringBuffer = extern struct {
    start: ?*u8,
    end: ?*u8,
    current: ?*u8,
};
const Input = extern union {
    string: StringBuffer,
    file: [*c]c.FILE,
};
const Buffer = extern struct {
    start: ?*u8,
    end: ?*u8,
    pointer: ?*u8,
    last: ?*u8,
};
const RawBuffer = extern struct {
    start: ?*u8,
    end: ?*u8,
    pointer: ?*u8,
    last: ?*u8,
};
const TokenList = extern struct {
    start: ?*Token,
    end: ?*Token,
    head: ?*Token,
    tail: ?*Token,
};
const IndentStack = extern struct {
    start: ?*c_int,
    end: ?*c_int,
    top: ?*c_int,
};
const SimpleKeyStack = extern struct {
    start: ?*SimpleKey,
    end: ?*SimpleKey,
    top: ?*SimpleKey,
};
const StateStack = extern struct {
    start: ?*ParserState,
    end: ?*ParserState,
    top: ?*ParserState,
};
const MarkStack = extern struct {
    start: ?*Mark,
    end: ?*Mark,
    top: ?*Mark,
};
const TagDirectiveStack = extern struct {
    start: ?*TagDirective,
    end: ?*TagDirective,
    top: ?*TagDirective,
};
const AliasStack = extern struct {
    start: ?*AliasData,
    end: ?*AliasData,
    top: ?*AliasData,
};
pub const Parser = extern struct {
    @"error": ErrorType,
    problem: [*c]const u8,
    problem_offset: usize,
    problem_value: c_int,
    problem_mark: Mark,
    context: [*c]const u8,
    context_mark: Mark,
    read_handler: ?*const ReadHandler,
    read_handler_data: ?*anyopaque,
    input: Input,
    eof: c_int,
    buffer: Buffer,
    unread: usize,
    raw_buffer: RawBuffer,
    encoding: EncodingType,
    offset: usize,
    mark: Mark,
    stream_start_produced: c_int,
    stream_end_produced: c_int,
    flow_level: c_int,
    tokens: TokenList,
    tokens_parsed: usize,
    token_available: c_int,
    indents: IndentStack,
    indent: c_int,
    simple_key_allowed: c_int,
    simple_keys: SimpleKeyStack,
    states: StateStack,
    state: ParserState,
    marks: MarkStack,
    tag_directives: TagDirectiveStack,
    aliases: AliasStack,
    document: ?*Document,
};

fn assert(ok: bool) void {
    if (!ok) unreachable;
}

fn wrap(comptime T: type, val: T, err: c_int) !T {
    return if (err == 0) error.LibyamlError else val;
}

fn wrapGet(val: c_int) !c_int {
    return if (val == 0) error.LibyamlError else val;
}

pub fn versionString() [*:0]const u8 {
    return c.yaml_get_version_string();
}

pub fn version() [3]c_int {
    var v: [3]c_int = undefined;
    c.yaml_get_version(&v[0], &v[1], &v[2]);
    return v;
}
