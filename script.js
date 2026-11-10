const canvas = document.getElementById('scene');
const ctx = canvas.getContext('2d', { alpha: true });
const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
let width = 0;
let height = 0;
let dpr = 1;
let particles = [];
let frame = 0;

function resize() {
  dpr = Math.min(window.devicePixelRatio || 1, 2);
  width = window.innerWidth;
  height = window.innerHeight;
  canvas.width = width * dpr;
  canvas.height = height * dpr;
  canvas.style.width = `${width}px`;
  canvas.style.height = `${height}px`;
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  particles = Array.from({ length: Math.min(100, Math.floor(width / 13)) }, (_, i) => ({
    x: Math.random() * width,
    y: Math.random() * height,
    r: Math.random() * 1.5 + .25,
    a: Math.random() * .55 + .12,
    speed: Math.random() * .18 + .03,
    drift: (Math.random() - .5) * .08,
    hue: i % 4 === 0 ? 170 : i % 5 === 0 ? 28 : 250
  }));
}

function draw() {
  ctx.clearRect(0, 0, width, height);
  const t = frame * .006;
  const glow = ctx.createRadialGradient(width * .56, height * .38, 0, width * .56, height * .38, Math.max(width, height) * .55);
  glow.addColorStop(0, 'rgba(54, 48, 126, .12)');
  glow.addColorStop(.4, 'rgba(23, 46, 82, .045)');
  glow.addColorStop(1, 'rgba(7, 10, 18, 0)');
  ctx.fillStyle = glow;
  ctx.fillRect(0, 0, width, height);

  particles.forEach((p, i) => {
    const x = p.x + Math.sin(t * .7 + i) * 10;
    const y = (p.y - frame * p.speed) % (height + 20);
    const yy = y < -10 ? y + height + 20 : y;
    const alpha = p.a * (.55 + .45 * Math.sin(t + i));
    ctx.beginPath();
    ctx.arc(x, yy, p.r, 0, Math.PI * 2);
    ctx.fillStyle = p.hue === 170 ? `rgba(82,228,224,${alpha})` : p.hue === 28 ? `rgba(255,149,100,${alpha})` : `rgba(141,123,255,${alpha})`;
    ctx.fill();
  });

  // Two slow, barely visible signal waves make the backdrop feel alive without competing with the content.
  ctx.lineWidth = 1;
  for (let band = 0; band < 2; band++) {
    ctx.beginPath();
    for (let x = -20; x <= width + 20; x += 12) {
      const y = height * (.68 + band * .1) + Math.sin(x * .007 + t * (.45 + band * .2)) * (18 + band * 13) + Math.sin(x * .018 - t) * 5;
      if (x === -20) ctx.moveTo(x, y); else ctx.lineTo(x, y);
    }
    ctx.strokeStyle = band ? 'rgba(82,228,224,.035)' : 'rgba(141,123,255,.04)';
    ctx.stroke();
  }

  frame += 1;
  if (!reduceMotion.matches) requestAnimationFrame(draw);
}

window.addEventListener('resize', resize);
reduceMotion.addEventListener?.('change', () => { if (!reduceMotion.matches) draw(); });
resize();
draw();

// Lightweight pointer bloom for desktop; no dependency and harmless on touch devices.
const pointerGlow = document.createElement('div');
pointerGlow.className = 'pointer-glow';
document.body.appendChild(pointerGlow);
window.addEventListener('pointermove', (event) => {
  if (reduceMotion.matches || event.pointerType === 'touch') return;
  pointerGlow.style.transform = `translate3d(${event.clientX - 120}px,${event.clientY - 120}px,0)`;
});
