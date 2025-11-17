#!/bin/bash

# Script de déploiement ObscuraSim
# Usage: ./deploy.sh [apk|bundle|both|install]

set -e

echo "🚀 ObscuraSim - Script de Déploiement"
echo "======================================"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Nettoyer le projet
clean_project() {
    print_info "Nettoyage du projet..."
    flutter clean
    print_success "Projet nettoyé"
}

# Installer les dépendances
install_dependencies() {
    print_info "Installation des dépendances..."
    flutter pub get
    print_success "Dépendances installées"
}

# Construire l'APK
build_apk() {
    print_info "Construction de l'APK Release..."
    flutter build apk --release
    print_success "APK créé : build/app/outputs/flutter-apk/app-release.apk"

    # Afficher la taille
    APK_SIZE=$(ls -lh build/app/outputs/flutter-apk/app-release.apk | awk '{print $5}')
    print_info "Taille de l'APK : $APK_SIZE"
}

# Construire l'App Bundle
build_bundle() {
    print_info "Construction de l'App Bundle..."
    flutter build appbundle --release
    print_success "App Bundle créé : build/app/outputs/bundle/release/app-release.aab"

    # Afficher la taille
    AAB_SIZE=$(ls -lh build/app/outputs/bundle/release/app-release.aab | awk '{print $5}')
    print_info "Taille de l'AAB : $AAB_SIZE"
}

# Installer sur l'appareil connecté
install_on_device() {
    print_info "Recherche d'appareils connectés..."

    if adb devices | grep -q "device$"; then
        print_info "Installation sur l'appareil..."
        flutter install --release
        print_success "Application installée avec succès !"
    else
        print_error "Aucun appareil Android connecté"
        echo "Assurez-vous que :"
        echo "  1. Le débogage USB est activé"
        echo "  2. L'appareil est connecté et autorisé"
        exit 1
    fi
}

# Menu principal
case "${1:-both}" in
    apk)
        clean_project
        install_dependencies
        build_apk
        ;;
    bundle)
        clean_project
        install_dependencies
        build_bundle
        ;;
    both)
        clean_project
        install_dependencies
        build_apk
        build_bundle
        ;;
    install)
        clean_project
        install_dependencies
        build_apk
        install_on_device
        ;;
    *)
        echo "Usage: $0 [apk|bundle|both|install]"
        echo "  apk     : Construit uniquement l'APK"
        echo "  bundle  : Construit uniquement l'App Bundle"
        echo "  both    : Construit APK et App Bundle (défaut)"
        echo "  install : Construit l'APK et l'installe sur l'appareil"
        exit 1
        ;;
esac

echo ""
echo "======================================"
print_success "Déploiement terminé avec succès !"

# Afficher les chemins des fichiers
echo ""
echo "📦 Fichiers générés :"
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo "  • APK : build/app/outputs/flutter-apk/app-release.apk"
fi
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    echo "  • AAB : build/app/outputs/bundle/release/app-release.aab"
fi

echo ""
echo "📱 Prochaines étapes :"
echo "  1. Tester l'application sur votre appareil"
echo "  2. Partager l'APK pour beta testing"
echo "  3. Publier sur Google Play Store avec l'AAB"