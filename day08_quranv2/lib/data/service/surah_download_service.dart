import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

/// Service spécialisé pour le téléchargement des sourates audio
/// Utilise GitHub comme source principale avec fallback et gestion d'erreurs
class SurahDownloadService {
  static final SurahDownloadService _instance =
      SurahDownloadService._internal();
  factory SurahDownloadService() => _instance;
  SurahDownloadService._internal() {
    // Configuration de Dio pour les téléchargements
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(minutes: 5);
    _dio.options.sendTimeout = const Duration(minutes: 5);

    // Headers pour GitHub
    _dio.options.headers = {
      'Accept': 'audio/mpeg,application/octet-stream,*/*',
      'User-Agent': 'Quran-App/1.0',
    };

    _initializeDirectory();
  }

  final Dio _dio = Dio();
  Directory? _downloadsDir;

  /// Initialise le répertoire de téléchargement persistant
  Future<void> _initializeDirectory() async {
    try {
      // Obtenir le répertoire documents de l'application (persistant)
      final directory = await getApplicationDocumentsDirectory();
      _downloadsDir = Directory('${directory.path}/quran_audio');

      // Créer le répertoire s'il n'existe pas
      if (!await _downloadsDir!.exists()) {
        await _downloadsDir!.create(recursive: true);
      }

      print('Répertoire de téléchargement initialisé: ${_downloadsDir!.path}');
    } catch (e) {
      print('Erreur d\'initialisation du répertoire: $e');
      // Fallback vers le répertoire temporaire
      final tempDir = await getTemporaryDirectory();
      _downloadsDir = Directory('${tempDir.path}/quran_audio');
      await _downloadsDir!.create(recursive: true);
    }
  }

  /// Demande les permissions nécessaires pour Android
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ nécessite des permissions granulaires
      final storagePermission = await Permission.storage.request();
      final mediaPermission = await Permission.photos.request();

