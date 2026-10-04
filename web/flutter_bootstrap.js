{{flutter_js}}
{{flutter_build_config}}

// Load without Flutter's (deprecated) service worker; web/sw.js, registered
// in index.html, provides offline support instead.
_flutter.loader.load();
