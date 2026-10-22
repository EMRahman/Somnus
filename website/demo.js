(() => {
  'use strict';

  const data = window.SomnusDemoData;
  const content = document.getElementById('app-content');
  const dialog = document.getElementById('info-dialog');
  const state = {
    tab: 'dashboard', period: '1W', target: 8, minimum: 7,
    views: {
      dashboard: { scrollTop: 0, detailOpen: false },
      trends: { scrollTop: 0, detailOpen: false },
      settings: { scrollTop: 0, detailOpen: false }
    }
  };
  const stageColors = { deep: '#252585', rem: '#5b47b9', core: '#9181d8', awake: '#ff9959' };
  const stageNames = { deep: 'Deep', rem: 'REM', core: 'Core', awake: 'Awake' };
  const periodNames = { '1D': 'Last Night', '1W': 'Past 7 Days', '1M': 'Past Month', '1Y': 'Past Year', '5Y': 'Past 5 Years', '10Y': 'Past 10 Years' };
  const iconPaths = {
    moon: '<path d="M20.8 15.1A9 9 0 0 1 8.9 3.2a9.2 9.2 0 1 0 11.9 11.9Z" fill="currentColor"/>',
    trends: '<path d="M3 2v19h19M5 13l5-5 5 5 6-7" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/><g fill="currentColor"><circle cx="5" cy="13" r="1.8"/><circle cx="10" cy="8" r="1.8"/><circle cx="15" cy="13" r="1.8"/><circle cx="21" cy="6" r="1.8"/></g>',
    settings: '<path d="m9.5 2-.7 2.4-2 .9-2.3-.9-2 3.5L4.4 10l-.1 2.2-1.8 1.7 2 3.5 2.4-.4 1.8 1.1.7 2.5h4.1l.7-2.5 1.9-1.1 2.3.4 2-3.5-1.8-1.7-.1-2.2 1.9-2.1-2-3.5-2.3.9-2-.9L13.5 2Z" fill="currentColor"/><circle cx="11.5" cy="11.5" r="3.5" fill="#222225"/>',
    target: '<g fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="9.2"/><circle cx="12" cy="12" r="5.7"/><circle cx="12" cy="12" r="2.2"/></g>',
    debt: '<path d="M4.8 6A9 9 0 1 1 3 15M4.8 2v5.6H.4" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/><path d="M12 6.6v6.7" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><circle cx="12" cy="17" r="1.2" fill="currentColor"/>',
    heart: '<path d="M12 21 3.8 13C-3 6.5 6-1 12 5.5 18-1 27 6.5 20.2 13Z" fill="currentColor"/>',
    info: '<circle cx="12" cy="12" r="10" fill="currentColor"/><path d="M12 10v7" stroke="#000" stroke-width="2"/><circle cx="12" cy="7" r="1.2" fill="#000"/>',
    watch: '<rect x="6" y="5" width="12" height="14" rx="4" fill="none" stroke="currentColor" stroke-width="1.7"/><path d="M8 5V1h8v4M8 19v4h8v-4" fill="none" stroke="currentColor" stroke-width="1.7"/>',
    bed: '<path d="M3 6v14M21 11v9M3 17h18M3 10h5a3 3 0 0 1 3 3v4M11 10h7a3 3 0 0 1 3 3v4" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><rect x="5" y="7" width="4" height="4" rx="1" fill="currentColor"/>',
    sunrise: '<path d="M3 18h18M5 22h14M6 15a6 6 0 0 1 12 0M12 2v3M3 7l2 2M21 7l-2 2M1 13h3M20 13h3M12 12V7m-3 3 3-3 3 3" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>',
    waveform: '<path d="M2 12h3l2-7 4 15 3-17 3 13 2-4h3" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round" stroke-linecap="round"/>',
    eye: '<path d="M1.5 12s4-7 10.5-7 10.5 7 10.5 7-4 7-10.5 7S1.5 12 1.5 12Z" fill="none" stroke="currentColor" stroke-width="1.8"/><circle cx="12" cy="12" r="3.5" fill="currentColor"/>',
    gauge: '<path d="M4 19a10 10 0 1 1 16 0M5 12H3m4-6L5 4m7 1V2m5 4 2-2m0 8h2M12 14l5-6" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/><circle cx="12" cy="14" r="2" fill="currentColor"/>',
    calendar: '<rect x="3" y="5" width="18" height="17" rx="2" fill="none" stroke="currentColor" stroke-width="1.7"/><path d="M7 2v6M17 2v6M3 10h18M7 14h2m3 0h2m3 0h1M7 18h2m3 0h2" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/>'
  };
  const icon = name => `<svg viewBox="0 0 24 24" aria-hidden="true">${iconPaths[name] || iconPaths.info}</svg>`;
  const num = (value, digits = 1) => Number(value).toFixed(digits);
  const hoursLabel = value => `${Number(value)}h`;
  const debtColor = hours => hours > 5 ? '#ff453a' : hours > 2 ? '#ff9828' : '#2bd158';
  const escape = value => String(value).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const clock = minutes => {
    const rounded = Math.round(minutes);
    const h = ((Math.floor(rounded / 60) % 24) + 24) % 24;
    return `${h % 12 || 12}:${String(rounded % 60).padStart(2, '0')} ${h < 12 ? 'AM' : 'PM'}`;
  };
  const summary = period => data.summarize(period, state.target, state.minimum);
  const metric = (title, value, symbol, subtitle, extra = '', color = '') => `<div class="card metric-hero"><span class="metric-icon ${extra}"${color ? ` style="color:${color}"` : ''}>${icon(symbol)}</span><strong class="hero-value">${value}</strong><div class="metric-label">${title}</div><div class="metric-subtitle">${subtitle}</div></div>`;
  const smallMetric = (title, value, symbol, color) => `<div class="small-metric"><div class="small-metric-heading"><span class="small-icon" style="color:${color}">${icon(symbol)}</span><span>${title}</span></div><strong>${value}</strong></div>`;
  const disclosure = body => `<details class="card detail-card"><summary>More Detail</summary><div class="detail-content">${body}</div></details>`;
  const stageLegend = (stages, percentages = false) => `<div class="legend">${stages.map(s => `<span><i class="dot stage-${s.stage}"></i>${stageNames[s.stage]}${percentages ? ` ${Math.round(s.percentage * 100)}%` : ''}</span>`).join('')}</div>`;

  function dashboard() {
    const week = summary('1W');
    const last = summary('1D');
    const night = last.timeline.at(-1);
    const score = week.score;
    const ringColor = score.overall >= 90 ? '#2bd158' : score.overall >= 75 ? '#72c75b' : '#ffd60a';
    const circumference = 2 * Math.PI * 66;
    const rows = [['Duration', score.durationScore], ['Efficiency', score.efficiencyScore], ['Consistency', score.consistencyScore], ['Sleep Stages', score.stageScore]];
    return `<div class="screen dashboard-screen">
      <section class="card night-header"><p class="eyebrow">LAST NIGHT</p><h1>${last.averageSleepHours < state.minimum ? 'Only' : 'You slept'} ${num(last.averageSleepHours)} hours last night</h1><p class="night-time">${clock(night.bedtimeMinutes)} — ${clock(night.wakeMinutes)}</p></section>
      <section class="ring-wrap" aria-label="Sleep score ${score.overall} out of 100, ${score.grade}"><div class="ring-glow"></div><svg class="score-ring" viewBox="0 0 160 160" aria-hidden="true"><defs><linearGradient id="ring-gradient" x1="0" y1="0" x2="1" y2="1"><stop stop-color="${ringColor}" stop-opacity=".65"/><stop offset="1" stop-color="${ringColor}"/></linearGradient></defs><circle cx="80" cy="80" r="66" stroke="#15251c" stroke-width="11" fill="none"/><circle cx="80" cy="80" r="66" stroke="url(#ring-gradient)" stroke-width="11" stroke-linecap="round" fill="none" stroke-dasharray="${circumference * score.overall / 100} ${circumference}" transform="rotate(-90 80 80)"/></svg><div class="ring-value"><strong>${score.overall}</strong><span style="color:${ringColor}">${score.grade}</span><span class="ring-star" style="color:${ringColor}" aria-hidden="true">✪</span></div></section>
      <button class="card card-button metric-hero" data-deep-link="sleep-debt" aria-label="Sleep Debt: ${num(week.totalSleepDebt)} hours. Open weekly sleep debt in Trends"><span class="chevron" aria-hidden="true"></span><span class="metric-icon" style="color:${debtColor(week.totalSleepDebt)}">${icon('debt')}</span><strong class="hero-value">${week.totalSleepDebt < .5 ? 'No debt' : `${num(week.totalSleepDebt)}h debt`}</strong><div class="metric-label">Sleep Debt</div><div class="metric-subtitle">avg ${num(week.averageSleepHours)}h/night this week</div></button>
      <button class="card card-button stage-card" data-deep-link="sleep-duration" aria-label="Sleep Stages: ${last.stageBreakdown.map(s => `${stageNames[s.stage]} ${Math.round(s.percentage * 100)} percent`).join(', ')}. Open weekly sleep duration in Trends"><h2 class="section-heading">Sleep Stages</h2><span class="chevron" aria-hidden="true"></span><div class="stage-strip" aria-hidden="true">${last.stageBreakdown.map(s => `<span class="stage-${s.stage}" style="flex:${s.percentage}"></span>`).join('')}</div>${stageLegend(last.stageBreakdown, true)}</button>
      ${disclosure(`<section class="score-breakdown"><h3>Score Breakdown</h3>${rows.map(([label, value]) => `<div class="score-row"><span>${label}</span><meter min="0" max="100" value="${value}" aria-label="${label} score ${value}"></meter><strong>${value}</strong></div>`).join('')}</section><div class="stage-minutes">${last.stageBreakdown.map(s => `<div><strong style="color:${stageColors[s.stage]}">${Math.round(s.minutes)}</strong>${stageNames[s.stage]}<small>min</small></div>`).join('')}</div><div class="metric-grid">${smallMetric('Target Nights', `${week.nightsMeetingTarget}/${week.nightCount}`, 'target', '#30d158')}${smallMetric('Efficiency', `${Math.round(week.averageEfficiency * 100)}%`, 'gauge', '#0a84ff')}</div>`)}
    </div>`;
  }

  function axisGrid(ticks, y, width = 282) {
    return ticks.map(t => `<line class="axis-grid" x1="0" x2="${width}" y1="${y(t)}" y2="${y(t)}"/><text x="${width + 5}" y="${y(t) + 3}">${Number.isInteger(t) ? t : num(t)}h</text>`).join('');
  }
  function xLabels(buckets, width = 282, y = 198) {
    const skip = Math.ceil(buckets.length / 6);
    return buckets.map((b, i) => i % skip === 0 || buckets.length <= 7 ? `<text text-anchor="middle" x="${(i + .5) * width / buckets.length}" y="${y}">${escape(b.label)}</text>` : '').join('');
  }
  function debtChart(s) {
    const buckets = s.debtBuckets;
    const max = Math.max(1, Math.ceil(Math.max(...buckets.map(b => b.cumulative)) * 1.15));
    const y = h => 179 - h / max * 166;
    const width = 282 / buckets.length;
    const short = ['1D', '1W', '1M'].includes(state.period);
    const ticks = Array.from({ length: 4 }, (_, i) => +(max * i / 3).toFixed(max > 10 ? 0 : 1));
    const bars = buckets.map((b, i) => {
      const title = `${b.label}: ${num(b.hours)}h ${b.count > 1 ? 'total' : 'nightly'} debt, ${num(b.cumulative)}h cumulative`;
      return `<g data-point="${escape(title)}" tabindex="0" role="button" aria-label="${escape(title)}"><rect x="${(i + .15) * width}" y="${y(b.hours)}" width="${width * .7}" height="${Math.max(.6, 179 - y(b.hours))}" rx="3" fill="#ce812e"/><rect x="${i * width}" y="10" width="${width}" height="170" fill="transparent"/><title>${escape(title)}</title>${short && b.hours >= .05 ? `<text class="bar-label" text-anchor="middle" x="${(i + .5) * width}" y="${b.hours / max > .14 ? y(b.hours) + 14 : y(b.hours) - 5}">${num(b.hours)}h</text>` : ''}</g>`;
    }).join('');
    const line = buckets.map((b, i) => `${(i + .5) * width},${y(b.cumulative)}`).join(' ');
    return `<svg class="chart" viewBox="0 0 320 209" role="group" aria-label="Sleep debt bars and cumulative debt line for ${periodNames[state.period]}">${axisGrid(ticks, y)}${bars}<polyline points="${line}" fill="none" stroke="#8270dc" stroke-width="1.8" pointer-events="none"/>${buckets.length <= 7 ? buckets.map((b, i) => `<circle cx="${(i + .5) * width}" cy="${y(b.cumulative)}" r="2.5" fill="#252527" stroke="#8270dc" stroke-width="1.7" pointer-events="none"/>`).join('') : ''}${xLabels(buckets)}</svg><div class="legend"><span><i class="bar-key"></i>${['1D', '1W'].includes(state.period) ? 'Nightly debt' : 'Period debt'}</span><span><i class="line-key"></i>Cumulative debt</span></div>`;
  }
  function durationChart(s) {
    const buckets = s.durationBuckets;
    const min = Math.floor(Math.min(state.minimum, state.target, ...buckets.map(b => b.hours)));
    let max = Math.ceil(Math.max(state.minimum, state.target, ...buckets.map(b => b.hours)));
    if (max <= min) max = min + 1;
    const y = h => 180 - (h - min) / (max - min) * 167;
    const barWidth = 282 / buckets.length;
    const ticks = Array.from({ length: max - min + 1 }, (_, i) => min + i);
    const bandTop = y(Math.max(state.minimum, state.target));
    const bandBottom = y(Math.min(state.minimum, state.target));
    return `<svg class="chart" viewBox="0 0 320 210" role="group" aria-label="Average sleep duration, ${periodNames[state.period]}"><rect x="0" y="${bandTop}" width="282" height="${bandBottom - bandTop}" fill="#2bd158" opacity=".08"/>${axisGrid(ticks, y)}<line x1="0" x2="282" y1="${y(state.minimum)}" y2="${y(state.minimum)}" stroke="#3eaa55" stroke-dasharray="4 3"/>${buckets.map((b, i) => {
      const title = `${b.label}: ${num(b.hours)} hours average sleep across ${b.count} nights`;
      return `<g data-point="${escape(title)}" tabindex="0" role="button" aria-label="${escape(title)}"><rect x="${(i + .12) * barWidth}" y="${y(b.hours)}" width="${barWidth * .76}" height="${Math.max(.8, 180 - y(b.hours))}" rx="2" fill="${b.hours >= state.minimum ? '#8070d7' : '#cc812e'}"/><rect x="${i * barWidth}" y="10" width="${barWidth}" height="170" fill="transparent"/><title>${escape(title)}</title>${state.period === '1M' ? `<text class="bar-label" text-anchor="middle" x="${(i + .5) * barWidth}" y="${b.hours - min > .3 ? y(b.hours) + 14 : y(b.hours) - 5}">${num(b.hours)}h</text>` : ''}</g>`;
    }).join('')}${xLabels(buckets)}<text class="minimum-label" text-anchor="end" x="277" y="${y(state.minimum) - 4}">${hoursLabel(state.minimum)}</text></svg><div class="legend"><span><i class="dot" style="background:#8070d7"></i>Average sleep</span><span><i class="line-key" style="background:#3eaa55"></i>Minimum ${hoursLabel(state.minimum)}</span></div>`;
  }
  function timelineChart(s) {
    const nights = s.timeline;
    const min = Math.floor(Math.min(...nights.map(n => n.bedtimeMinutes)) / 60) * 60 - 30;
    const max = Math.ceil(Math.max(...nights.map(n => n.wakeMinutes)) / 60) * 60 + 30;
    const y = m => 8 + (m - min) / (max - min) * 232;
    const barWidth = 282 / nights.length;
    const ticks = [];
    for (let t = Math.ceil(min / 180) * 180; t < max; t += 180) ticks.push(t);
    return `<svg class="chart" viewBox="0 0 320 266" role="group" aria-label="Nightly sleep stages from bedtime to wake time">${ticks.map(t => `<line class="axis-grid" x1="0" x2="282" y1="${y(t)}" y2="${y(t)}"/><text x="287" y="${y(t) + 3}">${clock(t).replace(':00 ', '')}</text>`).join('')}${nights.map((n, i) => {
      const left = (i + .14) * barWidth;
      const width = barWidth * .72;
      const title = `${n.label}: ${num(n.hours)}h asleep, ${clock(n.bedtimeMinutes)} to ${clock(n.wakeMinutes)}`;
      return `<g data-point="${escape(title)}" tabindex="0" role="button" aria-label="${escape(title)}">${n.segments.map(seg => `<rect x="${left}" y="${y(seg.start)}" width="${width}" height="${Math.max(1, y(seg.end) - y(seg.start))}" rx=".7" fill="${stageColors[seg.stage]}"/>`).join('')}<rect x="${i * barWidth}" y="8" width="${barWidth}" height="232" fill="transparent"/><text class="bar-label" text-anchor="middle" x="${(i + .5) * barWidth}" y="${(y(n.bedtimeMinutes) + y(n.wakeMinutes)) / 2 + 3}">${num(n.hours)}h</text><title>${escape(title)}</title></g>`;
    }).join('')}${xLabels(nights, 282, 259)}</svg>${stageLegend(['deep', 'core', 'rem', 'awake'].map(stage => ({ stage })))}`;
  }
  function trends() {
    const s = summary(state.period);
    const balance = s.targetRunningBalance;
    const balanceText = balance < -.05 ? `${num(-balance)}h behind goal` : balance > .05 ? `${num(balance)}h ahead` : 'On goal';
    const trendSymbol = s.durationTrend === 'Improving' ? '↗' : s.durationTrend === 'Declining' ? '↘' : '→';
    const trendColor = s.durationTrend === 'Improving' ? '#2bd158' : s.durationTrend === 'Declining' ? '#ff625a' : '#5cabff';
    const targetColor = s.targetComplianceRate >= .85 ? '#2bd158' : s.targetComplianceRate >= .6 ? '#ffe100' : '#ff9828';
    return `<div class="screen trends-screen"><h1 class="page-title">Trends</h1><div class="period-selector" role="group" aria-label="Trend time period">${data.periods.map(p => `<button data-period="${p}" class="${p === state.period ? 'selected' : ''}" aria-pressed="${p === state.period}">${p}</button>`).join('')}</div>
      <div class="summary-grid">${metric('Average Sleep', `${num(s.averageSleepHours)} hours`, 'moon', periodNames[state.period])}${metric('Target Rate', `${Math.round(s.targetComplianceRate * 100)}%`, 'target', `${hoursLabel(state.minimum)}+ hours`, 'target-icon', targetColor)}</div>
      <section class="card chart-card" id="sleep-debt" tabindex="-1"><h2 class="section-heading">Sleep Debt</h2><p class="debt-summary" style="color:${s.totalSleepDebt > 2 ? debtColor(s.totalSleepDebt) : '#949497'}">${balanceText} · ${num(Math.abs(s.averageNightlyBalance))}h/night</p>${debtChart(s)}</section>
      <section class="card chart-card" id="sleep-duration" tabindex="-1"><div class="chart-heading"><h2 class="section-heading">Sleep Duration</h2><span class="trend-label" style="color:${trendColor}">${trendSymbol} ${s.durationTrend}</span></div>${['1D', '1W'].includes(state.period) ? timelineChart(s) : durationChart(s)}</section>
      ${disclosure(`<div class="metric-grid">${smallMetric('Avg Bedtime', clock(s.averageBedtimeMinutes), 'bed', '#5e5ce6')}${smallMetric('Avg Wake', clock(s.averageWakeMinutes), 'sunrise', '#ff9f0a')}${smallMetric('Deep Sleep', `${Math.round(s.averageDeepSleepMinutes)} min`, 'waveform', stageColors.deep)}${smallMetric('REM Sleep', `${Math.round(s.averageREMSleepMinutes)} min`, 'eye', stageColors.rem)}${smallMetric('Efficiency', `${Math.round(s.averageEfficiency * 100)}%`, 'gauge', '#0a84ff')}${smallMetric('Records', `${s.nightCount.toLocaleString()} nights`, 'calendar', '#8e8e93')}</div>`)}
    </div>`;
  }
  function slider(id, title, value, min, max, color) {
    return `<div class="settings-row slider-row"><label class="slider-label" for="${id}"><span>${title}</span><output id="${id}-value" for="${id}">${num(value)} hours</output></label><input class="goal-slider" id="${id}" data-setting="${id}" type="range" min="${min}" max="${max}" step="0.5" value="${value}" aria-valuetext="${num(value)} hours" style="--fill:${(value - min) / (max - min) * 100}%;--slider-color:${color}"></div>`;
  }
  function settings() {
    return `<div class="screen settings-screen"><h1 class="page-title">Settings</h1>
      <section class="settings-section"><h2>${icon('target')}Sleep Goals</h2><div class="settings-group">${slider('target', 'Target Sleep', state.target, 6, 10, '#d72beb')}${slider('minimum', 'Minimum Acceptable', state.minimum, 5, 9, '#ff9828')}</div><p class="settings-note">Adjust the goals to see how sleep debt and target nights change throughout this demo.</p></section>
      <section class="settings-section"><h2>${icon('watch')}Data Source</h2><div class="settings-group"><div class="settings-row"><span class="health-label">${icon('heart')}Apple Health</span><span class="demo-badge">Demo data</span></div><button class="settings-row settings-action" data-info="health">About This Demo<span class="row-arrow" aria-hidden="true">›</span></button><button class="settings-row settings-action" data-info="tracking">How Sleep Data Works<span class="row-arrow" aria-hidden="true">›</span></button></div><p class="settings-note demo-note">All records in this browser demo are fictional. It does not connect to Apple Health, access your health records, or save your settings.</p></section>
      <section class="settings-section"><h2>${icon('info')}About</h2><div class="settings-group"><div class="settings-row"><span>Version</span><span class="secondary version">1.0 · Web demo</span></div><button class="settings-row settings-action" data-info="privacy">Privacy Policy<span class="row-arrow" aria-hidden="true">›</span></button><button class="settings-row settings-action" data-info="score">How Sleep Score Is Calculated<span class="row-arrow" aria-hidden="true">›</span></button><button class="settings-row settings-action" data-info="debt">Understanding Sleep Debt<span class="row-arrow" aria-hidden="true">›</span></button><a class="settings-row settings-action" href="https://www.sleepfoundation.org" target="_blank" rel="noopener">Sleep Foundation Resources<span class="row-arrow" aria-hidden="true">↗</span></a></div><p class="settings-note">Somnus provides educational wellness estimates. Scores and sleep debt are not medical measurements or advice.</p></section><button class="reset-button" data-reset>Reset demo goals</button>
    </div>`;
  }

  const information = {
    health: ['About This Demo', '<h3>Fictional sleep, real interactions</h3><p>Explore Dashboard, Trends, and Settings using a consistent set of fictional sleep records. No Apple Health connection is made, and no personal health information is accessed.</p><h3>Try your own goals</h3><p>Target Sleep changes the debt calculation. Minimum Acceptable changes the target rate and the minimum line in the duration chart. The demo resets when you reload this page.</p><h3>Ten years of perspective</h3><p>All periods come from the same sample history, ending October 21, 2026. Long periods group the fictional nights into averages. Missing nights are excluded.</p>'],
    tracking: ['Sleep Tracking', '<h3>In the iPhone app</h3><p>Somnus reads sleep times and sleep stages already recorded in Apple Health, including Deep, REM, Core, and Awake. The browser demo uses fictional records to show these views.</p><h3>Reading the timeline</h3><p>Each column represents a night. Clock time runs from bedtime at the top to wake time at the bottom. Colors show the recorded stages, while the label shows time asleep.</p><h3>Looking further back</h3><p>Month, year, and longer views group nights into average duration bars so patterns are easier to compare.</p>'],
    privacy: ['Privacy', '<h3>This browser demo</h3><p>The sample records are entirely fictional. This demo does not request Apple Health access or store your goal adjustments. Your controls affect only this page.</p><h3>The Somnus app</h3><p>Sleep analysis runs on your iPhone using the sleep records in Apple Health.</p><p><a href="privacy.html" target="_blank" rel="noopener">Read the Somnus privacy policy ↗</a></p>'],
    score: ['Sleep Score', '<h3>What the score means</h3><p>The score is an educational estimate from 0 to 100 that summarizes recorded sleep patterns. It is not a clinical measurement or diagnosis.</p><h3>Duration · 35%</h3><p>Compares average recorded sleep with an 8-hour reference.</p><h3>Efficiency · 25%</h3><p>Compares time asleep with elapsed time from bedtime to wake time.</p><h3>Consistency · 20%</h3><p>Looks at variation in bedtimes across the period.</p><h3>Sleep Stages · 20%</h3><p>Compares Deep and REM proportions with reference proportions of 20% and 25%.</p><h3>Your goals and the score</h3><p>The score uses fixed references. Changing your goals updates debt and target rate without changing this score.</p>'],
    debt: ['Understanding Sleep Debt', '<h3>Dashboard: missed sleep</h3><p>The dashboard adds up each night’s shortfall against Target Sleep for the past week. Longer nights do not erase those shortfalls.</p><h3>Trends: running balance</h3><p>The summary compares the total recorded sleep with the target across the selected period. Longer nights can offset shorter nights in this balance, so it can differ from the dashboard.</p><h3>Reading the chart</h3><p>Orange bars show nightly shortfall. The purple line adds those shortfalls over the selected period. For longer periods, each bar sums the shortfalls across a week, month, or year. The line rises by the same amount.</p>']
  };
  let returnFocus = null;
  function showInfo(name, trigger) {
    const info = information[name];
    if (!info) return;
    returnFocus = trigger;
    document.getElementById('dialog-title').textContent = info[0];
    document.getElementById('dialog-body').innerHTML = info[1];
    dialog.showModal();
    dialog.scrollTop = 0;
  }
  function rememberView() {
    const view = state.views[state.tab];
    view.scrollTop = content.scrollTop;
    const detail = content.querySelector('.detail-card');
    if (detail) view.detailOpen = detail.open;
  }
  function render() {
    if (!data) {
      content.innerHTML = '<p class="card">The demo could not load. Please refresh this page.</p>';
      return;
    }
    content.innerHTML = state.tab === 'trends' ? trends() : state.tab === 'settings' ? settings() : dashboard();
    const detail = content.querySelector('.detail-card');
    if (detail) detail.open = state.views[state.tab].detailOpen;
    content.setAttribute('aria-label', state.tab[0].toUpperCase() + state.tab.slice(1));
    document.querySelectorAll('[data-tab]').forEach(button => {
      const selected = button.dataset.tab === state.tab;
      button.classList.toggle('active', selected);
      if (selected) button.setAttribute('aria-current', 'page');
      else button.removeAttribute('aria-current');
    });
    content.scrollTo({ top: state.views[state.tab].scrollTop, behavior: 'instant' });
  }
  document.querySelectorAll('[data-icon]').forEach(node => { node.innerHTML = icon(node.dataset.icon); });
  document.querySelector('.tab-bar').addEventListener('click', event => {
    const button = event.target.closest('[data-tab]');
    if (!button) return;
    rememberView();
    state.tab = button.dataset.tab;
    render();
  });
  content.addEventListener('click', event => {
    const period = event.target.closest('[data-period]');
    if (period) {
      rememberView();
      state.period = period.dataset.period;
      state.views.trends.scrollTop = 0;
      render();
      content.querySelector(`[data-period="${state.period}"]`).focus({ preventScroll: true });
    }
    const deepLink = event.target.closest('[data-deep-link]');
    if (deepLink) {
      rememberView();
      state.tab = 'trends';
      state.period = '1W';
      state.views.trends.scrollTop = 0;
      render();
      const section = document.getElementById(deepLink.dataset.deepLink);
      requestAnimationFrame(() => { content.scrollTop = section.offsetTop - 10; section.focus({ preventScroll: true }); });
    }
    const info = event.target.closest('[data-info]');
    if (info) showInfo(info.dataset.info, info);
    const point = event.target.closest('[data-point]');
    if (point) {
      const card = point.closest('.chart-card');
      let note = card.querySelector('.chart-selection');
      if (!note) { note = document.createElement('p'); note.className = 'chart-selection'; note.setAttribute('role', 'status'); card.append(note); }
      note.textContent = point.dataset.point;
    }
    if (event.target.closest('[data-reset]')) { rememberView(); state.target = 8; state.minimum = 7; render(); content.querySelector('[data-reset]').focus({ preventScroll: true }); }
  });
  content.addEventListener('keydown', event => {
    const point = event.target.closest('[data-point]');
    if (point && ['Enter', ' '].includes(event.key)) { event.preventDefault(); point.dispatchEvent(new MouseEvent('click', { bubbles: true })); }
  });
  content.addEventListener('input', event => {
    const slider = event.target.closest('[data-setting]');
    if (!slider) return;
    const value = Number(slider.value);
    state[slider.dataset.setting] = value;
    document.getElementById(`${slider.id}-value`).textContent = `${num(value)} hours`;
    slider.setAttribute('aria-valuetext', `${num(value)} hours`);
    slider.style.setProperty('--fill', `${(value - Number(slider.min)) / (Number(slider.max) - Number(slider.min)) * 100}%`);
  });
  document.getElementById('dialog-done').addEventListener('click', () => dialog.close());
  dialog.addEventListener('click', event => {
    if (event.target !== dialog) return;
    const bounds = dialog.getBoundingClientRect();
    if (event.clientX < bounds.left || event.clientX > bounds.right || event.clientY < bounds.top || event.clientY > bounds.bottom) dialog.close();
  });
  dialog.addEventListener('close', () => { if (returnFocus?.isConnected) returnFocus.focus({ preventScroll: true }); });
  render();
})();
