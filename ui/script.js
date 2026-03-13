// Tayer Uptime NUI Dashboard

let isVisible = false;
let dashboardData = null;

// ---- NUI Communication ----

function postNUI(event, data) {
    return fetch('https://tayer-uptime/' + event, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {})
    }).then(r => r.json()).catch(() => ({}));
}

function closePanel() {
    const app = document.getElementById('app');
    app.classList.add('hidden');
    isVisible = false;
    postNUI('closeDashboard');
}

// ---- NUI Message Listener ----

window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'openDashboard') {
        dashboardData = data.data;
        renderDashboard(dashboardData);
        document.getElementById('app').classList.remove('hidden');
        isVisible = true;
    }

    if (data.action === 'closeDashboard') {
        closePanel();
    }

    if (data.action === 'updateAFK') {
        updateAFKStatus(data.isAFK);
    }
});

// ---- ESC to close ----

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' && isVisible) {
        closePanel();
    }
});

// ---- Tab Navigation ----

document.querySelectorAll('.tab').forEach(function(tab) {
    tab.addEventListener('click', function() {
        document.querySelectorAll('.tab').forEach(function(t) { t.classList.remove('active'); });
        document.querySelectorAll('.tab-content').forEach(function(c) { c.classList.remove('active'); });

        tab.classList.add('active');
        document.getElementById('tab-' + tab.dataset.tab).classList.add('active');
    });
});

// ---- Format Time ----

function formatTime(minutes) {
    if (!minutes || minutes <= 0) return '0m';
    var h = Math.floor(minutes / 60);
    var m = minutes % 60;
    if (h === 0) return m + 'm';
    return h + 'h ' + m + 'm';
}

// ---- Render Dashboard ----

function renderDashboard(data) {
    if (!data) return;

    // Overview
    document.getElementById('stat-total').textContent = formatTime(data.totalTime);
    document.getElementById('stat-daily').textContent = formatTime(data.dailyTime);
    document.getElementById('stat-weekly').textContent = formatTime(data.weeklyTime);
    document.getElementById('stat-monthly').textContent = formatTime(data.monthlyTime);
    document.getElementById('stat-session').textContent = formatTime(data.sessionTime);
    document.getElementById('stat-rank').textContent = data.rank ? '#' + data.rank : '--';

    updateAFKStatus(data.isAFK);

    // Leaderboard
    renderLeaderboard(data.leaderboard, data.playerName);

    // Milestones
    renderMilestones(data.milestones, data.totalTime);

    // Streak
    renderStreak(data.loginStreak);

    // Activity Heatmap
    renderHeatmap(data.heatmap);
}

function updateAFKStatus(isAFK) {
    var el = document.getElementById('afk-status');
    if (isAFK) {
        el.textContent = 'AFK - Tracking Paused';
        el.className = 'afk-status afk';
    } else {
        el.textContent = 'Active';
        el.className = 'afk-status active';
    }
}

function renderLeaderboard(leaderboard, playerName) {
    var container = document.getElementById('leaderboard-list');
    if (!leaderboard || leaderboard.length === 0) {
        container.innerHTML = '<div class="loading">No data available</div>';
        return;
    }

    var html = '';
    for (var i = 0; i < leaderboard.length; i++) {
        var entry = leaderboard[i];
        var isYou = entry.name === playerName;
        html += '<div class="lb-entry' + (isYou ? ' you' : '') + '">';
        html += '<div class="lb-rank">#' + (i + 1) + '</div>';
        html += '<div class="lb-name">' + escapeHtml(entry.name || 'Unknown') + (isYou ? ' (You)' : '') + '</div>';
        html += '<div class="lb-time">' + formatTime(entry.online_time) + '</div>';
        html += '</div>';
    }
    container.innerHTML = html;
}

