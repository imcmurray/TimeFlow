export 'image_share_stub.dart'
    if (dart.library.io) 'image_share_native.dart'
    if (dart.library.html) 'image_share_web.dart';
