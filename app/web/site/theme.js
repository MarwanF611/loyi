// Light / dark / system appearance, shared by the website and the Loyi app.
// The app (shared_preferences on the web) keeps the choice in localStorage under
// "flutter.themeMode" as a JSON string; using the same key keeps both in sync.
// Light is the default. Loaded without defer so the right colours apply before
// the first paint.
(function () {
  var KEY = "flutter.themeMode";
  var media = window.matchMedia ? window.matchMedia("(prefers-color-scheme: dark)") : null;

  function stored() {
    try {
      var v = JSON.parse(localStorage.getItem(KEY) || "null");
      return v === "dark" || v === "system" ? v : "light";
    } catch (e) {
      return "light";
    }
  }

  function apply(mode) {
    var dark = mode === "dark" || (mode === "system" && media && media.matches);
    document.documentElement.setAttribute("data-theme", dark ? "dark" : "light");
    document.documentElement.setAttribute("data-theme-choice", mode);
    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute("content", dark ? "#111015" : "#FFFFFF");
    document.querySelectorAll("[data-theme-choice]").forEach(function (b) {
      if (b.tagName === "BUTTON") b.setAttribute("aria-pressed", String(b.getAttribute("data-theme-choice") === mode));
    });
  }

  window.loyiSetTheme = function (mode) {
    try {
      localStorage.setItem(KEY, JSON.stringify(mode));
    } catch (e) {
      // Private mode or storage blocked: still switch for this page view.
    }
    apply(mode);
  };

  apply(stored());
  if (media && media.addEventListener) {
    media.addEventListener("change", function () {
      if (stored() === "system") apply("system");
    });
  }
  document.addEventListener("DOMContentLoaded", function () {
    apply(stored());
    document.querySelectorAll("button[data-theme-choice]").forEach(function (b) {
      b.addEventListener("click", function () {
        window.loyiSetTheme(b.getAttribute("data-theme-choice"));
      });
    });
  });
})();
