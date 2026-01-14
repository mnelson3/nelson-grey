#!/usr/bin/env bash
set -euo pipefail

# Validate project manifests against a minimal expected shape.
# Uses Ruby's built-in YAML parser (psych) to avoid external dependencies.
#
# Usage:
#   ./validate-config.sh .cicd/projects/*.yml
# Exits non-zero on the first invalid manifest.

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <manifest.yml> [more.yml ...]" >&2
  exit 2
fi

validate_file() {
  local file="$1"
  ruby - <<'RB'
require "yaml"
file = ENV.fetch("FILE")
begin
  data = YAML.load_file(file)
rescue => e
  abort "[validate-config] #{file}: YAML parse error: #{e.message}"
end

unless data.is_a?(Hash) && data.key?("project")
  abort "[validate-config] #{file}: missing required 'project' section"
end
project = data["project"] || {}
unless project["name"] && project["repo"]
  abort "[validate-config] #{file}: project.name and project.repo are required"
end

targets = data["targets"] || {}
if targets.empty?
  abort "[validate-config] #{file}: at least one target is required (mobile/web/firebase/chrome_extension)"
end

allowed_targets = %w[mobile web firebase chrome_extension]
unknown = targets.keys - allowed_targets
unless unknown.empty?
  abort "[validate-config] #{file}: unknown targets #{unknown.inspect}"
end

mobile = targets["mobile"] || {}
if targets.key?("mobile")
  unless mobile.is_a?(Hash)
    abort "[validate-config] #{file}: targets.mobile must be a map"
  end
end

web = targets["web"] || {}
if targets.key?("web")
  unless web.is_a?(Hash)
    abort "[validate-config] #{file}: targets.web must be a map"
  end
end

firebase = targets["firebase"] || {}
if targets.key?("firebase")
  unless firebase.is_a?(Hash)
    abort "[validate-config] #{file}: targets.firebase must be a map"
  end
end

chrome = targets["chrome_extension"] || {}
if targets.key?("chrome_extension")
  unless chrome.is_a?(Hash)
    abort "[validate-config] #{file}: targets.chrome_extension must be a map"
  end
end

puts "[validate-config] #{file}: OK"
RB
}

for f in "$@"; do
  FILE="$f" validate_file || exit 1
done
