class WhatsappAdmin {
  static const String developer = '628976385872';

  static const Map<String, String> csPerIsp = {
    'simtek': '6282123376300',
    'pastelindo': '6281111166200',
    'wimanet': '6281122839191',
  };

  static String csForIsp(String? ispId) {
    return csPerIsp[ispId] ?? '6282123376300';
  }
}
