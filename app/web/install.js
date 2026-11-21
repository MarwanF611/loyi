// Lets the app offer "put Loyi on your home screen" and see whether it already runs from there.
// Android Chrome fires beforeinstallprompt once, often before the app has loaded, so it is caught here.
// Loaded from index.html before the app (the Content-Security-Policy doesn't allow inline scripts).
let installPrompt = null;
window.addEventListener("beforeinstallprompt", (event) => {
  event.preventDefault();
  installPrompt = event;
});
window.addEventListener("appinstalled", () => (installPrompt = null));

window.loyiIsStandalone = () =>
  window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true;
window.loyiCanInstall = () => installPrompt !== null;
window.loyiPromptInstall = async () => {
  const event = installPrompt;
  if (!event) return false;
  installPrompt = null;
  event.prompt();
  return (await event.userChoice).outcome === "accepted";
};
