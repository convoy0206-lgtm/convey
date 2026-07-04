// State variables
let currentScreen = 'landing';
let currentTab = 'explore';
let isGhostMode = false;
let isOnline = true;
let offlineQueue = [];
let simulatedTrip = {
  title: 'Sierra Nevada Expedition',
  code: 'TRIP-5A9B',
  route: 'sierra'
};

// Start clock
function startClock() {
  const timeDisplay = document.getElementById('statusTime');
  setInterval(() => {
    const now = new Date();
    let hours = now.getHours();
    let minutes = now.getMinutes();
    hours = hours < 10 ? '0' + hours : hours;
    minutes = minutes < 10 ? '0' + minutes : minutes;
    timeDisplay.textContent = `${hours}:${minutes}`;
  }, 1000);
}

// Log message to sandbox console
function logEvent(source, message) {
  const consoleEl = document.getElementById('logConsole');
  const entry = document.createElement('div');
  entry.className = `log-entry ${source.toLowerCase()}`;
  
  const timestamp = new Date().toLocaleTimeString();
  entry.innerHTML = `[${timestamp}] <strong>[${source.toUpperCase()}]</strong> ${message}`;
  
  consoleEl.appendChild(entry);
  consoleEl.scrollTop = consoleEl.scrollHeight;
}

// Clear sandbox console logs
function clearLogs() {
  const consoleEl = document.getElementById('logConsole');
  consoleEl.innerHTML = '<div class="log-entry system">[SYSTEM] Console logs cleared.</div>';
}

// Navigation Tab switching (Explore, Groups, Timeline, Stats)
function navTabSwitch(tabName) {
  currentTab = tabName;
  
  // Update Nav visual active state
  const navItems = document.querySelectorAll('.nav-item');
  navItems.forEach(item => item.classList.remove('active'));
  
  // Map tab names to indices
  let activeIndex = 0;
  if (tabName === 'explore') activeIndex = 0;
  else if (tabName === 'groups') activeIndex = 1;
  else if (tabName === 'timeline') activeIndex = 2;
  else if (tabName === 'stats') activeIndex = 3;
  navItems[activeIndex].classList.add('active');

  // Trigger screen transitions based on tab
  if (tabName === 'explore') {
    goToScreen(currentScreen.startsWith('screen-') ? currentScreen.substring(7) : currentScreen);
  } else if (tabName === 'groups') {
    goToScreen('radar');
  } else if (tabName === 'stats') {
    goToScreen('stats');
  } else if (tabName === 'timeline') {
    goToScreen('timeline');
  }
  
  logEvent('Mixpanel', `Tracked navigation tab: ${tabName}`);
}

// Route to a specific screen container inside the phone bezel
function goToScreen(screenId) {
  const screens = document.querySelectorAll('.screen');
  screens.forEach(s => s.classList.remove('active'));
  
  const targetId = screenId.startsWith('screen-') ? screenId : `screen-${screenId}`;
  const targetScreen = document.getElementById(targetId);
  
  if (targetScreen) {
    targetScreen.classList.add('active');
    // Save current sub-explore screen so switching back to Explore tab remembers state
    if (currentTab === 'explore') {
      currentScreen = targetId;
    }
  }
}

// Forced Screen jump from developer controls
function forceGotoScreen(screenName, tabName) {
  navTabSwitch(tabName);
  
  if (screenName.startsWith('timeline-')) {
    goToScreen('timeline');
    const subTab = screenName.substring(9);
    switchTimelineView(subTab);
  } else {
    goToScreen(screenName);
  }
  
  logEvent('System', `Dev Force Navigation: showing ${screenName}`);
}

// Simulate Joining a Trip with Invite Code
function simulateJoinTrip() {
  const code = prompt("Enter 8-digit Trip Invite Code:", "TRIP-5A9B");
  if (code) {
    logEvent('Firebase', `Authenticating group invite code: ${code}`);
    logEvent('Mixpanel', `Funnel conversion: Joined trip group via invite`);
    
    // Setup Mock Info
    simulatedTrip.title = "Pacific Roadtrip";
    simulatedTrip.code = code.toUpperCase();
    
    document.getElementById('previewTripName').innerText = simulatedTrip.title;
    document.getElementById('inviteCodeDisplay').innerText = simulatedTrip.code;
    
    goToScreen('mappreview');
  }
}

// Setup Form Submission
function createTripSubmit() {
  const title = document.getElementById('tripTitleInput').value || 'Sierra Nevada Expedition';
  const selectedRoute = document.getElementById('tripRouteSelect').value;
  const isDefaultGhost = document.getElementById('defaultGhostToggle').checked;
  
  // Set trip properties
  simulatedTrip.title = title;
  simulatedTrip.route = selectedRoute;
  simulatedTrip.code = 'TRIP-' + Math.random().toString(36).substring(2, 6).toUpperCase();
  
  logEvent('Firebase', `Successfully wrote new trip document directly to Firestore.`);
  logEvent('Firebase', `Trip name: "${title}" | Invite Code: ${simulatedTrip.code}`);
  logEvent('Mixpanel', `Triggered event: trip_created { isGhostModeDefault: ${isDefaultGhost} }`);

  // Set visual properties
  document.getElementById('previewTripName').innerText = title;
  document.getElementById('inviteCodeDisplay').innerText = simulatedTrip.code;
  
  // Toggle Ghost mode based on selection
  document.getElementById('activeGhostToggle').checked = isDefaultGhost;
  toggleGhostMode(isDefaultGhost);

  goToScreen('mappreview');
}

// Initialize active maps and locations
function startActiveTracking() {
  goToScreen('mapactive');
  logEvent('Firebase', `Streaming real-time coordinates to Firestore geolocation nodes.`);
  logEvent('Mixpanel', `User started active journey tracking.`);
}

