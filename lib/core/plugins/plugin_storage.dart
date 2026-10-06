import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:timeflow/data/datasources/database.dart';

/// A plugin's private key-value store in the app database. Values are JSON.
class PluginStorage {
  PluginStorage(this._db, this.pluginId);

  final AppDatabase _db;
  final String pluginId;

  SimpleSelectStatement<$PluginDataTable, PluginDataRow> _select(String key) =>
      _db.select(_db.pluginData)
        ..where((r) => r.pluginId.equals(pluginId) & r.key.equals(key));

  Object? _decode(PluginDataRow? row) =>
      row == null ? null : jsonDecode(row.value);

  Future<Object?> read(String key) async =>
      _decode(await _select(key).getSingleOrNull());

  /// [read], re-emitted whenever the value changes.
  Stream<Object?> watch(String key) =>
      _select(key).watchSingleOrNull().map(_decode);

  Future<void> write(String key, Object? value) => _db
      .into(_db.pluginData)
      .insertOnConflictUpdate(
        PluginDataCompanion.insert(
          pluginId: pluginId,
          key: key,
          value: jsonEncode(value),
          updatedAt: DateTime.now(),
        ),
      );

  Future<void> delete(String key) => (_db.delete(
    _db.pluginData,
  )..where((r) => r.pluginId.equals(pluginId) & r.key.equals(key))).go();

  /// Removes everything this plugin stored.
  Future<void> clear() => (_db.delete(
    _db.pluginData,
  )..where((r) => r.pluginId.equals(pluginId))).go();
}
