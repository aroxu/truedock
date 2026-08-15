import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/apps/domain/app_installation.dart';

void main() {
  test('parses version questions and populates nested defaults', () {
    final details = CatalogAppInstallationDetails.fromJson(
      _fixture,
      fallbackName: 'fallback',
      train: 'community',
    );

    expect(details.name, 'actual-budget');
    expect(details.preferredVersion!.version, '1.2.0');
    expect(details.preferredVersion!.initialValues, {
      'actual_budget': {'registration': true, 'admin_password': ''},
      'storage': {
        'type': 'ix_volume',
        'ix_volume_config': {'acl_enable': false},
        'host_path_config': {'path': null},
      },
      'extra_hosts': <Object?>[],
    });
  });

  test('omits inactive show_if branches from the app.create values', () {
    final version = CatalogAppInstallationDetails.fromJson(
      _fixture,
      fallbackName: 'fallback',
      train: 'community',
    ).preferredVersion!;
    final values = Map<String, Object?>.from(version.initialValues);

    final payload = version.installationValues(values);

    expect(payload['storage'], {
      'type': 'ix_volume',
      'ix_volume_config': {'acl_enable': false},
    });
    expect('$payload', contains('admin_password'));
    expect(version.toString(), isNot(contains('super-secret')));
  });

  test('evaluates supported conditional comparison operators', () {
    final question = AppQuestion.fromJson({
      'variable': 'advanced',
      'schema': {
        'type': 'string',
        'show_if': [
          [
            'mode',
            'in',
            ['advanced', 'expert'],
          ],
          ['count', '>=', 2],
        ],
      },
    });

    expect(question.isVisible({'mode': 'advanced', 'count': 2}), isTrue);
    expect(question.isVisible({'mode': 'basic', 'count': 2}), isFalse);
  });
}

final _fixture = <String, dynamic>{
  'name': 'actual-budget',
  'latest_version': '1.2.0',
  'versions': {
    '1.2.0': {
      'version': '1.2.0',
      'human_version': '25.10.0_1.2.0',
      'healthy': true,
      'supported': true,
      'values': <String, Object?>{},
      'schema': {
        'groups': [
          {'name': 'App', 'description': 'Application settings'},
        ],
        'questions': [
          {
            'variable': 'actual_budget',
            'label': '',
            'group': 'App',
            'schema': {
              'type': 'dict',
              'attrs': [
                {
                  'variable': 'registration',
                  'label': 'Allow registration',
                  'schema': {'type': 'boolean', 'default': true},
                },
                {
                  'variable': 'admin_password',
                  'label': 'Password',
                  'schema': {'type': 'string', 'default': '', 'private': true},
                },
              ],
            },
          },
          {
            'variable': 'storage',
            'label': 'Storage',
            'group': 'App',
            'schema': {
              'type': 'dict',
              'attrs': [
                {
                  'variable': 'type',
                  'label': 'Type',
                  'schema': {
                    'type': 'string',
                    'default': 'ix_volume',
                    'enum': [
                      {'value': 'ix_volume', 'description': 'Dataset'},
                      {'value': 'host_path', 'description': 'Host path'},
                    ],
                  },
                },
                {
                  'variable': 'ix_volume_config',
                  'label': 'Dataset',
                  'schema': {
                    'type': 'dict',
                    'show_if': [
                      ['type', '=', 'ix_volume'],
                    ],
                    'attrs': [
                      {
                        'variable': 'acl_enable',
                        'label': 'ACL',
                        'schema': {'type': 'boolean', 'default': false},
                      },
                    ],
                  },
                },
                {
                  'variable': 'host_path_config',
                  'label': 'Host path',
                  'schema': {
                    'type': 'dict',
                    'show_if': [
                      ['type', '=', 'host_path'],
                    ],
                    'attrs': [
                      {
                        'variable': 'path',
                        'label': 'Path',
                        'schema': {
                          'type': 'hostpath',
                          'required': true,
                          'null': true,
                        },
                      },
                    ],
                  },
                },
              ],
            },
          },
          {
            'variable': 'extra_hosts',
            'label': 'Extra hosts',
            'group': 'App',
            'schema': {
              'type': 'list',
              'default': [],
              'items': [
                {
                  'variable': 'host',
                  'label': 'Host',
                  'schema': {'type': 'string', 'required': true},
                },
              ],
            },
          },
        ],
      },
    },
  },
};
