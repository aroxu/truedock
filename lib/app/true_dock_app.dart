import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_router.dart';
import '../core/widgets/connection_lost_banner.dart';
import '../core/security/credential_vault.dart';
import '../core/security/security_providers.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../l10n/app_localizations.dart';

class TrueDockApp extends ConsumerWidget {
  const TrueDockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeControllerProvider);
    final router = ref.watch(appRouterProvider);

    return DynamicColorBuilder(
      builder: (dynamicLight, dynamicDark) {
        final schemes = AppTheme.resolveSchemes(
          settings: settings,
          dynamicLight: dynamicLight,
          dynamicDark: dynamicDark,
        );

        return MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(schemes.light),
          darkTheme: AppTheme.build(schemes.dark),
          themeMode: settings.mode,
          // English only today, but the delegates are wired so a new ARB file
          // is the whole cost of adding a locale, and so Material/Cupertino
          // widgets already resolve their own strings and text direction.
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          // Android draws its biometric prompt itself and wants the strings
          // when the vault is built, not when the prompt appears. Resolve them
          // below the localization delegates and publish them upward.
          // The banner wraps every route from here rather than living in the
          // shell. A dropped socket is not a property of one screen, and the
          // `/system/*` routes are pushed outside the shell, so a shell-local
          // banner left those screens with no notice and no way to retry.
          builder: (context, child) {
            final platformMedia = MediaQuery.of(context);
            final reduceAnimations =
                platformMedia.disableAnimations || settings.reduceAnimations;
            return MediaQuery(
              data: platformMedia.copyWith(disableAnimations: reduceAnimations),
              child: _BiometricPromptStringsBridge(
                child: ConnectionLostHost(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Publishes localized Android biometric prompt strings to the credential
/// vault.
///
/// The vault is constructed before any widget can resolve localizations, so
/// the strings have to be pushed to it rather than read at prompt time.
///
/// A nested [ProviderScope] override would not work here: overrides only reach
/// providers that declare `dependencies`, and [credentialVaultProvider] does
/// not, so it would keep resolving from the root container. Writing into the
/// root [StateController] instead makes the value visible to the existing
/// vault provider.
class _BiometricPromptStringsBridge extends ConsumerStatefulWidget {
  const _BiometricPromptStringsBridge({required this.child});

  final Widget child;

  @override
  ConsumerState<_BiometricPromptStringsBridge> createState() =>
      _BiometricPromptStringsBridgeState();
}

class _BiometricPromptStringsBridgeState
    extends ConsumerState<_BiometricPromptStringsBridge>
    with WidgetsBindingObserver {
  Locale? _published;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Enrollment and device-security settings can change while TrueDock is
      // inactive (including through Simulator > Features > Face ID). Never
      // retain the pre-enrollment result after the app returns.
      ref.invalidate(biometricVaultAvailabilityProvider);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_published == locale) return;
    _published = locale;
    final l10n = AppLocalizations.of(context);
    final strings = BiometricPromptStrings(
      title: l10n.securityBiometricPromptTitle,
      subtitle: l10n.securityBiometricPromptSubtitle,
      negativeButton: l10n.securityBiometricPromptCancel,
    );
    // Deferred: the vault provider rebuilds on this write, and Riverpod
    // forbids mutating provider state during a build or dependency change.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(biometricPromptStringsProvider.notifier).state = strings;
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
