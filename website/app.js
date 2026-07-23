// PocketDesk Website Interactivity & OS Auto-Detection

document.addEventListener('DOMContentLoaded', () => {
  // ─── Theme Toggle ─────────────────────────────────────────────────────────
  const themeToggle = document.getElementById('theme-toggle');
  const body = document.body;

  // Read saved theme preference
  const savedTheme = localStorage.getItem('theme');
  if (savedTheme) {
    body.className = savedTheme;
  } else {
    // Media query fallback
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    body.className = prefersDark ? 'dark-mode' : 'light-mode';
  }

  themeToggle.addEventListener('click', () => {
    if (body.classList.contains('light-mode')) {
      body.classList.replace('light-mode', 'dark-mode');
      localStorage.setItem('theme', 'dark-mode');
    } else {
      body.classList.replace('dark-mode', 'light-mode');
      localStorage.setItem('theme', 'light-mode');
    }
  });

  // ─── OS Auto-Detection ────────────────────────────────────────────────────
  const osDetector = document.getElementById('os-detector');
  const heroDownloadBtn = document.getElementById('hero-download-btn');

  let osName = 'Linux';
  let downloadLink = '#download'; // default anchors to section
  let actionText = 'Download for Linux (.AppImage)';

  const userAgent = window.navigator.userAgent.toLowerCase();
  const platform = window.navigator.platform.toLowerCase();

  if (userAgent.indexOf('android') !== -1) {
    osName = 'Android';
    actionText = 'Download for Android (APK)';
    downloadLink = '#download';
  } else if (platform.indexOf('win') !== -1) {
    osName = 'Windows';
    actionText = 'Download for Windows (Installer)';
  } else if (platform.indexOf('mac') !== -1) {
    osName = 'macOS';
    actionText = 'Download for macOS (DMG)';
  } else if (platform.indexOf('linux') !== -1) {
    osName = 'Linux';
    actionText = 'Download for Linux (.AppImage)';
  }

  if (osDetector) {
    osDetector.textContent = `Detected OS: ${osName}`;
  }

  if (heroDownloadBtn) {
    heroDownloadBtn.textContent = actionText;
    heroDownloadBtn.setAttribute('href', downloadLink);
  }
});
