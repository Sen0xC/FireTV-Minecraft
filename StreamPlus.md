# Stream+ sur Cissou's TV

Source : https://github.com/HugoALVES7/StreamPlus, commit `2cc701c` (téléchargé le 16 novembre 2026). Application Android `com.hugo.streamplus`, minimum API 26 ; la Fire TV utilisée exécute API 28. Le dépôt ne fournissait pas de release APK au moment de l'installation : compilation locale du code officiel, sans plugin ni modification du code StreamPlus.

Le script `build-streamplus.ps1` adapte la chaîne de compilation Java/AAPT2/D8 du `build.sh` officiel à Windows. Il attend le code sous `tools/streamplus/source/` et le framework Android API 34 sous `tools/voxel-build/android-api34.jar`. Les outils Java et Android viennent de la préparation du launcher. Le framework de compilation est l'artefact Maven Central `org.robolectric:android-all:14-robolectric-10818077` et n'est pas embarqué dans l'app. L'APK signé localement en v1 convient à l'appareil Android 9 utilisé ; ce n'est pas une distribution officielle du développeur. Garder `tools/voxel-build/streamplus-local.keystore` pour les futures mises à jour locales. En cas de conflit de signature avec un futur APK officiel, ne pas désinstaller sans accord : les données pourraient être perdues.

Le script normalise également les noms des fichiers ZIP en séparateurs `/`, indispensables à Android. L'AAPT2 autonome utilisé sous Windows produisait sinon des chemins d'assets avec des antislashs, causant un écran noir. Le code StreamPlus lui-même reste inchangé. Installation et affichage de l'écran d'accueil/configuration vérifiés sur la vraie Fire TV le 16 novembre 2026.

Le code tiers et sa licence MIT restent dans le dossier ignoré `tools/streamplus/source/`. APK produit : `dist/StreamPlus.apk`, également ignoré par Git.

L'accueil Cissou's TV 1.3 affiche désormais une cinquième carte **Stream+**. Elle ouvre explicitement `com.hugo.streamplus.MainActivity`, car l'application expose aussi une tuile PiP. Les bornes de navigation et la restauration de sélection s'adaptent au nombre d'applications. Le package est ajouté à la liste de conservation `apps.json`.

## Première utilisation

L'application nécessite votre propre **Client ID Twitch**. Suivre le README officiel : créer une application sur https://dev.twitch.tv/console/apps/create, type **Public**, catégorie **Application Integration**, redirection `http://localhost`, puis saisir le Client ID dans l'application et suivre le code de connexion Twitch. Aucun identifiant ou jeton n'est ajouté au dépôt.

Les permissions spéciales de superposition et le service d'accessibilité PiP ne sont pas activés par cette installation. Ils sont facultatifs pour la fenêtre flottante et ses raccourcis. La connexion Twitch et la lecture vidéo doivent être validées après la configuration personnelle.
