module jitlang.parser;


import std.stdio;
import std.conv;
import std.algorithm;
import std.array;

struct Parser {

    import jitlang.ast: ASTNode;

    immutable(char)[] input;
    size_t pos;

    this(immutable(char)[] input) {
        this.input = input;
        this.pos = 0;
    }

    ASTNode parse() {
        auto result = parseExpr();
        skipWhitespace();
        if (pos < input.length) throw new Exception("Unexpected characters at end of input");
        return result;
    }

private:

    ASTNode parseExpr() {
        import jitlang.ast: BinaryExpression;

        auto left = parseTerm();
        while (true) {
            skipWhitespace();
            if (pos >= input.length) break;

            char op = input[pos];
            if (op != '+' && op != '-') break;

            pos++;
            auto right = parseTerm();
            left = new BinaryExpression(op == '+' ? BinaryExpression.Op.Add : BinaryExpression.Op.Sub, left, right);
        }
        return left;
    }

    ASTNode parseTerm() {
        import jitlang.ast: BinaryExpression;

        auto left = parseFactor();
        while (true) {
            skipWhitespace();
            if (pos >= input.length) break;

            if (lookAhead("<<")) {
                pos += 2; // Advance past the '<<'
                auto right = parseFactor();
                left = new BinaryExpression(BinaryExpression.Op.ShiftLeft, left, right);
            } else if (lookAhead(">>")) {
                pos += 2; // Advance past the '<<'
                auto right = parseFactor();
                left = new BinaryExpression(BinaryExpression.Op.ShiftRight, left, right);

            } else {
                char op = input[pos];
                if (op != '*' && op != '/') break;

                pos++;
                auto right = parseFactor();
                left = new BinaryExpression(op == '*' ? BinaryExpression.Op.Mul : BinaryExpression.Op.Div, left, right);
            }
        }
        return left;
    }

    ASTNode parseFactor() {
        import jitlang.ast: Literal;

        skipWhitespace();
        if (pos >= input.length) throw new Exception("Unexpected end of input");

        if (input[pos] == '(') {
            pos++; // Skip '('
            auto expr = parseExpr();
            skipWhitespace();
            if (pos >= input.length || input[pos] != ')') throw new Exception("Expected ')'");
            pos++; // Skip ')'
            return expr;
        } else {
            size_t start = pos;
            while (pos < input.length && isDigit(input[pos])) pos++;
            if (start == pos) throw new Exception("Expected number");
            return new Literal(to!int(input[start .. pos]));
        }
    }

    void skipWhitespace() {
        while (pos < input.length && isWhitespace(input[pos])) pos++;
    }

    bool isDigit(char c) {
        return c >= '0' && c <= '9';
    }

    bool isWhitespace(char c) {
        return c == ' ' || c == '\t' || c == '\n' || c == '\r';
    }

    bool lookAhead(string s) {
        return input[pos..$].startsWith(s);
    }
}
