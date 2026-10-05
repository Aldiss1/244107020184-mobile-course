import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../data/dummy_data.dart' as dummy;

enum RepeatState { off, all, one }

enum SoundProfile {
  normal('Normal Hi-Fi', Icons.graphic_eq_rounded, 1.0),
  slowedReverb('Slowed + Lo-Fi', Icons.waves_rounded, 0.85),
  nightcore('Nightcore Sped-Up', Icons.bolt_rounded, 1.25),
  bassBoost('Bass Booster', Icons.speaker_group_rounded, 1.0),
  acoustic('Acoustic Warmth', Icons.music_note_rounded, 1.0);

  final String label;
  final IconData icon;
  final double defaultSpeed;
  const SoundProfile(this.label, this.icon, this.defaultSpeed);
}

class MusicProvider with ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  final List<Song> _allSongs = List<Song>.from(dummy.allSongs);
  final List<Playlist> _playlists = List<Playlist>.from(dummy.initialPlaylists);
  List<Song> _queue = List<Song>.from(dummy.allSongs);
  final List<Song> _history = [];

  Song? _currentSong;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isShuffle = false;
  RepeatState _repeatState = RepeatState.off;
  double _volume = 0.8;
  double _playbackRate = 1.0;
  bool _spatialAudioEnabled = true;

  // Sound FX Profile
  SoundProfile _activeProfile = SoundProfile.normal;
  final List<double> _equalizerBands = [3.0, 1.5, 0.0, 2.0, 4.0]; // 60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz

  // Listening Statistics
  int _totalSecondsListened = 1420; // Simulated past baseline + live increments
  Timer? _statsTimer;

  // Sleep Timer
  Timer? _sleepTimer;
  int _sleepTimerSecondsRemaining = 0;

  // Getters
  List<Song> get allSongs => _allSongs;
  List<Playlist> get playlists => _playlists;
  List<Song> get queue => _queue;
  List<Song> get history => _history;
  List<Song> get favoriteSongs => _allSongs.where((s) => s.isFavorite).toList();
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  bool get isShuffle => _isShuffle;
  RepeatState get repeatState => _repeatState;
  double get volume => _volume;
  double get playbackRate => _playbackRate;
  bool get spatialAudioEnabled => _spatialAudioEnabled;
  SoundProfile get activeProfile => _activeProfile;
  List<double> get equalizerBands => _equalizerBands;
  int get totalSecondsListened => _totalSecondsListened;
  int get sleepTimerSecondsRemaining => _sleepTimerSecondsRemaining;
  bool get isSleepTimerActive => _sleepTimerSecondsRemaining > 0;

  // Calculated Stats
  int get todayMinutesListened => (_totalSecondsListened / 60).floor();
  List<Song> get topPlayedSongs {
    final list = List<Song>.from(_allSongs);
    list.sort((a, b) => b.playCount.compareTo(a.playCount));
    return list;
  }

  // Active Karaoke Lyric Line
  int get currentLyricIndex {
    if (_currentSong == null || _currentSong!.syncedLyrics.isEmpty) return 0;
    final currentSec = _position.inMilliseconds / 1000.0;
    int index = 0;
    for (int i = 0; i < _currentSong!.syncedLyrics.length; i++) {
      if (currentSec >= _currentSong!.syncedLyrics[i].timestampSeconds) {
        index = i;
      }
    }
    return index;
  }

  MusicProvider() {
    _initAudioPlayer();
    _startStatsTicker();
  }

  void _startStatsTicker() {
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPlaying) {
        _totalSecondsListened += 1;
        notifyListeners();
      }
    });
  }

  void _initAudioPlayer() {
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _player.onDurationChanged.listen((newDuration) {
      _duration = newDuration;
      notifyListeners();
    });

    _player.onPositionChanged.listen((newPosition) {
      _position = newPosition;
      notifyListeners();
    });

    _player.onPlayerComplete.listen((event) {
      _handleSongCompletion();
    });
  }

  Future<void> playSong(Song song, {List<Song>? customQueue}) async {
    if (customQueue != null) {
      _queue = List.from(customQueue);
    }
    _currentSong = song;
    song.playCount += 1;

    if (!_history.any((s) => s.id == song.id)) {
      _history.insert(0, song);
    } else {
      _history.removeWhere((s) => s.id == song.id);
      _history.insert(0, song);
    }

    try {
      await _player.stop();
      await _player.play(AssetSource(song.audioUrl));
      await _player.setPlaybackRate(_playbackRate);
      await _player.setVolume(_volume);
    } catch (e) {
      debugPrint('Error playing audio asset: $e');
    }
    notifyListeners();
  }

  Future<void> resume() async {
    if (_currentSong == null && _queue.isNotEmpty) {
      await playSong(_queue.first);
      return;
    }
    await _player.resume();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> seek(Duration pos) async {
    await _player.seek(pos);
  }

  Future<void> setVolume(double val) async {
    _volume = val.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    notifyListeners();
  }

  Future<void> setPlaybackRate(double rate) async {
    _playbackRate = rate.clamp(0.5, 2.0);
    await _player.setPlaybackRate(_playbackRate);
    notifyListeners();
  }

  void setSoundProfile(SoundProfile profile) {
    _activeProfile = profile;
    setPlaybackRate(profile.defaultSpeed);
    notifyListeners();
  }

  void toggleSpatialAudio() {
    _spatialAudioEnabled = !_spatialAudioEnabled;
    notifyListeners();
  }

  void setEqualizerBand(int index, double gain) {
    if (index >= 0 && index < _equalizerBands.length) {
      _equalizerBands[index] = gain.clamp(-6.0, 6.0);
      notifyListeners();
    }
  }

  void resetEqualizer() {
    for (int i = 0; i < _equalizerBands.length; i++) {
      _equalizerBands[i] = 0.0;
    }
    notifyListeners();
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    int currentIndex = _currentSong != null ? _queue.indexWhere((s) => s.id == _currentSong!.id) : -1;
    if (_isShuffle && _queue.length > 1) {
      int nextIdx = (currentIndex + 1 + (DateTime.now().millisecond % (_queue.length - 1))) % _queue.length;
      await playSong(_queue[nextIdx]);
    } else if (currentIndex >= 0 && currentIndex < _queue.length - 1) {
      await playSong(_queue[currentIndex + 1]);
    } else if (_repeatState == RepeatState.all && _queue.isNotEmpty) {
      await playSong(_queue.first);
    }
  }

  Future<void> previous() async {
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    if (_queue.isEmpty) return;
    int currentIndex = _currentSong != null ? _queue.indexWhere((s) => s.id == _currentSong!.id) : -1;
    if (currentIndex > 0) {
      await playSong(_queue[currentIndex - 1]);
    } else if (_queue.isNotEmpty) {
      await playSong(_queue.last);
    }
  }

  void _handleSongCompletion() {
    if (_repeatState == RepeatState.one && _currentSong != null) {
      playSong(_currentSong!);
    } else {
      next();
    }
  }

  void toggleFavorite(Song song) {
    song.isFavorite = !song.isFavorite;
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    if (_repeatState == RepeatState.off) {
      _repeatState = RepeatState.all;
    } else if (_repeatState == RepeatState.all) {
      _repeatState = RepeatState.one;
    } else {
      _repeatState = RepeatState.off;
    }
    notifyListeners();
  }

  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    if (minutes <= 0) {
      _sleepTimerSecondsRemaining = 0;
      notifyListeners();
      return;
    }
    _sleepTimerSecondsRemaining = minutes * 60;
    notifyListeners();

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sleepTimerSecondsRemaining > 0) {
        _sleepTimerSecondsRemaining--;
        if (_sleepTimerSecondsRemaining == 0) {
          pause();
          timer.cancel();
        }
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimerSecondsRemaining = 0;
    notifyListeners();
  }

  void createPlaylist(String name, String desc) {
    final newPlaylist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: desc,
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80',
      songs: [],
    );
    _playlists.add(newPlaylist);
    notifyListeners();
  }

  void addSongToPlaylist(Playlist playlist, Song song) {
    if (!playlist.songs.any((s) => s.id == song.id)) {
      playlist.songs.add(song);
      notifyListeners();
    }
  }

  void removeSongFromPlaylist(Playlist playlist, Song song) {
    playlist.songs.removeWhere((s) => s.id == song.id);
    notifyListeners();
  }

  void addToQueue(Song song) {
    _queue.add(song);
    notifyListeners();
  }

  void playNext(Song song) {
    if (_currentSong != null) {
      int idx = _queue.indexWhere((s) => s.id == _currentSong!.id);
      if (idx >= 0) {
        _queue.insert(idx + 1, song);
      } else {
        _queue.insert(0, song);
      }
    } else {
      _queue.insert(0, song);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _sleepTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
