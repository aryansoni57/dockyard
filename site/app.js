(() => {
const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => [...r.querySelectorAll(s)];
const calm = matchMedia('(prefers-reduced-motion: reduce)').matches;
const pad = n => String(n).padStart(2, '0');

// Clock, date, calendar
function tick() {
    const d = new Date();
    $$('[data-clock]').forEach(el => { el.textContent = pad(d.getHours()) + ':' + pad(d.getMinutes()); });
    $$('[data-date]').forEach(el => { el.textContent = d.toLocaleDateString('en-GB', { weekday: 'short', day: 'numeric', month: 'short' }); });
    $$('[data-zone]').forEach(el => { el.textContent = d.toLocaleTimeString('en-GB', { timeZone: el.dataset.zone, hour: '2-digit', minute: '2-digit' }); });
}
tick();
setInterval(tick, 10000);

const d = new Date();
$('[data-month]').textContent = d.toLocaleDateString('en-GB', { month: 'long', year: 'numeric' });
const first = (new Date(d.getFullYear(), d.getMonth(), 1).getDay() + 6) % 7;
const days = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
$('#cal').innerHTML = ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map(x => `<b>${x}</b>`).join('') + '<span></span>'.repeat(first)
    + [...Array(days)].map((_, i) => `<span class="${i + 1 === d.getDate() ? 'now' : ''}">${i + 1}</span>`).join('');

$$('.dock > *').forEach((el, i) => el.style.setProperty('--i', i));

// Feature list: advances by itself until someone picks a row.
const rows = $$('.row'), panes = $$('.pane');
let cur = 0, auto = !calm, started = 0, seen = false, hold = false;
const HOLD = 6500;
function show(i) {
    cur = i;
    rows.forEach((r, n) => { r.classList.toggle('on', n === i); r.setAttribute('aria-selected', n === i); r.style.removeProperty('--t'); });
    panes.forEach((p, n) => { p.hidden = n !== i; });
    started = performance.now();
}
rows.forEach((r, i) => r.addEventListener('click', () => { auto = false; show(i); }));
$('.list').addEventListener('keydown', e => {
    const step = { ArrowDown: 1, ArrowUp: -1 }[e.key];
    if (!step) return;
    e.preventDefault();
    const n = (cur + step + rows.length) % rows.length;
    auto = false; show(n); rows[n].focus();
});
$('.stage').addEventListener('pointerdown', () => { auto = false; rows[cur].style.removeProperty('--t'); });
// Hovering or focusing the feature section holds the rotation, and restarts the hold timer on release.
const split = $('.split');
const holdOn = () => { hold = true; };
const holdOff = () => { hold = false; started = performance.now(); };
split.addEventListener('pointerenter', holdOn);
split.addEventListener('pointerleave', holdOff);
split.addEventListener('focusin', holdOn);
split.addEventListener('focusout', holdOff);
new IntersectionObserver(es => { seen = es[0].isIntersecting; if (seen) started = performance.now(); }, { threshold: .4 }).observe(split);
(function loop(t) {
    if (auto && seen && !hold && !document.hidden) {
        const p = (t - started) / HOLD;
        if (p >= 1) show((cur + 1) % rows.length);
        else rows[cur].style.setProperty('--t', p.toFixed(3));
    }
    requestAnimationFrame(loop);
})(0);

// Launcher. The character check runs first, so only arithmetic reaches Function.
const APPS = [['Firefox', 'Web browser', 'firefox.svg'], ['Dolphin', 'File manager', 'org.kde.dolphin.svg'], ['Kate', 'Text editor', 'kate.svg'], ['Discord', 'Chat', 'discord.png'], ['VS Code', 'Code editor', 'vscode.png'], ['Spotify', 'Music', 'spotify-launcher.png']];
const SITE = [['Features', 'Five things you\'ll use all day', 'org.kde.dolphin.svg', '#features'], ['Glass theme', 'The whole desktop matches', 'systemsettings.svg', '#theme'], ['Install', 'Three commands', 'kate.svg', '#install'], ['GitHub', 'Source and changelog', 'firefox.svg', 'https://github.com/aryansoni57/dockyard']];
function calc(q) {
    const s = q.replace(/\s/g, '');
    if (!/^[\d.+\-*/()%]+$/.test(s) || !/[+\-*/%]/.test(s)) return null;
    try { const r = Function(`"use strict";return (${s})`)(); return Number.isFinite(r) ? +r.toFixed(8) : null; } catch { return null; }
}
function search(input, box, items, limit) {
    const q = input.value.trim(), sum = q ? calc(q) : null;
    if (sum !== null) {
        box.innerHTML = `<div class="hit sel"><span class="eq">=</span><span><div class="sum">${sum}</div><small>Enter copies the result</small></span></div>`;
        return;
    }
    const hits = items.filter(a => a[0].toLowerCase().includes(q.toLowerCase())).slice(0, limit);
    box.innerHTML = hits.map((a, i) => {
        const tag = a[3] ? 'a' : 'div', href = a[3] ? ` href="${a[3]}"` : '';
        return `<${tag}${href} class="hit ${i ? '' : 'sel'}"><img src="assets/icons/${a[2]}" alt=""><span>${a[0]}<br><small>${a[1]}</small></span>${i ? '' : '<em>Enter</em>'}</${tag}>`;
    }).join('') || '<div class="hit">No match</div>';
}
const featureSearch = () => search($('#q'), $('#res'), APPS, 3);
$('#q').addEventListener('input', featureSearch);
featureSearch();

// Start menu, opened over the Start tile like the real launcher.
const menu = $('#menu'), start = $('#start'), mq = $('#mq');
const menuSearch = () => search(mq, $('#mres'), SITE, 4);
function placeMenu() {
    const t = start.getBoundingClientRect(), h = $('.hero').getBoundingClientRect();
    menu.style.left = Math.max(8, Math.min(t.left - h.left, h.width - menu.offsetWidth - 8)) + 'px';
    menu.style.bottom = h.bottom - t.top + 12 + 'px';
}
function setMenu(open) {
    menu.hidden = !open;
    start.setAttribute('aria-expanded', open);
    if (open) { mq.value = ''; menuSearch(); placeMenu(); mq.focus({ preventScroll: true }); }
}
start.addEventListener('click', () => setMenu(menu.hidden));
mq.addEventListener('input', menuSearch);
mq.addEventListener('keydown', e => {
    if (e.key !== 'Enter') return;
    const link = $('#mres a'), sum = $('#mres .sum');
    if (link) { setMenu(false); link.click(); }
    else if (sum) {
        navigator.clipboard?.writeText(sum.textContent).catch(() => {});
        $('#mres small').textContent = 'Copied';
        $('#mres small').classList.add('copied');
    }
});
$('#mres').addEventListener('click', e => { if (e.target.closest('a')) setMenu(false); });
document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && !menu.hidden) { setMenu(false); start.focus(); }
});
document.addEventListener('pointerdown', e => {
    if (!menu.hidden && !menu.contains(e.target) && !start.contains(e.target)) setMenu(false);
});
addEventListener('resize', () => { if (!menu.hidden) placeMenu(); });

