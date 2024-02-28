module jitlang.io;

immutable imported!"std.datetime.systime".SysTime gStartTime;


shared static this() {
    import std.datetime: Clock;
    gStartTime = Clock.currTime;
}


void log(T...)(auto ref T args) {
    import std.functional: forward;
    version(unittest) {
        import unit_threaded;
        writelnUt("[JIT]  ", usSinceStartString, "us  ", forward!args);
    } else {
        import std.stdio: writeln;
        writeln("[JIT]  ", usSinceStartString, "us  ", forward!args);
    }
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
