import 'package:coui_web/coui_web.dart';

import 'model.dart';

/// Static gallery document built with Jaspr and CoUI Web components.
///
/// Native controls retain their built-in keyboard behavior.
class GalleryView extends StatelessComponent {
  /// Creates the page from a catalog and precomputed image positions.
  const GalleryView({
    required this.catalog,
    required this.title,
    required this.plainTitle,
    required this.metadata,
    required this.links,
    required this.generatedAt,
    required this.imageUrl,
    required this.imageIndices,
    super.key,
  });

  /// Scenarios and images to display.
  final GalleryCatalog catalog;

  /// Document heading.
  final String title;

  /// Heading for images without variant axes.
  final String plainTitle;

  /// Header labels and values.
  final List<(String, String)> metadata;

  /// Header links.
  final List<(String, String)> links;

  /// UTC generation time.
  final DateTime generatedAt;

  /// Resolves each image's URL.
  final String Function(GalleryImage) imageUrl;

  /// Stable lightbox position for each image.
  final Map<GalleryImage, int> imageIndices;

  List<GalleryScenario> get _plain => [
    for (final scenario in catalog.scenarios)
      if (!scenario.fromManifest) scenario,
  ];

  List<String> get _matrixSuites => [
    for (final suite in catalog.suites)
      if (catalog.scenarios.any(
        (scenario) => scenario.suite == suite && scenario.fromManifest,
      ))
        suite,
  ];

  Iterable<GalleryScenario> _matrixOf(String suite) => catalog.scenarios.where(
    (scenario) => scenario.suite == suite && scenario.fromManifest,
  );

  @override
  Component build(BuildContext context) => Component.fragment([
    _header(),
    _toolbar(),
    _e('div', classes: 'layout', [_toc(), _main()]),
    _viewer(),
  ]);

  Component _header() {
    final generated = generatedAt.toIso8601String().substring(0, 16);
    return _e('header', classes: 'top', [
      _e('div', classes: 'title', [
        _e('p', classes: 'eyebrow', [_t('COCODE / GOLDEN GALLERY')]),
        _e('h1', [_t(title)]),
        _e('ul', classes: 'stats', [
          _stat(catalog.scenarios.length, '시나리오'),
          _stat(catalog.imageCount, '이미지'),
          _stat(
            catalog.failedCount,
            '실패',
            status: catalog.failedCount > 0 ? 'bad' : 'good',
          ),
        ]),
        _e('dl', classes: 'meta', [
          for (final (label, value) in metadata)
            _e('div', [
              _e('dt', [_t(label)]),
              _e('dd', [_t(value)]),
            ]),
          _e('div', [
            _e('dt', [_t('생성')]),
            _e('dd', [_t('$generated UTC')]),
          ]),
        ]),
      ]),
      _e('div', classes: 'actions', [
        for (final (label, url) in links)
          Link(
            href: url,
            external: true,
            underline: false,
            classes: 'link',
            attributes: const {'rel': 'noopener'},
            child: _t(label),
          ),
        Button(
          id: 'theme-toggle',
          variant: CoreButtonVariant.outline,
          size: CoreComponentSize.sm,
          classes: 'link theme-toggle',
          attributes: const {'type': 'button', 'aria-label': '화면 테마 전환'},
          onPressed: () {},
          child: _t('테마: 어둡게'),
        ),
      ]),
    ]);
  }

  Component _stat(int count, String label, {String? status}) =>
      _e('li', classes: status, [
        _e('b', [_t('$count')]),
        _t(' $label'),
      ]);

