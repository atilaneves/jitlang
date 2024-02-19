#include <lightning.h>

// otherwise none of the stupid macros work
jit_state_t* _jit;

// demacroify
const jit_code_t R0 = JIT_R0; // call-clobbered
const jit_code_t R1 = JIT_R1;
const jit_code_t R2 = JIT_R2;
const jit_code_t V0 = JIT_V0; // callee-saved (persist across calls)
const jit_code_t V1 = JIT_V1;
const jit_code_t V2 = JIT_V2;
const jit_code_t FP = JIT_FP;

// copied from the header (sigh)
int movi(int u, int v) {
    return jit_movi(u, v);
}

int movr(int u, int v) {
    return jit_movr(u, v);
}

int addr(int u, int v, int w) {
    return jit_addr(u, v, w);
}

int subr(int u, int v, int w) {
    return jit_subr(u, v, w);
}

int mulr(int u, int v, int w) {
    return jit_mulr(u, v, w);
}

int divr(int u, int v, int w) {
    return jit_divr(u, v, w);
}

int stxi_i(int u, int v, int w) {
    return jit_stxi_i(u, v, w);
}

int ldxi_i(int u, int v, int w) {
    return jit_ldxi_i(u, v, w);
}

int lshr(int u, int v, int w) {
    return jit_lshr(u, v, w);
}

int rshr(int u, int v, int w) {
    return jit_rshr(u, v, w);
}

void pushargr(int u) {
    jit_pushargr(u);
}

jit_node_t* arg() {
    return jit_arg();
}

void getarg(jit_gpr_t u, jit_node_t* v) {
    return jit_getarg(u, v);
}

void retr(ulong u) {
    jit_retr(u);
}

void calli(void* symbol) {
    jit_calli(symbol);
}
