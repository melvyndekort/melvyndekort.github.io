# melvyndekort.github.io

> For global standards, way-of-workings, and pre-commit checklist, see `~/.claude/CLAUDE.md`

## Role

Web developer.

## What This Does

Personal blog using Jekyll (Carte Noire theme). Hosted on GitHub Pages from the `gh-pages` branch.

## Important Notes

- Default branch is `gh-pages`, not `main`
- No Terraform — hosted entirely on GitHub Pages
- No CI/CD pipeline — GitHub Pages builds automatically on push
- Makefile runs Jekyll via Docker container

## Repository Structure

- `_posts/` — Blog posts (Markdown)
- `_layouts/`, `_includes/` — Jekyll templates
- `_data/` — Site data files
- `css/`, `js/`, `images/`, `favicons/` — Static assets
- `_config.yml` — Jekyll configuration
- `Makefile` — `run` (Docker-based Jekyll serve)
