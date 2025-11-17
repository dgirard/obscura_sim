#!/bin/bash

echo "🔧 Correction rapide de la caméra ObscuraSim"
echo "=========================================="

# Demander les permissions explicitement
adb shell pm grant com.obscurasim.app android.permission.CAMERA
adb shell pm grant com.obscurasim.app android.permission.WRITE_EXTERNAL_STORAGE
adb shell pm grant com.obscurasim.app android.permission.READ_EXTERNAL_STORAGE

echo "✅ Permissions accordées"
echo ""
echo "Redémarrez l'application sur votre téléphone"