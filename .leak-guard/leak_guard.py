#!/usr/bin/env python3
"""Block commits and pushes that would put forbidden terms into this repo.

The terms are stored only as SHA-256 hashes, so the guard itself does not leak
them. Matching is case-insensitive and ignores punctuation: text is split on
whitespace, each token is lowercased and reduced to [a-z0-9], and every
substring of each term length is hashed. So "Foo-Bar", "foo.bar" and "xfoobarx"
all match the term "foobar"; "foo bar" (two tokens) does not.

Extra plaintext terms can be kept outside the repo, one per line, in
$XDG_CONFIG_HOME/leak-guard/terms (default ~/.config/leak-guard/terms).

Modes:
  pre-commit          staged diff, staged paths, author/committer identity
  commit-msg FILE     the commit message
  pre-push            every commit being pushed (reads git's pre-push stdin)
  history [REV...]    every commit reachable from REV (default: --all)
  tree                every tracked file and path at HEAD
  hash TERM...        print the hash line for new terms (for TERMS below)
"""

from __future__ import annotations

import argparse
import hashlib
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

# sha256(normalized term) -> term length. Add entries with `leak_guard.py hash`.
TERMS: dict[str, int] = {
    "3ee49785593999cef46e1c1482ad1a246d6e319b48149ec2e8cdff05ddf8b236": 5,
    "2da2db2b467dba83b722d8c323630706e3582d1998deeb5e0dd6b1470860f6bf": 16,
    "c9ea4ff2ffd161306ee06f07479f412af469d1e3368bc9efc45ed03d67367111": 7,
    "0003b001c2d8095f1fe013ed3ac36f4f22a18b8ea4a216e866924a22b15ab104": 4,
    "32d68ca75f5ea75d1bd4a899d9e0a333a08d123c6523094c3ce27e8212258613": 8,
    "74063de4974f1a884b0c3a5e78f0d87d78b941e10a896ab5b6b5dacf576a743d": 7,
    "b5746707eea8e3f25954cfefdeeb399dd762d2102b8e5b3227c6b0a874bd82fd": 8,
    "dd493aa515f586db8927d235714d6e081b292e282e74b989f83e4242aca84e97": 9,
}

NON_ALNUM = re.compile(r"[^a-z0-9]")
ZERO_SHA = "0" * 40


@dataclass(frozen=True)
class Hit:
    where: str
    line: int | None = None

    def __str__(self) -> str:
        return f"{self.where}:{self.line}" if self.line else self.where


def normalize(text: str) -> str:
    return NON_ALNUM.sub("", text.lower())


def digest(term: str) -> str:
    return hashlib.sha256(term.encode()).hexdigest()


def load_terms() -> dict[str, int]:
    terms = dict(TERMS)
    config = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    extra = config / "leak-guard" / "terms"
    if extra.is_file():
        for raw in extra.read_text().splitlines():
            term = normalize(raw)
            if term:
                terms[digest(term)] = len(term)
    return terms


class Scanner:
    def __init__(self, terms: dict[str, int]) -> None:
        self.hashes = set(terms)
        self.lengths = sorted(set(terms.values()))
        self.hits: list[Hit] = []

    def matches(self, text: str) -> bool:
        for token in text.split():
            s = normalize(token)
            for size in self.lengths:
                for i in range(len(s) - size + 1):
                    if digest(s[i : i + size]) in self.hashes:
                        return True
        return False

    def text(self, where: str, text: str) -> None:
        for number, line in enumerate(text.splitlines(), start=1):
            if self.matches(line):
                self.hits.append(Hit(where, number))

    def value(self, where: str, value: str) -> None:
        if self.matches(value):
            self.hits.append(Hit(where))

    def diff(self, label: str, patch: str) -> None:
        """Scan added lines and touched paths of a `git diff` / `git show` patch."""
        path = "?"
        line = 0
        for raw in patch.splitlines():
            if raw.startswith(("+++ ", "--- ")):
                name = raw[4:]
                if name != "/dev/null":
                    path = name[2:] if name[:2] in ("a/", "b/") else name
                    self.value(f"{label} path {path}", path)
            elif raw.startswith(
                ("rename from ", "rename to ", "copy from ", "copy to ")
            ):
                name = raw.split(" ", 2)[2]
                self.value(f"{label} path {name}", name)
            elif raw.startswith("@@"):
                match = re.search(r"\+(\d+)", raw)
                line = int(match.group(1)) if match else 0
            elif raw.startswith("+"):
                if self.matches(raw[1:]):
                    self.hits.append(Hit(f"{label} {path}", line))
                line += 1
            elif not raw.startswith("-"):
                line += 1


