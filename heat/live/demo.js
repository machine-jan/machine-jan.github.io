// ============================================================
// HEAT! – Demo-Modus für die Website
// Simuliert die latest.json, die in der Performance von Sonic Pi
// (circular_sounds 0.22) geschrieben wird. Gleiche Datenreihen,
// gleiche Formeln – nur im Zeitraffer und ohne Sonic Pi.
// Muss VOR app.js geladen werden.
// ============================================================
(function () {
  const years = [];
  for (let y = 1800; y <= 2100; y += 10) years.push(y);

  const anomaly = [-0.30, -0.28, -0.27, -0.25, -0.24, -0.22, -0.20, -0.18,
    -0.15, -0.12, -0.08, -0.03, 0.02, 0.08, 0.15, 0.22,
    0.30, 0.40, 0.52, 0.65, 0.80, 0.95, 1.12, 1.30,
    1.52, 1.75, 2.00, 2.25, 2.50, 2.75, 3.00];
  const temperature = anomaly.map(a => +(13.7 + a).toFixed(2));
  const co2 = [0.02, 0.03, 0.05, 0.08, 0.12, 0.18, 0.28, 0.45,
    0.70, 1.00, 1.50, 2.30, 3.50, 5.20, 7.80, 11.0,
    15.0, 20.0, 25.0, 31.0, 36.0, 40.0, 43.0, 46.0,
    48.0, 50.0, 51.0, 52.0, 53.0, 54.0, 55.0];
  const bio = [1.00, 0.995, 0.990, 0.985, 0.975, 0.965, 0.950, 0.930,
    0.905, 0.875, 0.840, 0.800, 0.755, 0.705, 0.650, 0.590,
    0.530, 0.470, 0.410, 0.350, 0.295, 0.245, 0.200, 0.160,
    0.125, 0.095, 0.072, 0.055, 0.043, 0.035, 0.030];
  const loss = [0.02, 0.02, 0.025, 0.03, 0.04, 0.05, 0.07, 0.09,
    0.12, 0.15, 0.18, 0.22, 0.26, 0.31, 0.36, 0.42,
    0.48, 0.54, 0.60, 0.65, 0.69, 0.72, 0.75, 0.77,
    0.79, 0.80, 0.805, 0.81, 0.815, 0.82, 0.825];

  const min = a => Math.min(...a), max = a => Math.max(...a);
  const c01 = x => Math.max(0, Math.min(1, x));
  const map = (v, a, b, c, d) => a === b ? c : c + (d - c) * c01((v - a) / (b - a));

  function tension(i) {
    const t = map(temperature[i], min(temperature), max(temperature), 0, 1);
    const c = map(co2[i], min(co2), max(co2), 0, 1);
    const b = map(bio[i], min(bio), max(bio), 1, 0);
    const l = map(loss[i], min(loss), max(loss), 0, 1);
    return c01(t * 0.34 + c * 0.26 + b * 0.22 + l * 0.18);
  }

  function jump(i) {
    if (i <= 0) return 0;
    const cj = Math.abs(co2[i] - co2[i - 1]) / Math.max(co2[i - 1], 1e-4);
    const tj = Math.abs(anomaly[i] - anomaly[i - 1]);
    const bj = Math.abs(bio[i] - bio[i - 1]) / Math.max(bio[i - 1], 1e-4);
    const lj = Math.abs(loss[i] - loss[i - 1]) / Math.max(loss[i - 1], 1e-4);
    let s = 0;
    s += cj > 0.18; s += cj > 0.35; s += tj > 0.12; s += tj > 0.22;
    s += bj > 0.06; s += bj > 0.12; s += lj > 0.08; s += lj > 0.16;
    return s >= 6 ? 3 : s >= 4 ? 2 : s >= 2 ? 1 : 0;
  }

  function frame(i) {
    return {
      year: years[i],
      year_index: i,
      temperature: temperature[i],
      temperature_anomaly: anomaly[i],
      co2: co2[i],
      biodiversity: bio[i],
      forest_loss: loss[i],
      forest_loss_percent: +(loss[i] * 100).toFixed(1),
      eco_tension: +tension(i).toFixed(3),
      jump_level: jump(i)
    };
  }

  // ------------------------------------------------------------
  // Zeitsteuerung: Tempo- und Jahresregler, Pause.
  // URL-Parameter: ?s=Sekunden pro Jahrzehnt, ?y=Startjahr, ?ui=0 ohne Regler.
  // ------------------------------------------------------------
  const params = new URLSearchParams(location.search);
  const S_MIN = 0.5, S_MAX = 240;
  let secondsPerDecade = Math.min(S_MAX, Math.max(S_MIN, Number(params.get("s")) || 3));
  const startYear = Number(params.get("y"));
  let pos = startYear >= 1800 && startYear <= 2100 ? Math.round((startYear - 1800) / 10) : 0;
  let playing = true;
  let last = performance.now();
  let shownIndex = -1;

  function currentIndex() {
    return Math.floor(pos) % years.length;
  }

  // Regler-Wert 0–1000 (logarithmisch) <-> Sekunden pro Jahrzehnt
  const toSlider = s => Math.round(1000 * Math.log(s / S_MIN) / Math.log(S_MAX / S_MIN));
  const fromSlider = v => S_MIN * Math.pow(S_MAX / S_MIN, v / 1000);

  function fmtDuration(sec) {
    if (sec < 60) return sec.toFixed(sec < 10 ? 1 : 0).replace(".", ",") + " s";
    const m = Math.floor(sec / 60), r = Math.round(sec % 60);
    if (m >= 60) return Math.floor(m / 60) + ":" + String(m % 60).padStart(2, "0") + " h";
    return m + ":" + String(r).padStart(2, "0") + " min";
  }

  let ui = null;
  function buildUI() {
    const css = document.createElement("style");
    css.textContent = `
      .hc{position:fixed;left:50%;bottom:14px;transform:translateX(-50%);z-index:50;
        display:flex;flex-wrap:wrap;align-items:center;gap:10px 18px;
        width:min(860px,calc(100vw - 24px));box-sizing:border-box;padding:10px 16px;
        background:rgba(10,14,12,.72);color:#fff6e8;border:1px solid rgba(255,246,232,.18);
        border-radius:10px;backdrop-filter:blur(6px);font:13px/1.3 Arial,Helvetica,sans-serif}
      .hc.off{width:auto;padding:6px 10px}
      .hc.off .hc-body{display:none}
      .hc-body{display:contents}
      .hc button{font:inherit;color:inherit;background:rgba(255,246,232,.1);
        border:1px solid rgba(255,246,232,.3);border-radius:6px;padding:5px 10px;cursor:pointer}
      .hc label{display:flex;align-items:center;gap:8px;flex:1 1 220px;min-width:0}
      .hc input[type=range]{flex:1;min-width:80px;accent-color:#ff8a5c}
      .hc .v{white-space:nowrap;opacity:.85;min-width:9.5em}
      .hc .k{opacity:.6;white-space:nowrap}
      @media print{.hc{display:none}}`;
    document.head.appendChild(css);

    const box = document.createElement("div");
    box.className = "hc";
    box.setAttribute("role", "group");
    box.setAttribute("aria-label", "Zeitsteuerung");
    box.innerHTML = `
      <button type="button" class="hc-play" aria-label="Pause">❚❚</button>
      <span class="hc-body">
        <label><span class="k">Jahr</span>
          <input class="hc-year" type="range" min="0" max="${years.length - 1}" step="1" value="0" aria-label="Jahr">
          <span class="v hc-yv"></span></label>
        <label><span class="k">Tempo</span>
          <input class="hc-speed" type="range" min="0" max="1000" step="1" aria-label="Tempo">
          <span class="v hc-sv"></span></label>
      </span>
      <button type="button" class="hc-hide" aria-label="Regler ausblenden" title="Regler ausblenden (H)">–</button>`;
    document.body.appendChild(box);

    const q = c => box.querySelector(c);
    ui = { box, play: q(".hc-play"), year: q(".hc-year"), yv: q(".hc-yv"),
           speed: q(".hc-speed"), sv: q(".hc-sv"), hide: q(".hc-hide") };
    ui.speed.value = toSlider(secondsPerDecade);

    ui.play.addEventListener("click", togglePlay);
    ui.year.addEventListener("input", () => { pos = Number(ui.year.value); refresh(true); });
    ui.speed.addEventListener("input", () => { secondsPerDecade = fromSlider(Number(ui.speed.value)); labels(); });
    ui.hide.addEventListener("click", toggleUI);
    document.addEventListener("keydown", e => {
      if (e.target.tagName === "INPUT" && e.key !== " ") return;
      if (e.key === " ") { e.preventDefault(); togglePlay(); }
      if (e.key === "h" || e.key === "H") toggleUI();
    });
    if (params.get("ui") === "0") toggleUI();
    labels();
  }

  function toggleUI() {
    if (!ui) return;
    const off = ui.box.classList.toggle("off");
    ui.hide.textContent = off ? "Regler" : "–";
    ui.hide.setAttribute("aria-label", off ? "Regler einblenden" : "Regler ausblenden");
  }

  function togglePlay() {
    playing = !playing;
    last = performance.now();
    if (ui) {
      ui.play.textContent = playing ? "❚❚" : "▶";
      ui.play.setAttribute("aria-label", playing ? "Pause" : "Abspielen");
    }
  }

  function labels() {
    if (!ui) return;
    const i = currentIndex();
    ui.year.value = i;
    ui.yv.textContent = years[i];
    ui.sv.textContent = fmtDuration(secondsPerDecade) + " / Jahrzehnt · Lauf " +
      fmtDuration(secondsPerDecade * years.length);
  }

  // Plakat sofort aktualisieren, wenn ein neues Jahrzehnt erreicht ist,
  // statt auf den Sekundentakt von app.js zu warten.
  function refresh(force) {
    const i = currentIndex();
    if (force || i !== shownIndex) {
      shownIndex = i;
      labels();
      if (typeof window.fetchLatest === "function") window.fetchLatest();
    }
  }

  function tick(now) {
    if (playing) {
      pos += (now - last) / 1000 / secondsPerDecade;
      if (pos >= years.length) pos -= years.length;
    }
    last = now;
    refresh(false);
    requestAnimationFrame(tick);
  }

  buildUI();
  requestAnimationFrame(tick);

  const realFetch = window.fetch.bind(window);
  window.fetch = function (url, opts) {
    if (String(url).includes("latest.json")) {
      const body = JSON.stringify(frame(currentIndex()));
      return Promise.resolve(new Response(body, { headers: { "Content-Type": "application/json" } }));
    }
    return realFetch(url, opts);
  };
})();
