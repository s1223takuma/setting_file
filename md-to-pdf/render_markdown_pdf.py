#!/usr/bin/env python3
"""Markdown文書全体を、Mermaid図を含めてA4 PDFへ変換する。

使用例:
    md-to-pdf document.md

出力:
    document.pdf
"""

from __future__ import annotations

import html
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import mistune
from playwright.sync_api import sync_playwright


SCRIPT_DIR = Path(__file__).resolve().parent

MERMAID_PATTERN = re.compile(
    r"```mermaid[ \t]*\r?\n(?P<source>.*?)\r?\n```",
    flags=re.DOTALL,
)

CSS = """
@page {
  size: A4;
  margin: 18mm 17mm 20mm;
}

:root {
  color-scheme: light;
}

body {
  color: #172033;
  background: #ffffff;
  font-family:
    "Hiragino Sans", "Yu Gothic", "YuGothic", "Noto Sans JP",
    -apple-system, BlinkMacSystemFont, sans-serif;
  font-size: 10.5pt;
  line-height: 1.85;
  overflow-wrap: anywhere;
}

main {
  max-width: 100%;
}

h1 {
  margin: 0 0 1.2em;
  padding-bottom: 0.35em;
  border-bottom: 2px solid #315a8a;
  color: #173b66;
  font-size: 22pt;
  line-height: 1.35;
}

h2 {
  margin: 1.8em 0 0.7em;
  padding: 0.25em 0.55em;
  border-left: 5px solid #315a8a;
  background: #eef4fa;
  color: #173b66;
  font-size: 16pt;
  line-height: 1.45;
  break-after: avoid-page;
}

h3 {
  margin: 1.5em 0 0.55em;
  color: #244f7b;
  font-size: 13pt;
  break-after: avoid-page;
}

h4 {
  margin: 1.3em 0 0.45em;
  color: #315a8a;
  font-size: 11.5pt;
  break-after: avoid-page;
}

p {
  margin: 0.55em 0;
  text-align: justify;
}

blockquote {
  margin: 1em 0;
  padding: 0.65em 1em;
  border-left: 4px solid #7c9fc3;
  background: #f6f8fb;
  color: #334155;
}

pre {
  margin: 0.9em 0;
  padding: 0.8em 1em;
  border: 1px solid #d7dee8;
  border-radius: 5px;
  background: #f7f9fc;
  font-size: 8.8pt;
  line-height: 1.55;
  white-space: pre-wrap;
  break-inside: avoid-page;
}

code {
  font-family: "SFMono-Regular", Consolas, "Liberation Mono", monospace;
}

:not(pre) > code {
  padding: 0.12em 0.28em;
  border-radius: 3px;
  background: #eef2f7;
  color: #9b2c2c;
  font-size: 0.92em;
}

table {
  width: 100%;
  margin: 1em 0;
  border-collapse: collapse;
  font-size: 9.2pt;
  break-inside: avoid-page;
}

th, td {
  padding: 0.48em 0.6em;
  border: 1px solid #b8c5d3;
  vertical-align: top;
}

th {
  background: #e5edf6;
  color: #173b66;
  font-weight: 700;
}

tr:nth-child(even) td {
  background: #f8fafc;
}

ul, ol {
  padding-left: 1.8em;
}

li {
  margin: 0.25em 0;
}

hr {
  margin: 1.8em 0;
  border: 0;
  border-top: 1px solid #cbd5e1;
}

.mermaid-diagram {
  display: flex;
  justify-content: center;
  margin: 1.2em auto;
  padding: 0.7em;
  break-inside: avoid-page;
}

.mermaid-diagram svg {
  width: 100%;
  max-width: 170mm;
  height: auto;
  max-height: 235mm;
}
"""


