import '../../../l10n/app_localizations.dart';

/// User-facing names for TrueNAS job methods.
///
/// `core.get_jobs` returns RPC identifiers rather than the translated action
/// labels used by the TrueNAS web UI. Keep those labels in TrueDock's ARB
/// files, while preserving the raw identifier in job details for diagnostics.
extension JobMethodLocalizations on AppLocalizations {
  String jobMethodLabel(String method) => switch (method) {
    'pool.scrub.scrub' => jobsMethodPoolScrub,
    'pool.create' => jobsMethodPoolCreate,
    'pool.export' => jobsMethodPoolExport,
    'pool.dataset.create' => jobsMethodDatasetCreate,
    'pool.dataset.update' => jobsMethodDatasetUpdate,
    'pool.dataset.delete' => jobsMethodDatasetDelete,
    'pool.snapshot.create' => jobsMethodSnapshotCreate,
    'pool.snapshot.delete' => jobsMethodSnapshotDelete,
    'pool.snapshot.rollback' => jobsMethodSnapshotRollback,
    'pool.snapshot.clone' => jobsMethodSnapshotClone,
    'filesystem.setacl' => jobsMethodSetAcl,
    'app.install' => jobsMethodAppInstall,
    'app.upgrade' => jobsMethodAppUpgrade,
    'app.rollback' => jobsMethodAppRollback,
    'app.delete' => jobsMethodAppDelete,
    'replication.run' => jobsMethodReplicationRun,
    'cloudsync.sync' => jobsMethodCloudSyncRun,
    'rsynctask.run' => jobsMethodRsyncRun,
    'update.run' => jobsMethodSystemUpdate,
    'system.reboot' => jobsMethodSystemReboot,
    'system.shutdown' => jobsMethodSystemShutdown,
    _ => jobsMethodUnknown,
  };
}