  Component _toolbar() {
    final images = [
      for (final scenario in catalog.scenarios) ...scenario.images,
    ];
    List<String> distinct(String? Function(GalleryImage image) pick) {
      final seen = <String>{};
      return [
        for (final image in images)
          if (pick(image) case final value? when seen.add(value)) value,
      ];
    }

    return _e(
      'div',
      classes: 'toolbar',
      attributes: const {'role': 'search'},
      [
        _e('label', classes: 'field grow', [
          _e('span', [_t('검색')]),
          _e(
            'input',
            [],
            id: 'q',
            attributes: const {
              'type': 'search',
              'autocomplete': 'off',
              'placeholder': '시나리오, 설명, 파일 이름',
            },
          ),
        ]),
        _select('f-suite', '스위트', catalog.suites),
        _select('f-device', '기기', distinct((image) => image.device)),
        _select('f-theme', '테마', distinct((image) => image.theme)),
        _select('f-locale', '언어', distinct((image) => image.locale)),
        _e('label', classes: 'check', [
          _e(
            'input',
            [],
            id: 'f-failed',
            attributes: const {'type': 'checkbox'},
          ),
          _t(' 실패만'),
        ]),
        _e(
          'output',
          [],
          id: 'visible',
          attributes: const {'aria-live': 'polite'},
        ),
      ],
    );
  }

  Component _select(String id, String label, List<String> values) =>
      _e('label', classes: 'field', [
        _e('span', [_t(label)]),
        _e('select', id: id, [
          _e('option', attributes: const {'value': ''}, [_t('전체')]),
          for (final value in values)
            _e('option', attributes: {'value': value}, [_t(value)]),
        ]),
      ]);

  Component _toc() => _e(
    'nav',
    classes: 'toc',
    attributes: const {'aria-label': '시나리오 목록'},
    [
      _e(
        'details',
        attributes: const {'open': ''},
        [
          _e('summary', [_t('시나리오')]),
          for (final suite in _matrixSuites)
            _e(
              'div',
              classes: 'toc-suite',
              attributes: {'data-suite': suite},
              [
                _e('h2', [_t(suite)]),
                _e('ul', [
                  for (final scenario in _matrixOf(suite))
                    _tocItem(scenario, scenario.name),
                ]),
              ],
            ),
          if (_plain.isNotEmpty)
            _e('div', classes: 'toc-suite plain', [
              _e('h2', [_t(plainTitle)]),
              _e('ul', [
                for (final scenario in _plain)
                  _tocItem(scenario, _plainHeading(scenario)),
              ]),
            ]),
        ],
      ),
    ],
  );

  Component _tocItem(GalleryScenario scenario, String label) => _e(
    'li',
    attributes: {'data-toc': scenario.anchor},
    [
      Link(
        href: '#${scenario.anchor}',
        underline: false,
        classes: 'toc-link',
        child: _t(label),
      ),
      _e('span', classes: 'count', [_t('${scenario.images.length}')]),
      if (scenario.failedCount > 0)
        _e('span', classes: 'count fail', [_t('실패 ${scenario.failedCount}')]),
    ],
  );

  Component _main() => _e('main', id: 'gallery', [
    for (final suite in _matrixSuites)
      _e(
        'section',
        classes: 'suite',
        attributes: {'data-suite': suite},
        [
          _e('h2', classes: 'suite-title', [_t(suite)]),
          for (final scenario in _matrixOf(suite))
            _scenario(scenario, scenario.name),
        ],
      ),
    if (_plain.isNotEmpty)
      _e('section', classes: 'suite plain', [
        _e('h2', classes: 'suite-title', [_t(plainTitle)]),
        _e('p', classes: 'suite-note', [
          _t('기기·테마·언어 정보가 없는 이미지입니다. 기기·테마·언어 필터를 고르면 숨겨집니다.'),
        ]),
        for (final scenario in _plain)
          _scenario(scenario, _plainHeading(scenario)),
      ]),
    _e(
      'p',
      id: 'empty',
      classes: 'empty',
      attributes: const {'hidden': ''},
      [_t('조건에 맞는 이미지가 없습니다.')],
    ),
  ]);

