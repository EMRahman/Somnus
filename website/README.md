# Marketing site and interactive demo

This is a buildless static site, published by the existing GitHub Pages workflow. No dependency installation or compilation is needed to serve it.

The homepage's **Try in your browser** links lead to `#demo`, which embeds `demo.html` in an iPhone frame. The **Open demo in a full window** link opens `demo-window.html`, which uses the same iPhone outline and sizes it to fit the browser window. The demo runs entirely in the browser with fictional data; it makes no HealthKit requests, uses no storage, and resets when reloaded.

## Preview

From the repository root:

```sh
python3 -m http.server 8765 --directory website
```

Open `http://localhost:8765/#demo`. You can also open `website/index.html` directly, because all assets and scripts use relative paths and require no server APIs.

## Implementation

- `demo.html`, `demo.css`, and `demo.js` reproduce the app's dark Dashboard, Trends, and Settings screens. The native SwiftUI source and the screenshots in `assets/` are the visual references.
- `demo-data.js` generates 3,652 fictional nights ending on 21 October 2026. A fixed date keeps previews reproducible. The 1D, 1W, 1M, 1Y, 5Y, and 10Y views all derive from this same history.
- Accumulated debt sums positive nightly shortfalls. The signed net balance also accounts for surplus sleep, matching the native app's separate metrics. The sleep target controls debt; the minimum acceptable duration controls target compliance and duration-chart thresholds. Both are session-only demo settings.
- Daily and weekly charts show stage timelines. Longer ranges aggregate into weekly, monthly, or yearly buckets. The score uses the native app's weighted components.

## Verification

Calculation and data invariants require only Node:

```sh
node --test website/tests/demo-data.test.cjs
node --check website/demo.js
```

The browser regression script uses Playwright. Install its test-only dependency outside the site, then run from the repository root:

```sh
npm install --prefix /tmp/somnus-demo-qa playwright@1.64.1
/tmp/somnus-demo-qa/node_modules/.bin/playwright install chromium webkit
SOMNUS_PLAYWRIGHT=/tmp/somnus-demo-qa/node_modules/playwright node website/tests/browser.cjs
SOMNUS_PLAYWRIGHT=/tmp/somnus-demo-qa/node_modules/playwright SOMNUS_BROWSER=webkit node website/tests/browser.cjs
```

The script serves the site under `/Somnus/`, matching GitHub Pages. It checks desktop and narrow mobile widths, six distinct chart ranges, goal changes, tab navigation, retained scroll and disclosures, keyboard focus, accessible stage values, fractional minimum labels, dialogs, and dashboard deep links. Set `SOMNUS_SCREENSHOTS=/tmp/somnus-demo-screenshots` to capture the embedded view and each app tab for visual comparison with the native screenshots. Browser runs need permission to bind a local port and launch a browser.

For manual review, also scroll every tab, select individual chart bars, check the 5Y/10Y axis labels, close dialogs with Escape, and verify keyboard focus remains visible. In Settings, set the minimum above the target and check that the two independently retain their native meanings.
