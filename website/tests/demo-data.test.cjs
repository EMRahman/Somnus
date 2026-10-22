const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const data = require('../demo-data.js');
const sum = values => values.reduce((total, value) => total + value, 0);
const close = (actual, expected) => assert.ok(Math.abs(actual - expected) < 1e-8, `${actual} != ${expected}`);

test('ten full years are contiguous, fixed and reproducible in the browser', () => {
  assert.equal(data.records[0].date, '2016-10-22');
  assert.equal(data.records.at(-1).date, '2026-10-21');
  assert.equal(data.records.length, 3652);
  data.records.forEach((record, index) => {
    if (index) assert.equal(record.timestamp - data.records[index - 1].timestamp, 86400000);
    assert.equal(sum(Object.values(record.stageMinutes)), record.timeInBedMinutes);
    assert.equal(record.timeInBedMinutes - record.stageMinutes.awake, record.sleepMinutes);
    assert.equal(record.wakeMinutes - record.bedtimeMinutes, record.timeInBedMinutes);
    assert.ok(record.efficiency > 0 && record.efficiency <= 1);
  });
  const context = {window: {}};
  vm.runInNewContext(fs.readFileSync(require.resolve('../demo-data.js'), 'utf8'), context);
  assert.equal(JSON.stringify(context.window.SomnusDemoData.records), JSON.stringify(data.records));
});

test('every period reconciles buckets, metrics, stage proportions and score', () => {
  const counts = [1, 7, 30, 365, 1826, 3652];
  data.periods.forEach((period, index) => {
    const summary = data.summarize(period);
    assert.equal(summary.nightCount, counts[index]);
    close(sum(summary.debtBuckets.map(bucket => bucket.hours)), summary.totalSleepDebt);
    close(summary.debtBuckets.at(-1).cumulative, summary.totalSleepDebt);
    close(sum(summary.durationBuckets.map(bucket => bucket.hours * bucket.count)), summary.averageSleepHours * summary.nightCount);
    assert.equal(sum(summary.durationBuckets.map(bucket => bucket.count)), summary.nightCount);
    close(summary.targetRunningBalance, (summary.averageSleepHours - 8) * summary.nightCount);
    close(summary.averageNightlyBalance, summary.averageSleepHours - 8);
    close(sum(summary.stageBreakdown.map(stage => stage.percentage)), 1);
    assert.equal(summary.nightsMeetingTarget, summary.records.filter(record => record.hours >= 7).length);
    for (const score of ['overall', 'durationScore', 'efficiencyScore', 'consistencyScore', 'stageScore']) {
      assert.ok(Number.isInteger(summary.score[score]) && summary.score[score] >= 0 && summary.score[score] <= 100);
    }
    summary.debtBuckets.forEach((bucket, bucketIndex) => {
      assert.ok(bucket.hours >= 0);
      if (bucketIndex) assert.ok(bucket.date > summary.debtBuckets[bucketIndex - 1].date);
    });
  });
});

test('recovery does not erase gross debt; target and minimum have independent meanings', () => {
  const week = data.summarize('1W');
  close(week.totalSleepDebt, 4.6);
  assert.ok(week.totalSleepDebt > -week.targetRunningBalance);
  assert.equal(week.durationTrend, 'Improving');
  assert.equal(week.nightsMeetingTarget, 5);
  const lowerTarget = data.summarize('1W', 7, 7);
  assert.ok(lowerTarget.totalSleepDebt < week.totalSleepDebt);
  close(lowerTarget.targetRunningBalance - week.targetRunningBalance, 7);
  assert.equal(lowerTarget.nightsMeetingTarget, week.nightsMeetingTarget);
  assert.deepEqual(lowerTarget.score, week.score); // Mirrors the native fixed physiological score.
  const higherMinimum = data.summarize('1W', 8, 8);
  assert.equal(higherMinimum.nightsMeetingTarget, 2);
  assert.equal(higherMinimum.totalSleepDebt, week.totalSleepDebt);
  close(data.summarize('10Y', 1, 1).totalSleepDebt, 0);
  assert.equal(data.summarize('10Y', 1, 1).targetComplianceRate, 1);
});

test('stage timelines exactly reconcile to nightly asleep and in-bed minutes', () => {
  for (const period of ['1D', '1W', '1M']) {
    const summary = data.summarize(period);
    assert.equal(summary.timeline.length, period === '1D' ? 1 : 7);
    for (const night of summary.timeline) {
      const record = summary.records.find(record => record.date === night.date);
      assert.equal(night.segments[0].start, record.bedtimeMinutes);
      assert.equal(night.segments.at(-1).end, record.wakeMinutes);
      night.segments.forEach((segment, index) => {
        assert.ok(segment.minutes > 0);
        assert.equal(segment.end - segment.start, segment.minutes);
        if (index) assert.equal(segment.start, night.segments[index - 1].end);
      });
      for (const stage of ['deep', 'rem', 'core', 'awake']) {
        assert.equal(sum(night.segments.filter(segment => segment.stage === stage).map(segment => segment.minutes)), record.stageMinutes[stage]);
      }
      close(sum(night.segments.filter(segment => segment.stage !== 'awake').map(segment => segment.minutes)) / 60, night.hours);
    }
  }
  assert.deepEqual(data.summarize('1Y').timeline, []);
});

test('unsupported periods and invalid settings fail explicitly', () => {
  assert.throws(() => data.summarize('2W'), RangeError);
  for (const value of [NaN, Infinity, 0, -1]) {
    assert.throws(() => data.summarize('1W', value), RangeError);
    assert.throws(() => data.summarize('1W', 8, value), RangeError);
  }
});
