module jitlang.bindings.templates;

auto demacroify(string macroName, A...)(auto ref A args) {
    return macroName(args);
}
