"""IP // Revealer bridge for the Who's talking card.

    py iplookup.py --root "<IP Revealer project folder>" 1.1.1.1 140.82.112.4 ...

Prints one line per address: ip|country code|city|owner network|threat flags
Without IP // Revealer it prints the addresses with empty fields, so the card still works.
"""
import re
import sys

SUFFIX = re.compile(r"[\s,.]+(inc|corp|corporation|co|ltd|llc|gmbh|ag|s\.?a|b\.?v|limited|l\.l\.c)\.?$", re.I)


def owner(name: str) -> str:
    if " - " in name:                      # "CLOUDFLARENET - Cloudflare, Inc." -> "Cloudflare, Inc."
        name = name.split(" - ", 1)[1]
    else:                                  # "AKAMAI-ASN1 Akamai International B.V." -> "Akamai International B.V."
        m = re.match(r"^[A-Z0-9][A-Z0-9-]*\s+(.*[a-z].*)$", name)
        if m:
            name = m.group(1)
    for _ in range(3):
        m = SUFFIX.search(name)
        if not m:
            break
        name = name[:m.start()]
    return name.strip(" ,.")


def main():
    args = sys.argv[1:]
    root = None
    if args[:1] == ["--root"]:
        root, args = args[1], args[2:]
    try:
        sys.path.insert(0, f"{root}/src")
        from iprevealer.engine import Revealer
        rev = Revealer()
    except Exception:
        for ip in args:
            print(f"{ip}||||")
        return
    for ip in args:
        try:
            res = rev.lookup(ip)
        except Exception:
            print(f"{ip}||||")
            continue
        lo = res.get("location") or {}
        cc = lo.get("country_iso") or (res.get("verdict") or {}).get("country") or ""
        city = re.sub(r"\s*\(.*?\)", "", lo.get("city") or "")
        asn = next(iter((res.get("asn") or {}).values()), {}) or {}
        v = res.get("verdict") or {}
        flags = sorted({t.get("label") or "threat list" for t in (res.get("threats") or [])})
        if v.get("tor_exit"):
            flags.append("Tor exit")
        if v.get("spamhaus_drop"):
            flags.append("Spamhaus DROP")
        print("|".join(str(x).replace("|", " ").replace("\n", " ")
                       for x in (ip, cc, city, owner(asn.get("name") or ""), ", ".join(flags))))


if __name__ == "__main__":
    main()
