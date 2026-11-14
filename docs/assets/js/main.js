document.addEventListener('DOMContentLoaded', () => {
  // Copy button for code blocks
  document.querySelectorAll('pre').forEach(pre => {
    const code = pre.querySelector('code');
    if (!code) return;

    const header = document.createElement('div');
    header.className = 'code-header';
    const lang = code.className.replace('language-', '') || 'code';
    header.innerHTML = `<span>${lang}</span><button class="btn-copy">Копировать</button>`;
    pre.insertBefore(header, code);

    const btn = header.querySelector('.btn-copy');
    btn.addEventListener('click', () => {
      navigator.clipboard.writeText(code.innerText).then(() => {
        btn.innerText = 'Скопировано!';
        setTimeout(() => { btn.innerText = 'Копировать'; }, 2000);
      });
    });
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
