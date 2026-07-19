import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;
  GoTrueClient get auth => client.auth;

  Future<void> init() async {
    final url = dotenv.env['SUPABASE_URL'];
    final publishableKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];

    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL is not set. Please add it to .env file.');
    }

    if (publishableKey == null || publishableKey.isEmpty) {
      throw Exception(
        'SUPABASE_PUBLISHABLE_KEY is not set. Please add it to .env file.',
      );
    }

    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }
}
