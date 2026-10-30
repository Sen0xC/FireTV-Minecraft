# Accueil voxel Fire TV

## Platform
android

## Stack
Kotlin et vues Android natives, conformément au cahier des charges utilisateur.

## Users
Un utilisateur de Fire TV Stick HD sous Fire OS 7.7.1.7, utilisant une télécommande.

## Product Purpose
Ouvrir Stremio, YouTube, Crunchyroll et ADN depuis un accueil local gratuit inspiré du pixel art classique. Accéder aux paramètres Amazon et revenir à l'accueil Amazon.

## Constraints
Aucun abonnement, publicité ajoutée, tracking, service permanent ou accès réseau. Paysage original ; l'utilisateur autorise désormais une animation discrète de feuilles, désactivable. Aucune désactivation système ou interception du bouton Accueil. Aucun asset extrait de Minecraft. API 28 détectée dans le rapport matériel. L'utilisateur demande le lancement au démarrage : tentative standard BOOT_COMPLETED, désactivable, résultat matériel à vérifier ; la sortie de veille n'est pas un démarrage complet.

## Decisions
Composition déjà demandée : paysage cubique, ciel bleu, herbe, terre et pierre, cadres pixelisés, une rangée principale de quatre applications. Les performances matérielles restent à mesurer.
