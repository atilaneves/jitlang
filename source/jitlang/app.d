module jitlang.app;


void run(string[] args) {
    import jitlang.parser: Parser;
    import jitlang.backend.lightning;
    import std.stdio: writeln;
    import std.file: readText;

    if(args.length < 2)
        throw new Exception("Usage: jit filename");

    const fileName = args[1];
    const source = readText(fileName);
    const nodes = Parser(source).parse;

    nodes.writeln;
    auto compiler = new JITCompiler;
    const fun = compiler.compile(nodes[0]); // FIXME
    fun(4).writeln;
}
