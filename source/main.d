int main(string[] args) {
    try {
        import jitlang.app: run;
        run(args);
        return 0;
    } catch(Throwable t) {
        import std.stdio: stderr;
        stderr.writeln("Error: ", t.msg);
        return 1;
    }
}
