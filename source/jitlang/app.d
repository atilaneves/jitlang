module jitlang.app;

void run(string[] args) {
    import jitlang.parser: Parser;
    import jitlang.backend.lightning: JITCompiler;
    import jitlang.io: log;
    import std.stdio: stdout;
    import std.file: readText;

    scope(exit)
        stdout.log("Finished");

    stdout.log("Start");

    const options = Options(args);
    stdout.log("Source file: ", options.fileName);
    const source = readText(options.fileName);
    stdout.log("Read source file");

    const nodes = Parser(source).parse;
    stdout.log("Parsed source file");
    notLog(nodes);

    auto compiler = new JITCompiler;
    stdout.log("Compiling...");
    const symbols = compiler.compile(nodes);
    stdout.log("Compiled");

    foreach(symbol; symbols) {
        // FIXME: use type information to get the right cast
        auto fun = cast(int function(int)) symbol;
        notLog(fun(options.arg));
    }
}

private struct Options {

    string fileName;
    int arg;

    this(string[] args) {
        import std.algorithm: countUntil;
        import std.conv: to;

        if(args.length < 2)
            throw new Exception("Usage: jit filename");

        fileName = args[1];

        const indexOfDashDash = args.countUntil("--");
        arg = indexOfDashDash == -1
            ? 7
            : args[indexOfDashDash + 1].to!int;
    }
}

private void notLog(A...)(auto ref A args) {
    import std.stdio: writeln;
    writeln("\n", args, "\n");
}
