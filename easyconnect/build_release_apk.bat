@echo off
echo Construction de l'APK de production pour EasyConnect...
echo.

echo Nettoyage du build precedent...
flutter clean

echo.
echo Installation des dependances...
flutter pub get

echo.
echo Construction de l'APK release...
flutter build apk --release

echo.
echo APK genere avec succes !
echo Fichier: build\app\outputs\flutter-apk\app-release.apk
echo.
pause

