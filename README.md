# Icebang — proyecto listo para generar APK

Este proyecto está preparado para compilarse automáticamente con GitHub Actions.

## Generar el APK desde el celular

1. Crea o inicia sesión en una cuenta de GitHub.
2. Crea un repositorio nuevo, por ejemplo `icebang`.
3. Sube **el contenido de esta carpeta** al repositorio.
   - Deben quedar en la raíz: `pubspec.yaml`, `lib/`, `assets/` y `.github/`.
4. En GitHub entra a **Actions**.
5. Selecciona **Construir APK Icebang**.
6. Pulsa **Run workflow**.
7. Espera a que termine el proceso.
8. En la ejecución terminada, baja el artefacto **icebang-apk**.
9. Dentro del ZIP estará `app-release.apk`, listo para instalar en Android.

El workflow genera automáticamente la carpeta Android, instala las dependencias y compila el APK en modo release.

## APK generado localmente

Si en el futuro usas un computador con Flutter:

```bash
flutter pub get
flutter create --platforms=android --org=com.icebang .
flutter build apk --release
```

El APK aparecerá en:

`build/app/outputs/flutter-apk/app-release.apk`
