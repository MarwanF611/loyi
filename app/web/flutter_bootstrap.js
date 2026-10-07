{{flutter_js}}
{{flutter_build_config}}

// Fallback fonts (Roboto, emoji, other scripts) from our own hosting, not fonts.gstatic.com;
// see scripts/vendor-fallback-fonts.sh. A custom onEntrypointLoaded must pass the config on itself.
const engineConfig = { fontFallbackBaseUrl: "/fallback-fonts/" };

_flutter.loader.load({
  config: engineConfig,
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine(engineConfig);
    document.getElementById('loader')?.remove();
    await appRunner.runApp();
  },
});
