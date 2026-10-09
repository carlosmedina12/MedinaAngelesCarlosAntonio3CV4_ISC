const form = document.getElementById('flight-form');
const message = document.getElementById('form-message');
const dateInput = document.getElementById('date');
const today = new Date();
const localToday = new Date(today.getTime() - today.getTimezoneOffset() * 60000).toISOString().slice(0,10);
dateInput.min = localToday;
form.addEventListener('submit', event => {
  event.preventDefault();
  const origin = document.getElementById('origin').value;
  const destination = document.getElementById('destination').value;
  if (origin === destination) { message.textContent = 'El origen y el destino deben ser diferentes.'; return; }
  message.textContent = `Búsqueda de ${origin} a ${destination}: esta es una demostración académica; todavía no hay vuelos reales disponibles.`;
});
const dialog = document.getElementById('demo-dialog');
document.getElementById('operations-button').addEventListener('click', () => dialog.showModal());
document.getElementById('close-dialog').addEventListener('click', () => dialog.close());
document.getElementById('dialog-ok').addEventListener('click', () => dialog.close());
dialog.addEventListener('click', event => { if (event.target === dialog) dialog.close(); });
document.getElementById('year').textContent = new Date().getFullYear();
const menu = document.querySelector('.menu-toggle');
const nav = document.querySelector('.nav');
menu.addEventListener('click', () => { const open = nav.classList.toggle('open'); menu.setAttribute('aria-expanded', String(open)); });
nav.querySelectorAll('a').forEach(a => a.addEventListener('click', () => { nav.classList.remove('open'); menu.setAttribute('aria-expanded', 'false'); }));