function renderMilestones(milestones, totalMinutes) {
    var container = document.getElementById('milestones-list');
    document.getElementById('milestone-time').textContent = formatTime(totalMinutes);

    if (!milestones || milestones.length === 0) {
        container.innerHTML = '<div class="loading">No milestones configured</div>';
        return;
    }

    var totalHours = (totalMinutes || 0) / 60;
    var html = '';

    for (var i = 0; i < milestones.length; i++) {
        var ms = milestones[i];
        var progress = Math.min(100, (totalHours / ms.hours) * 100);
        var statusClass, statusText, icon;

        if (ms.claimed) {
            statusClass = 'claimed';
            statusText = 'Claimed';
            icon = '&#10003;';
        } else if (totalHours >= ms.hours) {
            statusClass = 'available';
            statusText = 'Auto-claimed!';
            icon = '&#9733;';
        } else {
            statusClass = 'locked';
            statusText = Math.ceil(ms.hours - totalHours) + 'h left';
            icon = '&#9711;';
        }

        html += '<div class="ms-entry ' + statusClass + '">';
        html += '<div class="ms-icon">' + icon + '</div>';
        html += '<div class="ms-info">';
        html += '<div class="ms-label">' + escapeHtml(ms.label) + '</div>';
        html += '<div class="ms-reward">$' + numberFormat(ms.money) + '</div>';
        if (statusClass === 'locked') {
            html += '<div class="ms-progress"><div class="ms-progress-bar" style="width:' + progress.toFixed(1) + '%"></div></div>';
        }
        html += '</div>';
        html += '<div class="ms-status ' + statusClass + '">' + statusText + '</div>';
        html += '</div>';
    }

    container.innerHTML = html;
}

function renderStreak(streak) {
    if (!streak) return;

    document.getElementById('streak-count').textContent = streak.currentStreak || 0;
    document.getElementById('streak-max').textContent = streak.maxStreak || 0;
    document.getElementById('streak-total').textContent = streak.totalLogins || 0;

    var statusEl = document.getElementById('streak-status');
    if (streak.claimedToday) {
        statusEl.textContent = "Today's reward claimed!";
        statusEl.className = 'streak-status claimed';
    } else {
        statusEl.textContent = 'Reward pending - will be claimed on next login';
        statusEl.className = 'streak-status pending';
    }

    // Scale flame based on streak
    var flame = document.getElementById('streak-flame');
    var count = streak.currentStreak || 0;
    if (count >= 30) flame.textContent = '🔥🔥🔥';
    else if (count >= 14) flame.textContent = '🔥🔥';
    else if (count >= 1) flame.textContent = '🔥';
    else flame.textContent = '❄️';
}

function renderHeatmap(heatmap) {
    var container = document.getElementById('heatmap-grid');
    if (!heatmap) {
        container.innerHTML = '<div class="loading">No activity data yet</div>';
        return;
    }

    var dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    var html = '';

    // Header row with hour labels
    html += '<div class="heatmap-day-label"></div>';
    for (var h = 0; h < 24; h++) {
        if (h % 3 === 0) {
            html += '<div class="heatmap-hour-label">' + h + '</div>';
        } else {
            html += '<div class="heatmap-hour-label"></div>';
        }
    }

    // Find max value for scaling
    var maxVal = 1;
    for (var d = 0; d < 7; d++) {
        var dayData = heatmap[String(d)] || {};
        for (var h2 = 0; h2 < 24; h2++) {
            var val = dayData[String(h2)] || 0;
            if (val > maxVal) maxVal = val;
        }
    }

    // Render each day row
    for (var d2 = 0; d2 < 7; d2++) {
        html += '<div class="heatmap-day-label">' + dayNames[d2] + '</div>';
        var dayData2 = heatmap[String(d2)] || {};
        for (var h3 = 0; h3 < 24; h3++) {
            var minutes = dayData2[String(h3)] || 0;
            var level = 0;
            if (minutes > 0) {
                var ratio = minutes / maxVal;
                if (ratio > 0.75) level = 4;
                else if (ratio > 0.5) level = 3;
                else if (ratio > 0.25) level = 2;
                else level = 1;
            }
            html += '<div class="heatmap-cell level-' + level + '" title="' + dayNames[d2] + ' ' + h3 + ':00 - ' + minutes + 'm"></div>';
        }
    }

    container.innerHTML = html;
}

// ---- Utilities ----

function escapeHtml(str) {
    var div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}

function numberFormat(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}
