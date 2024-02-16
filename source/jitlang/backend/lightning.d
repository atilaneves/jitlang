module jitlang.backend.lightning;

// apparently jitlang.bindings.lightning doesn't work
import lightning;

final class JITCompiler: imported!"jitlang.ast".ASTVisitor {

    import jitlang.ast;

    jit_state_t* _jit;
    int stackPtr;
    void*[] symbols;

    this() {
        _jit = jit_new_state();
        // HACK: FIXME
        lightning._jit = _jit;
    }

    ~this() {
        if (_jit) _jit_destroy_state(_jit);
        lightning._jit = null;
    }

    void visit(in Module module_) {
        import std.exception: enforce;
        import std.algorithm: map, filter;
        import std.array: array;

        jit_node_t*[] notes;

        foreach(node; module_.nodes.filter!(n => n.isFunction)) {
            // mark the start of this node
            notes ~= _jit_note(_jit, null, 0);
            // generate the code
            node.accept(this);
        }

        // emit all of the code
        enforce(_jit_emit(_jit) !is null, "JIT compilation failed");

        // convert to function pointer addresses
        symbols = notes
            .map!(n => _jit_address(_jit, n))
            .array
            ;
    }

    void visit(in Function func) {
        _jit_prolog(_jit);
        stackPtr = _jit_allocai(_jit, 1024 * int.sizeof);

        func.body.accept(this);

        // Move the result from the stack to the return register
        stackPop(R0);

        _jit_ret(_jit);
        _jit_epilog(_jit);
    }

    void visit(in BinaryExpression expr) {
        expr.right.accept(this);
        expr.left.accept(this);

        stackPop(R0); // Pop left operand
        stackPop(R1); // Pop right operand

        final switch (expr.op) with(BinaryExpression.Op) {
            case Add:
                dem_jit_addr(R0, R0, R1);
                break;
            case Sub:
                dem_jit_subr(R0, R0, R1);
                break;
            case Mul:
                dem_jit_mulr(R0, R0, R1);
                break;
            case Div:
                dem_jit_divr(R0, R0, R1);
                break;
            case ShiftLeft:
                dem_jit_lshr(R0, R0, R1);
                break;
            case ShiftRight:
                dem_jit_rshr(R0, R0, R1);
                break;
        }
        stackPush(R0); // Push result back onto stack
    }

    void visit(in Literal lit) {
        dem_jit_movi(R0, lit.value);
        stackPush(R0);
    }

    void visit(in Identifier) {
        auto arg = _jit_arg(_jit, jit_code_arg_i);
        _jit_getarg_i(_jit, R0, arg);
        stackPush(R0);
    }

private:
    void emitAST(in ASTNode node) {
        import jitlang.ast: BinaryExpression, Literal;

        if (auto lit = cast(Literal)node) {
            dem_jit_movi(R0, lit.value);
            stackPush(R0);
        } else if (auto binOp = cast(BinaryExpression) node) {
            emitAST(binOp.right);
            emitAST(binOp.left);

            stackPop(R1); // Pop left operand
            stackPop(R0); // Pop right operand, now R0 has the left operand, R1 has the right operand

            switch (binOp.op) {
            case BinaryExpression.Op.Add:
                dem_jit_addr(R0, R0, R1);
                break;
            case BinaryExpression.Op.Sub:
                dem_jit_subr(R0, R0, R1);
                break;
            case BinaryExpression.Op.Mul:
                dem_jit_mulr(R0, R0, R1);
                break;
            case BinaryExpression.Op.Div:
                dem_jit_divr(R0, R0, R1);
                break;
            default:
                throw new Exception("Unsupported binary operation");
            }
            stackPush(R0); // Push result back onto stack
        } else {
            throw new Exception("Unsupported AST node type");
        }
    }

    void stackPush(int reg) {
        dem_jit_stxi_i(stackPtr, FP, reg);
        stackPtr += int.sizeof;
    }

    void stackPop(int reg) {
        stackPtr -= int.sizeof;
        dem_jit_ldxi_i(reg, FP, stackPtr);
    }
}