// Active tracking UI simulator updates
function updateSimulatorSpeed(val) {
  document.getElementById('speedLabel').textContent = val;
  const speedValEl = document.getElementById('activeSpeedVal');
  if (speedValEl) speedValEl.textContent = `${val} MPH`;
  
  if (val > 80) {
    logEvent('Firebase', `Performance Alert: High velocity warning flagged.`);
  }
}

// Translate progress percentage slider into active locations
function updateSimulatorProgress(val) {
  document.getElementById('progressLabel').textContent = `${val}%`;
  
  // Move Me avatar marker along route line
  const meMarker = document.getElementById('markerMe');
  if (meMarker) {
    // Basic linear slide based on percentage
    const startX = 72;
    const startY = 180;
    const endX = 230;
    const endY = 320;
    
    const deltaX = endX - startX;
    const deltaY = endY - startY;
    
    const currentX = startX + (deltaX * (val / 100));
    const currentY = startY + (deltaY * (val / 100));
    
    meMarker.style.left = `${currentX}px`;
    meMarker.style.top = `${currentY}px`;
  }
  
  // Calculate remaining distance (Total 48.5 mi)
  const totalDist = 48.5;
  const distRemaining = (totalDist * (1 - (val / 100))).toFixed(1);
  const distValEl = document.getElementById('activeDistVal');
  if (distValEl) distValEl.textContent = `${distRemaining} mi`;
  
  logEvent('Firebase', `Pushed location update to Firestore: progress: ${val}%`);
}

// Adjust companion spacing distance
function updateSimulatorSeparation(val) {
  document.getElementById('sepLabel').textContent = `${val} mi`;
  const sepTextEl = document.getElementById('memberSeparationText');
  if (sepTextEl) sepTextEl.textContent = `${val} miles back`;
  
  // Adjust Marcus Wright marker position based on separation slider
  const user1Marker = document.getElementById('markerUser1');
  if (user1Marker) {
    // Marcus follows behind
    const baseMe = document.getElementById('markerMe');
    const meLeft = parseFloat(baseMe.style.left || 72);
    const meTop = parseFloat(baseMe.style.top || 180);
    
    user1Marker.style.left = `${meLeft - (val * 4)}px`;
    user1Marker.style.top = `${meTop + (val * 2)}px`;
  }
}

// Ghost Mode Toggle
function toggleGhostMode(checked) {
  isGhostMode = checked;
  const meMarker = document.getElementById('markerMe');
  
  if (isGhostMode) {
    if (meMarker) {
      meMarker.style.opacity = '0.5';
      meMarker.querySelector('.avatar-ring').style.borderColor = '#9ca3af';
      meMarker.querySelector('.avatar-img').style.color = '#9ca3af';
    }
    
    // Sync to backend queue
    if (isOnline) {
      logEvent('Firebase', `Privacy setting updated: isGhostActive = true. Stopping active stream.`);
    } else {
      offlineQueue.push({ action: 'ghost_mode', state: true });
      logEvent('Local', `Offline: queued 'isGhostActive = true' change locally.`);
    }
    logEvent('Mixpanel', `Tracked event: privacy_mode_activated`);
  } else {
    if (meMarker) {
      meMarker.style.opacity = '1.0';
      meMarker.querySelector('.avatar-ring').style.borderColor = 'var(--neon-blue)';
      meMarker.querySelector('.avatar-img').style.color = '#fff';
    }
    
    if (isOnline) {
      logEvent('Firebase', `Privacy setting updated: isGhostActive = false. Resuming location stream.`);
    } else {
      offlineQueue.push({ action: 'ghost_mode', state: false });
      logEvent('Local', `Offline: queued 'isGhostActive = false' change locally.`);
    }
    logEvent('Mixpanel', `Tracked event: privacy_mode_deactivated`);
  }
}

// Offline resilience: network switch
function toggleNetworkState(connected) {
  isOnline = connected;
  const wifiEl = document.getElementById('wifiIcon');
  const subtitleEl = document.getElementById('networkStateSubtitle');
  
  if (!isOnline) {
    wifiEl.textContent = '❌';
    subtitleEl.textContent = 'Offline (SQLite caching)';
    logEvent('System', `Connection Lost. Offline caching mode activated.`);
  } else {
    wifiEl.textContent = '📶';
    subtitleEl.textContent = 'Connected to Firebase';
    logEvent('System', `Connection restored. Synchronizing cached database transactions...`);
    
    // Process local queue
    if (offlineQueue.length > 0) {
      const itemsCount = offlineQueue.length;
      offlineQueue = [];
      logEvent('Firebase', `Synced ${itemsCount} pending location/privacy actions to Cloud Firestore.`);
    }
  }
}

// Timeline sub-view routing
function switchTimelineView(viewType) {
  // Highlight tab button
  document.querySelectorAll('.time-tab').forEach(b => b.classList.remove('active'));
  document.getElementById(`tab-${viewType}`).classList.add('active');
  
  // Show target view layout
  document.getElementById('timeline-active-view').classList.add('hidden');
  document.getElementById('timeline-history-view').classList.add('hidden');
  document.getElementById('timeline-empty-view').classList.add('hidden');
  
  document.getElementById(`timeline-${viewType}-view`).classList.remove('hidden');
  
  logEvent('Mixpanel', `Viewed timeline sub-feed: ${viewType}`);
}

// Empty state timeline simulated trigger
function simulateStartEmptyJourney() {
  switchTimelineView('active');
  logEvent('System', `Simulated journey timeline activated.`);
}

// Initialize scripts
window.onload = () => {
  startClock();
  logEvent('System', `Sandbox Simulator ready. Environment preset: Staging / Dev.`);
};
