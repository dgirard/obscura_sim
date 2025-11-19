# ObscuraSim 📸

![Flutter Version](https://img.shields.io/badge/flutter-3.9.2-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

**ObscuraSim** est une application mobile expérimentale développée avec Flutter qui transforme votre smartphone en une véritable *camera obscura* numérique.

L'application ne se contente pas d'appliquer des filtres ; elle simule l'expérience physique et optique des premiers appareils photographiques, invitant l'utilisateur à ralentir et à composer ses images avec soin.

---

## ✨ Fonctionnalités Clés

### 🔄 Le Viseur Inversé
Fidèle à l'optique d'une chambre noire, l'image dans le viseur est **inversée à 180 degrés** (haut/bas et gauche/droite). Cette contrainte créative force l'œil à se concentrer sur la composition, les lignes et la lumière plutôt que sur le sujet lui-même.

### 🧪 Laboratoire de Développement
Les photos ne sont pas instantanément disponibles.
1.  **Capture** : Prenez une photo (mode instantané ou pose longue de 3s).
2.  **Négatif** : L'image est stockée sous forme de "négatif" (inversé).
3.  **Développement** : Vous devez "développer" manuellement vos meilleures prises dans la chambre noire virtuelle pour obtenir l'image finale redressée.

### 🎞️ Procédés Historiques (Filtres)
L'application propose des traitements d'image avancés simulant des procédés chimiques réels :
*   **Monochrome** : Un noir et blanc granuleux classique.
*   **Sépia** : Le vieillissement chaleureux des tirages anciens.
*   **Plaque de Verre** : Contraste fort, vignettage et imperfections de surface (poussières, rayures).
*   **Cyanotype** : Le célèbre "Bleu de Prusse", monochrome bleu profond et cyan.
*   **Daguerréotype** : Rendu métallique, argenté et très détaillé avec un fort vignettage.

### 🌊 Gestion du Mouvement
*   **Pose Longue** : Maintenez le déclencheur pour une exposition de 3 secondes.
*   **Flou Cinétique** : L'accéléromètre du téléphone est utilisé pour détecter les micro-mouvements pendant la pose et appliquer un flou de bougé réaliste si vous n'êtes pas stable.

---

## 🛠️ Architecture Technique

Ce projet est conçu comme une démonstration de code propre et modulaire sous Flutter.

*   **Pattern BLoC** : Gestion d'état rigoureuse séparant la logique métier de l'interface (`CameraBloc`, `FilterBloc`, `GalleryBloc`).
*   **Isolates** : Tout le traitement d'image (application des filtres, rotations, encodage JPG) est déporté dans des threads séparés (Isolates) pour garantir une UI fluide à 60fps, même lors de calculs lourds.
*   **Repository Pattern** : Abstraction des dépendances externes (Caméra, Capteurs, Stockage) pour faciliter les tests.
*   **Tests Unitaires & Widget** : Couverture de test robuste (voir dossier `test/`).

### Dépendances Principales
*   `flutter_bloc`: Gestion d'état.
*   `camera`: Accès bas niveau au matériel photo.
*   `image`: Manipulation de pixels (pixel-perfect processing).
*   `sqflite`: Base de données locale pour les métadonnées de la galerie.
*   `sensors_plus`: Accès à l'accéléromètre.

---

## 🚀 Installation & Démarrage

1.  **Prérequis** : Flutter SDK installé et un appareil physique (recommandé pour la caméra) ou un émulateur.
2.  **Cloner le projet** :
    ```bash
    git clone https://github.com/votre-user/obscura_sim.git
    cd obscura_sim
    ```
3.  **Installer les paquets** :
    ```bash
    flutter pub get
    ```
4.  **Lancer l'application** :
    ```bash
    flutter run
    ```
5.  **Lancer les tests** :
    ```bash
    flutter test
    ```

---

## 🤝 Contribuer

Les contributions sont les bienvenues ! Si vous avez des idées de nouveaux procédés photographiques à simuler ou des améliorations d'interface :

1.  Forkez le projet.
2.  Créez votre branche (`git checkout -b feature/AmazingFeature`).
3.  Commitez vos changements (`git commit -m 'Add some AmazingFeature'`).
4.  Push vers la branche (`git push origin feature/AmazingFeature`).
5.  Ouvrez une Pull Request.

---

*Développé avec ❤️ et ☕ pour les amoureux de la photographie argentique.*
