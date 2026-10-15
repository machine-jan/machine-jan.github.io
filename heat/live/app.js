const yearEl = document.getElementById("year");

const temperatureEl = document.getElementById("temperature");
const anomalyEl = document.getElementById("anomaly");
const anomalyTextEl = document.getElementById("anomaly-text");
const co2El = document.getElementById("co2");
const co2TextEl = document.getElementById("co2-text");
const co2BaseEl = document.getElementById("co2-base");
const co2GrowthEl = document.getElementById("co2-growth");
const biodiversityEl = document.getElementById("biodiversity");
const biodiversityTextEl = document.getElementById("biodiversity-text");
const forestLossEl = document.getElementById("forest-loss");
const stressEl = document.getElementById("stress");

const co2FillEl = document.getElementById("co2-fill");
const anomalyFillEl = document.getElementById("anomaly-fill");
const bioFillEl = document.getElementById("bio-fill");

function clamp(x, min, max) {
  return Math.max(min, Math.min(max, x));
}

function lerp(a, b, t) {
  return a + (b - a) * t;
}

function formatSigned(value) {
  const v = Number(value);
  return v >= 0 ? `+${v.toFixed(2)}` : v.toFixed(2);
}

function setYearTypography(year) {
  yearEl.classList.remove("epoch-1", "epoch-2", "epoch-3", "epoch-4", "epoch-5");

  if (year < 1900) {
    yearEl.classList.add("epoch-1");
  } else if (year < 1950) {
    yearEl.classList.add("epoch-2");
  } else if (year < 2000) {
    yearEl.classList.add("epoch-3");
  } else if (year < 2100) {
    yearEl.classList.add("epoch-4");
  } else {
    yearEl.classList.add("epoch-5");
  }
}

function updateAtmosphere(data) {
  const year = Number(data.year);
  const stress = clamp(Number(data.eco_tension ?? 0), 0, 1);
  const jump = clamp(Number(data.jump_level ?? 0) / 3, 0, 1);

  let hue;
  let saturation;
  let lightness;

  if (year < 1950) {
    const t = clamp((year - 1800) / (1950 - 1800), 0, 1);
    hue = lerp(135, 102, t);
    saturation = lerp(82, 34, t);
    lightness = lerp(15, 19, t);
  } else if (year < 2030) {
    const t = clamp((year - 1950) / (2030 - 1950), 0, 1);
    hue = lerp(102, 8, t);
    saturation = lerp(34, 24, t);
    lightness = lerp(19, 22, t);
  } else if (year < 2050) {
    const t = clamp((year - 2030) / (2050 - 2030), 0, 1);
    hue = lerp(8, 1, t);
    saturation = lerp(24, 80, t);
    lightness = lerp(22, 24, t);
  } else {
    const t = clamp((year - 2050) / (2100 - 2050), 0, 1);
    hue = lerp(1, 18, t);
    saturation = lerp(80, 100, t);
    lightness = lerp(24, 38, t);
  }

  hue -= stress * 4 + jump * 2;
  saturation += stress * 7 + jump * 4;
  lightness += stress * 3 + jump * 2;

  hue = clamp(hue, 0, 140);
  saturation = clamp(saturation, 18, 100);
  lightness = clamp(lightness, 10, 45);

  document.body.style.backgroundColor =
    `hsl(${hue}, ${saturation}%, ${lightness}%)`;

  const glowStrength =
    (year >= 2050 ? 0.34 : 0.08) + stress * 0.40 + jump * 0.14;

  const innerGlow =
    year >= 2050
      ? `inset 0 0 ${Math.round(40 + glowStrength * 80)}px rgba(255, 90, 0, ${Math.min(0.48, glowStrength)})`
      : `inset 0 0 ${Math.round(12 + glowStrength * 28)}px rgba(255, 90, 0, ${Math.min(0.18, glowStrength * 0.7)})`;

  const outerGlow =
    `0 0 ${Math.round(18 + glowStrength * 58)}px rgba(255, 70, 0, ${Math.min(0.35, glowStrength)})`;

  document.body.style.boxShadow = `${innerGlow}, ${outerGlow}`;

  yearEl.style.color = year >= 2050 ? "#fff3d6" : "#fff6e7";
  yearEl.style.textShadow =
    year >= 2050
      ? `0 0 18px rgba(255, 220, 120, 0.34), 0 0 42px rgba(255, 80, 0, ${0.16 + stress * 0.30})`
      : `0 0 12px rgba(255, 180, 120, ${0.05 + stress * 0.15})`;
}

