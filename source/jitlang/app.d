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

    const module_ = Parser(source).parse;
    stdout.log("Parsed source file");
    notLog(module_);
    stdout.log("Printed");

    stdout.log("Creating JIT compiler");
    auto compiler = new JITCompiler;
    stdout.log("Compiling...");
    compiler.visit(module_);
    stdout.log("Compiled");

    if("main" !in compiler.symbols)
        throw new Exception("No main function");

    alias MainFunc = extern(C) int function(int);
    auto main = cast(MainFunc) compiler.symbols["main"];
    stdout.log("Main: ", main(options.arg));
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
