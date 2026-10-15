"""mkdocs hook: links from the pages to files outside docs/ go to the repository on the forge.

The hand-written pages link to the fabrication package, the KiCad sources and other files of the repository with
relative paths (`../fab/<board>/README.md`), which read on the forge; the site does not publish those files, so mkdocs
would warn about every such link and `--strict` fail. Before mkdocs validates a page, this hook rewrites each
Markdown link or image whose target resolves outside the docs directory but inside the repository to the file's URL at
the repository: `repo_url` plus `blob/<branch>/<path>`, an image `raw/<branch>/<path>`. A target that does not exist
is left for mkdocs to report; a link outside the repository, an absolute URL, an anchor and raw HTML are left alone.
`extra.outward_links` in mkdocs.yml sets `branch` (default `main`) and the forge's path shapes `blob` and `raw`
(defaults GitHub's; Codeberg's would be `src/branch/{branch}` and `raw/branch/{branch}`). From kicad-libs
templates/kicad-repo (PLANS 2026-10-14, the board site, step 4); Python standard library only.
"""
import pathlib
import re

LINK = re.compile(r"(!?)\[([^\]]*)\]\(([^)\s]+)(\s+\"[^\"]*\")?\)")


def rewrite_links(markdown, source, docs_dir, repo_root, repo_url, branch="main", blob="blob/{branch}", raw="raw/{branch}"):
    """MARKDOWN of the page at SOURCE (a path under DOCS_DIR) with its outward links rewritten; pure, for a test."""
    source, docs_dir, repo_root = pathlib.Path(source).resolve(), pathlib.Path(docs_dir).resolve(), pathlib.Path(repo_root).resolve()

    def rewrite(match):
        bang, text, target, title = match.groups()
        if "://" in target or target.startswith(("#", "/", "mailto:", "<")):
            return match.group(0)
        path, _, fragment = target.partition("#")
        resolved = (source.parent / path).resolve()
        if resolved == docs_dir or docs_dir in resolved.parents:
            return match.group(0)  # inside docs/: mkdocs's business
        if repo_root != resolved and repo_root not in resolved.parents:
            return match.group(0)  # outside the repository: left alone
        if not resolved.exists():
            return match.group(0)  # a broken link stays for mkdocs to report
        shape = raw if bang else blob
        url = f"{repo_url.rstrip('/')}/{shape.format(branch=branch)}/{resolved.relative_to(repo_root).as_posix()}"
        return f"{bang}[{text}]({url}{'#' + fragment if fragment else ''}{title or ''})"

    return LINK.sub(rewrite, markdown)


def on_page_markdown(markdown, page, config, files):
    repo_url = config.get("repo_url") or ""
    if not repo_url:
        return markdown
    options = (config.get("extra") or {}).get("outward_links") or {}
    docs_dir = pathlib.Path(config["docs_dir"])
    return rewrite_links(markdown, docs_dir / page.file.src_path, docs_dir, pathlib.Path(config.config_file_path).parent, repo_url,
                         options.get("branch", "main"), options.get("blob", "blob/{branch}"), options.get("raw", "raw/{branch}"))
