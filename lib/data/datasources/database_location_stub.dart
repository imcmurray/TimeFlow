/// Browsers keep the database in IndexedDB; there's no file path.
Future<String> databasePath() async =>
    throw UnsupportedError('No database file on the web');
