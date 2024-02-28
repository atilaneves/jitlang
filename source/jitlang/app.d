module jitlang.app;

private:

public void run(string[] args) {
    import jitlang.parser: Parser;
    import jitlang.backend.lightning: JITCompiler;
    import jitlang.io: log, sink;
    import std.file: readText;

    scope(exit)
        sink.log("Finished");

    sink.log("Start");

    const options = Options(args);
    sink.log("Source file: ", options.fileName);
    const source = readText(options.fileName);
    sink.log("Read source file");

    auto main = mainFunc(source);
    sink.log("Main: ", main(options.arg));
}

alias MainFunc = extern(C) int function(int);

public MainFunc mainFunc(in string source) {
    import jitlang.parser: Parser;
    import jitlang.backend.lightning: JITCompiler;
    import jitlang.io: log, sink;

    const module_ = Parser(source).parse;
    sink.log("Parsed source");
    notLog(module_);
    sink.log("Printed");

    sink.log("Creating JIT compiler");
    auto compiler = new JITCompiler;
    sink.log("Compiling...");
    compiler.visit(module_);
    sink.log("Compiled");

    if("main" !in compiler.symbols)
        throw new Exception("No main function");

    return cast(MainFunc) compiler.symbols["main"];
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
