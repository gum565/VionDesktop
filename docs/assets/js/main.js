document.addEventListener('DOMContentLoaded', () => {
  // Syntax highlighting
  if (window.Prism) {
    window.Prism.highlightAll();
  }

  // Mobile drawer navigation
  const toggleBtn = document.getElementById('mobile-menu-toggle');
  const sidebar = document.querySelector('.sidebar');
  const backdrop = document.getElementById('sidebar-backdrop');

  if (toggleBtn && sidebar && backdrop) {
    const toggleMenu = () => {
      const isOpen = sidebar.classList.toggle('open');
      backdrop.classList.toggle('active', isOpen);
      toggleBtn.classList.toggle('active', isOpen);
      document.body.classList.toggle('menu-open', isOpen);
    };

    toggleBtn.addEventListener('click', toggleMenu);
    backdrop.addEventListener('click', toggleMenu);

    sidebar.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', () => {
        if (sidebar.classList.contains('open')) {
          toggleMenu();
        }
      });
    });
  }

  // Copy button & clean container for code blocks
  document.querySelectorAll('pre').forEach(pre => {
    const code = pre.querySelector('code');
    if (!code) return;

    const wrapper = document.createElement('div');
    wrapper.className = 'code-block-wrapper';
    pre.parentNode.insertBefore(wrapper, pre);
    wrapper.appendChild(pre);

    const header = document.createElement('div');
    header.className = 'code-header';
    let lang = 'code';
    for (const c of code.classList) {
      if (c.startsWith('language-')) {
        lang = c.replace('language-', '');
        break;
      }
    }
    header.innerHTML = `<span>${lang}</span><button class="btn-copy"><svg viewBox="0 0 24 24"><path fill="currentColor" d="M19 21H8V7h11m0-2H8a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h11a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2m-3-4H4a2 2 0 0 0-2 2v14h2V3h12V1Z"/></svg><span>Копировать</span></button>`;
    wrapper.insertBefore(header, pre);

    const btn = header.querySelector('.btn-copy');
    const label = btn.querySelector('span');
    btn.addEventListener('click', () => {
      navigator.clipboard.writeText(code.innerText).then(() => {
        btn.classList.add('copied');
        label.innerText = 'Скопировано!';
        setTimeout(() => {
          btn.classList.remove('copied');
          label.innerText = 'Копировать';
        }, 2000);
      });
    });
  });

  // Ensure all tables are wrapped in a responsive scroll container
  document.querySelectorAll('table').forEach(table => {
    if (!table.parentElement.classList.contains('table-container')) {
      const container = document.createElement('div');
      container.className = 'table-container';
      table.parentNode.insertBefore(container, table);
      container.appendChild(table);
    }
  });

  // Client-side search filter in sidebar
  const searchInput = document.getElementById('sidebar-search');
  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      const q = e.target.value.toLowerCase().trim();
      document.querySelectorAll('.sidebar-links li').forEach(li => {
        const text = li.innerText.toLowerCase();
        if (!q || text.includes(q)) {
          li.style.display = '';
        } else {
          li.style.display = 'none';
        }
      });
    });
  }

  // Highlight active link in sidebar
  const currentPath = window.location.pathname.split('/').pop() || 'index.html';
  document.querySelectorAll('.sidebar-links a').forEach(a => {
    const href = a.getAttribute('href');
    if (href === currentPath || (currentPath === '' && href === 'index.html')) {
      a.classList.add('active');
    }
  });
});
