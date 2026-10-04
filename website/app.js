// PocketDesk Website Interactivity & Smooth Antigravity Transitions

document.addEventListener('DOMContentLoaded', () => {

  // ─── Theme Toggle ─────────────────────────────────────────────────────────
  const themeToggle = document.getElementById('theme-toggle');
  const root = document.documentElement;
  const body = document.body;

  if (themeToggle) {
    const applyTheme = (isDark) => {
      if (isDark) {
        root.classList.add('dark-mode');
        body.classList.add('dark-mode');
        root.classList.remove('light-mode');
        body.classList.remove('light-mode');
      } else {
        root.classList.remove('dark-mode');
        body.classList.remove('dark-mode');
        root.classList.add('light-mode');
        body.classList.add('light-mode');
      }
    };

    const savedTheme = localStorage.getItem('theme');
    if (savedTheme) {
      applyTheme(savedTheme === 'dark-mode');
    } else {
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      applyTheme(prefersDark);
    }

    themeToggle.addEventListener('click', () => {
      const isDarkNow = root.classList.contains('dark-mode') || body.classList.contains('dark-mode');
      const newDark = !isDarkNow;
      applyTheme(newDark);
      localStorage.setItem('theme', newDark ? 'dark-mode' : 'light-mode');
    });
  }

  // ─── OS Auto-Detection ────────────────────────────────────────────────────
  const osDetector = document.getElementById('os-detector');
  const heroDownloadBtn = document.getElementById('hero-download-btn');

  let osName = 'Linux';
  let downloadLink = 'download.html';
  let actionText = 'Download for Linux (.AppImage)';

  const userAgent = window.navigator.userAgent.toLowerCase();
  const platform = window.navigator.platform.toLowerCase();

  if (userAgent.indexOf('android') !== -1) {
    osName = 'Android';
    actionText = 'Download for Android (APK)';
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

  // ─── Scroll-Driven Full-Section Reveal System ──────────────────────────────
  const fullSections = document.querySelectorAll('.full-section, .hero-section, .showcase-container');

  if ('IntersectionObserver' in window && fullSections.length > 0) {
    const sectionObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
        }
      });
    }, {
      threshold: 0.15,
      rootMargin: '0px 0px -50px 0px'
    });

    fullSections.forEach(sec => sectionObserver.observe(sec));
  }

  // ─── Smooth Page Transitions Between HTML Pages ───────────────────────────
  const internalLinks = document.querySelectorAll('a[href]:not([target="_blank"]):not([href^="#"]):not([href^="javascript:"]):not([href^="mailto:"])');

  internalLinks.forEach(link => {
    link.addEventListener('click', (e) => {
      const targetUrl = link.getAttribute('href');
      if (!targetUrl || targetUrl.startsWith('#')) return;

      // Check if browser supports View Transitions natively
      if (document.startViewTransition) {
        e.preventDefault();
        document.startViewTransition(() => {
          window.location.href = targetUrl;
        });
      } else {
        // Fallback smooth CSS fade out transition
        e.preventDefault();
        body.classList.add('page-fade-out');
        setTimeout(() => {
          window.location.href = targetUrl;
        }, 220);
      }
    });
  });

  // ─── Mobile Hamburger Drawer Toggle Logic ─────────────────────────────────
  const hamburgerBtn = document.getElementById('hamburger-btn');
  const mobileDrawer = document.getElementById('mobile-menu-drawer');

  if (hamburgerBtn && mobileDrawer) {
    hamburgerBtn.addEventListener('click', () => {
      const isActive = mobileDrawer.classList.contains('active');
      if (isActive) {
        mobileDrawer.classList.remove('active');
        hamburgerBtn.classList.remove('active');
        hamburgerBtn.setAttribute('aria-expanded', 'false');
      } else {
        mobileDrawer.classList.add('active');
        hamburgerBtn.classList.add('active');
        hamburgerBtn.setAttribute('aria-expanded', 'true');
      }
    });

    // Close mobile drawer when clicking any link inside it
    const drawerLinks = mobileDrawer.querySelectorAll('a');
    drawerLinks.forEach(link => {
      link.addEventListener('click', () => {
        mobileDrawer.classList.remove('active');
        hamburgerBtn.classList.remove('active');
        if (hamburgerBtn) hamburgerBtn.setAttribute('aria-expanded', 'false');
      });
    });
  }

});
