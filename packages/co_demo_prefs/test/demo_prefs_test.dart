import 'package:co_demo_prefs/co_demo_prefs.dart';
import 'package:test/test.dart';

void main() {
  group('DemoPrefs.fromUri', () {
    test('should_read_lang_and_theme_when_query_is_before_hash', () {
      final prefs = DemoPrefs.fromUri(
        Uri.parse(
          'https://docs.cocode.im/crux-climbing/app/?lang=ja&theme=light#/climbs',
        ),
      );
      expect(
        prefs,
        const DemoPrefs(locale: DemoLocale.ja, theme: DemoTheme.light),
      );
    });

    test('should_read_fragment_query_when_hash_router_moved_it', () {
      final prefs = DemoPrefs.fromUri(
        Uri.parse('https://docs.cocode.im/x/app/#/climbs?lang=ar&theme=dark'),
      );
      expect(
        prefs,
        const DemoPrefs(locale: DemoLocale.ar, theme: DemoTheme.dark),
      );
    });

    test('should_prefer_query_before_hash_when_both_are_present', () {
      final prefs = DemoPrefs.fromUri(
        Uri.parse(
          'https://docs.cocode.im/x/app/?lang=en#/a?lang=de&theme=light',
        ),
      );
      expect(prefs.locale, DemoLocale.en);
      expect(prefs.theme, DemoTheme.light);
    });

    test('should_be_empty_when_values_are_missing_or_unknown', () {
      expect(
        DemoPrefs.fromUri(Uri.parse('https://docs.cocode.im/x/app/')).isEmpty,
        isTrue,
      );
      expect(
        DemoPrefs.fromUri(
          Uri.parse('https://docs.cocode.im/x/app/?lang=xx&theme=sepia'),
        ).isEmpty,
        isTrue,
      );
    });
  });

  group('DemoPrefs.fromMessage', () {
    test('should_read_values_when_message_is_a_v1_sync', () {
      final prefs = DemoPrefs.fromMessage({
        'source': 'cocode-site',
        'type': 'sync',
        'v': 1,
        'locale': 'zh-Hans',
        'theme': 'dark',
      });
      expect(
        prefs,
        const DemoPrefs(locale: DemoLocale.zhHans, theme: DemoTheme.dark),
      );
    });

    test('should_accept_version_as_double_when_js_number_is_converted', () {
      final prefs = DemoPrefs.fromMessage({
        'source': 'cocode-site',
        'type': 'sync',
        'v': 1.0,
        'theme': 'light',
      });
      expect(prefs, const DemoPrefs(theme: DemoTheme.light));
    });

    test('should_return_null_when_message_does_not_follow_the_protocol', () {
      expect(DemoPrefs.fromMessage(null), isNull);
      expect(DemoPrefs.fromMessage('sync'), isNull);
      expect(
        DemoPrefs.fromMessage({
          'source': 'unibook-web',
          'type': 'sync',
          'v': 1,
          'locale': 'en',
        }),
        isNull,
      );
      expect(
        DemoPrefs.fromMessage({
          'source': 'cocode-site',
          'type': 'ready',
          'v': 1,
        }),
        isNull,
      );
      expect(
        DemoPrefs.fromMessage({
          'source': 'cocode-site',
          'type': 'sync',
          'v': 2,
          'locale': 'en',
        }),
        isNull,
      );
    });

    test('should_drop_invalid_fields_when_the_envelope_is_valid', () {
      final prefs = DemoPrefs.fromMessage({
        'source': 'cocode-site',
        'type': 'sync',
        'v': 1,
        'locale': 7,
        'theme': 'x',
      });
      expect(prefs, isNotNull);
      expect(prefs!.isEmpty, isTrue);
    });
  });

  group('DemoPrefs.applyTo', () {
    const prefs = DemoPrefs(locale: DemoLocale.en, theme: DemoTheme.dark);

    test('should_add_query_when_href_has_none', () {
      expect(
        prefs.applyTo('https://docs.cocode.im/clinic-emr/app/'),
        'https://docs.cocode.im/clinic-emr/app/?lang=en&theme=dark',
      );
    });

    test('should_insert_query_before_hash_when_href_has_a_fragment', () {
      expect(
        prefs.applyTo('https://docs.cocode.im/crux-climbing/app/#/climbs'),
        'https://docs.cocode.im/crux-climbing/app/?lang=en&theme=dark#/climbs',
      );
    });

    test(
      'should_replace_existing_keys_and_keep_others_when_href_has_query',
      () {
        expect(
          prefs.applyTo('https://cocode.im/x/?theme=light&ref=demo'),
          'https://cocode.im/x/?theme=dark&ref=demo&lang=en',
        );
      },
    );

    test('should_leave_href_unchanged_when_prefs_are_empty', () {
      expect(
        const DemoPrefs().applyTo('https://docs.cocode.im/x/#/a'),
        'https://docs.cocode.im/x/#/a',
      );
    });

    test('should_round_trip_through_from_uri_when_applied', () {
      expect(
        DemoPrefs.fromUri(
          Uri.parse(prefs.applyTo('https://docs.cocode.im/x/#/a')),
        ),
        prefs,
      );
    });
  });

  group('DemoEmbedProtocol', () {
    test('should_build_sync_message_that_from_message_reads_back', () {
      const prefs = DemoPrefs(locale: DemoLocale.ar, theme: DemoTheme.light);
      expect(
        DemoPrefs.fromMessage(DemoEmbedProtocol.syncMessage(prefs)),
        prefs,
      );
    });

    test('should_build_ready_message_with_app_source_and_version', () {
      expect(DemoEmbedProtocol.readyMessage(), {
        'source': 'cocode-demo',
        'type': 'ready',
        'v': 1,
      });
    });

    test('should_allow_only_cocode_sites_when_localhost_is_off', () {
      expect(
        DemoEmbedProtocol.isAllowedOrigin('https://demo.cocode.im'),
        isTrue,
      );
      expect(
        DemoEmbedProtocol.isAllowedOrigin('https://docs.cocode.im'),
        isTrue,
      );
      expect(DemoEmbedProtocol.isAllowedOrigin('https://cocode.im'), isTrue);
      expect(
        DemoEmbedProtocol.isAllowedOrigin('https://evil.example'),
        isFalse,
      );
      expect(
        DemoEmbedProtocol.isAllowedOrigin(
          'https://demo.cocode.im.evil.example',
        ),
        isFalse,
      );
      expect(
        DemoEmbedProtocol.isAllowedOrigin('http://demo.cocode.im'),
        isFalse,
      );
      expect(
        DemoEmbedProtocol.isAllowedOrigin('http://localhost:8197'),
        isFalse,
      );
    });

    test('should_allow_loopback_origins_when_localhost_is_on', () {
      expect(
        DemoEmbedProtocol.isAllowedOrigin(
          'http://localhost:8197',
          allowLocalhost: true,
        ),
        isTrue,
      );
      expect(
        DemoEmbedProtocol.isAllowedOrigin(
          'http://127.0.0.1',
          allowLocalhost: true,
        ),
        isTrue,
      );
      expect(
        DemoEmbedProtocol.isAllowedOrigin(
          'http://localhost.evil.example',
          allowLocalhost: true,
        ),
        isFalse,
      );
      expect(
        DemoEmbedProtocol.isAllowedOrigin(
          'https://localhost:8197',
          allowLocalhost: true,
        ),
        isFalse,
      );
    });
  });
}
