# Guide de Déploiement ObscuraSim

## 🎉 Déploiement Réussi !

L'application ObscuraSim a été compilée avec succès et est prête pour la distribution.

## 📦 Fichiers Générés

### 1. APK Release
- **Fichier** : `build/app/outputs/flutter-apk/app-release.apk`
- **Taille** : 48 MB
- **Usage** : Installation directe sur appareils Android

### 2. App Bundle (AAB)
- **Fichier** : `build/app/outputs/bundle/release/app-release.aab`
- **Taille** : 41 MB
- **Usage** : Publication sur Google Play Store

## 🚀 Installation Immédiate

### Sur l'appareil connecté (Pixel 7a)
✅ **L'application a été installée avec succès sur votre Pixel 7a !**

Pour lancer l'application :
1. Ouvrez le tiroir d'applications sur votre téléphone
2. Cherchez "ObscuraSim"
3. Tapez sur l'icône pour lancer

### Sur d'autres appareils Android

#### Option 1 : Via ADB
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

#### Option 2 : Transfert Manuel
1. Copiez le fichier APK sur l'appareil
2. Activez "Sources inconnues" dans les paramètres
3. Ouvrez le fichier APK pour installer

## 📱 Distribution

### 1. Partage Direct (APK)
Partagez le fichier APK via :
- Email
- Google Drive
- Dropbox
- WeTransfer
- QR Code avec lien de téléchargement

### 2. Google Play Store
Pour publier sur le Play Store :

1. **Créer un compte développeur Google Play**
   - Coût unique : 25$
   - https://play.google.com/console

2. **Préparer les éléments**
   - Icône de l'app (512x512 px)
   - Screenshots (minimum 2)
   - Description courte (80 caractères)
   - Description longue (4000 caractères)
   - Catégorie : Photographie

3. **Uploader l'App Bundle**
   ```
   Fichier : build/app/outputs/bundle/release/app-release.aab
   ```

### 3. Firebase App Distribution (Beta Testing)
```bash
# Installer Firebase CLI
npm install -g firebase-tools

# Se connecter
firebase login

# Distribuer
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_APP_ID \
  --groups testers
```

## 🔧 Commandes Utiles

### Reconstruire l'APK
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Créer un APK plus léger (par architecture)
```bash
flutter build apk --split-per-abi
```
Génère 3 APK :
- `app-armeabi-v7a-release.apk` (~16 MB)
- `app-arm64-v8a-release.apk` (~17 MB)
- `app-x86_64-release.apk` (~18 MB)

### Tester en mode release
```bash
flutter run --release
```

## 📊 Informations Techniques

- **Version** : 1.0.0+1
- **Min SDK** : Android 7.0 (API 24)
- **Target SDK** : Latest
- **Package ID** : com.obscurasim.app
- **Architecture** : Universal (tous les processeurs)

## 🔐 Signature

L'APK actuel utilise la signature de débogage. Pour la production :

1. Générer un keystore :
```bash
keytool -genkey -v -keystore ~/obscura-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias obscura
```

2. Configurer dans `android/app/build.gradle.kts`

3. Ajouter `key.properties` dans `android/`

## 📝 Prochaines Étapes

1. **Tester** l'application sur votre Pixel 7a
2. **Collecter** les retours utilisateurs
3. **Préparer** les assets marketing si publication
4. **Signer** l'APK pour la production
5. **Publier** sur le store de votre choix

## 🎯 Checklist de Lancement

- [x] Build APK créé
- [x] Build AAB créé
- [x] Installation testée sur appareil
- [ ] Tests utilisateurs
- [ ] Screenshots pour le store
- [ ] Description marketing
- [ ] Icône haute résolution
- [ ] Politique de confidentialité
- [ ] Compte développeur Play Store
- [ ] Signature de production

---

**L'application est maintenant prête et installée sur votre appareil !** 🎉