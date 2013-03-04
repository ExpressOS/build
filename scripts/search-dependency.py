import sys
import subprocess
import re

root_path = "android-x86/out/target/product/eeepc"

#lib_search_path = [ root_path + "/sytem/lib"]
lib_path = root_path + "/system/lib"

queue = [ "/system/bin/surfaceflinger", "/system/bin/servicemanager", "/system/bin/presenter", "/system/bin/netcfg", "/system/bin/netd" ]

processed_file = set()

def find_file(f):
    if f.startswith("/"):
        return root_path + f
    else:
        return lib_path + "/" + f

def get_deps(f):
    r = subprocess.check_output(["ldd", find_file(f)])
    for l in r.split('\n'):
        p = re.match(r"([0-9a-zA-Z\.\+_]+) => not found", l.strip())
        if p != None:
            fn = p.group(1)
            yield fn

def search(queue):
    while len(queue) != 0:
        h = queue[0]
        queue = queue[1:]
        if h not in processed_file:
            processed_file.add(h)
            for fn in get_deps(h):
                queue.append(fn)

search(queue)

for f in processed_file:
    print find_file(f)
