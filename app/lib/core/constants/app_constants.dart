class AppConstants {
  /// Backend address injected per environment at build time
  /// (`--dart-define=API_URL=...`). Without the flag (local dev) the app hits
  /// a locally running FastAPI.
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Oficjalne USOS API (instalacja PW). Z wklejonego linku USOS wyciągamy
  /// `prz_kod` i odpytujemy `services/courses/course` - nie scrapujemy HTML.
  /// Konfigurowalne, bo różne uczelnie mają różne instalacje API.
  static const String usosApiBaseUrl = 'https://apps.usos.pw.edu.pl';

  /// USOSweb (strona dla ludzi) - tu odsyłamy po pełny opis/sylabus przedmiotu,
  /// zamiast kopiować chronioną treść do naszej aplikacji.
  static const String usosWebBaseUrl = 'https://usosweb.usos.pw.edu.pl';

  static const int searchDebounceMs = 350;
  static const String savedOpiniaIdsKey = 'saved_opinia_ids';
  static const double maxContentWidth = 880;
}
