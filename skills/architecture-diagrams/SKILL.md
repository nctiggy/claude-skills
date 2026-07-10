---
name: architecture-diagrams
description: >-
  Author clear, maintainable architecture diagrams and explanatory docs as code. Uses D2 for
  structural diagrams (context / container / component) and Mermaid for behavioural diagrams
  (sequence / state / flow), organised by the C4 mental model, rendered into an MkDocs Material
  site (or any Markdown host). Diagram-as-code, brand-aware, honest about built-vs-designed. Use
  when someone asks for an architecture diagram, a "what does this do" explainer, or a docs site
  that visualises a system.
---

# Architecture Diagrams (as code)

The goal: diagrams that read as one system, stay in version control, and never drift from reality
because they're **text, reviewed like code**. Pick the right tool per diagram, structure by the C4
levels, and be explicit about what exists vs. what's designed.

## Tool choice — the one rule

| Diagram kind | Tool | Why |
|---|---|---|
| **Structural** — boxes, containers, who-talks-to-what (context / container / component) | **D2** | Best auto-layout for architecture (ELK/TALA); container nesting + edge routing beat Mermaid's dagre. Renders to SVG at build time via `mkdocs-d2-plugin`. |
| **Behavioural** — sequence, state machine, decision flow | **Mermaid** | Native to MkDocs Material & GitHub, zero build step, `sequenceDiagram` / `stateDiagram-v2` / `flowchart` are exactly the right primitives. |
| **Auto-from-manifests** (live K8s) | KubeDiagrams (upstream: `github.com/philippemerle/KubeDiagrams`; out of scope here) | Only when the system is *deployed and real*. Skip for early/scaffold repos — it diagrams what exists, not the concept. |

Don't force everything into one tool. D2 for the "map", Mermaid for the "movie".

## Structure by C4 (the mental model, not the ceremony)

Author top-down; each level zooms in one step. You rarely need Structurizr itself — just borrow the levels:

1. **System context** — the system as one box; who uses it, what it sits between. (D2)
2. **Container** — the deployable pieces inside (services, operator, agent, DB, CLI). (D2)
3. **Component** — inside one container: the modules/interfaces/seams. (D2)
4. **Behaviour** — how a key flow actually runs across those pieces. (Mermaid sequence/state)

Stop at the level that answers the question. A "what does this do" explainer is usually context +
container + one behaviour diagram.

## The honesty principle

Architecture docs describe **intent**; code is **reality**. Always mark which is which — a status
table (built / in-progress / designed) and inline callouts. Overclaiming is the fastest way to make
docs untrusted. Read the actual code before drawing; cite real file paths.

## Toolchain

```bash
brew install d2                                   # D2 binary (structural diagrams)
pipx inject mkdocs-material mkdocs-d2-plugin       # if mkdocs-material is a pipx install
# mkdocs.yml: plugins: [search, {d2: {layout: elk}}]; superfences mermaid custom_fence
mkdocs build                                       # D2 -> inline SVG server-side; Mermaid client-side
```
Verify render before deploy (best-effort smoke test, not proof): grep the built HTML — raw
`direction:`/```d2 leaking as text means D2 didn't render; `class="mermaid"` blocks are expected
(client-rendered). Spot-check one page visually too. See
`references/diagram-patterns.md` for copy-paste D2 + Mermaid templates and the mkdocs config.

## Brand

Read the `spectrocloud-brand` skill for colours/type. Apply them to diagram fills and the site theme
so diagrams and page read as one system. Default fills: primary `#1F7A78`, deep `#043736`/`#005B5B`,
accent `#F0BE65`, warn `#B94B01`, secondary `#9EB277`, external systems lilac `#7E5C8E`, paper
`#F7F1ED`, ink `#012121`. Style both
light and dark; keep diagram SVGs on a light card in both schemes for legibility.

## Deploy

The built `site/` is static — deploy anywhere. For Cloudflare Pages:
`wrangler pages deploy site --project-name <name>`. For the site scaffold/theme/nav, compose with the
`docs-site-generator` skill (it owns the shell; this skill owns the rich diagram content). When
composing, merge this skill's `d2` plugin block into docs-site-generator's `mkdocs.yml` — keep its
existing `pymdownx.superfences` mermaid fence (both skills use the same one).

## Procedure

1. **Investigate** the real system (code, manifests, design docs) — gather actual names, files, flows.
2. **Choose levels** — which C4 levels answer the question; don't over-produce.
3. **Draw structural** in D2 (context → container → component), branded fills.
4. **Draw behavioural** in Mermaid (the 1–2 flows that matter).
5. **Write the honesty layer** — status table + built-vs-designed callouts.
6. **Build, verify render, deploy.**

## Files
- `references/diagram-patterns.md` — D2 + Mermaid copy-paste templates, mkdocs.yml snippet, verify commands.
