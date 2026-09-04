// Procedural chiptune/synthwave loop generator for Neon Dodge.
//
// There are no binary assets in the repo. This tool synthesizes the two
// background music loops as 16-bit PCM WAV files into assets/audio/.
//
// Run from the project root:
//   dart run tool/generate_audio.dart
//
// Menu loop: chill 8th-note arpeggio over Am7 - Fmaj7 - Cmaj7 - G7
// Game loop: driving 16th-note square arp + saw bass over Dm - Bb - F - C
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 44100;

double midi(int note) => 440.0 * pow(2, (note - 69) / 12.0);

enum Wave { sine, triangle, square, saw }

void addPcm(
  Float64List buf,
  double start,
  double dur,
  double freq,
  double amp,
  Wave wave, {
  double attack = 0.008,
  double release = 0.05,
}) {
  if (amp <= 0 || dur <= 0) return;
  final startIndex = (start * sampleRate).round();
  final n = (dur * sampleRate).round();
  final a = min(attack, dur);
  final relStart = max(0.0, dur - release);

  for (var i = 0; i < n; i++) {
    final idx = startIndex + i;
    if (idx >= buf.length || idx < 0) break;
    final t = i / sampleRate;

    double env = 1.0;
    if (t < a) env = t / a;
    final afterRel = t - relStart;
    if (afterRel > 0) env = max(0.0, 1 - afterRel / release);

    final phase = (freq * t) % 1.0;
    double s;
    switch (wave) {
      case Wave.sine:
        s = sin(2 * pi * freq * t);
      case Wave.triangle:
        // Near-triangle: fundamental plus quieter odd harmonics.
        s = sin(2 * pi * freq * t) +
            0.30 * sin(2 * pi * freq * 3 * t) +
            0.12 * sin(2 * pi * freq * 5 * t);
        s /= 1.42;
      case Wave.square:
        s = phase < 0.5 ? 1.0 : -1.0;
        // Blend a sine back in to soften digital harshness.
        s = 0.72 * s + 0.28 * sin(2 * pi * freq * t);
      case Wave.saw:
        s = 2 * phase - 1;
        s = 0.6 * s + 0.4 * sin(2 * pi * freq * t);
    }
    buf[idx] += s * env * amp;
  }
}

/// One bar of music: arpeggio midi notes plus the bass midi hit.
class Bar {
  const Bar(this.arp, this.bass);

  final List<int> arp;
  final int bass;
}

/// Renders a full loop sheet into a float sample buffer.
Float64List renderLoop({
  required List<Bar> bars,
  required int bpm,
  required int subdivisions,
  required Wave arpWave,
  required double arpAmp,
  required double arpNoteDuration,
  required Wave bassWave,
  required double bassAmp,
  bool withPad = false,
  double padAmp = 0.05,
}) {
  final beat = 60.0 / bpm;
  final barDur = beat * 4;
  final seconds = bars.length * barDur;
  final buf = Float64List((seconds * sampleRate).ceil() + 16);

  for (var b = 0; b < bars.length; b++) {
    final bar = bars[b];
    final barStart = b * barDur;

    for (var s = 0; s < subdivisions; s++) {
      final note = bar.arp[s % bar.arp.length];
      final t = barStart + s * (barDur / subdivisions);
      addPcm(buf, t, arpNoteDuration, midi(note), arpAmp, arpWave);
    }

    // Bass: eighth-note drive on beats 0 and 2.
    addPcm(buf, barStart, beat * 1.8, midi(bar.bass), bassAmp, bassWave);
    addPcm(buf, barStart + beat * 2, beat * 1.8, midi(bar.bass - 12),
        bassAmp * 0.9, bassWave);

    if (withPad) {
      // Soft sustained chord root + fifth below for warmth.
      for (final m in [bar.bass - 12, bar.bass + 7, bar.arp[0] - 12]) {
        addPcm(buf, barStart, barDur, midi(m), padAmp, Wave.sine,
            attack: 0.35, release: 0.25);
      }
    }
  }

  // Master fade across the final 40 ms so the loop seam is click-free.
  final fadeSamples = (0.04 * sampleRate).round();
  for (var i = 0; i < fadeSamples && i < buf.length; i++) {
    buf[buf.length - 1 - i] *= i / fadeSamples;
  }
  return buf;
}

void writeWav(String path, Float64List samples) {
  final data = ByteData(samples.length * 2 + 44);
  void writeString(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  writeString(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  writeString(8, 'WAVE');
  writeString(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  data.setUint16(32, 2, Endian.little); // block align
  data.setUint16(34, 16, Endian.little); // bits per sample
  writeString(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);

  for (var i = 0; i < samples.length; i++) {
    final v = (samples[i] * 32767).round().clamp(-32768, 32767);
    data.setInt16(44 + i * 2, v, Endian.little);
  }

  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(data.buffer.asUint8List());
  stdout.writeln('Wrote ${file.path} (${(data.lengthInBytes / 1024).round()} KB)');
}

/// Menu: Am7 / Fmaj7 / Cmaj7 / G7, 8th-note triangle arp + soft bass.
void generateMenu() {
  const bpm = 96;
  final bars = [
    const Bar([57, 60, 64, 67], 45), // A3 C4 E4 G4 / A2
    const Bar([53, 57, 60, 64], 41), // F3 A3 C4 E4 / F2
    const Bar([60, 64, 67, 71], 48), // C4 E4 G4 B4 / C3
    const Bar([55, 59, 62, 67], 43), // G3 B3 D4 G4 / G2
  ];
  final wav = renderLoop(
    bars: bars,
    bpm: bpm,
    subdivisions: 8,
    arpWave: Wave.triangle,
    arpAmp: 0.16,
    arpNoteDuration: 0.32,
    bassWave: Wave.triangle,
    bassAmp: 0.11,
    withPad: true,
    padAmp: 0.045,
  );
  writeWav('assets/audio/menu_loop.wav', wav);
}

/// Game: Dm / Bb / F / C, 16th-note square arp + saw bass.
void generateGame() {
  const bpm = 132;
  final bars = [
    const Bar([50, 53, 57, 62], 38), // D3 F3 A3 D4 / D2
    const Bar([46, 50, 53, 58], 34), // Bb2 D3 F3 Bb3 / Bb1
    const Bar([53, 57, 60, 65], 41), // F3 A3 C4 F4 / F2
    const Bar([48, 52, 55, 60], 36), // C3 E3 G3 C4 / C2
  ];
  final wav = renderLoop(
    bars: bars,
    bpm: bpm,
    subdivisions: 16,
    arpWave: Wave.square,
    arpAmp: 0.14,
    arpNoteDuration: 0.26,
    bassWave: Wave.saw,
    bassAmp: 0.12,
  );
  writeWav('assets/audio/game_loop.wav', wav);
}

void main() {
  generateMenu();
  generateGame();
  stdout.writeln('Done synthesizing audio assets.');
}