  Component _scenario(GalleryScenario scenario, String heading) {
    final search = [
      scenario.suite,
      scenario.name,
      scenario.description ?? '',
      for (final image in scenario.images) image.name,
    ].join(' ').toLowerCase();
    return _e(
      'section',
      id: scenario.anchor,
      classes: 'scenario',
      attributes: {'data-suite': scenario.suite, 'data-search': search},
      [
        Card(
          classes: 'scenario-card',
          cardStyle: const CoreCardStyle(
            sizing: CoreCardSizing.expand,
            elevation: CoreCardElevation.none,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
            padding: CoreEdgeInsets.all(20),
          ),
          child: _e('div', classes: 'scenario-content', [
            _e('div', classes: 'scenario-head', [
              _e('h3', [_t(heading)]),
              if (scenario.description case final description?)
                _e('p', [_t(description)]),
              _e('div', classes: 'badges', [
                Badge(
                  variant: CoreBadgeVariant.outline,
                  classes: 'status-badge',
                  child: _t(
                    '${scenario.fromManifest ? '매트릭스' : '이미지'} ${scenario.images.length}',
                  ),
                ),
                if (scenario.failedCount > 0)
                  Badge(
                    variant: CoreBadgeVariant.destructive,
                    classes: 'status-badge fail',
                    child: _t('실패 ${scenario.failedCount}'),
                  ),
              ]),
            ]),
            if (scenario.fromManifest) _matrix(scenario) else _cards(scenario),
          ]),
        ),
      ],
    );
  }

  Component _matrix(GalleryScenario scenario) {
    final images = scenario.images;
    final axes = scenario.axes;
    final cells = <String, GalleryImage>{};
    final samples = <String, GalleryImage>{};
    for (final image in images) {
      cells['${image.device ?? image.name}\u0000${image.columnKey}'] = image;
      samples.putIfAbsent(image.columnKey, () => image);
    }
    final devices = _sorted(
      _firstSeen([for (final image in images) image.device ?? image.name]),
      [_rank(_orderOf(axes?.devices, const []))],
      (device) => [device],
    );
    final themeRank = _rank(
      _orderOf(axes?.themes, [for (final image in images) image.theme ?? '']),
    );
    final localeRank = _rank(
      _orderOf(axes?.locales, [for (final image in images) image.locale ?? '']),
    );
    final scaleRank = _rank(
      _orderOf(axes?.textScales, [
        for (final image in images) image.textScale ?? 1.0,
      ]),
    );
    final columns = _sorted<String, Object>(
      samples.keys.toList(),
      [
        (value) => themeRank(value),
        (value) => localeRank(value),
        (value) => scaleRank(value),
      ],
      (column) {
        final image = samples[column]!;
        return [image.theme ?? '', image.locale ?? '', image.textScale ?? 1.0];
      },
    );

    return _e('div', classes: 'matrix-wrap', [
      _e('table', classes: 'matrix', [
        _e('thead', [
          _e('tr', [
            _e('th', attributes: const {'scope': 'col'}, [_t('기기')]),
            for (final column in columns)
              _e(
                'th',
                attributes: {
                  'scope': 'col',
                  'data-theme': samples[column]?.theme ?? '',
                  'data-locale': samples[column]?.locale ?? '',
                },
                [_t(column)],
              ),
          ]),
        ]),
        _e('tbody', [
          for (final device in devices)
            _e(
              'tr',
              attributes: {'data-device': device},
              [
                _e('th', attributes: const {'scope': 'row'}, [_t(device)]),
                for (final column in columns)
                  if (cells['$device\u0000$column'] case final image?)
                    _e('td', attributes: _imageAttributes(image), [
                      _shot(scenario, image),
                    ])
                  else
                    _e(
                      'td',
                      [],
                      classes: 'none',
                      attributes: const {'aria-label': '해당 조합 없음'},
                    ),
              ],
            ),
        ]),
      ]),
    ]);
  }

  Component _cards(GalleryScenario scenario) => _e('div', classes: 'cards', [
    for (final image in scenario.images)
      _e('figure', classes: 'card', attributes: _imageAttributes(image), [
        _shot(scenario, image),
        _e('figcaption', [_t(image.name)]),
      ]),
  ]);

