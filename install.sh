#!/usr/bin/env bash
# agentscar installer: copies bin/agentscar onto your PATH. No other side effects.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$HOME/.local/bin" 2>/dev/null || true
for d in "$HOME/.local/bin" /usr/local/bin; do
  if [ -d "$d" ] && [ -w "$d" ]; then
    cp "$here/bin/agentscar" "$d/agentscar" && chmod +x "$d/agentscar"
    printf 'installed: %s/agentscar\n' "$d"
    case ":$PATH:" in
      *":$d:"*) ;;
      *) printf 'note: %s is not on your PATH — add it to your shell profile.\n' "$d" ;;
    esac
    exit 0
  fi
done
printf 'no writable install dir found; copy bin/agentscar onto your PATH manually.\n' >&2
exit 1
