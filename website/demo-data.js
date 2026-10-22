/* Fictional, deterministic demo data. No HealthKit or personal data is used. */
(function (root) {
  'use strict';
  const DAY = 86400000;
  const periods = ['1D', '1W', '1M', '1Y', '5Y', '10Y'];
  const end = Date.UTC(2026, 9, 22); // Exclusive end; last wake day is 21 October.
  const first = Date.UTC(2016, 9, 22);
  const iso = value => new Date(value).toISOString().slice(0, 10);
  const mean = values => values.reduce((sum, value) => sum + value, 0) / values.length;
  const sum = values => values.reduce((total, value) => total + value, 0);
  const clamp = (value, low, high) => Math.min(high, Math.max(low, value));
  const deviation = values => {
    const average = mean(values);
    return Math.sqrt(mean(values.map(value => (value - average) ** 2)));
  };
  // Integer hash: identical results in every browser, without Math.random or local time.
  function noise(index, salt) {
    let value = Math.imul(index + salt, 1597334677);
    value ^= value >>> 16;
    value = Math.imul(value, 2246822507);
    return (value >>> 0) / 4294967296;
  }
  const lastWeek = [366, 396, 432, 510, 495, 456, 474];
  const recordCount = (end - first) / DAY;
  const records = [];
  for (let index = 0; index < recordCount; index++) {
    const timestamp = first + index * DAY;
    const weekday = new Date(timestamp).getUTCDay();
    const weekend = weekday === 0 || weekday === 6;
    const progress = index / recordCount;
    let sleepMinutes = Math.round(clamp(416 + 29 * progress + (weekend ? 38 : -9)
      + 24 * Math.sin(index / 29) + (noise(index, 13) - 0.5) * 78
      - (index % 47 === 0 ? 72 : 0), 290, 565));
    if (index >= recordCount - 7) sleepMinutes = lastWeek[index - recordCount + 7];
    const awakeMinutes = index === recordCount - 1 ? 26 : Math.round(16 + noise(index, 97) * 28);
    const deep = Math.round(sleepMinutes * (0.16 + noise(index, 51) * 0.07));
    const rem = Math.round(sleepMinutes * (0.20 + noise(index, 71) * 0.09));
    const bedtimeMinutes = index === recordCount - 1 ? 1370
      : Math.round(1390 + (weekend ? 27 : 0) + 21 * Math.sin(index / 17) + (noise(index, 31) - 0.5) * 64);
    records.push(Object.freeze({
      date: iso(timestamp), timestamp, sleepMinutes, hours: sleepMinutes / 60,
      bedtimeMinutes, wakeMinutes: bedtimeMinutes + sleepMinutes + awakeMinutes,
      timeInBedMinutes: sleepMinutes + awakeMinutes,
      efficiency: sleepMinutes / (sleepMinutes + awakeMinutes),
      stageMinutes: Object.freeze({deep, rem, core: sleepMinutes - deep - rem, awake: awakeMinutes})
    }));
  }
  Object.freeze(records);

  function windowStart(period) {
    const date = new Date(end);
    if (period === '1D') return end - DAY;
    if (period === '1W') return end - 7 * DAY;
    if (period === '1M') date.setUTCMonth(date.getUTCMonth() - 1);
    else date.setUTCFullYear(date.getUTCFullYear() - ({'1Y': 1, '5Y': 5, '10Y': 10}[period]));
    return date.getTime();
  }
  function bucketStart(record, period) {
    const date = new Date(record.timestamp);
    if (period === '1M') date.setUTCDate(date.getUTCDate() - ((date.getUTCDay() + 6) % 7));
    if (period === '1Y') date.setUTCDate(1);
    if (period === '5Y' || period === '10Y') date.setUTCMonth(0, 1);
    return date.getTime();
  }
  function label(timestamp, period) {
    const date = new Date(timestamp);
    if (period === '5Y' || period === '10Y') return String(date.getUTCFullYear());
    if (period === '1Y') return date.toLocaleDateString('en-GB', {month: 'short', timeZone: 'UTC'});
    if (period === '1D' || period === '1W') return date.toLocaleDateString('en-GB', {weekday: 'short', timeZone: 'UTC'});
    return date.toLocaleDateString('en-GB', {day: 'numeric', month: 'short', timeZone: 'UTC'});
  }
  // Spread exact stage totals across five cycles, with deep sleep earlier and REM later.
  function timeline(record) {
    const weights = {awake: [5, 1, 1, 1, 2], core: [1, 1, 1, 1, 1], deep: [4, 3, 2, 1, 0], rem: [1, 2, 3, 4, 5]};
    const allocated = {};
    for (const stage of Object.keys(weights)) {
      let previous = 0;
      let accumulated = 0;
      const totalWeight = sum(weights[stage]);
      allocated[stage] = weights[stage].map(weight => {
        accumulated += weight;
        const next = Math.round(record.stageMinutes[stage] * accumulated / totalWeight);
        const value = next - previous;
        previous = next;
        return value;
      });
    }
    let cursor = record.bedtimeMinutes;
    const segments = [];
    for (let cycle = 0; cycle < 5; cycle++) {
      for (const stage of ['awake', 'core', 'deep', 'rem']) {
        const minutes = allocated[stage][cycle];
        if (minutes) {
          segments.push({stage, start: cursor, end: cursor + minutes, minutes});
          cursor += minutes;
        }
      }
    }
    return {date: record.date, label: label(record.timestamp, '1W'), bedtimeMinutes: record.bedtimeMinutes,
      wakeMinutes: record.wakeMinutes, hours: record.hours, segments};
  }
  function scoreFor(nights) {
    const hours = mean(nights.map(record => record.hours));
    let durationScore;
    if (hours >= 7 && hours <= 9) durationScore = Math.trunc(100 - Math.abs(hours - 8) * 10);
    else if (hours < 7) durationScore = Math.max(0, Math.trunc(70 - (7 - hours) * 20));
    else durationScore = Math.max(40, Math.trunc(80 - (hours - 9) * 15));
    const efficiency = mean(nights.map(record => record.efficiency));
    const efficiencyScore = efficiency >= 0.85 ? Math.min(100, Math.trunc(efficiency * 100 + 10))
      : Math.max(0, Math.trunc(efficiency * 120 - 10));
    const consistencyScore = nights.length < 2 ? 70 : Math.trunc(Math.max(0,
      100 - deviation(nights.map(record => record.bedtimeMinutes)) / 120 * 100));
    const stageScore = Math.trunc(mean(nights.map(record => {
      const deepScore = 100 - Math.min(100, Math.abs(record.stageMinutes.deep / record.sleepMinutes - 0.20) * 500);
      const remScore = 100 - Math.min(100, Math.abs(record.stageMinutes.rem / record.sleepMinutes - 0.25) * 400);
      return (deepScore + remScore) / 2;
    })));
    const overall = Math.trunc(durationScore * 0.35 + efficiencyScore * 0.25 + consistencyScore * 0.20 + stageScore * 0.20);
    const grade = overall >= 90 ? 'Excellent' : overall >= 75 ? 'Good' : overall >= 60 ? 'Fair' : overall >= 40 ? 'Poor' : 'Very Poor';
    return {overall, durationScore, efficiencyScore, consistencyScore, stageScore, grade};
  }

  function summarize(period = '1W', target = 8, minimum = 7) {
    if (!periods.includes(period)) throw new RangeError('Unknown demo period');
    if (!Number.isFinite(target) || target <= 0 || !Number.isFinite(minimum) || minimum <= 0) {
      throw new RangeError('Sleep targets must be positive finite hours');
    }
    const start = windowStart(period);
    const nights = records.filter(record => record.timestamp >= start);
    const buckets = new Map();
    for (const record of nights) {
      const timestamp = bucketStart(record, period);
      if (!buckets.has(timestamp)) buckets.set(timestamp, {timestamp, total: 0, debt: 0, count: 0});
      const bucket = buckets.get(timestamp);
      bucket.total += record.hours;
      bucket.debt += Math.max(0, target - record.hours);
      bucket.count++;
    }
    let cumulative = 0;
    const durationBuckets = [];
    const debtBuckets = [];
    for (const bucket of buckets.values()) {
      const base = {date: iso(bucket.timestamp), label: label(bucket.timestamp, period), count: bucket.count};
      durationBuckets.push({...base, hours: bucket.total / bucket.count});
      cumulative += bucket.debt;
      debtBuckets.push({...base, hours: bucket.debt, cumulative});
    }
    const targetRunningBalance = sum(nights.map(record => record.hours - target));
    const nightsMeetingTarget = nights.filter(record => record.hours >= minimum).length;
    const half = Math.floor(nights.length / 2);
    const difference = half ? mean(nights.slice(-half).map(record => record.hours)) - mean(nights.slice(0, half).map(record => record.hours)) : 0;
    const totalBedMinutes = sum(nights.map(record => record.timeInBedMinutes));
    const stageBreakdown = ['deep', 'rem', 'core', 'awake'].map(stage => {
      const minutes = sum(nights.map(record => record.stageMinutes[stage]));
      return {stage, minutes: minutes / nights.length, percentage: minutes / totalBedMinutes};
    });
    return {
      period, target, minimum, startDate: nights[0].date, endDate: nights[nights.length - 1].date,
      rangeLabel: `${label(nights[0].timestamp, '1M')} ${nights[0].date.slice(0, 4)} – ${label(end - DAY, '1M')} 2026`,
      nightCount: nights.length, records: nights,
      averageSleepHours: mean(nights.map(record => record.hours)),
      totalSleepDebt: cumulative, targetRunningBalance, averageNightlyBalance: targetRunningBalance / nights.length,
      nightsMeetingTarget, targetComplianceRate: nightsMeetingTarget / nights.length,
      averageEfficiency: mean(nights.map(record => record.efficiency)),
      averageBedtimeMinutes: mean(nights.map(record => record.bedtimeMinutes)),
      averageWakeMinutes: mean(nights.map(record => record.wakeMinutes)) % 1440,
      bedtimeConsistencyMinutes: deviation(nights.map(record => record.bedtimeMinutes)),
      averageDeepSleepMinutes: mean(nights.map(record => record.stageMinutes.deep)),
      averageREMSleepMinutes: mean(nights.map(record => record.stageMinutes.rem)),
      score: scoreFor(nights), durationTrend: Math.abs(difference) < 0.1 ? 'Stable' : difference > 0 ? 'Improving' : 'Declining',
      stageBreakdown, durationBuckets, debtBuckets,
      timeline: ['1D', '1W', '1M'].includes(period) ? nights.slice(-7).map(timeline) : []
    };
  }
  const api = Object.freeze({periods: Object.freeze(periods), records, summarize});
  if (typeof module === 'object' && module.exports) module.exports = api;
  if (root) root.SomnusDemoData = api;
})(typeof window !== 'undefined' ? window : null);
