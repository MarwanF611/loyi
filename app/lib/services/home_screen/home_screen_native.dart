// The native apps are installed already: nothing to offer.
bool isStandalone() => true;

bool canPromptInstall() => false;

Future<bool> promptInstall() async => false;
