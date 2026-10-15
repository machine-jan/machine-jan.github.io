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

  const params = new URLSearchParams(location.search);
  const secondsPerDecade = Math.max(0.5, Number(params.get("s")) || 3);
  const start = Date.now();

  function currentIndex() {
    const step = Math.floor((Date.now() - start) / (secondsPerDecade * 1000));
    return step % years.length;
  }

  const realFetch = window.fetch.bind(window);
  window.fetch = function (url, opts) {
    if (String(url).includes("latest.json")) {
      const body = JSON.stringify(frame(currentIndex()));
      return Promise.resolve(new Response(body, { headers: { "Content-Type": "application/json" } }));
    }
    return realFetch(url, opts);
  };
})();
