class AppUpdate {
  final String appVersionOld;
  final String appVersionNew;
  final String appUpdateUrl;

  const AppUpdate({
    required this.appVersionOld,
    required this.appVersionNew,
    required this.appUpdateUrl,
  });

  factory AppUpdate.fromJson(Map<String, dynamic> json) => AppUpdate(
        appVersionOld: json['app_version_old']?.toString() ?? '',
        appVersionNew: json['app_version_new']?.toString() ?? '',
        appUpdateUrl: json['app_update_url']?.toString() ?? '',
      );
}
