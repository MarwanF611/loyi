// Fade sections in as they scroll into view. Loaded as a file (the site's
// Content-Security-Policy blocks inline scripts). Without JS, nothing is hidden.
document.documentElement.classList.add("js");

const targets = document.querySelectorAll(".reveal, .reveal-stagger");
if (!("IntersectionObserver" in window)) {
  targets.forEach((el) => el.classList.add("in"));
} else {
  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          entry.target.classList.add("in");
          observer.unobserve(entry.target);
        }
      }
    },
    { rootMargin: "0px 0px -10% 0px", threshold: 0.12 },
  );
  targets.forEach((el) => observer.observe(el));
}

// Business showcase tabs: click (or arrow keys) to switch; rotates by itself until touched.
for (const root of document.querySelectorAll("[data-tabs]")) {
  const tabs = [...root.querySelectorAll('[role="tab"]')];
  let timer = null;
  const select = (i, focus = false) => {
    tabs.forEach((t, j) => {
      t.setAttribute("aria-selected", String(i === j));
      t.tabIndex = i === j ? 0 : -1;
      document.getElementById(t.getAttribute("aria-controls"))?.classList.toggle("on", i === j);
    });
    if (focus) tabs[i].focus();
  };
  const stop = () => clearInterval(timer);
  tabs.forEach((t, i) => {
    t.addEventListener("click", () => { stop(); select(i); });
    t.addEventListener("keydown", (e) => {
      const d = e.key === "ArrowRight" ? 1 : e.key === "ArrowLeft" ? -1 : 0;
      if (!d) return;
      e.preventDefault();
      stop();
      select((i + d + tabs.length) % tabs.length, true);
    });
  });
  select(0);
  if (!window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
    let n = 0;
    timer = setInterval(() => select((n = (n + 1) % tabs.length)), 5000);
    root.addEventListener("pointerenter", stop, { once: true });
  }
}