// Meta+N walks along the app row.
const keyApps = $$('#keyapps span');
let k = 0;
function key() {
    keyApps.forEach((s, i) => s.classList.toggle('on', i === k));
    $('#keynum').textContent = k + 1;
    k = (k + 1) % keyApps.length;
}
key();
if (!calm) setInterval(() => { if (seen && !panes[2].hidden) key(); }, 1100);

$$('.tg').forEach(b => b.addEventListener('click', () => b.setAttribute('aria-pressed', b.classList.toggle('on'))));

// Plasma style variant: the same alphas as theme/gen.py writes for each folder.
$$('.pick button').forEach(b => b.addEventListener('click', () => {
    $$('.pick button').forEach(x => { x.classList.toggle('on', x === b); x.setAttribute('aria-pressed', x === b); });
    const scene = $('#scene');
    scene.style.setProperty('--glass-a', b.dataset.a);
    scene.style.setProperty('--bar-a', b.dataset.b);
}));

// The desktop scene is drawn at 1280 wide and scaled to fit; phones keep it legible and crop.
const desk = $('#desk');
new ResizeObserver(() => {
    const w = desk.clientWidth, s = w < 600 ? .62 : w / 1280;
    const scene = $('#scene');
    scene.style.setProperty('--s', s);
    scene.style.left = Math.min(0, w - 1280 * s) + 'px';
}).observe(desk);

// Hero play button: look only. It changes its icon and caption and touches nothing else.
const hplay = $('#hplay');
const ICON = { play: '<svg viewBox="0 0 24 24"><path d="M7 4v16l13-8z"/></svg>', pause: '<svg viewBox="0 0 24 24"><path d="M6 4h4v16H6zM14 4h4v16h-4z"/></svg>' };
let hOn = true;
function paintHero() {
    hplay.innerHTML = hOn ? ICON.pause : ICON.play;
    hplay.setAttribute('aria-pressed', hOn);
    hplay.setAttribute('aria-label', hOn ? 'Pause' : 'Play');
    $('#vtime').textContent = hOn ? 'Playing' : 'Paused';
}
hplay.addEventListener('click', () => { hOn = !hOn; paintHero(); });
paintHero();

// The reel: loops silently while on screen. Tap it to play or pause, or use Sound on.
const reel = $('#reel'), snd = $('#snd'), big = $('#rplay');
function syncReel() {
    big.hidden = !reel.paused;
    snd.textContent = reel.muted ? 'Sound on' : 'Sound off';
}
['play', 'pause', 'volumechange'].forEach(ev => reel.addEventListener(ev, syncReel));
syncReel();
const tryPlay = () => { if (reel.paused) reel.play().catch(syncReel); };
reel.addEventListener('click', () => { reel.paused ? reel.play().catch(() => {}) : reel.pause(); });
big.addEventListener('click', () => { reel.play().catch(() => {}); });
snd.addEventListener('click', e => { e.stopPropagation(); reel.muted = !reel.muted; tryPlay(); });
reel.addEventListener('loadeddata', () => { if (onScreen && !calm) tryPlay(); });
let onScreen = false;
new IntersectionObserver(es => {
    onScreen = es[0].isIntersecting;
    if (calm) return;
    if (onScreen) tryPlay(); else if (reel.muted) reel.pause();
}, { threshold: .3 }).observe(reel);

$('#copy').addEventListener('click', e => {
    const b = e.currentTarget;
    navigator.clipboard?.writeText($('#install .term code').textContent).catch(() => {});
    b.textContent = 'Copied';
    setTimeout(() => { b.textContent = 'Copy'; }, 1600);
});

const io = new IntersectionObserver(es => es.forEach(e => {
    if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
}), { rootMargin: '0px 0px -8% 0px' });
const seenIn = new Map();
$$('.rise').forEach(el => {
    const p = el.parentElement, i = seenIn.get(p) || 0;
    seenIn.set(p, i + 1);
    el.style.setProperty('--d', i * 70 + 'ms');
    io.observe(el);
});
})();
