module jitlang.parser;


import std.stdio;
import std.conv;
import std.algorithm;
import std.array;

struct Parser {

    import jitlang.ast: ASTNode, Module;

    string input;
    size_t pos;

    this(string input) {
        this.input = input;
        this.pos = 0;
    }

    Module parse() {
        ASTNode[] nodes;

        while(pos < input.length) {
            skipWhitespace();
            if (lookAhead("fn")) {
                nodes ~= parseFunction();
            } else {
                nodes ~= parseExpr();
                skipWhitespace();
            }
        }

        return new Module(nodes);
    }

    ASTNode parseFunction() {
        import jitlang.ast: Function, Identifier;

        skipWhitespace();
        if (!lookAhead("fn")) throw new Exception("Expected 'fn' for function definition");
        pos += 2; // Advance past 'fn'
        skipWhitespace();

        // Parse the function name
        size_t start = pos;
        while (pos < input.length && isAlpha(input[pos])) pos++;
        if (start == pos) throw new Exception("Expected function name");
        string name = input[start .. pos];

        // Parse parameters
        ASTNode[] parameters;
        skipWhitespace();
        if (input[pos] != '(') throw new Exception("Expected '(' after function name");
        pos++; // Skip '('
        while (input[pos] != ')') {
            skipWhitespace();
            start = pos;
            while (pos < input.length && isAlpha(input[pos])) pos++;
            if (start == pos) throw new Exception("Expected parameter name");
            parameters ~= new Identifier(input[start .. pos]);
            skipWhitespace();
            if (input[pos] == ',') pos++; // Skip ','
        }
        pos++; // Skip ')'

        skipWhitespace();
        if (!lookAhead("=>")) throw new Exception("Expected '=>' after parameters");
        pos += 2; // Advance past '=>'

        // Parse the function body
        ASTNode body = parseExpr();

        return new Function(name, parameters, body);
    }

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
            left = new BinaryExpression(
                op == '+' ? BinaryExpression.Op.Add : BinaryExpression.Op.Sub,
                left,
                right,
            );
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
                left = new BinaryExpression(
                    op == '*' ? BinaryExpression.Op.Mul : BinaryExpression.Op.Div,
                    left,
                    right,
                );
            }
        }
        return left;
    }

    ASTNode parseFactor() {
        import jitlang.ast: Literal, Identifier;

        skipWhitespace();
        if (pos >= input.length) throw new Exception("Unexpected end of input");

        // Handle parentheses for grouped expressions
        if (input[pos] == '(') {
            pos++; // Skip '('
            auto expr = parseExpr();
            skipWhitespace();
            if (pos >= input.length || input[pos] != ')') throw new Exception("Expected ')'");
            pos++; // Skip ')'
            return expr;
        }
        // Handle numeric literals
        else if (isDigit(input[pos])) {
            size_t start = pos;
            while (pos < input.length && isDigit(input[pos])) pos++;
            return new Literal(to!int(input[start .. pos]));
        }
        // Handle identifiers
        else if (isAlpha(input[pos])) {
            size_t start = pos;
            while (pos < input.length && (isAlpha(input[pos]) || isDigit(input[pos]))) pos++;
            string name = input[start .. pos];
            return new Identifier(name);
        }
        else {
            throw new Exception("Expected expression");
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

    static bool isAlpha(char c) @safe @nogc pure nothrow {
        return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
    }

}
