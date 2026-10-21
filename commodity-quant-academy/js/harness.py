"""
harness.py: runs learner code and hidden tests. Loaded by js/py-worker.js inside Pyodide,
and by tools/check_content.py in normal CPython, so grading is identical in both places.

run(user_code, setup_code, tests) -> dict with stdout, stderr, error, tests, figures.
Tests are small Python snippets executed in a COPY of the learner's namespace. They may use:
    approx(a, b, tol=0.01)   float comparison
    __stdout__               everything the learner's code printed
    rerun(**inputs)          re-run the learner's code with different input variables
                             (set after the setup code) and return the resulting namespace
"""
import base64
import io
import sys
import traceback

USER_FILE = "<your code>"


def approx(a, b, tol=0.01):
    try:
        return abs(float(a) - float(b)) <= tol
    except (TypeError, ValueError):
        return False


def _format_error(exc, code):
    """Short, learner-facing error: only frames from the learner's own code."""
    lines = code.splitlines()
    if isinstance(exc, SyntaxError) and exc.filename == USER_FILE:
        src = (exc.text or "").rstrip("\n")
        pointer = " " * max((exc.offset or 1) - 1, 0) + "^"
        return f"Line {exc.lineno}: {src}\n{pointer}\n{type(exc).__name__}: {exc.msg}"
    frames = [f for f in traceback.extract_tb(exc.__traceback__) if f.filename == USER_FILE]
    where = ""
    if frames:
        f = frames[-1]
        src = lines[f.lineno - 1].strip() if 0 < f.lineno <= len(lines) else ""
        where = f"Line {f.lineno}: {src}\n"
    return f"{where}{type(exc).__name__}: {exc}"


def _friendly_test_error(exc):
    if isinstance(exc, AssertionError):
        return str(exc) or "Check failed (no detail given)."
    if isinstance(exc, NameError):
        name = getattr(exc, "name", None) or str(exc)
        return f"Expected a name `{name}` but your code didn't define it (check spelling and that it is not inside an if that never ran)."
    if isinstance(exc, TypeError):
        return f"TypeError while testing: {exc}. Check what type your value is (e.g. str vs float) and how many arguments your function takes."
    return f"{type(exc).__name__} while testing: {exc}"


def _collect_figures():
    figs = []
    if "matplotlib.pyplot" not in sys.modules:
        return figs
    import matplotlib.pyplot as plt
    for num in plt.get_fignums():
        buf = io.BytesIO()
        plt.figure(num).savefig(buf, format="png", dpi=110, bbox_inches="tight")
        figs.append(base64.b64encode(buf.getvalue()).decode("ascii"))
    plt.close("all")
    return figs


def _rerun(user_code, setup_code, inputs):
    ns = {"__name__": "__main__", "approx": approx}
    old = sys.stdout
    sys.stdout = io.StringIO()
    try:
        if setup_code:
            exec(compile(setup_code, "<setup>", "exec"), ns)
        ns.update(inputs)
        exec(compile(user_code, USER_FILE, "exec"), ns)
        ns["__stdout__"] = sys.stdout.getvalue()
    finally:
        sys.stdout = old
    return ns


def run(user_code, setup_code="", tests=None):
    tests = tests or []
    ns = {"__name__": "__main__", "approx": approx}
    out, err = io.StringIO(), io.StringIO()
    result = {"stdout": "", "stderr": "", "error": None, "tests": [], "figures": []}
    old = sys.stdout, sys.stderr
    sys.stdout, sys.stderr = out, err
    try:
        if setup_code:
            exec(compile(setup_code, "<setup>", "exec"), ns)
        try:
            exec(compile(user_code, USER_FILE, "exec"), ns)
        except SystemExit:
            pass
        except BaseException as exc:  # noqa: BLE001 - we report every learner error
            result["error"] = _format_error(exc, user_code)
        result["figures"] = _collect_figures()
    finally:
        sys.stdout, sys.stderr = old
    result["stdout"], result["stderr"] = out.getvalue(), err.getvalue()

    for t in tests:
        if result["error"]:
            result["tests"].append({"name": t["name"], "passed": False,
                                    "message": "Not run: your code raised an error first (see output)."})
            continue
        tns = dict(ns)
        tns["__stdout__"] = result["stdout"]
        tns["approx"] = approx
        tns["rerun"] = lambda **inputs: _rerun(user_code, setup_code, inputs)
        sink = io.StringIO()
        sys.stdout = sink
        try:
            exec(compile(t["code"], "<test>", "exec"), tns)
            result["tests"].append({"name": t["name"], "passed": True, "message": ""})
        except BaseException as exc:  # noqa: BLE001
            result["tests"].append({"name": t["name"], "passed": False, "message": _friendly_test_error(exc)})
        finally:
            sys.stdout = old[0]
    return result
