// Aprende Jugando: sumas e inglés para peques. Sin dependencias.

const ROUNDS = 10;
const OBJECTS = ['🍎', '⭐', '🐟', '🎈', '🍓', '🐞', '🚗', '🌸'];

const TOPICS = {
  animales: {
    label: '🐶 Animales',
    words: [
      ['dog', '🐶'], ['cat', '🐱'], ['cow', '🐮'], ['pig', '🐷'], ['duck', '🦆'],
      ['fish', '🐟'], ['bird', '🐦'], ['horse', '🐴'], ['lion', '🦁'], ['monkey', '🐵'],
    ],
  },
  frutas: {
    label: '🍎 Frutas',
    words: [
      ['apple', '🍎'], ['banana', '🍌'], ['grapes', '🍇'], ['orange', '🍊'], ['strawberry', '🍓'],
      ['pear', '🍐'], ['watermelon', '🍉'], ['cherry', '🍒'], ['lemon', '🍋'], ['pineapple', '🍍'],
    ],
  },
  colores: {
    label: '🎨 Colores',
    words: [
      ['red', '🟥'], ['blue', '🟦'], ['green', '🟩'], ['yellow', '🟨'], ['orange', '🟧'],
      ['purple', '🟪'], ['black', '⬛'], ['white', '⬜'], ['brown', '🟫'],
    ],
  },
  numeros: {
    label: '🔢 Números',
    words: [
      ['one', '1'], ['two', '2'], ['three', '3'], ['four', '4'], ['five', '5'],
      ['six', '6'], ['seven', '7'], ['eight', '8'], ['nine', '9'], ['ten', '10'],
    ],
  },
};

const $ = (sel) => document.querySelector(sel);
const rand = (n) => Math.floor(Math.random() * n);
const shuffle = (arr) => arr.map((v) => [Math.random(), v]).sort((a, b) => a[0] - b[0]).map((p) => p[1]);

// ---------- Estrellas (se guardan en el dispositivo) ----------
let stars = 0;
try { stars = Number(localStorage.getItem('stars')) || 0; } catch (_) {}
function addStar() {
  stars += 1;
  $('#star-count').textContent = stars;
  try { localStorage.setItem('stars', stars); } catch (_) {}
}
$('#star-count').textContent = stars;

// ---------- Voz ----------
function say(text, lang) {
  if (!('speechSynthesis' in window)) return;
  speechSynthesis.cancel();
  const u = new SpeechSynthesisUtterance(text);
  u.lang = lang;
  u.rate = 0.85;
  const voice = speechSynthesis.getVoices().find((v) => v.lang.startsWith(lang.slice(0, 2)));
  if (voice) u.voice = voice;
  speechSynthesis.speak(u);
}

// ---------- Navegación ----------
const TITLES = {
  menu: 'Aprende Jugando', 'math-levels': 'Sumar', math: 'Sumar',
  'english-topics': 'Inglés', english: 'Inglés', done: '¡Bravo!', premium: 'Premium',
};
function show(name) {
  document.querySelectorAll('.screen').forEach((s) => s.classList.remove('active'));
  $(`#screen-${name}`).classList.add('active');
  $('#title').textContent = TITLES[name];
  $('#btn-home').hidden = name === 'menu';
  if (name === 'premium') renderPremium();
}
document.addEventListener('click', (e) => {
  const go = e.target.closest('[data-go]');
  if (go) show(go.dataset.go);
  const parental = e.target.closest('[data-parental]');
  if (parental) Monetization.parentalGate().then((ok) => ok && show(parental.dataset.parental));
});
$('#btn-home').addEventListener('click', () => show('menu'));

function flash(symbol) {
  const f = $('#feedback');
  f.textContent = symbol;
  f.classList.remove('show');
  void f.offsetWidth; // reinicia la animación
  f.classList.add('show');
  setTimeout(() => f.classList.remove('show'), 700);
}

// ---------- Ronda genérica ----------
let game = null; // { kind, round, correct, next, again }

function startGame(kind, next, again) {
  game = { kind, round: 0, correct: 0, next, again };
  show(kind);
  next();
}

function renderOptions(container, options, answer, onAnswer) {
  container.innerHTML = '';
  let locked = false;
  options.forEach((opt) => {
    const b = document.createElement('button');
    b.className = 'opt';
    b.textContent = opt.label;
    b.addEventListener('click', () => {
      if (locked) return;
      if (opt.value === answer) {
        locked = true;
        b.classList.add('right');
        onAnswer(true);
      } else {
        b.classList.add('wrong');
        b.disabled = true;
        onAnswer(false);
      }
    });
    container.appendChild(b);
  });
}

function answered(ok, firstTry, bar) {
  if (!ok) { flash('🙈'); return; }
  if (firstTry) { game.correct += 1; addStar(); }
  flash(firstTry ? '⭐' : '👍');
  game.round += 1;
  $(bar).style.width = `${(game.round / ROUNDS) * 100}%`;
  setTimeout(() => (game.round >= ROUNDS ? finish() : game.next()), 900);
}

