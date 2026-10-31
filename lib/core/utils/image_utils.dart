import 'package:image_picker/image_picker.dart';

import '../constants/app_constants.dart';

/// Nom d'envoi d'une image choisie : le sélecteur Android peut fournir un
/// nom sans extension, que le serveur refuse (« Format non supporté »).
String nomImageEnvoi(XFile image) {
  final nom = image.name;
  if (RegExp(r'\.\w{3,4}$').hasMatch(nom)) return nom;
  return image.mimeType == 'image/png' ? '$nom.png' : '$nom.jpg';
}

class ImageUtils {
  /// Construit l'URL absolue d'une image servie par le backend.
  static String imageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return '';
    if (relativePath.startsWith('http')) return relativePath;
    return '${AppConstants.baseUrl}$relativePath';
  }

  /// Placeholder local selon le type de contenu
  static String placeholder(String type) {
    switch (type) {
      case 'produit':     return 'assets/images/placeholder_produit.png';
      case 'producteur':  return 'assets/images/placeholder_user.png';
      default:            return 'assets/images/placeholder.png';
    }
  }
}
