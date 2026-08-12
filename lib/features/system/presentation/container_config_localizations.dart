import '../../../l10n/app_localizations.dart';
import '../domain/container_configuration.dart';

/// Maps container configuration codes onto ARB-localized strings.
extension ContainerConfigLocalizations on AppLocalizations {
  String containerValidationMessage(ContainerValidationCode code) =>
      switch (code) {
        ContainerValidationCode.nameRequired =>
          sysContainerConfigValidationNameRequired,
        ContainerValidationCode.datasetRequired =>
          sysContainerConfigValidationDatasetRequired,
        ContainerValidationCode.vcpusMinimum =>
          sysContainerConfigValidationVcpusMinimum,
        ContainerValidationCode.memoryMinimum =>
          sysContainerConfigValidationMemoryMinimum,
      };
}
