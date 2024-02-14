module jitlang.ast;

interface ASTVisitor {
    void visit(in Function);
    void visit(in Literal);
    void visit(in BinaryExpression);
    void visit(in Identifier);
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

class Function : ASTNode {
    string name;
    ASTNode[] parameters;
    ASTNode body;

    this(string name, ASTNode[] parameters, ASTNode body) {
        this.name = name;
        this.parameters = parameters;
        this.body = body;
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
