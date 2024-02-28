module jitlang.io;

immutable imported!"std.datetime.systime".SysTime gStartTime;


shared static this() {
    import std.datetime: Clock;
    gStartTime = Clock.currTime;
}


void log(O, T...)(auto ref O output, auto ref T args) {
    import std.functional: forward;
    output.writeln("[JIT]  ", usSinceStartString, "us  ", forward!args);
    output.flush;
}

private string usSinceStartString() @safe {
    import std.string: rightJustify;
    import std.conv: to;
    return ("+" ~ sinceStart.to!string).rightJustify(8, ' ');
}

private auto sinceStart() @safe {
    import std.datetime: Clock;
    return (Clock.currTime - gStartTime).total!"usecs";
}

auto sink() {
    import std.stdio: stdout;

    version(unittest) {
        static struct UnitThreadedSink {
            void flush() {}
            void writeln(A...)(auto ref A args) {
                import unit_threaded.io;
                writelnUt(args);
            }
        }
        return stdout;
    } else
        return stdout;
}
