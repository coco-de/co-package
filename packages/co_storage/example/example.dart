import 'package:co_storage/co_storage.dart';

Future<void> main() async {
  Disk disk = Disk(MemoryDriver());
  const String key = 'notes/welcome.txt';

  await disk.put(key, 'Hello from co_storage');
  print(await disk.getString(key));

  await disk.delete(key);
  print('File exists: ${await disk.exists(key)}');
}
