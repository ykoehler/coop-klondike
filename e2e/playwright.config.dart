import 'package:playwright/playwright.dart';

void main() {
  PlaywrightConfig(
    browser: BrowserType.chromium,
    headless: true,
    baseURL: 'http://localhost:8080',
    viewportSize: Size(width: 1280, height: 720),
  );
}