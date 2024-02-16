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

    void visit(in Literal lit) {
        dem_jit_movi(DEM_JIT_R0, lit.value);
        stackPush(DEM_JIT_R0);
    }

    void visit(in BinaryExpression expr) {
        expr.right.accept(this);
        expr.left.accept(this);

        stackPop(DEM_JIT_R0); // Pop left operand
        stackPop(DEM_JIT_R1); // Pop right operand

        final switch (expr.op) with(BinaryExpression.Op) {
            case Add:
                dem_jit_addr(DEM_JIT_R0, DEM_JIT_R0, DEM_JIT_R1);
                break;
            case Sub:
                dem_jit_subr(DEM_JIT_R0, DEM_JIT_R0, DEM_JIT_R1);
                break;
            case Mul:
                dem_jit_mulr(DEM_JIT_R0, DEM_JIT_R0, DEM_JIT_R1);
                break;
            case Div:
                dem_jit_divr(DEM_JIT_R0, DEM_JIT_R0, DEM_JIT_R1);
                break;
            case ShiftLeft:
                dem_jit_lshr(DEM_JIT_R0, DEM_JIT_R0, DEM_JIT_R1);
                break;
            case ShiftRight:
                dem_jit_rshr(DEM_JIT_R0, DEM_JIT_R0, DEM_JIT_R1);
                break;
        }
        stackPush(DEM_JIT_R0); // Push result back onto stack
    }

    void visit(in Function func) {
        _jit_prolog(_jit);
        stackPtr = _jit_allocai(_jit, 1024 * int.sizeof);

        func.body.accept(this);

        // Move the result from the stack to the return register
        stackPop(DEM_JIT_R0);

        _jit_ret(_jit);
        _jit_epilog(_jit);
    }

    void visit(in Identifier) {
        auto arg = _jit_arg(_jit, jit_code_arg_i);
        _jit_getarg_i(_jit, DEM_JIT_R0, arg);
        stackPush(DEM_JIT_R0);
    }

private:
    void emitAST(in ASTNode node) {
        import jitlang.ast: BinaryExpression, Literal;

        if (auto lit = cast(Literal)node) {
            dem_jit_movi(DEM_JIT_R0, lit.value);
            stackPush(DEM_JIT_R0);
        } else if (auto binOp = cast(BinaryExpression) node) {
            emitAST(binOp.right);
            emitAST(binOp.left);

            stackPop(DEM_JIT_R1); // Pop left operand
            stackPop(DEM_JIT_R0); // Pop right operand, now DEM_JIT_R0 has the left operand, DEM_JIT_R1 has the right operand

            switch (binOp.op) {
            case BinaryExpression.Op.Add:
                dem_jit_addr(DEM_JIT_R0, DEM_JIT_R0, DEM_JIT_R1);
                break;
            case BinaryExpression.Op.Sub:
                dem_jit_subr(DEM_JIT_R0, DEM_JIT_R0, DEM_JIT_R1);
                break;
            case BinaryExpression.Op.Mul:
                dem_jit_mulr(DEM_JIT_R0, DEM_JIT_R0, DEM_JIT_R1);
                break;
            case BinaryExpression.Op.Div:
                dem_jit_divr(DEM_JIT_R0, DEM_JIT_R0, DEM_JIT_R1);
                break;
            default:
                throw new Exception("Unsupported binary operation");
            }
            stackPush(DEM_JIT_R0); // Push result back onto stack
        } else {
            throw new Exception("Unsupported AST node type");
        }
    }

    void stackPush(int reg) {
        dem_jit_stxi_i(stackPtr, DEM_JIT_FP, reg);
        stackPtr += int.sizeof;
    }

    void stackPop(int reg) {
        stackPtr -= int.sizeof;
        dem_jit_ldxi_i(reg, DEM_JIT_FP, stackPtr);
    }
}
