// Premium, publicidad y control parental.
// Reglas para apps infantiles (Google Play Familias, App Store Kids, COPPA/RGPD):
//  - Solo anuncios NO personalizados y de redes certificadas para niños.
//  - Nunca anuncios durante el juego: solo en la pantalla final.
//  - Compras y enlaces externos siempre tras el control parental.

const Monetization = (() => {
  let premium = false;
  let gamesSinceAd = 0;
  try { premium = localStorage.getItem('premium') === '1'; } catch (_) {}

  function isPremium() { return premium; }

  function setPremium(value) {
    premium = value;
    try { localStorage.setItem('premium', value ? '1' : '0'); } catch (_) {}
  }

  function isMathLevelFree(max) { return CONFIG.free.mathMax.includes(max); }
  function isTopicFree(key) { return CONFIG.free.englishTopics.includes(key); }

  // TODO tienda: sustituir por Google Play Billing / StoreKit (p. ej. vía Capacitor).
  // Hoy desbloquea directamente para poder probar la experiencia.
  function purchase() {
    return Promise.resolve(true).then((ok) => { if (ok) setPremium(true); return ok; });
  }

  // Llamar al terminar cada partida. Devuelve true si se mostró un anuncio.
  function maybeShowAd(slot) {
    slot.hidden = true;
    slot.innerHTML = '';
    if (premium || !CONFIG.ads.enabled) return false;
    gamesSinceAd += 1;
    if (gamesSinceAd < CONFIG.ads.everyNGames) return false;
    gamesSinceAd = 0;

    if (CONFIG.ads.provider) {
      // Aquí se pedirá el anuncio a la red elegida, siempre con
      // tratamiento infantil activado y sin personalización.
      return false;
    }
    slot.innerHTML = '<span class="ad-label">Publicidad</span><div class="ad-body">Espacio para anuncio</div>';
    slot.hidden = false;
    return true;
  }

  // ---------- Control parental ----------
  // Una multiplicación que un niño pequeño no sabe resolver.
  function parentalGate() {
    return new Promise((resolve) => {
      const a = 6 + Math.floor(Math.random() * 4);
      const b = 6 + Math.floor(Math.random() * 4);
      const gate = document.getElementById('gate');
      const input = document.getElementById('gate-input');
      document.getElementById('gate-q').textContent = `¿Cuánto es ${a} × ${b}?`;
      input.value = '';
      gate.hidden = false;
      input.focus();

      const close = (ok) => {
        gate.hidden = true;
        okBtn.removeEventListener('click', onOk);
        cancelBtn.removeEventListener('click', onCancel);
        input.removeEventListener('keydown', onKey);
        resolve(ok);
      };
      const onOk = () => close(Number(input.value) === a * b);
      const onCancel = () => close(false);
      const onKey = (e) => { if (e.key === 'Enter') onOk(); };
      const okBtn = document.getElementById('gate-ok');
      const cancelBtn = document.getElementById('gate-cancel');
      okBtn.addEventListener('click', onOk);
      cancelBtn.addEventListener('click', onCancel);
      input.addEventListener('keydown', onKey);
    });
  }

  return { isPremium, setPremium, isMathLevelFree, isTopicFree, purchase, maybeShowAd, parentalGate };
})();