function updateThermometers(data) {
  const co2 = Number(data.co2);
  const anomaly = Number(data.temperature_anomaly);
  const biodiversity = Number(data.biodiversity);

  const co2Min = 0.02;
  const co2Max = 55.0;
  const co2T = clamp((co2 - co2Min) / (co2Max - co2Min), 0, 1);
  const co2Height = 8 + co2T * 92;

  const anomalyMin = -0.30;
  const anomalyMax = 3.00;
  const anomalyT = clamp((anomaly - anomalyMin) / (anomalyMax - anomalyMin), 0, 1);
  const anomalyHeight = 8 + anomalyT * 92;

  // Der Pegel steigt nach oben, orientiert sich aber am Verlust der Biodiversität
  const bioLoss = clamp(1 - biodiversity, 0, 1);
  const bioHeight = 8 + bioLoss * 92;

  co2FillEl.style.height = `${co2Height}%`;
  anomalyFillEl.style.height = `${anomalyHeight}%`;
  bioFillEl.style.height = `${bioHeight}%`;

  const co2Hue = lerp(34, 58, co2T);
  const co2Sat = lerp(28, 92, co2T);
  const co2Light = lerp(80, 52, co2T);
  co2FillEl.style.backgroundColor = `hsl(${co2Hue}, ${co2Sat}%, ${co2Light}%)`;
  co2FillEl.style.boxShadow =
    co2 > 35 ? `0 0 14px rgba(230, 255, 60, 0.28)` : `0 0 6px rgba(210, 200, 160, 0.10)`;

  const anomalyHue = lerp(198, 18, anomalyT);
  const anomalyLightness = lerp(74, 52, anomalyT);
  anomalyFillEl.style.backgroundColor =
    `hsl(${anomalyHue}, 96%, ${anomalyLightness}%)`;
  anomalyFillEl.style.boxShadow =
    anomaly > 2
      ? `0 0 18px rgba(255, 120, 0, 0.45)`
      : `0 0 8px rgba(120, 200, 255, 0.20)`;

  // Betongrauer Pegel auf grünem Hintergrund
  bioFillEl.style.backgroundColor = `hsl(0, 0%, 58%)`;
  bioFillEl.style.boxShadow =
    bioLoss > 0.55
      ? `0 0 10px rgba(140, 140, 140, 0.16)`
      : `0 0 5px rgba(110, 110, 110, 0.10)`;
}

function updateInfo(data) {
  const co2 = Number(data.co2);
  const anomaly = Number(data.temperature_anomaly);
  const temp = Number(data.temperature);
  const biodiversity = Number(data.biodiversity);
  const forestLoss = Number(data.forest_loss_percent ?? 0);
  const stress = Number(data.eco_tension);

  const startCo2 = 0.02;
  const growthPct = ((co2 - startCo2) / startCo2) * 100;

  temperatureEl.textContent = temp.toFixed(2);
  anomalyEl.textContent = formatSigned(anomaly);
  anomalyTextEl.textContent = formatSigned(anomaly);

  co2El.textContent = co2.toFixed(2);
  co2TextEl.textContent = co2.toFixed(2);
  co2BaseEl.textContent = startCo2.toFixed(2);
  co2GrowthEl.textContent = `+${growthPct.toFixed(0)}%`;

  biodiversityEl.textContent = biodiversity.toFixed(3);
  biodiversityTextEl.textContent = biodiversity.toFixed(3);

  forestLossEl.textContent = forestLoss.toFixed(1);

  stressEl.textContent = stress.toFixed(3);
}

async function fetchLatest() {
  try {
    const res = await fetch("./latest.json?t=" + Date.now());
    if (!res.ok) return;

    const data = await res.json();

    yearEl.textContent = data.year;

    setYearTypography(Number(data.year));
    updateAtmosphere(data);
    updateThermometers(data);
    updateInfo(data);
  } catch (e) {
    console.log("Fehler beim Laden von latest.json", e);
  }
}

setInterval(fetchLatest, 1000);
fetchLatest();