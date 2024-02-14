module jitlang.app;


void run(string[] args) {
    import jitlang.parser: Parser;
    import jitlang.backend.lightning;
    import std.stdio: writeln;
    import std.file: readText;
    import std.datetime: Clock;

    const startTime = Clock.currTime;

    auto sinceStart() {
        import std.datetime: Clock;
        return (Clock.currTime - startTime).total!"msecs";
    }

    string secondsSinceStartString() {
        import std.string: rightJustify;
        import std.conv: to;
        return ("+" ~ (sinceStart / 1000.0).to!string).rightJustify(8, ' ');
    }

    void log(T...)(auto ref T args) {
        import std.functional: forward;
        import std.stdio: stdout;
        alias output = stdout;
        output.writeln("[JIT]  ", secondsSinceStartString, "s  ", forward!args);
        output.flush;
    }

    scope(exit)
        log("Finished");

    if(args.length < 2)
        throw new Exception("Usage: jit filename");

    const fileName = args[1];
    const source = readText(fileName);
    log("Read source file");

    const nodes = Parser(source).parse;
    log("Parsed source file");
    writeln("\n", nodes, "\n");

    auto compiler = new JITCompiler;
    log("Compiling...");
    const symbols = compiler.compile(nodes);
    log("Compiled");

    const fun = cast(int function(int)) symbols[0];

    writeln("\n", fun(2), "\n");
}
