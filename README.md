# Fire TV — accueil voxel et optimisation prudente

## Installer l'accueil voxel gratuit

Projectivy réserve le fond personnel à Premium. Pour le besoin de ce projet, un accueil Kotlin gratuit est maintenant fourni avec le fond inclus et les quatre applications choisies. [Guide court de l'accueil Voxel](launcher/README.md).

Après construction, depuis le terminal à la racine du projet :

```powershell
.\tools\platform-tools\adb.exe -s 192.168.1.10:5555 install .\dist\AccueilVoxel.apk
.\tools\platform-tools\adb.exe -s 192.168.1.10:5555 shell am start -n fr.local.voxelhome/.MainActivity
```

Cela ajoute l'accueil gratuit sans retirer Projectivy ni modifier le bouton Accueil Amazon. Les tests télécommande, paramètres et lancement des quatre applications doivent être réalisés sur l'appareil.

Outils Windows PowerShell 5.1 / PowerShell 7. Aucune modification de la TV par défaut. Aucune connexion ou suppression automatique. Aucun root, modification de partition, blocage réseau, désactivation de service ou de mise à jour. Les rapports contiennent des identifiants privés : ne pas les publier sans les relire.

## 1. Identifier le système avant la connexion

Sur la TV, relever **Paramètres → Ma Fire TV → À propos** : modèle exact, version complète du logiciel et adresse IP dans Réseau. **Un nom “Fire TV Stick HD” ne prouve pas que l'appareil utilise Android.**

Amazon distingue notamment les modèles Fire OS et les modèles HD 2026 sous Vega. Comparer le modèle exact à la [table Amazon](https://developer.amazon.com/docs/fire-tv/fire-os-overview.html). La génération reste à confirmer avec cette table ; les scripts n'inventent pas une correspondance.

**Vega ou OS inconnu : arrêter ici.** Ces scripts et les APK Android ne conviennent pas. Le [guide officiel Vega](https://developer.amazon.com/apps-and-games/blogs/2026/07/guide-to-building-for-fire-tv-on-vega-os) indique un environnement de développement Mac/Linux, sans prise en charge Windows/WSL à la date de consultation du 30 octobre 2026. Il ne documente pas de remplacement de l'accueil grand public par ce projet. Ne pas essayer de contourner ces limites.

## 2. Outils et connexion autorisée

Ouvrir PowerShell dans ce dossier, sans droits administrateur. Si une politique Windows bloque les scripts, respecter la politique de votre poste ; ne pas la modifier globalement.

```powershell
.\setup.ps1
.\setup.ps1 -InstallTools
```

La seconde commande demande confirmation avant téléchargement dans `tools/`, depuis Google uniquement. Lire et accepter au préalable la [licence et les informations officielles Platform-Tools](https://developer.android.com/tools/releases/platform-tools). Le SHA256 affiché identifie le téléchargement ; il ne constitue pas une comparaison à une empreinte indépendante. Alternative : extraire manuellement le ZIP officiel dans `tools/`.

Sur **Fire OS confirmé**, activer Débogage ADB dans Options développeur. Si le menu est caché, sélectionner sept fois le nom de l'appareil dans À propos. PC et TV doivent être sur le même réseau local. [Instructions ADB Amazon](https://developer.amazon.com/docs/fire-tv/developer-tools.html).

```powershell
.\setup.ps1 -Connect -DeviceIP 192.168.1.50
```

Remplacer l'adresse par celle de votre TV. Confirmer Fire OS, puis la connexion à cette adresse. Accepter la clé RSA sur la TV. Le script vérifie ensuite fabricant et API Android. Il cible toujours explicitement cet appareil, même si plusieurs appareils sont connectés. Aucun balayage du réseau.

## 3. Inventaire et choix des applications

```powershell
.\diagnostic.ps1 -Label avant
```

Rapports horodatés JSON et CSV dans `reports/` : modèle matériel, firmware, Android/API, stockage, RAM totale/disponible, état mémoire, packages système/utilisateur/inconnus et état activé. Les noms et fonctions inconnus restent explicitement non résolus : aucun nom commercial ou rôle critique n'est deviné depuis un identifiant. Compléter `labels` après vérification sur la TV, par exemple `"identifiant.verifie": "Nom sur la TV"`.

**Choisir d'abord les applications à conserver**, puis remplir `keep` dans `apps.json` avec leurs identifiants exacts issus du rapport. `uninstall` est une sélection distincte, explicite, initialement vide. Une absence de la liste blanche ne déclenche jamais une suppression. Tout package système ou inconnu reste protégé ; ce projet ne propose aucune désactivation système faute de preuve de compatibilité et de dépendances.

```powershell
.\preview.ps1
.\optimize.ps1
.\optimize.ps1 -Apply
```

Les deux premières commandes simulent. La dernière présente le plan puis demande **pour chaque package** la phrase exacte de confirmation. Conséquence : l'application et ses données peuvent disparaître. Une réinstallation ne garantit pas le retour des données. Après chaque suppression, vérifier télécommande, Wi-Fi, paramètres et lecture avant de continuer. Certains services classés utilisateur restent volontairement protégés par leur espace de noms. Aucune suppression n'est recommandée tant que votre inventaire et votre choix ne sont pas examinés.

## 4. Accueil original : essayer Projectivy d'abord

[Projectivy, dépôt du développeur et téléchargements](https://github.com/spocky/miproja1) constitue la première piste sur Fire OS Android. Vérifier les prérequis de la version choisie avec votre API et firmware avant installation. Son installation n'est pas effectuée automatiquement. Télécharger uniquement depuis le développeur ou une boutique officielle, puis, après votre validation, suivre les [instructions d'installation APK Amazon](https://www.developer.amazon.com/docs/fire-tv/installing-and-running-your-app.html).

Le projet contient `assets/voxel-landscape.jpg` : paysage original statique 1920×1080, ciel bleu, collines cubiques, herbe, terre et pierre. Aucun asset Minecraft. Régénération locale facultative : `./create-wallpaper.ps1` (Windows, System.Drawing).

Dans Projectivy, si la version installée le permet : choisir le fond local, créer une catégorie avec les applications de `keep`, une seconde catégorie facultative, masquer les autres catégories et choisir des couleurs vert/marron. Les cadres pixelisés exacts dépendent des options disponibles. Importer le fond via le sélecteur de fichiers de l'appareil, après transfert local autorisé. Aucun transfert n'est réalisé par ce projet.

Tester les directions, OK, Retour, l'ouverture de chaque application et l'accès aux paramètres Amazon. **Privilégier le lancement manuel depuis les applications Amazon.** Ne pas activer de redirection Accueil, service d'accessibilité ou outil Launcher Manager sans étude du firmware. Un [signalement sur le dépôt Projectivy](https://github.com/spocky/miproja1/issues/338) décrit des lenteurs et problèmes d'accès aux paramètres sur un firmware précis ; ce n'est pas une preuve universelle de compatibilité. Le bouton Accueil doit continuer à ouvrir Amazon. Retour à l'interface Amazon : bouton Accueil ; désinstallation facultative de Projectivy depuis les paramètres.

Après identification réelle d'Android 9/API 28 et constat de la limitation Premium du fond personnel, un accueil Kotlin est fourni dans `launcher/`. Il inclut gratuitement le fond voxel local. La construction et la signature sont vérifiables sur PC ; la validation d'exécution reste à réaliser sur la TV.

## 5. Publicités et performances

Dans Paramètres → Préférences → Contenu à la une, désactiver la lecture automatique vidéo et audio si ces options existent. Dans Confidentialité, examiner les options de données d'utilisation et de publicités basées sur les centres d'intérêt. [Réponse officielle Amazon sur ces réglages](https://au.amazonforum.com/s/question/0D5at00000r3dXnCAI/how-do-i-disable-inappropriate-thumbnails-and-recommendations-on-firestick-home). Cela ne supprime pas toutes les promotions Amazon. L'accueil alternatif ne supprime pas les publicités dans YouTube, Netflix ou les autres applications.

`animationScale` est `null` : aucun changement. Après mesure et essai de compatibilité, `0.5` permet de proposer trois réglages Android, chacun confirmé et sauvegardé séparément. Réduire les animations ne prouve pas un gain de décodage vidéo ou de RAM. Toute commande refusée arrête le script.

Pour les caches, utiliser manuellement Paramètres → Applications → Gérer les applications installées → application → **Vider le cache**, seulement si le bouton existe et si le cache est pertinent. Ne pas choisir Effacer les données. Aucune purge automatique, fermeture forcée, suppression de fichiers ou pseudo-optimisation mémoire.

## 6. Mesurer, tester et restaurer

Exécuter `diagnostic.ps1 -Label apres` dans les mêmes conditions que le rapport avant. Comparer stockage et mémoire au repos après un délai identique. Pour chaque application conservée, chronométrer cinq ouvertures dans les mêmes conditions (chaud/froid identiques), puis comparer les médianes. Noter séparément la fluidité de navigation ; aucun gain n'est annoncé par le projet sans ces mesures.

Checklist à remplir dans `validation.md` après chaque étape : démarrage normal (redémarrage manuel), télécommande, navigation, lancement de toutes les applications conservées, vidéo/audio et DRM, Wi-Fi, paramètres et retour Amazon par Accueil.

Les journaux dans `journal/` sont écrits **avant** chaque changement avec état pending puis applied. En cas de coupure, les consulter : pending ne prouve pas un échec. Pour les animations :

```powershell
.\restore.ps1 -Journal .\journal\NOM-DU-JOURNAL.json
.\restore.ps1 -Journal .\journal\NOM-DU-JOURNAL.json -Apply
```

Simulation puis confirmation de chaque restauration. Le journal est lié à l'adresse et à l'empreinte firmware de la TV ; vérifier l'identité si l'adresse est réattribuée. Une mise à jour du firmware exige une réévaluation manuelle. Une désinstallation utilisateur est seulement consignée : réinstaller depuis la boutique et se reconnecter ; **aucun retour des données n'est promis**.

Fin de session : désactiver le débogage ADB sur la TV et révoquer les autorisations si l'option existe. Ne pas exposer le port ADB sur Internet.

## État de validation

Les fichiers sont contrôlables localement avec `tests.ps1` (syntaxe et barrières du plan). La connexion réseau, l'installation Projectivy et les essais matériels restent à effectuer avec votre accord, votre modèle/OS et votre IP. Aucun changement n'a été appliqué à votre Fire TV.
