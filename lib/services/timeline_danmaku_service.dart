import 'package:flutter/material.dart';

class TimelineDanmakuService {
  /// Generate timeline notification danmaku track
  /// 
  /// [videoDuration] Total video duration
  static Map<String, dynamic> generateTimelineDanmaku(Duration videoDuration) {
    final totalSeconds = videoDuration.inSeconds;
    final List<Map<String, dynamic>> comments = [];

    final percentages = [0.25, 0.50, 0.75, 0.90];
    final labels = ['25%', '50%', '75%', '90%'];

    for (int i = 0; i < percentages.length; i++) {
      final time = totalSeconds * percentages[i];
      final content = 'Video progress: ${labels[i]}';
      
      comments.add({
        'time': time,                 // time (double)
        'type': 'scroll',             // type (string)
        'content': content,           // content (string)
        'color': 'rgb(255,255,255)',  // color (string)
        // Add other compatibility fields
        't': time,
        'c': content,
        'y': 'scroll',
        'r': 'rgb(255,255,255)',
        'p': '', 
        'd': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'size': 25, // default font size
        'weight': 1, // default weight
      });
    }

    return {
      'name': 'Timeline Notification',
      'source': 'timeline',
      'count': comments.length,
      'comments': comments,
    };
  }
} 