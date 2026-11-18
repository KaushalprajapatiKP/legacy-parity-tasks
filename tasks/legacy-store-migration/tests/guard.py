# Runs a migrator script with process creation disabled. MIT License.
# usage: python3 guard.py SCRIPT ARG...
import runpy
import sys

BLOCKED = ("subprocess.Popen", "os.system", "os.exec", "os.posix_spawn", "os.spawn", "os.fork",
           "os.forkpty", "pty.spawn", "ctypes.dlopen", "ctypes.dlsym", "os.startfile")


def _hook(event, args):
    if event in BLOCKED:
        raise PermissionError("starting other programs is not allowed during grading (%s)" % event)


sys.addaudithook(_hook)
script = sys.argv[1]
sys.argv = sys.argv[1:]
runpy.run_path(script, run_name="__main__")
