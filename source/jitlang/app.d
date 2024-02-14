module jitlang.app;


void run(string[] args) {
    import jitlang.parser: Parser;
    import jitlang.backend.lightning;
    import jitlang.io: log;
    import std.stdio: writeln, stdout;
    import std.file: readText;

    scope(exit)
        stdout.log("Finished");

    if(args.length < 2)
        throw new Exception("Usage: jit filename");

    const fileName = args[1];
    const source = readText(fileName);
    stdout.log("Read source file");

    const nodes = Parser(source).parse;
    stdout.log("Parsed source file");
    writeln("\n", nodes, "\n");

    auto compiler = new JITCompiler;
    stdout.log("Compiling...");
    const symbols = compiler.compile(nodes);
    stdout.log("Compiled");

    const fun = cast(int function(int)) symbols[0];

    writeln("\n", fun(2), "\n");
}
