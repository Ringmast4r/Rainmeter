"""Builds @Resources\\Lookup\\oui.tsv (MAC prefix -> vendor) for the Wi-Fi survey and LAN cards.

Source: the IEEE registration authority listings (MA-L, MA-M, MA-S, IAB), which are public. Point it at any
SQLite file with an `identifier(namespace_id, value, registrant)` table, or at the IEEE CSVs:
    py -3.13 build_oui.py path\\to\\hardware-devices.db
    py -3.13 build_oui.py oui.csv mam.csv oui36.csv iab.csv
Output lines: <hex prefix, 6/7/9 digits><TAB><short vendor name>
"""
import csv
import pathlib
import re
import sqlite3
import sys

OUT = pathlib.Path(__file__).resolve().parents[1] / "Lookup" / "oui.tsv"
SUFFIX = re.compile(r"[\s,.]+(inc|incorporated|corp|corporation|co|company|ltd|limited|llc|l\.l\.c|gmbh|ag|s\.?a|s\.?a\.?s|"
                    r"b\.?v|n\.?v|oy|ab|as|a/s|plc|pte|pty|kg|spa|s\.p\.a|srl|s\.r\.l|kk|k\.k|sdn bhd|bhd|gmbh & co)\.?$", re.I)


def short(name: str) -> str:
    n = " ".join((name or "").split())
    for _ in range(4):
        m = SUFFIX.search(n)
        if not m:
            break
        n = n[:m.start()]
    return n.strip(" ,.") or (name or "").strip()


def from_db(path):
    c = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    q = "SELECT value, registrant FROM identifier WHERE namespace_id IN ('ieee-ma-l','ieee-ma-m','ieee-ma-s','ieee-iab')"
    for value, reg in c.execute(q):
        yield value.replace(":", "").upper(), reg


def from_csv(paths):
    for p in paths:
        with open(p, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                yield row["Assignment"].upper(), row["Organization Name"]


def main():
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    rows = from_db(args[0]) if args[0].lower().endswith(".db") else from_csv(args)
    out = {}
    for prefix, reg in rows:
        if re.fullmatch(r"[0-9A-F]{6}|[0-9A-F]{7}|[0-9A-F]{9}", prefix) and reg:
            out[prefix] = short(reg).replace("\t", " ")
    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text("".join(f"{k}\t{v}\n" for k, v in sorted(out.items())), encoding="utf-8")
    print(f"wrote {len(out):,} prefixes to {OUT}")


if __name__ == "__main__":
    main()
