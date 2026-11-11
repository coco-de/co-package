#!/usr/bin/env bash
# Build and scan all browser examples from an authenticated checkout.
set -euo pipefail
cd "$(dirname "$0")/../.."
repo_root=$PWD
site_dir="$repo_root/build/pages"
flutter pub get --no-example
for entry in open_board:open-board open_epub:open-epub xterm2:xterm2; do
  package=${entry%%:*}
  route=${entry##*:}
  (
    cd "packages/$package/example"
    if [[ "$package" == xterm2 ]]; then flutter pub get --no-example; fi
    flutter build web --release --no-wasm-dry-run --base-href "/co-package/$route/"
  )
done
mkdir -p "$site_dir"
cp tool/pages/index.html "$site_dir/index.html"
cat packages/co_example_ui/fonts/LICENSE.txt packages/co_example_ui/fonts/NotoSansArabic-LICENSE.txt > "$site_dir/FONT-LICENSES.txt"
touch "$site_dir/.nojekyll"
for entry in open_board:open-board open_epub:open-epub xterm2:xterm2; do
  package=${entry%%:*}
  route=${entry##*:}
  stage_dir=$(mktemp -d "$site_dir/.${route}.XXXXXX")
  cp -R "packages/$package/example/build/web/." "$stage_dir/"
  if [[ -d "$site_dir/$route" ]]; then rm -r "${site_dir:?}/${route:?}"; fi
  mv "$stage_dir" "$site_dir/$route"
done
python3 tool/pages/check_no_credentials.py "$site_dir"
printf 'Pages site: %s\n' "$site_dir"
