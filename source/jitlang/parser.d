module jitlang.parser;


import std.stdio;
import std.conv;
import std.algorithm;
import std.array;

struct Parser {

    import jitlang.ast: ASTNode, Module, Type;

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
        import jitlang.ast: Function, Identifier, Type, U32, Array;

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
        Function.Parameter[] parameters;
        skipWhitespace();
        if (input[pos] != '(') throw new Exception("Expected '(' after function name");
        pos++; // Skip '('
        while (input[pos] != ')') {
            skipWhitespace();
            start = pos;
            while (pos < input.length && isAlphaNumeric(input[pos])) pos++;
            if (start == pos) throw new Exception("Expected parameter name");
            string paramName = input[start .. pos];

            skipWhitespace();
            if (input[pos] != ':')
                throw new Exception("Expected ':' after parameter name for type declaration");
            pos++; // Skip ':'
            Type paramType = parseType(); // Parse the type of the parameter

            parameters ~= Function.Parameter(paramName, paramType);

            skipWhitespace();
            if (input[pos] == ',') pos++; // Skip ',' to continue to the next parameter
        }
        pos++; // Skip ')'

        skipWhitespace();
        if (input[pos] != ':') throw new Exception("Expected ':' after parameters for return type declaration");
        pos++; // Skip ':'
        Type returnType = parseType(); // Parse the return type

        skipWhitespace();
        if (!lookAhead("=>")) throw new Exception("Expected '=>' after return type");
        pos += 2; // Advance past '=>'

        // Parse the function body
        ASTNode body = parseExpr();

        return new Function(name, parameters, body, returnType);
    }

    Type parseType() {
        import jitlang.ast: U32, Array;

        skipWhitespace();
        if (input[pos] == '[') {
            pos++; // Skip '['
            Type elementType = parseType(); // Recursively parse the element type
            skipWhitespace();
            if (input[pos] != ']') throw new Exception("Expected ']' after type in array declaration");
            pos++; // Skip ']'
            return new Array(elementType); // Create and return an Array type
        } else {
            // Assuming 'u32' is the only simple type for now
            string typeName = parseTypeName(); // Extract the type name, e.g., "u32"
            if (typeName == "u32") {
                return new U32();
            } else {
                throw new Exception("Unknown type: " ~ typeName);
            }
        }
    }

    string parseTypeName() {
        size_t start = pos;
        while (pos < input.length && isAlphaNumeric(input[pos])) pos++;
        return input[start .. pos];
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
        import jitlang.ast: Literal, Identifier, FunctionCall;

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
        // Handle function calls
        else if (isAlpha(input[pos])) {
            size_t start = pos;
            while (pos < input.length && (isAlpha(input[pos]) || isDigit(input[pos]))) pos++;
            string name = input[start .. pos];

            skipWhitespace();
            // Check for function call
            if (pos < input.length && input[pos] == '(') {
                pos++; // Skip '('
                ASTNode[] args = parseArguments();
                skipWhitespace();
                // no need to skip closing paren since done in `parseArguments`
                return new FunctionCall(name, args);
            } else {
                return new Identifier(name);
            }
        }
        else {
            throw new Exception("Expected expression");
        }
    }

    ASTNode[] parseArguments() {
        ASTNode[] args;
        skipWhitespace();

        // Check if we're immediately at the end of the argument list.
        if (pos < input.length && input[pos] == ')') {
            pos++; // Correctly skip the closing ')' for the current function call.
            return args; // Return the empty argument list.
        }

        while (pos < input.length) {
            args ~= parseExpr(); // Parse an argument expression.
            skipWhitespace();
            if (pos < input.length && input[pos] == ',') {
                pos++; // Skip the comma to parse the next argument.
                skipWhitespace();
            } else if (pos < input.length && input[pos] == ')') {
                pos++; // Correctly skip the closing ')' for the current function call.
                break; // Exit the loop, as we've found the end of the current argument list.
            } else {
                if (pos >= input.length)
                    throw new Exception("Unexpected end of input while parsing arguments");

                // If neither ',' nor ')' is found, it indicates an unexpected character.
                throw new Exception("Expected ',' or ')' in function arguments, found '" ~ input[pos] ~ "'");
            }
        }

        // No need for an additional check for exhausting input here, as the loop condition and breaks handle it.
        return args;
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
        static import std.ascii;
        return std.ascii.isAlpha(c);
    }

    static bool isAlphaNumeric(char c) @safe @nogc pure nothrow {
        static import std.ascii;
        return std.ascii.isAlphaNum(c);
    }
}
