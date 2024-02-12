module jitlang.app;


void run(string[] args) {
    import jitlang.parser: Parser;
    import jitlang.backend.lightning;
    import std.stdio: writeln;

    auto ast = Parser("2+3").parse;
    ast.writeln;
    auto compiler = new JITCompiler;
    auto fun = compiler.compile(ast);
    fun().writeln;
}
