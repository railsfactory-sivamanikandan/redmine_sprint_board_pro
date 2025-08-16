const palette = ['#4e79a7','#f28e2b','#e15759','#76b7b2','#59a14f','#edc949','#af7aa1','#ff9da7','#9c755f','#bab0ab'];


function renderDashboardCharts(data) {
  const velocity = data.velocity || {};
  const burndown = data.burndown || [];
  const cfd = data.cfd || {};
  const openClosed = data.open_closed || {};
  const team = data.team || [];
  const issue_types = data.issue_types || [];
  new Chart(document.getElementById('velocityChart'), {
    type: 'bar',
    data: {
      labels: ['Total Points','Closed Points'],
      datasets: [{ data: [velocity.total || 0, velocity.closed || 0], backgroundColor: [palette[0], palette[2]] }]
    },
    options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } } }
  });

  new Chart(document.getElementById('burndownChart'), {
    type: 'line',
    data: {
      labels: burndown.map(d => d[0]),
      datasets: [{ label: 'Remaining Points', data: burndown.map(d => d[1]), borderColor: '#e15759', fill: false, tension: 0.2 }]
    },
    options: { responsive: true, maintainAspectRatio: false }
  });

  const cfdDatasets = (cfd.datasets || []).map((ds, idx) => ({
    label: ds.label, data: ds.data, backgroundColor: palette[idx % palette.length], fill: true, tension: 0.2
  }));
  new Chart(document.getElementById('cfdChart'), {
    type: 'line',
    data: { labels: cfd.labels || [], datasets: cfdDatasets },
    options: { responsive: true, maintainAspectRatio: false, scales: { x: { stacked: true }, y: { stacked: true } } }
  });

  new Chart(document.getElementById('openClosedChart'), {
    type: 'doughnut',
    data: { labels: ['Open','Closed'], datasets: [{ data: [openClosed.open_count || 0, openClosed.closed_count || 0], backgroundColor: [palette[1], palette[2]] }] },
    options: { responsive: true, maintainAspectRatio: false }
  });

  new Chart(document.getElementById('issueTypeChart'), {
    type: 'doughnut',
    data: { labels: issue_types.map(i => i.tracker_name), datasets: [{ data: issue_types.map(i => i.points), backgroundColor: issue_types.map((_, i) => palette[i % palette.length]) }] },
    options: { responsive: true, maintainAspectRatio: false }
  });

  new Chart(document.getElementById('teamChart'), {
    type: 'bar',
    data: { labels: team.map(t => t.user_name), datasets: [{ data: team.map(t => t.points), backgroundColor: team.map((_, i) => palette[i % palette.length]) }] },
    options: { indexAxis: 'y', responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } } }
  });
}