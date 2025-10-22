import markdown
import pygments.lexers
from markdown.extensions import fenced_code, toc, codehilite, tables
from pygments.formatters import HtmlFormatter
from lexer import USRLLexer
import htmlmin
import rcssmin
import bs4
import os
import time

__all__ = ['USRLLexer']

def build(md: markdown.Markdown, md_file: str, template_file: str, output_file: str):
    with open(md_file, 'r', encoding='utf-8') as f:
        content = md.convert(f.read())

    with open(template_file, 'r', encoding='utf-8') as f:
        template = f.read()

    html = template.replace('{{CONTENT}}', content)
    html = html.replace('{{TOC}}', md.toc)

    try:
        dark_formatter = HtmlFormatter(
            style='stata-dark',
            css_class='hl',
        )
        light_formatter = HtmlFormatter(
            style='friendly',
            css_class='hl',
        )
        dark = dark_formatter.get_style_defs('.hl')
        light = light_formatter.get_style_defs('.hl')
        html = html.replace('{{HEAD}}', '<style> {0} @media (prefers-color-scheme: dark) {{ {1} }} </style>'.format(light, dark))
    except Exception as e:
        print(f"Pygments formatting failed: {e}")
        html = html.replace('{{HEAD}}', '')

    try:
        soup = bs4.BeautifulSoup(html, 'html.parser')
        for style in soup.find_all('style'):
            minified_css = rcssmin.cssmin(style.string)
            style.string.replace_with(minified_css)
        html = str(soup)
        html = htmlmin.minify(html, remove_empty_space=True, remove_all_empty_space=True)
    except Exception as e:
        print(f"HTML minification failed: {e}")

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html)

# Injecting the custom lexer directly because im too lazy to do it properly 
pygments.lexers._lexer_cache['USRLLexer'] = USRLLexer
pygments.lexers.LEXERS['USRLLexer'] = ('__main__', 'USRLLexer', ('usrl',), ('*.usrl',), ('text/x-usrl',))

manual_edit_time = 0
template_edit_time = 0
md_file = 'MANUAL.md'
template_file = 'manual/template.html'
output_file = 'src/manual.html'

md = markdown.Markdown(
    extensions=[
        toc.TocExtension(),
        tables.TableExtension(),
        fenced_code.FencedCodeExtension(),
        codehilite.CodeHiliteExtension(
            use_pygments=True,
            linenums=False,
            guess_lang=False,
            cssclass='hl',
        ),
    ],
)

while True:
    if os.stat(md_file).st_mtime == manual_edit_time and os.stat(template_file).st_mtime == template_edit_time:
        time.sleep(0.5)
        continue

    print("Changes detected, rebuilding manual...", end=' ', flush=True)
    manual_edit_time = os.stat(md_file).st_mtime
    template_edit_time = os.stat(template_file).st_mtime
    build(md, md_file, template_file, output_file)
    print("DONE")