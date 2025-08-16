const palette = [
  '#4e79a7', // easy
  '#f28e2b', // medium
  '#e15759', // hard
  '#76b7b2'  // unspecified
];

const difficultyLabels = ['easy', 'medium', 'hard', 'unspecified'];

function normalizeDifficultyKey(key) {
  return (key || '').toString().trim().toLowerCase();
}

function renderDifficultyCharts(data) {
  // --- 1: Velocity by Difficulty ---
  new Chart(document.getElementById('velocityByDifficultyChart'), {
    type: 'bar',
    data: {
      labels: difficultyLabels,
      datasets: [{
        label: 'Story Points',
        data: difficultyLabels.map(d => data.velocity_by_difficulty?.[d] || 0),
        backgroundColor: palette
      }]
    },
    options: { responsive: true, maintainAspectRatio: false }
  });

  // --- 2: Planned vs Completed ---
  new Chart(document.getElementById('plannedVsCompletedChart'), {
    type: 'bar',
    data: {
      labels: difficultyLabels,
      datasets: [
        {
          label: 'Planned',
          data: difficultyLabels.map(d => data.planned_vs_completed?.[d]?.planned || 0),
          backgroundColor: palette[0]
        },
        {
          label: 'Completed',
          data: difficultyLabels.map(d => data.planned_vs_completed?.[d]?.completed || 0),
          backgroundColor: palette[2]
        }
      ]
    },
    options: { responsive: true, maintainAspectRatio: false }
  });

  // --- 3: Burndown by Difficulty ---
  const burndownDatasets = difficultyLabels.map((diff, idx) => {
    const series = data.burndown_by_difficulty?.find(b => normalizeDifficultyKey(b.difficulty) === diff)?.series || [];
    return {
      label: diff,
      data: series.map(v => v[1]),
      borderColor: palette[idx],
      fill: false,
      tension: 0.2
    };
  });
  new Chart(document.getElementById('burndownByDifficultyChart'), {
    type: 'line',
    data: {
      labels: (data.burndown_by_difficulty?.[0]?.series || []).map(v => v[0]),
      datasets: burndownDatasets
    },
    options: { responsive: true, maintainAspectRatio: false }
  });

  // --- 4: Difficulty Distribution Pie ---
  new Chart(document.getElementById('difficultyDistributionChart'), {
    type: 'pie',
    data: {
      labels: difficultyLabels,
      datasets: [{
        data: difficultyLabels.map(d => data.difficulty_distribution?.[d] || 0),
        backgroundColor: palette
      }]
    },
    options: { responsive: true, maintainAspectRatio: false }
  });

  // --- 5: Difficulty Trend ---
  const trendLabels = data.difficulty_trend?.map(t => t.sprint) || [];
  const trendDatasets = difficultyLabels.map((diff, idx) => ({
    label: diff,
    data: (data.difficulty_trend || []).map(t => t.data?.[diff] || 0),
    borderColor: palette[idx],
    fill: false
  }));
  new Chart(document.getElementById('difficultyTrendChart'), {
    type: 'line',
    data: { labels: trendLabels, datasets: trendDatasets },
    options: { responsive: true, maintainAspectRatio: false }
  });

  // --- 6: Team Contribution by Difficulty ---
  const teamLabels = Object.keys(data.team_contribution_diff || {});
  const teamDatasets = difficultyLabels.map((diff, idx) => ({
    label: diff,
    data: teamLabels.map(user => data.team_contribution_diff?.[user]?.[diff] || 0),
    backgroundColor: palette[idx]
  }));
  new Chart(document.getElementById('teamContributionDiffChart'), {
    type: 'bar',
    data: { labels: teamLabels, datasets: teamDatasets },
    options: { indexAxis: 'y', responsive: true, maintainAspectRatio: false }
  });

  // --- 7: Difficulty vs Cycle Time ---
  new Chart(document.getElementById('difficultyVsCycleChart'), {
    type: 'scatter',
    data: {
      datasets: difficultyLabels.map((diff, idx) => ({
        label: diff,
        data: (data.difficulty_vs_cycle_time || [])
          .filter(i => normalizeDifficultyKey(i.difficulty) === diff)
          .map(i => ({ x: i.story_points, y: i.cycle_time })),
        backgroundColor: palette[idx]
      }))
    },
    options: {
      scales: {
        x: { title: { display: true, text: 'Story Points' } },
        y: { title: { display: true, text: 'Cycle Time (days)' } }
      },
      responsive: true,
      maintainAspectRatio: false
    }
  });

  // --- 8: Difficulty vs Bugs ---
  new Chart(document.getElementById('difficultyVsBugsChart'), {
    type: 'bar',
    data: {
      labels: difficultyLabels,
      datasets: [{
        label: 'Bugs',
        data: difficultyLabels.map(d => data.difficulty_vs_bugs?.[d] || 0),
        backgroundColor: palette
      }]
    },
    options: { responsive: true, maintainAspectRatio: false }
  });

  const developers = Object.keys(data.developer_difficulty);
  const difficulties = ["easy", "medium", "hard", "unspecified"];

  const datasets = difficulties.map((diff, idx) => ({
    label: diff,
    data: developers.map(dev => (data.developer_difficulty[dev] && data.developer_difficulty[dev][diff]) ? data.developer_difficulty[dev][diff] : 0),
    backgroundColor: palette[idx]
  }));

  new Chart(document.getElementById('developerDifficultyChart'), {
    type: 'bar',
    data: {
      labels: developers,
      datasets: datasets
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        x: { stacked: true },
        y: { stacked: true, beginAtZero: true }
      }
    }
  });

}