def git(*args: str) -> str:
    result = subprocess.run(
        ["git", *args], check=True, capture_output=True, text=True, errors="replace"
    )
    return result.stdout


def scan_commit(scanner: Scanner, sha: str) -> None:
    short = sha[:10]
    meta = git("show", "-s", "--format=%an <%ae>%n%cn <%ce>%n%B", sha)
    ident, _, message = meta.partition("\n")
    committer, _, message = message.partition("\n")
    scanner.value(f"{short} author", ident)
    scanner.value(f"{short} committer", committer)
    scanner.text(f"{short} message", message)
    scanner.diff(short, git("show", "--format=", "-p", "--text", "-M", "--root", sha))


def scan_revs(scanner: Scanner, revs: list[str]) -> int:
    shas = git("rev-list", *revs).split()
    for sha in shas:
        scan_commit(scanner, sha)
    return len(shas)


def has_commit(sha: str) -> bool:
    return (
        subprocess.run(
            ["git", "cat-file", "-e", f"{sha}^{{commit}}"],
            check=False,
            capture_output=True,
        ).returncode
        == 0
    )


def pushed_ranges(lines: list[str]) -> list[list[str]]:
    """Turn git's pre-push stdin ("<lref> <lsha> <rref> <rsha>") into rev-list args."""
    ranges: list[list[str]] = []
    for line in lines:
        parts = line.split()
        if len(parts) != 4 or parts[1] == ZERO_SHA:
            continue
        local, remote = parts[1], parts[3]
        # A force-push can name a remote commit this clone never had.
        if remote == ZERO_SHA or not has_commit(remote):
            ranges.append([local, "--not", "--remotes"])
        else:
            ranges.append([f"{remote}..{local}"])
    return ranges


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="mode", required=True)
    sub.add_parser("pre-commit", help="scan the staged change and identity")
    msg = sub.add_parser("commit-msg", help="scan a commit message file")
    msg.add_argument("file", type=Path, help="path git passes to commit-msg")
    sub.add_parser("pre-push", help="scan commits being pushed")
    hist = sub.add_parser("history", help="scan every commit reachable from REVs")
    hist.add_argument(
        "revs", nargs=argparse.REMAINDER, help="rev-list args (default --all)"
    )
    sub.add_parser("tree", help="scan all tracked files and paths at HEAD")
    hsh = sub.add_parser("hash", help="print TERMS entries for new terms")
    hsh.add_argument("terms", nargs="+", help="plaintext terms (not stored)")
    args, extra = parser.parse_known_args()
    if extra and args.mode != "history":
        parser.error(f"unrecognized arguments: {' '.join(extra)}")
    if args.mode == "history":
        args.revs = [*args.revs, *extra]

    if args.mode == "hash":
        for raw in args.terms:
            term = normalize(raw)
            print(f'    "{digest(term)}": {len(term)},')
        return 0

    scanner = Scanner(load_terms())

    if args.mode == "pre-commit":
        scanner.value("author identity", git("var", "GIT_AUTHOR_IDENT"))
        scanner.value("committer identity", git("var", "GIT_COMMITTER_IDENT"))
        for key in ("user.email", "user.signingkey"):
            value = subprocess.run(
                ["git", "config", "--get", key],
                check=False,
                capture_output=True,
                text=True,
            ).stdout
            scanner.value(f"git config {key}", value)
        scanner.diff("staged", git("diff", "--cached", "--text", "-M"))
    elif args.mode == "commit-msg":
        message = args.file.read_text(errors="replace")
        body = "\n".join(
            line for line in message.splitlines() if not line.startswith("#")
        )
        scanner.text("commit message", body)
    elif args.mode == "pre-push":
        ranges = pushed_ranges(sys.stdin.read().splitlines())
        count = sum(scan_revs(scanner, revs) for revs in ranges)
        print(f"leak-guard: scanned {count} commit(s)", file=sys.stderr)
    elif args.mode == "history":
        print(
            f"leak-guard: scanned {scan_revs(scanner, args.revs or ['--all'])} commit(s)",
            file=sys.stderr,
        )
    elif args.mode == "tree":
        for path in git("ls-files", "-z").split("\0"):
            if not path:
                continue
            scanner.value(f"path {path}", path)
            file = Path(path)
            if file.is_file():
                scanner.text(path, file.read_text(errors="replace"))

    if scanner.hits:
        print("leak-guard: forbidden term found (matched by hash):", file=sys.stderr)
        for hit in scanner.hits:
            print(f"  {hit}", file=sys.stderr)
        print("Remove it; this repo must stay free of those terms.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
