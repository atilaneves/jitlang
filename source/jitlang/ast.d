module jitlang.ast;


class ASTNode {
    override string toString() @safe pure scope const {
        assert(0);
    }
}

class Literal : ASTNode {
    int value;

    this(int value) {
        this.value = value;
    }

    override string toString() @safe pure scope const {
        import std.conv: text;
        return text("IntLiteral(", value, ")");
    }
}

class BinaryExpression : ASTNode {
    enum Op { Add, Sub, Mul, Div }

    Op op;
    ASTNode left;
    ASTNode right;

    this(Op op, ASTNode left, ASTNode right) {
        this.op = op;
        this.left = left;
        this.right = right;
    }

    override string toString() @safe pure scope const {
        import std.conv: text;
        return text("BinExp(", op, ", ", left, ", ", right, ")");
    }
}
