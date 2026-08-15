import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/domain/iscsi_auth_configuration.dart';

void main() {
  group('IscsiAuth.fromJson', () {
    test('parses a one-way CHAP entry', () {
      final auth = IscsiAuth.fromJson({'id': 4, 'tag': 1, 'user': 'alice'});
      expect(auth.id, 4);
      expect(auth.tag, 1);
      expect(auth.user, 'alice');
      expect(auth.peerUser, isNull);
      expect(auth.isMutual, isFalse);
      expect(auth.label, 'alice');
    });

    test('parses a mutual CHAP entry with peeruser', () {
      final auth = IscsiAuth.fromJson({
        'id': 5,
        'tag': 2,
        'user': 'bob',
        'peeruser': 'target-peer',
      });
      expect(auth.user, 'bob');
      expect(auth.peerUser, 'target-peer');
      expect(auth.isMutual, isTrue);
      expect(auth.label, 'bob · mutual');
    });

    test('accepts peer_user as an alternate field name', () {
      final auth = IscsiAuth.fromJson({
        'id': 6,
        'tag': 3,
        'user': 'carol',
        'peer_user': 'peer-carol',
      });
      expect(auth.peerUser, 'peer-carol');
      expect(auth.isMutual, isTrue);
    });

    test('falls back to an empty user for the implicit NONE entry', () {
      final auth = IscsiAuth.fromJson({'id': 7, 'tag': 0});
      expect(auth.user, '');
      expect(auth.isMutual, isFalse);
    });
  });

  group('IscsiAuthConfiguration.toCreateApiJson', () {
    test('emits tag, user, secret, and optional mutual fields', () {
      const configuration = IscsiAuthConfiguration(
        tag: 1,
        user: 'alice',
        secret: 's3cret',
        peerUser: '',
        peerSecret: null,
      );
      expect(configuration.toCreateApiJson(), {
        'tag': 1,
        'user': 'alice',
        'secret': 's3cret',
      });
    });

    test('includes peeruser and peersecret for mutual CHAP', () {
      const configuration = IscsiAuthConfiguration(
        tag: 2,
        user: 'bob',
        secret: 's3cret',
        peerUser: 'target-peer',
        peerSecret: 'peers3cret',
      );
      expect(configuration.toCreateApiJson(), {
        'tag': 2,
        'user': 'bob',
        'secret': 's3cret',
        'peeruser': 'target-peer',
        'peersecret': 'peers3cret',
      });
    });

    test('isMutual reflects the peer user', () {
      const oneWay = IscsiAuthConfiguration(
        tag: 1,
        user: 'alice',
        secret: 's',
        peerUser: '',
        peerSecret: null,
      );
      const mutual = IscsiAuthConfiguration(
        tag: 2,
        user: 'bob',
        secret: 's',
        peerUser: 'peer',
        peerSecret: null,
      );
      expect(oneWay.isMutual, isFalse);
      expect(mutual.isMutual, isTrue);
    });
  });

  group('IscsiAuthConfiguration.toUpdateApiJson', () {
    test('omits secrets when left blank so the server keeps them', () {
      const configuration = IscsiAuthConfiguration(
        tag: 1,
        user: 'alice',
        secret: null,
        peerUser: '',
        peerSecret: null,
      );
      expect(configuration.toUpdateApiJson(), {'tag': 1, 'user': 'alice'});
    });

    test('includes secrets only when rotating', () {
      const configuration = IscsiAuthConfiguration(
        tag: 1,
        user: 'alice',
        secret: 'newsecret',
        peerUser: 'peer',
        peerSecret: 'newpeersecret',
      );
      expect(configuration.toUpdateApiJson(), {
        'tag': 1,
        'user': 'alice',
        'secret': 'newsecret',
        'peeruser': 'peer',
        'peersecret': 'newpeersecret',
      });
    });
  });
}