  Component _shot(GalleryScenario scenario, GalleryImage image) {
    final failed = image.status == GalleryStatus.failed;
    final flags = <Component>[
      if (failed) _e('span', classes: 'flag', [_t('실패')]),
      if (image.overflowCount > 0)
        _e('span', classes: 'flag', [_t('오버플로 ${image.overflowCount}')]),
    ];
    if (image.path.isEmpty) {
      return Component.fragment([
        _e('div', classes: 'shot missing', [
          ...flags,
          _e('span', [_t('캡처 없음')]),
        ]),
        _errors(image),
      ]);
    }
    return Component.fragment([
      _e(
        'button',
        classes: failed ? 'shot failed' : 'shot',
        attributes: {
          'type': 'button',
          'data-index': '${imageIndices[image]}',
          'aria-label': '${scenario.name} — ${image.label} 크게 보기',
        },
        [
          ...flags,
          _e(
            'img',
            [],
            attributes: {
              'src': imageUrl(image),
              'alt': '${scenario.name} — ${image.label}',
              'loading': 'lazy',
              'decoding': 'async',
              if (image.width case final width?) 'width': '$width',
              if (image.height case final height?) 'height': '$height',
            },
          ),
        ],
      ),
      _errors(image),
    ]);
  }

  Component _errors(GalleryImage image) => image.errors.isEmpty
      ? const Component.fragment([])
      : _e('details', classes: 'errors', [
          _e('summary', [_t('오류 ${image.errors.length}')]),
          _e('ul', [
            for (final error in image.errors) _e('li', [_t(error)]),
          ]),
        ]);

  Component _viewer() => _e(
    'dialog',
    id: 'viewer',
    attributes: const {'aria-labelledby': 'viewer-title'},
    [
      _e('div', classes: 'viewer-bar', [
        _e('div', [
          _e('p', [], id: 'viewer-title'),
          _e('p', [], id: 'viewer-label'),
        ]),
        _e('div', classes: 'viewer-actions', [
          _viewerButton('viewer-prev', '이전 이미지', '이전'),
          _viewerButton('viewer-next', '다음 이미지', '다음'),
          _viewerButton('viewer-close', '닫기', '닫기'),
        ]),
      ]),
      _e('ul', [], id: 'viewer-errors'),
      _e('div', classes: 'viewer-body', [
        _e('img', [], id: 'viewer-image', attributes: const {'alt': ''}),
      ]),
    ],
  );

  Component _viewerButton(String id, String label, String text) => Button(
    id: id,
    variant: CoreButtonVariant.outline,
    size: CoreComponentSize.sm,
    classes: 'viewer-button',
    attributes: {'type': 'button', 'aria-label': label},
    onPressed: () {},
    child: _t(text),
  );
}

String _plainHeading(GalleryScenario scenario) =>
    '${scenario.suite} / ${scenario.name}';

Map<String, String> _imageAttributes(GalleryImage image) => {
  'data-device': image.device ?? '',
  'data-theme': image.theme ?? '',
  'data-locale': image.locale ?? '',
  'data-status': image.status.name,
};

Component _t(String value) => Component.text(value);

Component _e(
  String tag,
  List<Component> children, {
  String? id,
  String? classes,
  Map<String, String>? attributes,
}) => Component.element(
  tag: tag,
  id: id,
  classes: classes,
  attributes: attributes,
  children: children,
);

List<T> _firstSeen<T>(Iterable<T> values) {
  final seen = <T>{};
  return [
    for (final value in values)
      if (seen.add(value)) value,
  ];
}

List<T> _orderOf<T>(List<T>? declared, Iterable<T> values) =>
    declared != null && declared.isNotEmpty ? declared : _firstSeen(values);

int Function(Object value) _rank<T>(List<T> order) => (value) {
  final index = order.indexOf(value as T);
  return index < 0 ? order.length : index;
};

List<T> _sorted<T, K extends Object>(
  List<T> items,
  List<int Function(K value)> ranks,
  List<K> Function(T item) keys,
) {
  final position = {for (var i = 0; i < items.length; i++) items[i]: i};
  return [...items]..sort((leftItem, rightItem) {
    final left = keys(leftItem);
    final right = keys(rightItem);
    for (var i = 0; i < ranks.length; i++) {
      final order = ranks[i](left[i]).compareTo(ranks[i](right[i]));
      if (order != 0) return order;
    }
    return position[leftItem]!.compareTo(position[rightItem]!);
  });
}
