#!/usr/bin/python

from parse_idl import IDLParser
import sys

def get_ctype(t):
    if t == "uint":
        return "unsigned"
    elif t == "ipc_ptr_t":
        return "void *"
    elif t == "intptr_t":
        return "long"
    else:
        return t

def annotate_ast(ast):

    for d in ast:
        d["noreturn"] = "noreturn" in d["attributes"]

        for a in d["arguments"]:
            out_param         = "out" in a["attributes"]
            pass_by_ref       = out_param or "ref" in a["attributes"]
            a["out_param"]    = out_param
            a["pass_by_ref"]  = pass_by_ref
            a["opaque"]       = "opaque" in a["attributes"]
                
def gen_ipc_server_stub(decl):
    def gen_arg_def(idx, arg):
        s = ["%s a%d" % (get_ctype(arg["type"]), idx)]

        if not arg["out_param"]:
            if arg["type"] == "ipc_ptr_t":
                s.append(" = expressos_ipc_shm_buf + mr->mr[%d]" % idx)
            else:
                s.append(" = mr->mr[%d]" % idx)

        s.append(";\n")
        return "".join(s)

    res = []
    res.append(
        """void expressos_stub_{name}(struct expressos_ipc_req *w)
{{ l4_msg_regs_t *mr = &w->mr;
""".format(name = decl["name"]))

    res.extend(map(lambda (idx, a) : gen_arg_def(idx, a),
                   zip(range(1, len(decl["arguments"]) + 1), decl["arguments"])))

    # call real handler
    has_return_value = decl["return_type"] != "void" and not decl["noreturn"]
    if has_return_value:
        res.append("%s ret = " % get_ctype(decl["return_type"]))
    res.append("expressos_ipc_{name}(".format(name = decl["name"]))

    arglist = filter(lambda (idx, a) : not a["opaque"],
                     zip(range(1, len(decl["arguments"]) + 1), decl["arguments"]))

    args = ", ".join(map(lambda (idx, a) :
                             ("&a%d" if a["pass_by_ref"] else "a%d") % idx, arglist))

    res.append(args)
    res.append(");\n")

    # return statement
    return_arglist = map(lambda idx : "a%d" % (idx + 1),
                         filter(lambda idx: decl["arguments"][idx]["opaque"],
                                range(len(decl["arguments"]))
                                ))

    if has_return_value:
        return_arglist.append("ret")

    return_arglist.extend(
        map(lambda idx : "a%d" % (idx + 1),
            filter(lambda idx: decl["arguments"][idx]["pass_by_ref"],
                   range(len(decl["arguments"]))
                   )))

    if len(return_arglist) != 0 and not decl["noreturn"]:
        res.append("expressos_ipc_return_{num}(expressos_op_{name}, "
                   .format(num = len(return_arglist), name = decl["name"]))

        res.append(", ".join(return_arglist))
        res.append(");\n")    

    # end of function, remove the warnings of unused variable
    res.append("(void)mr;\n")

    res.append("}\n")
    return "".join(res)


def gen_enum(decllist):
    res = ["enum {"]
    res.append("expressos_op_kickstart = 1,")

    res.extend(map(lambda decl : "expressos_op_{name},".
                   format(name = decl["name"]),
                   decllist))

    res.append("};")
    return "\n".join(res)


def gen_dispatcher(decllist):
    res = []
    res.append("""void expressos_ipc_dispatch(struct expressos_ipc_req *w)
{switch (w->mr.mr[0]) {""")

    res.extend(map(lambda decl : 
                   "case expressos_op_{name}: expressos_stub_{name}(w); break;\n".
                   format(name = decl["name"]),
                   decllist))

    res.append("""
    default:
        printk(KERN_WARNING "Invalid ExpressOS call %lu\\n", w->mr.mr[0]);
        break;
    }
}
""")
    return "".join(res)

t = IDLParser()
t.build()

r = '\n'.join(sys.stdin.readlines())

ast = t.parse(r)
annotate_ast(ast)

print """
/*
 * Implementation for IPC stubs.
 *
 * AUTOMATICALLY GENERATED. DO NOT EDIT.
 */

#include "ipc-stubs.h"
#include "expressos.h"
#include <l4/sys/utcb.h>

"""

for x in ast:
    print gen_ipc_server_stub(x)


print gen_dispatcher(ast)