def render_mermaid(markdown_text: str, work_dir: Path) -> str:
    """MermaidコードブロックをインラインSVGへ置換する。"""
    if not MERMAID_PATTERN.search(markdown_text):
        return markdown_text

    if shutil.which("mmdc") is None:
        raise RuntimeError(
            "Mermaid図を含む文書ですが、Mermaid CLI (mmdc) が見つかりません。"
        )

    diagram_number = 0

    def replace(match: re.Match[str]) -> str:
        nonlocal diagram_number
        diagram_number += 1
        source_path = work_dir / f"diagram-{diagram_number}.mmd"
        svg_path = work_dir / f"diagram-{diagram_number}.svg"
        source_path.write_text(match.group("source"), encoding="utf-8")

        subprocess.run(
            [
                "mmdc",
                "--input",
                str(source_path),
                "--output",
                str(svg_path),
                "--theme",
                "neutral",
                "--backgroundColor",
                "white",
            ],
            check=True,
        )
        svg = svg_path.read_text(encoding="utf-8")
        return f'\n<div class="mermaid-diagram">{svg}</div>\n'

    return MERMAID_PATTERN.sub(replace, markdown_text)


def markdown_to_html(markdown_text: str, title: str) -> str:
    renderer = mistune.HTMLRenderer(escape=False)
    markdown = mistune.create_markdown(
        renderer=renderer,
        plugins=["table", "strikethrough", "task_lists", "url"],
    )
    body = markdown(markdown_text)
    return f"""<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <title>{html.escape(title)}</title>
  <style>{CSS}</style>
</head>
<body>
  <main>{body}</main>
</body>
</html>
"""


def find_chromium(playwright) -> Path:
    """既にインストール済みのChromiumを探す。ダウンロードは行わない。"""
    candidates = [Path(playwright.chromium.executable_path)]
    candidates.extend(
        sorted(
            (Path.home() / ".cache" / "puppeteer" / "chrome-headless-shell").glob(
                "*/chrome-headless-shell-*/chrome-headless-shell"
            ),
            reverse=True,
        )
    )
    candidates.extend(
        sorted(
            (Path.home() / ".cache" / "puppeteer" / "chrome").glob(
                "*/chrome-*/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing"
            ),
            reverse=True,
        )
    )

    for candidate in candidates:
        if candidate.is_file():
            return candidate

    raise RuntimeError(
        "PDF描画に使用できるChromiumが見つかりません。"
        "ブラウザの追加インストールが必要です。"
    )


def render_pdf(input_path: Path, output_path: Path) -> None:
    if not input_path.is_file():
        raise FileNotFoundError(f"Markdownファイルが見つかりません: {input_path}")

    output_path.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="markdown-pdf-") as temp_dir:
        work_dir = Path(temp_dir)
        markdown_text = input_path.read_text(encoding="utf-8")
        markdown_text = render_mermaid(markdown_text, work_dir)
        document = markdown_to_html(markdown_text, input_path.stem)

        with sync_playwright() as playwright:
            # インストール済みのChromium本体を明示し、追加ダウンロードを不要にする。
            browser = playwright.chromium.launch(
                executable_path=str(find_chromium(playwright))
            )
            page = browser.new_page()
            page.set_content(document, wait_until="networkidle")
            page.emulate_media(media="print")
            page.pdf(
                path=str(output_path),
                format="A4",
                print_background=True,
                margin={
                    "top": "18mm",
                    "right": "17mm",
                    "bottom": "20mm",
                    "left": "17mm",
                },
            )
            browser.close()


def main() -> None:
    if len(sys.argv) != 2:
        print(
            "使用方法: python3 render_markdown_pdf.py <Markdownファイル>",
            file=sys.stderr,
        )
        raise SystemExit(2)

    input_path = Path(sys.argv[1]).resolve()
    if input_path.suffix.lower() != ".md":
        raise ValueError(f"拡張子が.mdのファイルを指定してください: {input_path}")

    # 入力Markdownと同じ階層・同じ名前で、拡張子だけ.pdfへ変更する。
    output_path = input_path.with_suffix(".pdf")

    render_pdf(input_path, output_path)
    print(f"Markdown: {input_path}")
    print(f"PDF:      {output_path}")


if __name__ == "__main__":
    main()
