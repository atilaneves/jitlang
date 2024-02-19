module jitlang.ast;

interface ASTVisitor {
    void visit(in Module);
    void visit(in Function);
    void visit(in Literal);
    void visit(in BinaryExpression);
    void visit(in Identifier);
    void visit(in FunctionCall);
}

class ASTNode {
    abstract void accept(ASTVisitor visitor) const;

    override string toString() @safe pure scope const {
        assert(0);
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

    override string toString() @safe pure scope const {
        import std.conv: text;
        return text(nodes);
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

    override string toString() @safe pure scope const {
        import std.conv: text;
        return text("IntLiteral(", value, ")");
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

    override string toString() @safe pure scope const {
        import std.conv: text;
        return text("BinExp(", op, ", ", left, ", ", right, ")");
    }
}

abstract class Type {
}

class U32: Type {

}

class Array: Type {
    Type element;

    this(Type element) {
        this.element = element;
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

    override string toString() @safe pure scope const {
        import std.conv: text;
        return text("Function ", name, " (", parameters, ") => ", body);
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

    override string toString() @safe pure scope const {
        import std.conv: text;
        return text("Identifier(", name, ")");
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

    override string toString() @safe pure scope const {
        import std.conv: text;
        return text(`FunctionCall(`, name, `, `, args, `)`);
    }
}
