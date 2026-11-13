#!/usr/bin/env python3
"""Build the internship report PDF from its Typst sources.

    pip install -r requirements.txt
    python build.py                 # -> Farah_Ayari_Internship_Report_v2.pdf
    python build.py --preview       # also renders every page to build/pages/*.png

The build is hermetic: only the fonts vendored in ./fonts are used, so the
result is the same on every machine.
"""
from __future__ import annotations

import argparse
import pathlib
import sys
import time

ROOT = pathlib.Path(__file__).resolve().parent
SRC = ROOT / "src"
FONTS = ROOT / "fonts"
DEFAULT_OUT = ROOT / "Farah_Ayari_Internship_Report_v2.pdf"


def shown(path: pathlib.Path) -> str:
    """Path relative to the project when possible, absolute otherwise."""
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def compile_pdf(entry: pathlib.Path, out: pathlib.Path) -> int:
    try:
        import typst
    except ImportError:  # pragma: no cover - guidance only
        sys.exit("The 'typst' package is missing: pip install -r requirements.txt")

    started = time.time()
    try:
        pdf, warnings = typst.compile_with_warnings(
            str(entry),
            root=str(ROOT),
            font_paths=[str(FONTS)],
            ignore_system_fonts=True,
            format="pdf",
        )
    except typst.TypstError as exc:
        print("Typst error:\n", exc, file=sys.stderr)
        details = getattr(exc, "diagnostic", None) or getattr(exc, "trace", None)
        if details:
            print(details, file=sys.stderr)
        return 1
    for w in warnings:
        message = getattr(w, "message", w)
        trace = getattr(w, "trace", "")
        print(f"warning: {message} {trace}".rstrip(), file=sys.stderr)
    out.write_bytes(pdf)
    print(f"wrote {shown(out)}  ({len(pdf) / 1024:.0f} KiB, {time.time() - started:.1f}s)")
    return 0


def render_pages(pdf: pathlib.Path, dpi: int, target: pathlib.Path) -> None:
    try:
        import pymupdf
    except ImportError:  # pragma: no cover - guidance only
        sys.exit("Preview needs PyMuPDF: pip install pymupdf")
    target.mkdir(parents=True, exist_ok=True)
    for old in target.glob("*.png"):
        old.unlink()
    with pymupdf.open(pdf) as doc:
        for index, page in enumerate(doc, start=1):
            page.get_pixmap(dpi=dpi).save(target / f"page-{index:03d}.png")
        print(f"rendered {doc.page_count} pages to {shown(target)}/")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--entry", default=str(SRC / "main.typ"), help="Typst entry file")
    parser.add_argument("--out", default=str(DEFAULT_OUT), help="output PDF path")
    parser.add_argument("--preview", action="store_true", help="render pages to PNG after building")
    parser.add_argument("--dpi", type=int, default=110, help="preview resolution")
    parser.add_argument("--pages-dir", default=str(ROOT / "build" / "pages"), help="where previews are written")
    args = parser.parse_args()

    out = pathlib.Path(args.out).resolve()
    status = compile_pdf(pathlib.Path(args.entry).resolve(), out)
    if status == 0 and args.preview:
        render_pages(out, args.dpi, pathlib.Path(args.pages_dir).resolve())
    return status


if __name__ == "__main__":
    raise SystemExit(main())
