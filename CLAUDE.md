# unipal-apps

UniPal's internal Flutter app for employees. It is one codebase for Android, iOS, Windows and macOS,
and it is distributed from the hub's "apps" page, not from public stores. All data comes from
`unipal-api` (`/v1`).

## Layout

This is a Dart pub workspace: run `flutter pub get` once at the root.

- `apps/unipal` - the app.
  - `lib/src/session.dart` holds the token (kept in the platform keychain through flutter_secure_storage), the user, their companies, and the selected company.
  - `lib/src/app.dart` sets up the router (go_router) and the theme.
  - Screens live in `lib/src/screens`.
- `packages/unipal_api` - pure Dart API client and models. They mirror the API Resources in unipal-api and the TypeScript types in `unipal-web/packages/api-client`. Keep all three in step.

## Rules

- **Theme.** It comes only from `unipal_brand`, a git dependency pinned to a commit of unipal-brand.
  - Never write a color or font name here.
  - The selected company's slug picks the `UnipalBrand`, the same way `data-brand` does on the web.
  - The accent is `colorScheme.secondary`.
- **Language.** The UI is Arabic and RTL (locale `ar`). Use `EdgeInsetsDirectional` and `AlignmentDirectional`, never left/right.
- **Permissions.** Gate actions on `company.can('crm.manage')` and similar ability checks, never on roles. The API enforces the same rules.
- **API calls.**
  - Make every call through `session.guard(...)`, so a revoked token signs the user out.
  - Every call is scoped to `session.company!.slug`.
- **Base URL.** It is a build-time define: `--dart-define=UNIPAL_API_URL=...`. The default is production.
- **Fonts.** Readex Pro is bundled (`assets/fonts`, OFL). Widget tests show text as boxes unless they load the font.

## Commands

- `flutter pub get` (root)
- `flutter analyze` (root)
- `dart format --line-length 120 packages apps/unipal/lib apps/unipal/test`
- `cd packages/unipal_api && dart test`
- `cd apps/unipal && flutter test`
- Run against a local API: `cd apps/unipal && flutter run -d macos --dart-define=UNIPAL_API_URL=http://localhost:8000`

## Branches and releases

- `main` = released and `develop` = integration. Work on a feature branch and open a PR into `develop`.
- Desktop installers come from `.github/workflows/desktop.yml` (Actions > "Desktop installers" > Run workflow, with the API URL, or push a tag `desktop-vX.Y.Z`). It builds a per-user Windows installer with Inno Setup (`apps/unipal/windows/installer/unipal.iss`, keep its AppId) and a macOS `.dmg`, and attaches both to a GitHub pre-release. The version comes from `apps/unipal/pubspec.yaml`.
- Neither installer is code-signed yet: Windows shows SmartScreen ("More info > Run anyway") and macOS needs right-click > Open the first time. Signing (Windows certificate, Apple Developer ID + notarization) is a later step.
- Until macOS builds are signed with a team, `session.dart` keeps the token in the login keychain (`usesDataProtectionKeychain: false`). Switch it back once the Keychain Sharing capability is set up.
- Mobile release builds (APK, TestFlight) are still to come.
