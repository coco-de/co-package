// zlib for PDF streams where `dart:io` exists, none elsewhere (the writer then
// stores streams uncompressed, which is still a valid PDF).
export 'note_pdf_deflate_stub.dart'
    if (dart.library.io) 'note_pdf_deflate_io.dart';
