// The website's language (Dutch at "/", French at "/fr/", English at "/en/"), shared
// with the Loyi app: the app reads localStorage["flutter.locale"] (a JSON string, as
// shared_preferences stores it), so a shop that signs up from the French page gets
// the app in French. Loaded without defer so a redirect happens before the first paint.
(function () {
  var KEY = "flutter.locale";
  var page = document.documentElement.lang;

  function stored() {
    try {
      return JSON.parse(localStorage.getItem(KEY) || "null");
    } catch (e) {
      return null;
    }
  }

  function remember(lang) {
    try {
      localStorage.setItem(KEY, JSON.stringify(lang));
    } catch (e) {
      // Storage blocked: the page language still works, it just isn't remembered.
    }
  }

  // Back on the Dutch home page after choosing French or English earlier: go there.
  var chosen = stored();
  var home = location.pathname === "/" || location.pathname === "/index.html";
  if (page === "nl" && home && (chosen === "fr" || chosen === "en")) {
    location.replace("/" + chosen + "/" + location.hash);
    return;
  }
  remember(page);

  document.addEventListener("click", function (e) {
    var link = e.target.closest && e.target.closest("a[data-lang]");
    if (link) remember(link.getAttribute("data-lang"));
  });
})();
