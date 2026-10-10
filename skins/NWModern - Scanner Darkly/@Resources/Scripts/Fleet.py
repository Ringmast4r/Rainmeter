# NWModern Scanner Darkly: every URL in the Scanner Darkly registry, checked in parallel.
# Run by the Links skin (py -3.13 -I, hidden). Prints one line per link for Fleet.lua:
#   Src=<registry|cache|example>|<registry rows>
#   S=<name>|<url>|<category>|<stat>|<ct>|<description>|<status code, 0 = no answer>|<ms>|<error>
# The list comes from scanner-darkly.db (read-only). Each good read is cached to Local\links.txt, so the skin
# still works when the library drive is away; without either it falls back to Examples\links.txt.
import concurrent.futures
import ctypes
import os
import socket
import sqlite3
import string
import sys
import time
import urllib.error
import urllib.request

RES = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))   # @Resources
LOCAL, EXAMPLES = os.path.join(RES, "Local"), os.path.join(RES, "Examples")
DB_TAIL = r"03 Website Library\Scanner Darkly\data\scanner-darkly.db"
TIMEOUT = 6
FIELDS = 6   # name|url|category|stat|ct|description


def clean(v):
    return " ".join(str("" if v is None else v).replace("|", "/").split())


def setting(key):
    for d in (LOCAL, EXAMPLES):
        try:
            with open(os.path.join(d, "settings.txt"), encoding="utf-8-sig") as f:
                for line in f:
                    k, _, v = line.strip().partition("=")
                    if k == key and not line.lstrip().startswith("#"):
                        return v.strip()
        except OSError:
            pass
    return ""


def find_db():
    p = setting("Db")
    if p:
        return p if os.path.isfile(p) else None
    # library drive letters move, so look on every fixed drive (never the network shares: a dead share can hang)
    for letter in string.ascii_uppercase:
        root = letter + ":\\"
        if ctypes.windll.kernel32.GetDriveTypeW(root) == 3:
            p = os.path.join(root, DB_TAIL)
            if os.path.isfile(p):
                return p
    return None


def from_db(path):
    con = sqlite3.connect("file:" + path.replace("\\", "/") + "?mode=ro", uri=True, timeout=3)
    try:
        total = con.execute("SELECT count(*) FROM scanners").fetchone()[0]
        rows = con.execute(
            "SELECT name, url, category, stat, ct_id, description FROM scanners"
            " WHERE url IS NOT NULL AND trim(url) <> '' ORDER BY name COLLATE NOCASE").fetchall()
    finally:
        con.close()
    return [[clean(v) for v in r] for r in rows], total


def from_file(path):
    out = []
    try:
        with open(path, encoding="utf-8-sig") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#"):
                    parts = (line.split("|") + [""] * FIELDS)[:FIELDS]
                    if parts[1]:
                        out.append([clean(v) for v in parts])
    except OSError:
        pass
    return out


def save_cache(rows):
    path = os.path.join(LOCAL, "links.txt")
    text = ("# Written by Fleet.py from scanner-darkly.db; edit the database, not this file.\n"
            "# name|url|category|stat|ct|description\n"
            + "".join("|".join(r) + "\n" for r in rows))
    try:
        with open(path, encoding="utf-8") as f:
            if f.read() == text:
                return
    except OSError:
        pass
    os.makedirs(LOCAL, exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


# LAN dashboards: go direct, never through a system proxy
OPENER = urllib.request.build_opener(urllib.request.ProxyHandler({}))
OPENER.addheaders = [("User-Agent", "NWModern-Rainmeter/0.1 (Scanner Darkly links)")]


def probe(url):
    t = time.perf_counter()
    code, err = 0, ""
    try:
        with OPENER.open(url, timeout=TIMEOUT) as r:     # returns once the headers are in
            code = r.status
    except urllib.error.HTTPError as e:
        code = e.code
    except Exception as e:                               # URLError, timeouts, resets
        r = getattr(e, "reason", e)
        m = str(r).lower()
        if isinstance(r, socket.timeout) or "timed out" in m:
            err = "timeout"
        elif "refused" in m or "10061" in m:
            err = "refused"
        elif "getaddrinfo" in m or "11001" in m:
            err = "no DNS"
        elif "reset" in m or "10054" in m or "closed" in m:
            err = "reset"
        elif "unreachable" in m or "10065" in m or "10051" in m:
            err = "unreachable"
        else:
            err = clean(r)[:40]
    return code, int((time.perf_counter() - t) * 1000), err


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    rows, total, src = [], 0, "registry"
    db = find_db()
    if db:
        try:
            rows, total = from_db(db)
            save_cache(rows)
        except Exception:
            rows = []
    if not rows:
        rows, src = from_file(os.path.join(LOCAL, "links.txt")), "cache"
    if not rows:
        rows, src = from_file(os.path.join(EXAMPLES, "links.txt")), "example"
    if not rows:
        print("Err=no links: Scanner Darkly db not found and no Local\\links.txt")
        return
    print(f"Src={src}|{total}")
    with concurrent.futures.ThreadPoolExecutor(max_workers=min(32, len(rows))) as ex:
        results = list(ex.map(lambda r: probe(r[1]), rows))
    for r, (code, ms, err) in zip(rows, results):
        print("S=" + "|".join(r + [str(code), str(ms), err]))


main()
