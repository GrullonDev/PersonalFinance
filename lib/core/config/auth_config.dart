class AuthConfig {
  // CONFIGURACIÓN DE GOOGLE
  // ---------------------------------------------------------------------------
  // Requerido para Android.
  // Se encuentra en Google Cloud Console > APIs & Services > Credentials
  // Busque el "Web Client ID" (Tipo: Web application).
  // NO use el ID de Android, debe ser el de la Web.
  // También puede buscarlo en google-services.json si tiene "client_type": 3.
  static const String googleWebClientId =
      '116411792004-o75ph5p5c103qtaa4nhvt3e1su84ghho.apps.googleusercontent.com';

  // CONFIGURACIÓN DE APPLE (PARA ANDROID)
  // ---------------------------------------------------------------------------
  // Apple Sign In no es nativo en Android, requiere flujo web.

  // Service ID creado en Apple Developer Portal (Identifiers > Service IDs)
  static const String appleServiceId = 'com.grullondev.personal_finance';

  // Redirect URI configurado en Apple Developer Portal y Firebase Console
  // Formato usual: https://<project-id>.firebaseapp.com/__/auth/handler
  static const String appleRedirectUri =
      'https://personalfinancedev-e972f.firebaseapp.com/__/auth/handler';
}
