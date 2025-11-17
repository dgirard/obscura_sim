# ObscuraSim

Une application Flutter qui simule l'expérience photographique d'une camera obscura.

## Fonctionnalités

### 📸 Viseur Inversé
- Prévisualisation en temps réel avec double inversion (verticale et horizontale)
- Simule la vision sur plaque de verre dépoli d'une chambre photographique ancienne

### ⏳ Capture Lente
- Maintien du bouton pendant 3 secondes pour "exposer" la photo
- Détection de mouvement via l'accéléromètre
- Application automatique de flou de mouvement si l'appareil bouge

### 🎨 Filtres d'Époque
- **Monochrome** : Noir et blanc avec grain élevé
- **Sépia** : Teintes brunes chaudes vintage
- **Plaque de Verre** : Contraste élevé, vignettage et imperfections

### 🖼️ Galerie "La Chambre Noire"
- **Négatifs** : Photos capturées affichées inversées
- **Développement** : Processus de redressement et traitement
- **Photos Développées** : Prêtes à l'export et au partage

## Installation

### Prérequis
- Flutter 3.9.2 ou supérieur
- Android SDK 24+ (Android 7.0)
- Un appareil Android ou émulateur

### Étapes

1. Cloner le dépôt et naviguer dans le dossier
```bash
cd obscura_sim
```

2. Installer les dépendances
```bash
flutter pub get
```

3. Lancer l'application
```bash
flutter run
```

## Architecture

L'application utilise l'architecture **BLoC Pattern** avec :
- **CameraBloc** : Gestion du flux vidéo et des inversions
- **FilterBloc** : Sélection et application des filtres
- **GalleryBloc** : Stockage et développement des photos
- **Services** : Traitement d'image et base de données SQLite

## Permissions

L'application nécessite les permissions suivantes :
- **Caméra** : Pour la capture photo
- **Stockage** : Pour sauvegarder les photos
- **Capteurs** : Pour détecter le mouvement

## Structure du Projet

```
lib/
├── bloc/               # Business Logic Components
│   ├── camera/        # Gestion de la caméra
│   ├── filter/        # Gestion des filtres
│   └── gallery/       # Gestion de la galerie
├── models/            # Modèles de données
├── screens/           # Écrans de l'application
├── services/          # Services (DB, traitement d'image)
├── widgets/           # Widgets personnalisés
└── main.dart         # Point d'entrée

```

## Technologies Utilisées

- **Flutter & Dart**
- **BLoC Pattern** pour la gestion d'état
- **SQLite** pour le stockage local
- **camera** pour l'accès à la caméra
- **image** pour le traitement d'image
- **sensors_plus** pour l'accéléromètre

## Développement

Pour contribuer au projet :

1. Créer une branche feature
```bash
git checkout -b feature/ma-fonctionnalite
```

2. Commiter les changements
```bash
git commit -m "Ajout de ma fonctionnalité"
```

3. Pousser la branche
```bash
git push origin feature/ma-fonctionnalite
```

## Licence

Ce projet est développé à des fins éducatives et expérimentales.