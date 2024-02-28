module jitlang.ast;

interface ASTVisitor {
    void visit(in Module);
    void visit(in Function);
    void visit(in Literal);
    void visit(in BinaryExpression);
    void visit(in Identifier);
    void visit(in FunctionCall);
    void visit(in ArrayLiteral);
    void visit(in ArrayIndexing);
}

class ASTNode {
    abstract void accept(ASTVisitor visitor) const;

    override string toString() @safe pure scope const {
        return toStringImpl(0);
    }

    protected string toStringImpl(int depth) const @safe pure scope {
        assert(0, "This method should be overridden in subclasses.");
        return "";
    }

    protected static string indent(int depth) @trusted pure scope {
        auto ret = new char[depth* 4];
        ret[] = ' ';
        return cast(typeof(return)) ret;
    }

    bool isFunction() @safe @nogc pure scope nothrow const {
        return false;
    }
}

class Module: ASTNode {

    ASTNode[] nodes;

    this(ASTNode[] nodes) @safe @nogc pure nothrow {
        this.nodes = nodes;
    }

    override void accept(ASTVisitor visitor) const {
        visitor.visit(this);
    }

    override string toStringImpl(int depth) const @safe pure scope {
        string repr = indent(depth) ~ "Module:\n";
        foreach (node; nodes) {
            repr ~= node.toStringImpl(depth + 1) ~ "\n";
        }
        return repr;
    }
}

class Literal : ASTNode {
    int value;

    this(int value) {
        this.value = value;
    }

    override void accept(ASTVisitor visitor) const {
        visitor.visit(this);
    }

    override protected string toStringImpl(int depth) const @safe pure scope {
        import std.conv: text;
        return indent(depth) ~ "Literal: " ~ value.text;
    }
}

class BinaryExpression : ASTNode {
    enum Op {
        Add,
        Sub,
        Mul,
        Div,
        ShiftLeft,
        ShiftRight,
        Or,
        And,
    }

    Op op;
    ASTNode left;
    ASTNode right;

    this(Op op, ASTNode left, ASTNode right) {
        this.op = op;
        this.left = left;
        this.right = right;
    }

    override void accept(ASTVisitor visitor) const {
        visitor.visit(this);
    }

  override protected string toStringImpl(int depth) const @safe pure scope {
      import std.conv: text;
      return text(indent(depth), "BinaryExpression: ", op, "\n",
                  left.toStringImpl(depth + 1), "\n",
                  right.toStringImpl(depth + 1));
    }
}

abstract class Type {
    override string toString() @safe pure scope const {
        assert(0);
    }
}

class U32: Type {
    override string toString() const @safe @nogc pure scope {
        return "u32";
    }
}

class Array: Type {
    Type element;

    this(Type element) {
        this.element = element;
    }

    override string toString() const @safe pure scope {
        import std.conv: text;
        return text(`[`, element, `]`);
    }
}

class Function : ASTNode {

    static struct Parameter {
        string name;
        Type type;
    }

    string name;
    Parameter[] parameters;
    ASTNode body;
    Type returnType;

    this(string name, Parameter[] parameters, ASTNode body, Type returnType) {
        this.name = name;
        this.parameters = parameters;
        this.body = body;
        this.returnType = returnType;
    }

    override bool isFunction() @safe @nogc pure scope nothrow const {
        return true;
    }

    override void accept(ASTVisitor visitor) const {
        visitor.visit(this);
    }

    override string toStringImpl(int depth) const @safe pure scope {
        string repr = indent(depth) ~ "Function " ~ name ~ ":\n";
        repr ~= indent(depth + 1) ~ "Parameters:\n";
        foreach (param; parameters) {
            repr ~= indent(depth + 2) ~ param.name ~ ": " ~ param.type.toString() ~ "\n";
        }
        repr ~= indent(depth + 1) ~ "Return Type: " ~ returnType.toString() ~ "\n";
        repr ~= indent(depth + 1) ~ "Body:\n" ~ body.toStringImpl(depth + 2);
        return repr;
    }
}

class Identifier : ASTNode {
    string name;

    this(string name) {
        this.name = name;
    }

    override void accept(ASTVisitor visitor) const {
        visitor.visit(this);
    }

    override protected string toStringImpl(int depth) const @safe pure scope {
        import std.conv: text;
        return text(indent(depth), "Identifier: ", name);
    }
}

class FunctionCall : ASTNode {
    string name;
    ASTNode[] args;

    this(string name, ASTNode[] args) {
        this.name = name;
        this.args = args;
    }

    override void accept(ASTVisitor visitor) const {
        visitor.visit(this);
    }

    override string toStringImpl(int depth) @safe pure scope const {
        import std.conv: text;
        return text(indent(depth), `FunctionCall(`, name, `, `, args, `)`);
    }
}

class ArrayLiteral : ASTNode {
    ASTNode[] elements;

    this(ASTNode[] elements) {
        this.elements = elements;
    }

    override void accept(ASTVisitor visitor) const {
        visitor.visit(this);
    }

    override protected string toStringImpl(int depth) const @safe pure scope {
        import std.algorithm: map, joiner;
        import std.conv: text;

        return text(
            indent(depth),
            "ArrayLiteral: [\n",
            elements.map!(e => e.toStringImpl(depth + 4)).joiner(",\n"),
            "\n",
            indent(depth), "]",
        );
    }
}

class ArrayIndexing : ASTNode {
    string array;
    ASTNode index;

    this(string array, ASTNode index) {
        this.array = array;
        this.index = index;
    }

    override void accept(ASTVisitor visitor) const {
        visitor.visit(this);
    }

    override protected string toStringImpl(int depth) const @safe pure scope {
        import std.conv: text;
        return text(indent(depth), "ArrayIndexing:\n",
                    indent(depth + 1), "identifier: ", array, "\n",
                    indent(depth + 1), "Index:\n",
                    index.toStringImpl(depth + 2));
    }
}
