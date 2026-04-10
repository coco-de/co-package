import 'package:co_test_gen/src/driver/test_driver.dart';
import 'package:co_test_gen/src/key/common_keys.dart';
import 'package:flutter/widgets.dart';

/// Reusable search step functions.
///
/// ```dart
/// final search = SearchSteps(driver);
/// await search.tapSearchIcon();
/// await search.enterQuery('flutter');
/// await search.expectResultsVisible();
/// ```
class SearchSteps {
  /// Creates search steps with optional custom keys.
  const SearchSteps(
    this.driver, {
    this.searchIconKey = CommonKeys.searchIcon,
    this.searchFieldKey = CommonKeys.searchField,
    this.searchResultsKey = CommonKeys.searchResults,
  });

  /// The test driver.
  final TestDriver driver;

  /// Key for the search icon/button.
  final Key searchIconKey;

  /// Key for the search text field.
  final Key searchFieldKey;

  /// Key for the search results container.
  final Key searchResultsKey;

  /// Taps the search icon to open search.
  Future<void> tapSearchIcon() async {
    await driver.tap(searchIconKey);
    await driver.settle();
  }

  /// Enters [query] in the search field.
  Future<void> enterQuery(String query) =>
      driver.enterText(searchFieldKey, query);

  /// Verifies that search results are visible.
  Future<void> expectResultsVisible() =>
      driver.expectVisible(searchResultsKey);

  /// Full search flow: tap icon, enter query, wait for results.
  Future<void> searchFor(String query) async {
    await tapSearchIcon();
    await enterQuery(query);
    await driver.settle();
  }
}
