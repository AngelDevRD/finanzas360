import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opciones de intervalo de sync ofrecidas en Ajustes (modo Nube). El motor
/// sigue siendo local-first (ver SyncEngine): esto solo cambia cada cuánto se
/// drena lo pendiente hacia Supabase, no si se guarda local primero.
enum SyncFrequency {
  nearInstant(Duration(minutes: 1), 'Casi instantáneo'),
  every10Min(Duration(minutes: 10), 'Cada 10 minutos'),
  every30Min(Duration(minutes: 30), 'Cada 30 minutos'),
  hourly(Duration(hours: 1), 'Cada hora'),
  every3Hours(Duration(hours: 3), 'Cada 3 horas'),
  every5Hours(Duration(hours: 5), 'Cada 5 horas'),
  every12Hours(Duration(hours: 12), 'Cada 12 horas');

  const SyncFrequency(this.interval, this.label);
  final Duration interval;
  final String label;
}

const _syncFrequencyPrefsKey = 'sync_frequency_minutes';

class SyncFrequencyController extends Notifier<SyncFrequency> {
  @override
  SyncFrequency build() {
    _loadSaved();
    return SyncFrequency.every3Hours;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMinutes = prefs.getInt(_syncFrequencyPrefsKey);
    if (storedMinutes == null) return;
    final match = SyncFrequency.values.where(
      (f) => f.interval.inMinutes == storedMinutes,
    );
    if (match.isEmpty) return;
    state = match.first;
  }

  Future<void> setFrequency(SyncFrequency frequency) async {
    state = frequency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_syncFrequencyPrefsKey, frequency.interval.inMinutes);
  }
}

final syncFrequencyProvider =
    NotifierProvider<SyncFrequencyController, SyncFrequency>(
      SyncFrequencyController.new,
    );
