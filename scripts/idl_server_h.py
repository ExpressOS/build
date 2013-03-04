#!/usr/bin/python

from parse_idl import IDLParser
import sys

def gen_enum(decllist):
    res = ["enum {"]
    res.append("expressos_op_kickstart = 1,")

    res.extend(map(lambda decl : "expressos_op_{name},".
                   format(name = decl["name"]),
                   decllist))

    res.append("expressos_op_count,")
    res.append("};")
    return "\n".join(res)

def gen_is_async_call(decllist):
    res = ["""static inline int expressos_ipc_is_async_call(int opcode)
{
    switch (opcode) {
"""]
    res.extend(
        map(lambda d : "case expressos_op_{name}:\n".format(name = d["name"]),
            filter(lambda d : "async" in d["attributes"], decllist)))

    res.append("""return 1;\n
default:
return 0;
}
}""")
    return "".join(res)

t = IDLParser()
t.build()

r = '\n'.join(sys.stdin.readlines())
ast = t.parse(r)

print """
/*
 * AUTOMATICALLY GENERATED. DO NOT EDIT.
 */
#ifndef LINUX_EXPRESSOS_IPC_STUBS_H_
#define LINUX_EXPRESSOS_IPC_STUBS_H_
"""

print gen_enum(ast)
print gen_is_async_call(ast)
print """
#endif
"""
