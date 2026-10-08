#!/usr/bin/env bash
# Prepara la carpeta android/ para compilar con Flutter 3.41.9: usa los archivos
# de Gradle de su plantilla (AGP 8.11, Gradle 8.14, Kotlin 2.2) en lugar de los
# de Flutter 3.47 (AGP 9.1, Gradle 9.3), y vuelve a aplicar los ajustes de la app.
set -euo pipefail
GEN=$(mktemp -d)/gen
flutter create --org com.aprendejugando --project-name aprende_jugando --platforms android "$GEN" >/dev/null
cp "$GEN/android/settings.gradle.kts" android/
cp "$GEN/android/gradle.properties" android/
cp "$GEN/android/gradle/wrapper/gradle-wrapper.properties" android/gradle/wrapper/
cp "$GEN/android/app/build.gradle.kts" android/app/
sed -i 's/applicationId = "com.aprendejugando.aprende_jugando"/applicationId = "com.owlitokids.aprendejugando"/' android/app/build.gradle.kts
sed -i 's/minSdk = flutter.minSdkVersion/minSdk = 24/' android/app/build.gradle.kts
sed -i 's#signingConfig = signingConfigs.getByName("debug")#signingConfig = signingConfigs.getByName("debug")\n            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")#' android/app/build.gradle.kts
grep -q 'proguard-rules.pro' android/app/build.gradle.kts
grep -q 'applicationId = "com.owlitokids.aprendejugando"' android/app/build.gradle.kts
grep -q 'minSdk = 24' android/app/build.gradle.kts
sed -i 's/  sdk: \^3.13.5/  sdk: ^3.11.0/' pubspec.yaml
