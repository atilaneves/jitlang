module jitlang.ast;

interface ASTVisitor {
    void visit(in Literal lit);
    void visit(in BinaryExpression expr);
}

class ASTNode {
    abstract void accept(ASTVisitor visitor) const;

    override string toString() @safe pure scope const {
        assert(0);
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
