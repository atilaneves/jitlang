module jitlang.backend.lightning;

// apparently jitlang.bindings.lightning doesn't work
import lightning;

final class JITCompiler: imported!"jitlang.ast".ASTVisitor {

    import jitlang.ast;

    jit_state_t* _jit;
    int stackPtr;
    void*[string] symbols;

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
        import jitlang.ast: Function;
        import std.exception: enforce;
        import std.algorithm: map, filter;
        import std.array: array;

        jit_node_t*[] notes;

        auto functions = module_
            .nodes
            .filter!(n => n.isFunction)
            .map!(f => cast(Function) f)
            ;

        foreach(node; functions.save) {
            // mark the start of this node
            notes ~= _jit_note(_jit, null, 0);
            // generate the code
            node.accept(this);
        }

        // emit all of the code
        enforce(_jit_emit(_jit) !is null, "JIT compilation failed");

        // convert to function pointer addresses
        foreach(i; 0 .. notes.length) {
            symbols[functions.array[i].name] = _jit_address(_jit, notes[i]);

        }
    }

    void visit(in Function func) {
        _jit_prolog(_jit);
        stackPtr = _jit_allocai(_jit, 1024 * int.sizeof);

        func.body.accept(this);

        _jit_ret(_jit);
        _jit_epilog(_jit);
    }

    void visit(in FunctionCall call) {
        if(call.args.length > 3)
            throw new Exception("Can only handle functions of up to 3 parameters");

        if(call.name !in symbols)
            throw new Exception("No symbol found for function `" ~ call.name ~ "`");

        _jit_prepare(_jit);

        foreach(i, arg; call.args) {
            arg.accept(this);
            pushargr(R0);
        }

        _jit_finishi(_jit, symbols[call.name]);
    }

    void visit(in BinaryExpression expr) {
        expr.right.accept(this);
        movr(V0, R0);
        expr.left.accept(this);
        movr(V1, R0);

        final switch (expr.op) with(BinaryExpression.Op) {
            case Add:
                addr(R0, V0, V1);
                break;
            case Sub:
                subr(R0, V0, V1);
                break;
            case Mul:
                mulr(R0, V0, V1);
                break;
            case Div:
                divr(R0, V0, V1);
                break;
            case ShiftLeft:
                lshr(R0, V0, V1);
                break;
            case ShiftRight:
                rshr(R0, V0, V1);
                break;
        }
    }

    void visit(in Literal lit) {
        movi(R0, lit.value);
    }

    void visit(in Identifier) {
        // FIXME: this assumes there's only one parameter and that the
        // value is in R0
        auto arg = _jit_arg(_jit, jit_code_arg_i);
        _jit_getarg_i(_jit, R0, arg);
    }

private:

    // push a register onto the stack
    void stackPush(int reg) {
        stxi_i(stackPtr, FP, reg);
        stackPtr += int.sizeof;
    }

    // pop a value from the stack into a register
    void stackPop(int reg) {
        stackPtr -= int.sizeof;
        ldxi_i(reg, FP, stackPtr);
    }
}
