#!/usr/bin/env bash
# scaffold_poc_site.sh — render the spectrocloud-poc-docs templates into a new docs-site.
#
# Usage:
#   scaffold_poc_site.sh <dest-dir> \
#     --site-name "Acme × Spectro Cloud — Palette POC Guide" \
#     --project acme-docs \
#     [--description "Phased proof-of-value ..."] \
#     [--customer "Acme"] \
#     [--customer-domain acme.com] \
#     [--phase-title "Single-Node Cluster (Agent Mode)"] \
#     [--assets-from <existing-docs-site-dir>]   # copies logo/favicon assets
#
# <dest-dir> must not already exist (refuses to clobber).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES="$SCRIPT_DIR/../references/templates"

DEST="" SITE_NAME="" PROJECT="" DESCRIPTION="" CUSTOMER="" CUSTOMER_DOMAIN="customer.example"
PHASE_TITLE="First Cluster" ASSETS_FROM=""

usage() { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --site-name)       SITE_NAME="$2"; shift 2 ;;
    --project)         PROJECT="$2"; shift 2 ;;
    --description)     DESCRIPTION="$2"; shift 2 ;;
    --customer)        CUSTOMER="$2"; shift 2 ;;
    --customer-domain) CUSTOMER_DOMAIN="$2"; shift 2 ;;
    --phase-title)     PHASE_TITLE="$2"; shift 2 ;;
    --assets-from)     ASSETS_FROM="$2"; shift 2 ;;
    -h|--help)         usage ;;
    -*)                echo "unknown flag: $1" >&2; usage 1 ;;
    *)                 [ -z "$DEST" ] && DEST="$1" || { echo "unexpected arg: $1" >&2; exit 1; }; shift ;;
  esac
done

[ -n "$DEST" ] && [ -n "$SITE_NAME" ] && [ -n "$PROJECT" ] || { echo "dest, --site-name and --project are required" >&2; usage 1; }
[ -e "$DEST" ] && { echo "refusing to overwrite: $DEST already exists" >&2; exit 1; }
case "$PROJECT" in
  *[!a-z0-9-]*) echo "--project must be lowercase alnum + dashes (Cloudflare Pages project name): $PROJECT" >&2; exit 1 ;;
esac
[ -z "$DESCRIPTION" ] && DESCRIPTION="Self-guided Palette POC for ${CUSTOMER:-the customer}"
[ -z "$CUSTOMER" ] && CUSTOMER="the customer"

mkdir -p "$DEST/docs/reference" "$DEST/docs/assets/images" "$DEST/docs/overrides/stylesheets"

# render <template> <output>: substitute {{PLACEHOLDER}} tokens.
render() {
  python3 - "$1" "$2" <<'PY'
import sys
src, out = sys.argv[1], sys.argv[2]
import os
subs = {
    "SITE_NAME": os.environ["S_SITE_NAME"],
    "SITE_DESCRIPTION": os.environ["S_DESCRIPTION"],
    "PROJECT": os.environ["S_PROJECT"],
    "CUSTOMER": os.environ["S_CUSTOMER"],
    "CUSTOMER_DOMAIN": os.environ["S_CUSTOMER_DOMAIN"],
    "PHASE_TITLE": os.environ["S_PHASE_TITLE"],
}
text = open(src, encoding="utf-8").read()
for key, val in subs.items():
    text = text.replace("{{%s}}" % key, val)
open(out, "w", encoding="utf-8").write(text)
PY
}
export S_SITE_NAME="$SITE_NAME" S_DESCRIPTION="$DESCRIPTION" S_PROJECT="$PROJECT" \
       S_CUSTOMER="$CUSTOMER" S_CUSTOMER_DOMAIN="$CUSTOMER_DOMAIN" S_PHASE_TITLE="$PHASE_TITLE"

render "$TEMPLATES/mkdocs.yml.tmpl"          "$DEST/mkdocs.yml"
render "$TEMPLATES/wrangler.toml.tmpl"       "$DEST/wrangler.toml"
render "$TEMPLATES/gitignore.tmpl"           "$DEST/.gitignore"
render "$TEMPLATES/index.md.tmpl"            "$DEST/docs/index.md"
render "$TEMPLATES/prerequisites.md.tmpl"    "$DEST/docs/prerequisites.md"
render "$TEMPLATES/phase.md.tmpl"            "$DEST/docs/phase-1.md"
render "$TEMPLATES/support.md.tmpl"          "$DEST/docs/reference/support.md"
render "$TEMPLATES/poc-test-suite.yaml.tmpl" "$DEST/poc-test-suite.yaml"
render "$TEMPLATES/deploy.yaml.tmpl"         "$DEST/deploy.yaml"
cp "$TEMPLATES/brand.css"                    "$DEST/docs/overrides/stylesheets/brand.css"

# Logo / favicon assets (binary — not shipped in the skill).
NEED_ASSETS="spectrocloud-logo-white.svg spectrocloud-logo.png favicon.png"
if [ -n "$ASSETS_FROM" ]; then
  for f in $NEED_ASSETS; do
    src="$ASSETS_FROM/docs/assets/images/$f"
    [ -f "$src" ] && cp "$src" "$DEST/docs/assets/images/$f" || echo "warn: missing asset $src" >&2
  done
else
  echo "NOTE: copy logo assets ($NEED_ASSETS) into $DEST/docs/assets/images/" >&2
  echo "      (source: an existing docs-site or the spectrocloud-brand skill)" >&2
fi

echo "scaffolded $DEST"
echo "next:"
echo "  1. author docs/ (see references/authoring-guide.md)"
echo "  2. static QA:   python3 $SCRIPT_DIR/check_docs.py $DEST"
echo "  3. live test:   python3 $SCRIPT_DIR/run_doc_tests.py --suite $DEST/poc-test-suite.yaml --adapter <lab-adapter>"
echo "  4. publish:     $SCRIPT_DIR/deploy/cf-pages.sh deploy --site-dir $DEST"