      return storagePermission.isGranted || mediaPermission.isGranted;
    }
    // iOS n'a pas besoin de permission pour le répertoire documents
    return true;
  }

  /// Construit l'URL GitHub pour une sourate spécifique
  String _buildGitHubUrl(int surahNumber) {
    return 'https://github.com/The-Quran-Project/Quran-Audio-Chapters/raw/refs/heads/main/Data/$surahNumber/$surahNumber.mp3';
  }

  /// Construit l'URL de fallback (alternative)
  String _buildFallbackUrl(int surahNumber) {
    return 'https://everyayah.com/data/abdul_basit_abdus_samad_64kbps/${surahNumber.toString().padLeft(3, '0')}.mp3';
  }

  /// Vérifie si une URL est accessible avant de tenter le téléchargement
  Future<bool> _validateUrl(String url) async {
    try {
      final response = await _dio.head(
        url,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('URL validation failed for $url: $e');
      return false;
    }
  }

  /// 🔥 **FONCTION PRINCIPALE** - Télécharge une sourate complète
  ///
  /// [surahNumber] : Numéro de la sourate (1-114)
  /// [surahName] : Nom de la sourate (optionnel, pour le logging)
  /// [onProgress] : Callback pour la progression (0.0 à 1.0)
  ///
  /// **Retourne** : Future<File?> - Le fichier local téléchargé ou null en cas d'erreur
  Future<File?> downloadSurah({
    required int surahNumber,
    String? surahName,
    Function(double progress)? onProgress,
  }) async {
    try {
      // 1. Vérifier les permissions
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        throw Exception('Permission de stockage refusée');
      }

      // 2. S'assurer que le répertoire est prêt
      if (_downloadsDir == null) {
        await _initializeDirectory();
      }

      // 3. Construire le chemin du fichier local
      final fileName = 'surah_$surahNumber.mp3';
      final filePath = '${_downloadsDir!.path}/$fileName';
      final localFile = File(filePath);

      // 4. Vérifier si le fichier existe déjà
      if (await localFile.exists()) {
        print('Sourate $surahNumber déjà présente localement');
        if (onProgress != null) onProgress(1.0);
        return localFile;
      }

      // 5. Tenter le téléchargement depuis GitHub (source principale)
      print('Téléchargement de la sourate $surahNumber depuis GitHub...');
      final githubUrl = _buildGitHubUrl(surahNumber);

      try {
        // Valider l'URL avant de télécharger
        if (await _validateUrl(githubUrl)) {
          await _downloadWithRetry(
            url: githubUrl,
            savePath: filePath,
            onProgress: onProgress,
            retryCount: 3,
          );

          print('Succès: Sourate $surahNumber téléchargée depuis GitHub');
          return localFile;
        } else {
          throw Exception('URL GitHub non valide: $githubUrl');
        }
      } catch (githubError) {
        print('Échec GitHub, tentative avec URL fallback: $githubError');

        // 6. Fallback vers URL alternative
        try {
          final fallbackUrl = _buildFallbackUrl(surahNumber);

          // Valider l'URL fallback avant de télécharger
          if (await _validateUrl(fallbackUrl)) {
            await _downloadWithRetry(
              url: fallbackUrl,
              savePath: filePath,
              onProgress: onProgress,
              retryCount: 2,
            );

            print('Succès: Sourate $surahNumber téléchargée depuis fallback');
            return localFile;
          } else {
            throw Exception('URL fallback non valide: $fallbackUrl');
          }
        } catch (fallbackError) {
          print('Échec complet du téléchargement: $fallbackError');
          throw Exception(
              'Impossible de télécharger la sourate $surahNumber: $fallbackError');
        }
      }
    } catch (e) {
      print('Erreur générale de téléchargement: $e');
      return null;
    }
  }

  /// Télécharge avec système de retry automatique
  Future<void> _downloadWithRetry({
    required String url,
    required String savePath,
    Function(double progress)? onProgress,
    required int retryCount,
  }) async {
    int attempts = 0;

    while (attempts < retryCount) {
      try {
        final response = await _dio.download(
          url,
          savePath,
          onReceiveProgress: (received, total) {
            if (total != null && onProgress != null) {
              final progress = received / total;
              onProgress(progress);
            }
          },
          options: Options(
            receiveTimeout: const Duration(minutes: 3),
            sendTimeout: const Duration(minutes: 1),
            headers: {
              'Cache-Control': 'no-cache',
              'User-Agent': 'Quran-App/1.0',
            },
          ),
        );

        // Vérifier le statut de la réponse
        if (response.statusCode == 200) {
          print('Téléchargement réussi: $url');
          return; // Succès
        } else {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: 'HTTP ${response.statusCode}: ${response.statusMessage}',
          );
        }
      } on DioException catch (e) {
        attempts++;
        print('Tentative $attempts/$retryCount échouée: ${e.message}');

        // Loguer les détails de l'erreur pour debugging
        if (e.response != null) {
          print('Status Code: ${e.response?.statusCode}');
          print('Status Message: ${e.response?.statusMessage}');
          print('Request URL: ${e.requestOptions.uri}');

          // Informations supplémentaires pour certains codes d'erreur
          switch (e.response?.statusCode) {
            case 404:
              print(
                  'Erreur 404: Ressource non trouvée - vérifiez que le fichier existe sur le serveur');
              break;
            case 403:
              print(
                  'Erreur 403: Accès interdit - vérifiez les permissions ou les headers');
              break;
            case 429:
              print(
                  'Erreur 429: Trop de requêtes - attendez avant de réessayer');
              break;
            case 500:
              print('Erreur 500: Erreur serveur interne - réessayez plus tard');
              break;
            case 502:
            case 503:
            case 504:
              print(
                  'Erreur ${e.response?.statusCode}: Erreur serveur - service temporairement indisponible');
              break;
          }
        }

        if (attempts >= retryCount) {
          // Relancer avec plus de contexte pour le debugging
          throw Exception(
              'Échec du téléchargement après $retryCount tentatives: ${e.message}');
        }

        // Attendre avant de réessayer (exponentiel backoff)
        final waitTime = attempts * 2;
        print('Attente de $waitTime secondes avant la prochaine tentative...');
        await Future.delayed(Duration(seconds: waitTime));
      } catch (e) {
        attempts++;
        print('Tentative $attempts/$retryCount échouée (erreur générale): $e');

        if (attempts >= retryCount) {
          throw Exception(
              'Échec du téléchargement après $retryCount tentatives: $e');
        }

        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
  }

  /// Vérifie si une sourate est déjà téléchargée
  Future<bool> isSurahDownloaded(int surahNumber) async {
    try {
      if (_downloadsDir == null) {
        await _initializeDirectory();
      }

      final fileName = 'surah_$surahNumber.mp3';
      final filePath = '${_downloadsDir!.path}/$fileName';
      final file = File(filePath);

      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Obtient le chemin local d'une sourate téléchargée
  Future<String?> getSurahLocalPath(int surahNumber) async {
    try {
      if (_downloadsDir == null) {
        await _initializeDirectory();
      }

      final fileName = 'surah_$surahNumber.mp3';
      final filePath = '${_downloadsDir!.path}/$fileName';
      final file = File(filePath);

      return await file.exists() ? filePath : null;
    } catch (e) {
      return null;
    }
  }

  /// Supprime une sourate téléchargée
  Future<bool> deleteSurah(int surahNumber) async {
    try {
      final localPath = await getSurahLocalPath(surahNumber);
      if (localPath != null) {
        final file = File(localPath);
        await file.delete();
        print('Sourate $surahNumber supprimée');
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur de suppression: $e');
      return false;
    }
  }

  /// Obtient la taille d'une sourate téléchargée
  Future<int?> getSurahSize(int surahNumber) async {
    try {
      final localPath = await getSurahLocalPath(surahNumber);
      if (localPath != null) {
        final file = File(localPath);
        final stat = await file.stat();
        return stat.size;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Liste toutes les sourates téléchargées
  Future<List<Map<String, dynamic>>> getDownloadedSurahs() async {
    try {
      if (_downloadsDir == null) {
        await _initializeDirectory();
      }

      final List<Map<String, dynamic>> surahs = [];

      if (!await _downloadsDir!.exists()) {
        return surahs;
      }

      await for (final entity in _downloadsDir!.list()) {
        if (entity is File && entity.path.endsWith('.mp3')) {
          final file = entity;
          final stat = await file.stat();
          final fileName = file.path.split('/').last;

          // Extraire le numéro de la sourate du nom du fichier
          final match = RegExp(r'surah_(\d+)\.mp3').firstMatch(fileName);
          if (match != null) {
            final surahNumber = int.parse(match.group(1)!);

            surahs.add({
              'surahNumber': surahNumber,
              'fileName': fileName,
              'filePath': file.path,
              'size': stat.size,
              'date': stat.modified,
            });
          }
        }
      }

      // Trier par numéro de sourate
      surahs.sort((a, b) => a['surahNumber'].compareTo(b['surahNumber']));

      return surahs;
    } catch (e) {
      print('Erreur de liste des téléchargements: $e');
      return [];
    }
  }

  /// Calcule l'espace total utilisé
  Future<int> getTotalStorageUsed() async {
    try {
      final surahs = await getDownloadedSurahs();
      int totalSize = 0;

      for (final surah in surahs) {
        totalSize += surah['size'] as int;
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Formate la taille en unités lisibles
  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Nettoie les anciens fichiers (optionnel)
  Future<void> cleanupOldFiles(
      {Duration olderThan = const Duration(days: 30)}) async {
    try {
      final surahs = await getDownloadedSurahs();
      final cutoffDate = DateTime.now().subtract(olderThan);

      for (final surah in surahs) {
        final fileDate = surah['date'] as DateTime;
        if (fileDate.isBefore(cutoffDate)) {
          final filePath = surah['filePath'] as String;
          final file = File(filePath);
          await file.delete();
          print('Ancien fichier supprimé: $filePath');
        }
      }
    } catch (e) {
      print('Erreur de nettoyage: $e');
    }
  }
}
