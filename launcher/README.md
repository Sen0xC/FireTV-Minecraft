# Accueil Voxel — gratuit et local

## Version 1.2 — Cissou's TV

Le titre à l'écran et le nom de l'application sont désormais **Cissou's TV**. Le package reste `fr.local.voxelhome` pour mettre à jour sans effacer les données.

La touche Maison et le démarrage sont confiés à [Home on Fire 1.5.2, dépôt officiel](https://github.com/toolicious/home-on-fire/releases/tag/v1.5.2), configuré avec la cible `fr.local.voxelhome`, redirection Maison et Launch on boot actifs. Le nouveau bouton **Maison / démarrage** ouvre ses réglages. Le receveur de démarrage intégré s'abstient lorsque cet outil est installé, pour éviter deux lancements concurrents.

Validation réelle sur ce Stick / Fire OS 7.7.1.7 : retour vers Cissou's TV après Maison et lancement automatique après un redémarrage complet confirmés le 30 octobre 2026. Le double appui espacé sur Maison a permis de retrouver Amazon. Le test d'appui long injecté n'a affiché que le panneau rapide : privilégier le double appui vérifié. La sortie de veille reste à confirmer.

L'outil utilise un service d'accessibilité et la permission WRITE_SECURE_SETTINGS pour activer cette redirection. Il ne désactive pas l'accueil Amazon. Sur Fire OS 7, son développeur documente un délai de changement d'application pouvant aller jusqu'à cinq secondes ; aucune arrivée instantanée n'est garantie. Un appui long sur Maison ou un double appui espacé d'environ une seconde permet, selon le firmware, de retrouver Amazon. Le bouton « Accueil Amazon » de Cissou's TV rappelle ce geste au lieu d'entrer dans une boucle de redirection. Maintenir Menu ouvre la configuration de Home on Fire.

Retour arrière : ouvrir Home on Fire et couper **Accessibility service**. Alternative depuis le PC : `./restore-home.ps1` pour simuler, puis `./restore-home.ps1 -Apply` et confirmer. Ce script préserve les autres services d'accessibilité et ne désinstalle rien. État avant activation consigné dans `reports/home-before.json`.

L'ancien paragraphe « Au démarrage » ci-dessous décrit le comportement autonome sans Home on Fire. Avec l'outil présent, ses propres réglages gèrent également la sortie de veille, dans les limites du firmware.

Application Kotlin native pour la TV détectée (Android 9, API 28). Paysage forestier original inclus, quatre applications, titre cubique et boutons de pierre, télécommande directionnelle/OK/Retour, paramètres Amazon. Seule permission : recevoir la fin du démarrage. Aucun accès réseau, publicité ajoutée ou service permanent. Ne modifie pas le bouton Accueil.

## Version 1.1 : forêt et feuilles

Le paysage `assets/voxel-forest.png` est une création originale générée pour ce projet, sans extraction de textures ou de capture du jeu. Les feuilles sont des particules dessinées séparément : 14 au maximum, cadence plafonnée à 20 images/s, arrêt dès la perte de focus ou la pause de l'activité. Le bouton **Feuilles : oui/non** permet de couper cet effet. Le fond reste fixe, sans vidéo ni moteur 3D. Le gain ou coût réel en mémoire/CPU reste à mesurer sur la TV.

## Au démarrage

Le bouton **Au démarrage : oui/non** active ou coupe une tentative de lancement après un **redémarrage complet du Stick**, via le broadcast Android documenté `BOOT_COMPLETED`, avec un délai unique de trois secondes. Actif par défaut conformément à la demande utilisateur. Ouvrir l'application au moins une fois après installation. Aucun service, réveil périodique, redirection HOME ou surveillance des autres applications. Le receveur n'est pas exporté aux applications tierces.

Cette méthode standard est tentée uniquement sous Android API 22–28 ; le firmware Amazon peut empêcher le lancement ou repasser au premier plan. **Le fonctionnement sur Fire OS 7.7.1.7 doit être validé par un vrai redémarrage.** Éteindre/rallumer le téléviseur laisse souvent le Stick alimenté et en veille : ce n'est pas un redémarrage. Le retour automatique à la sortie de veille n'est pas implémenté.

Après mise à jour et ouverture de l'app, vérifier « Au démarrage : oui », puis utiliser **Paramètres Amazon → Ma Fire TV → Redémarrer** une fois que toute lecture est arrêtée. Observer si Accueil Voxel apparaît et reste visible. Si Amazon le masque, ne pas répéter des commandes, désactiver les services Amazon ou activer une accessibilité au hasard ; rester en lancement manuel et réévaluer. Les [broadcasts de démarrage sont documentés par Android](https://developer.android.com/develop/background-work/background-tasks/broadcasts/broadcast-exceptions), mais cela ne garantit pas l'affichage au premier plan sur un firmware constructeur.

Restauration : mettre « Au démarrage : non » et « Feuilles : non ». L'accueil Amazon et Projectivy restent disponibles. Aucune désinstallation n'est nécessaire pour arrêter ces fonctions.

## Construire sur Windows

JDK 17 requis (présent sur le PC utilisé). Depuis la racine du projet :

```powershell
.\build-launcher.ps1
```

Le script télécharge des outils de compilation dans `tools/voxel-build` : Kotlin (Maven Central), Android AAPT2/R8 (Google Maven), framework Android de compilation (artefact Robolectric Android 9/API 28 depuis Maven Central). Ce framework sert uniquement à la compilation et n'est pas inclus dans l'APK ; le manifeste exige Android API 22 minimum, cible API 28. Aucun Android Studio, service de compilation payant, compte ou SDK complet requis.

Une clé locale de développement est créée dans `tools/voxel-build/local.keystore`. La conserver pour signer les mises à jour ; elle n'est pas publiée. L'APK local est signé en v1 pour Android 5.1–9, vérifié par jarsigner, sans prétention de signature de production ou de publication en boutique. Les versions des outils sont fixées dans le script. Les bibliothèques téléchargées conservent leurs licences ; aucun asset de jeu n'est utilisé.

## Installer et ouvrir

L'installation ajoute une application et n'en supprime aucune. Elle doit être effectuée volontairement depuis le terminal, une fois l'APK construit :

```powershell
.\tools\platform-tools\adb.exe -s 192.168.1.10:5555 install .\dist\AccueilVoxel.apk
.\tools\platform-tools\adb.exe -s 192.168.1.10:5555 shell am start -n fr.local.voxelhome/.MainActivity
```

Pour une mise à jour seulement, utiliser `install -r` avec la même clé de signature. En cas de conflit de signature, ne pas désinstaller aveuglément : vérifier la clé utilisée.

Ouvrir ensuite « Accueil Voxel » dans les applications Amazon. Retour et le bouton « Accueil Amazon » ouvrent l'accueil système ; le bouton physique Accueil reste géré par Amazon. Le bouton paramètres envoie l'intent Android officiel ; son résultat doit être vérifié sur le firmware réel. Si Amazon le refuse, accéder aux paramètres depuis l'accueil Amazon.

Les quatre packages sont explicitement définis dans `src/MainActivity.kt`, d'après l'inventaire de cet appareil. `apps.json` sert aux scripts d'optimisation et ne reconfigure pas dynamiquement cet APK. Pour une autre sélection, modifier la liste Kotlin et reconstruire. Les icônes sont lues depuis les applications installées, et non redistribuées dans l'APK.

## Vérification matérielle

Tester les quatre lancements, les directions/OK/Retour, la sélection visible, les paramètres, puis la lecture vidéo et audio dans les applications. La construction et la vérification de signature ne prouvent ni l'absence d'erreur d'exécution ni un gain de performance. Aucun lancement sur la TV n'est exécuté automatiquement par le script de construction.

Pour retirer cet accueil, utiliser Paramètres Amazon → Applications → Accueil Voxel → Désinstaller. Projectivy et l'accueil Amazon restent disponibles.