function finish() {
  const { correct } = game;
  const msg = correct >= 8 ? '¡Eres una estrella!' : correct >= 5 ? '¡Muy bien!' : '¡Sigue practicando!';
  $('#done-text').textContent = `${msg} ${correct} de ${ROUNDS} a la primera.`;
  Monetization.maybeShowAd($('#ad-slot'));
  say(game.kind === 'english' ? 'Great job!' : `¡${msg.replace(/¡|!/g, '')}!`, game.kind === 'english' ? 'en-US' : 'es-ES');
  show('done');
}
$('#btn-again').addEventListener('click', () => game && game.again());

// ---------- Sumas ----------
function mathRound(max) {
  const a = 1 + rand(max - 1);
  const b = 1 + rand(max - a);
  const sum = a + b;
  const obj = OBJECTS[rand(OBJECTS.length)];

  // Dibujos para contar (solo cuando son pocos)
  const visual = $('#math-visual');
  visual.innerHTML = '';
  if (sum <= 10) {
    const group = (n) => {
      const g = document.createElement('div');
      g.className = 'group';
      g.textContent = obj.repeat(n);
      return g;
    };
    const plus = document.createElement('span');
    plus.className = 'plus';
    plus.textContent = '+';
    visual.append(group(a), plus, group(b));
  }

  $('#math-question').textContent = `${a} + ${b} = ?`;
  say(`${a} más ${b}`, 'es-ES');

  const wrong = new Set();
  while (wrong.size < 2) {
    const w = sum + (rand(2) ? 1 : -1) * (1 + rand(3));
    if (w >= 0 && w !== sum) wrong.add(w);
  }
  const opts = shuffle([sum, ...wrong]).map((v) => ({ value: v, label: String(v) }));
  let firstTry = true;
  renderOptions($('#math-options'), opts, sum, (ok) => {
    if (!ok) firstTry = false;
    if (ok) say(String(sum), 'es-ES');
    answered(ok, firstTry, '#math-bar');
  });
}

// ---------- Premium ----------
function canPlay(free) {
  if (free || Monetization.isPremium()) return true;
  say('Pide ayuda a papá o a mamá', 'es-ES');
  Monetization.parentalGate().then((ok) => ok && show('premium'));
  return false;
}

function refreshLocks() {
  document.querySelectorAll('[data-math-max]').forEach((btn) => {
    btn.classList.toggle('locked', !Monetization.isPremium() && !Monetization.isMathLevelFree(Number(btn.dataset.mathMax)));
  });
  document.querySelectorAll('[data-topic]').forEach((btn) => {
    btn.classList.toggle('locked', !Monetization.isPremium() && !Monetization.isTopicFree(btn.dataset.topic));
  });
}

function renderPremium() {
  const owned = Monetization.isPremium();
  $('#btn-buy').textContent = owned ? '✅ Ya tienes Premium' : `Desbloquear por ${CONFIG.premium.price}`;
  $('#btn-buy').disabled = owned;
  $('#premium-status').textContent = owned ? '¡Gracias por apoyar la app!' : 'Pago único. Sin suscripción.';
}

$('#btn-buy').addEventListener('click', () => {
  Monetization.purchase().then((ok) => {
    if (!ok) return;
    refreshLocks();
    renderPremium();
    flash('👑');
  });
});

// ---------- Sumas: niveles ----------
document.querySelectorAll('[data-math-max]').forEach((btn) => {
  btn.addEventListener('click', () => {
    const max = Number(btn.dataset.mathMax);
    if (!canPlay(Monetization.isMathLevelFree(max))) return;
    $('#math-bar').style.width = '0';
    const play = () => startGame('math', () => mathRound(max), () => { $('#math-bar').style.width = '0'; play(); });
    play();
  });
});

// ---------- Inglés ----------
function englishRound(topic) {
  const words = TOPICS[topic].words;
  const [word, pic] = words[rand(words.length)];
  const others = shuffle(words.filter((w) => w[0] !== word)).slice(0, 2);
  const opts = shuffle([[word, pic], ...others]).map(([w, p]) => ({ value: w, label: p }));

  $('#eng-word').textContent = word;
  $('#eng-speak').onclick = () => say(word, 'en-US');
  say(word, 'en-US');

  let firstTry = true;
  renderOptions($('#eng-options'), opts, word, (ok) => {
    if (!ok) firstTry = false;
    if (ok) say(firstTry ? `Yes! ${word}` : word, 'en-US');
    answered(ok, firstTry, '#eng-bar');
  });
}

const topicList = $('#topic-list');
Object.entries(TOPICS).forEach(([key, t]) => {
  const b = document.createElement('button');
  b.className = 'pill';
  b.textContent = t.label;
  b.dataset.topic = key;
  b.addEventListener('click', () => {
    if (!canPlay(Monetization.isTopicFree(key))) return;
    $('#eng-bar').style.width = '0';
    const play = () => startGame('english', () => englishRound(key), () => { $('#eng-bar').style.width = '0'; play(); });
    play();
  });
  topicList.appendChild(b);
});

refreshLocks();

// Algunas plataformas cargan las voces tarde
if ('speechSynthesis' in window) speechSynthesis.onvoiceschanged = () => {};
