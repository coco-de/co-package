// MockPlatformInterfaceMixin 은 plugin_platform_interface 에서
// @visibleForTesting 이다. 이 페이크는 feature BDD hooks 가
// `installFakeWebViewPlatform()` 로 부르므로 lib/ 에 있어야 한다 —
// test/ 로 옮기면 소비 패키지가 설치 함수를 import 하지 못한다.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

/// 웹뷰를 품은 화면을 위젯 테스트에서 mount 할 수 있게 하는 플랫폼 페이크 (coco-de/unibook#9506).
///
/// ## 왜 필요한가
///
/// `WebViewController()` 는 내부적으로 `WebViewPlatform.instance` 를 요구한다
/// (`platform_webview_controller.dart:27` 의 `assert`). 위젯 테스트에는 네이티브
/// 플랫폼 등록이 없으므로, 웹뷰를 만드는 코드 경로가 **빌드 중 assertion 으로
/// 죽는다**.
///
/// 이게 조용한 함정인 이유는 화면이 웹뷰를 **직접 보여주지 않아도** 걸리기
/// 때문이다. 실측(`book_content_search`): 본문검색 화면은 본문내/네이버/구글
/// 3탭을 `IndexedStack` 으로 묶는데, `IndexedStack` 은 선택되지 않은 자식도
/// **전부 빌드한다**(`Visibility` 로 감쌀 뿐이다). 그래서 "본문 내 검색"
/// 시나리오만 검증하려 해도 웹뷰 탭 2개가 함께 빌드되어 터진다.
///
/// ## 무엇을 하지 않는가
///
/// 실제 페이지 로드·JS 실행·네비게이션을 흉내내지 **않는다**. 위젯 트리가
/// 조립되게만 하고, 웹뷰 자리에는 [FakeWebViewWidget.placeholderKey] 를 가진
/// 빈 위젯을 놓는다. 웹뷰 **내용**을 검증해야 하는 시나리오라면 이 페이크가
/// 아니라 Patrol E2E 가 맞는 도구다.
///
/// ## 사용
///
/// ```dart
/// void setUpBddTests() {
///   installFakeWebViewPlatform();
///   ...
/// }
/// ```
///
/// 멱등이므로 매 시나리오 호출해도 안전하다.
void installFakeWebViewPlatform() {
  if (WebViewPlatform.instance is FakeWebViewPlatform) return;
  WebViewPlatform.instance = FakeWebViewPlatform();
}

/// [installFakeWebViewPlatform] 이 설치하는 플랫폼 구현.
class FakeWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) => FakeWebViewController(params);

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) => FakeNavigationDelegate(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) => FakeWebViewWidget(params);

  @override
  PlatformWebViewCookieManager createPlatformCookieManager(
    PlatformWebViewCookieManagerCreationParams params,
  ) => FakeWebViewCookieManager(params);
}

/// 호출을 기록만 하는 컨트롤러.
///
/// [loadedRequests] 로 "무엇을 로드하려 했는가"를 단언할 수 있다 — 웹뷰 내용
/// 대신 **의도**를 검증하는 용도다.
class FakeWebViewController extends PlatformWebViewController
    with MockPlatformInterfaceMixin {
  FakeWebViewController(super.params) : super.implementation();

  /// 이 컨트롤러가 로드를 요청받은 URL 목록.
  final List<String> loadedRequests = [];

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    loadedRequests.add(params.uri.toString());
  }

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}

  @override
  Future<bool> canGoBack() async => false;

  @override
  Future<bool> canGoForward() async => false;

  @override
  Future<void> goBack() async {}

  @override
  Future<void> goForward() async {}

  @override
  Future<void> reload() async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<String?> currentUrl() async => loadedRequests.lastOrNull;
}

/// 콜백을 보관만 하는 네비게이션 델리게이트.
class FakeNavigationDelegate extends PlatformNavigationDelegate
    with MockPlatformInterfaceMixin {
  FakeNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {}

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {}

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {}
}

/// 웹뷰 자리에 놓이는 빈 위젯.
class FakeWebViewWidget extends PlatformWebViewWidget
    with MockPlatformInterfaceMixin {
  FakeWebViewWidget(super.params) : super.implementation();

  /// 웹뷰가 렌더될 자리를 가리키는 Key — "웹뷰 탭이 열렸다"를 단언할 때 쓴다.
  static const Key placeholderKey = Key('fake_web_view');

  @override
  Widget build(BuildContext context) =>
      const SizedBox.expand(key: placeholderKey);
}

/// 쿠키 조작을 무시하는 매니저.
class FakeWebViewCookieManager extends PlatformWebViewCookieManager
    with MockPlatformInterfaceMixin {
  FakeWebViewCookieManager(super.params) : super.implementation();

  @override
  Future<bool> clearCookies() async => false;

  @override
  Future<void> setCookie(WebViewCookie cookie) async {}
}
