// Run with Node and Playwright installed; see ../README.md.
// Serve under /Somnus/ to exercise the same relative paths as GitHub Pages.
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const http = require('node:http');
const path = require('node:path');
const { chromium, webkit } = require(process.env.SOMNUS_PLAYWRIGHT || 'playwright');
const root = path.resolve(__dirname, '..');
const data = require('../demo-data.js');
const mime = { '.html': 'text/html', '.css': 'text/css', '.js': 'text/javascript', '.png': 'image/png' };

const server = http.createServer(async (request, response) => {
  const pathname = new URL(request.url, 'http://localhost').pathname;
  const relative = pathname.replace(/^\/Somnus\//, '') || 'index.html';
  const filename = path.resolve(root, relative);
  if (!pathname.startsWith('/Somnus/') || !filename.startsWith(root + path.sep)) {
    response.writeHead(404).end();
    return;
  }
  try {
    const body = await fs.readFile(filename);
    response.writeHead(200, { 'Content-Type': mime[path.extname(filename)] || 'application/octet-stream' }).end(body);
  } catch {
    response.writeHead(404).end();
  }
});

async function main() {
  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', resolve);
  });
  const url = `http://127.0.0.1:${server.address().port}/Somnus/`;
  let browser;
  try {
    browser = await (process.env.SOMNUS_BROWSER === 'webkit' ? webkit : chromium).launch();
    const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('response', response => { if (response.status() >= 400) errors.push(`${response.status()} ${response.url()}`); });
    await page.goto(url);
    await page.getByRole('link', { name: 'Try in your browser', exact: true }).first().click();
    const app = page.frameLocator('iframe[title^="Interactive Somnus"]');
    await app.locator('[data-tab="dashboard"]').waitFor();
    assert.match(await app.locator('#app-content').innerText(), /Last Night/i);
    const lastNight = data.summarize('1D');
    assert.ok((await app.locator('.stage-card').innerText()).includes(`Deep ${Math.round(lastNight.stageBreakdown[0].percentage * 100)}%`));
    assert.match(await app.locator('.stage-card').getAttribute('aria-label'), new RegExp(`Deep ${Math.round(lastNight.stageBreakdown[0].percentage * 100)}(?:%| percent)`), 'Stage values must be available to screen readers');
    await app.locator('[data-tab="dashboard"]').focus();
    await app.locator('[data-tab="dashboard"]').press('Tab');
    assert.equal(await app.locator('[data-tab="trends"]').evaluate(element => getComputedStyle(element).outlineStyle), 'solid', 'Keyboard navigation must have visible focus');

    // The same usable demo must fit desktop, narrow mobile, and modern iPhone widths.
    for (const width of [1440, 390, 320]) {
      await page.setViewportSize({ width, height: 1000 });
      assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), `Homepage overflow at ${width}px`);
      assert.ok(await app.locator('body').evaluate(() => document.documentElement.scrollWidth <= innerWidth), `App overflow at ${width}px`);
      for (const tab of ['dashboard', 'trends', 'settings']) {
        await app.locator(`[data-tab="${tab}"]`).click();
        assert.equal(await app.locator(`[data-tab="${tab}"]`).getAttribute('aria-current'), 'page');
      }
    }

    await app.locator('[data-tab="trends"]').click();
    const chartShapes = new Set();
    for (const period of data.periods) {
      await app.getByRole('button', { name: period, exact: true }).click();
      const summary = data.summarize(period);
      assert.match(await app.locator('#app-content').innerText(), new RegExp(summary.averageSleepHours.toFixed(1).replace('.', '\\.') + ' hours'));
      const chart = app.locator('.chart').first();
      assert.ok(await chart.isVisible(), `${period} debt chart missing`);
      chartShapes.add(await chart.innerHTML());
      const debtSummary = await app.locator('.debt-summary').innerText();
      assert.ok(debtSummary.includes(`${Math.abs(summary.targetRunningBalance).toFixed(1)}h behind`), `${period} balance sign or total`);
      await chart.locator('[data-point]').first().click();
      assert.ok((await app.locator('#sleep-debt .chart-selection').innerText()).includes(`${summary.debtBuckets[0].hours.toFixed(1)}h`));
      assert.ok(!(await app.locator('#app-content').innerHTML()).match(/NaN|undefined/), `${period} invalid output`);
      await app.locator('.chart').last().scrollIntoViewIfNeeded();
    }
    assert.equal(chartShapes.size, data.periods.length, 'Period buttons must render distinct charts');

    // Keyboard-accessible settings must survive tab switches and affect the metrics.
    await app.locator('[data-tab="settings"]').click();
    const sliders = app.locator('input[type="range"]');
    assert.equal(await sliders.count(), 2);
    await sliders.nth(0).focus();
    await sliders.nth(0).press('Home');
    const target = Number(await sliders.nth(0).inputValue());
    await sliders.nth(1).focus();
    await sliders.nth(1).press('End');
    const minimum = Number(await sliders.nth(1).inputValue());
    await app.locator('[data-tab="trends"]').click();
    await app.getByRole('button', { name: '1W', exact: true }).click();
    const changed = data.summarize('1W', target, minimum);
    assert.ok((await app.locator('#app-content').innerText()).includes(`${Math.round(changed.targetComplianceRate * 100)}%`));
    assert.ok((await app.locator('.debt-summary').innerText()).includes(`${changed.targetRunningBalance.toFixed(1)}h ahead`));
    await app.locator('[data-tab="settings"]').click();
    assert.equal(Number(await sliders.nth(0).inputValue()), target);
    assert.equal(Number(await sliders.nth(1).inputValue()), minimum);
    await app.getByRole('button', { name: 'How Sleep Data Works', exact: true }).click();
    assert.ok(await app.locator('dialog').isVisible());
    await app.locator('#dialog-done').press('Escape');
    assert.ok(!(await app.locator('dialog').isVisible()));
    assert.equal(await app.getByRole('link', { name: 'Sleep Foundation Resources' }).getAttribute('href'), 'https://www.sleepfoundation.org');

    await sliders.nth(1).focus();
    await sliders.nth(1).press('Home');
    for (let step = 0; step < 3; step++) await sliders.nth(1).press('ArrowRight');
    assert.equal(await sliders.nth(1).inputValue(), '6.5');
    await app.locator('[data-tab="trends"]').click();
    await app.getByRole('button', { name: '5Y', exact: true }).click();
    assert.ok((await app.locator('#sleep-duration .chart').textContent()).includes('6.5h'), 'Fractional minimum must be labeled on the chart');
    await app.locator('summary').click();
    await app.getByRole('button', { name: '10Y', exact: true }).click();
    assert.equal(await app.locator('details').getAttribute('open'), '', 'Period changes retain expanded detail');

    await app.locator('[data-tab="dashboard"]').click();
    await app.locator('summary').click();
    assert.equal(await app.locator('details').getAttribute('open'), '');
    const dashboardScroll = await app.locator('#app-content').evaluate(element => {
      element.scrollTo({ top: 100, behavior: 'instant' });
      return element.scrollTop;
    });
    assert.ok(dashboardScroll > 0, 'Dashboard has scrollable content');
    await app.locator('[data-tab="settings"]').click();
    await app.locator('[data-tab="dashboard"]').click();
    assert.equal(await app.locator('details').getAttribute('open'), '', 'Tab changes retain expanded detail');
    assert.ok(Math.abs(await app.locator('#app-content').evaluate(element => element.scrollTop) - dashboardScroll) <= 1, 'Tab changes restore scroll position');
    await app.getByRole('button', { name: /Sleep Debt/ }).click();
    assert.equal(await app.locator('[data-tab="trends"]').getAttribute('aria-current'), 'page');
    assert.equal(await app.getByRole('button', { name: '1W', exact: true }).getAttribute('aria-pressed'), 'true');
    await app.locator('[data-tab="dashboard"]').click();
    await app.getByRole('button', { name: /Sleep Stages/ }).click();
    assert.equal(await app.locator('[data-tab="trends"]').getAttribute('aria-current'), 'page');

    if (process.env.SOMNUS_SCREENSHOTS) {
      await fs.mkdir(process.env.SOMNUS_SCREENSHOTS, { recursive: true });
      await page.setViewportSize({ width: 1440, height: 1100 });
      await page.locator('#demo').screenshot({ path: path.join(process.env.SOMNUS_SCREENSHOTS, 'marketing-demo.png') });
      await page.goto(url + 'demo.html');
      await page.setViewportSize({ width: 390, height: 844 });
      for (const tab of ['dashboard', 'trends', 'settings']) {
        await page.locator(`[data-tab="${tab}"]`).click();
        await page.screenshot({ path: path.join(process.env.SOMNUS_SCREENSHOTS, `${tab}.png`) });
      }
    }
    assert.deepEqual(errors, [], 'Browser errors or missing assets');
    console.log('PASS: responsive embed, six periods, charts, settings, dialogs, and dashboard deep links');
  } finally {
    if (browser) await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
}
main().catch(error => {
  console.error(error);
  server.close();
  process.exitCode = 1;
});
