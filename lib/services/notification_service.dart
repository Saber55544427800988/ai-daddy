// Notification service — conditionally exports real or stub implementation.
//
// On mobile (dart:io available): uses flutter_local_notifications.
// On web: all methods are safe no-ops, flutter_local_notifications is never loaded.
export 'notification_service_stub.dart'
    if (dart.library.io) 'notification_service_impl.dart';
