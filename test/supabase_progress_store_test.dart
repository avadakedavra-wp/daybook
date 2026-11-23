import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_mini_todo/supabase_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'loads and updates progress with an account-scoped offline cache',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final client = SupabaseClient(
        'http://127.0.0.1:${server.port}',
        'test-key',
      );
      addTearDown(client.dispose);

      Map<String, dynamic>? written;
      var rejectReads = false;
      server.listen((request) async {
        request.response.headers.contentType = ContentType.json;
        if (request.method == 'POST') {
          written =
              jsonDecode(await utf8.decoder.bind(request).join())
                  as Map<String, dynamic>;
          request.response.statusCode = HttpStatus.created;
        } else if (rejectReads) {
          request.response.statusCode = HttpStatus.serviceUnavailable;
          request.response.write('{"message":"Offline"}');
        } else {
          final user = request.uri.queryParameters['user_id'];
          request.response.write(
            jsonEncode([
              if (user == 'eq.user-a')
                {'activity_date': '2026-11-23', 'activity_id': 'read'},
            ]),
          );
        }
        await request.response.close();
      });

      final day = DateTime(2026, 11, 23);
      final store = SupabaseProgressStore(client, prefs, 'user-a', 'project');
      await store.refresh();
      expect(store.completedOn(day), {'read'});

      final other = SupabaseProgressStore(client, prefs, 'user-b', 'project');
      expect(other.completedOn(day), isEmpty);

      expect(await store.save(day, 'walk', true), isTrue);
      expect(written, {
        'user_id': 'user-a',
        'activity_date': '2026-11-23',
        'activity_id': 'walk',
        'completed': true,
      });

      rejectReads = true;
      final reopened = SupabaseProgressStore(
        client,
        prefs,
        'user-a',
        'project',
      );
      await expectLater(reopened.refresh(), throwsA(isA<PostgrestException>()));
      expect(reopened.completedOn(day), {'read', 'walk'});
      expect(other.completedOn(day), isEmpty);
    },
  );
}
