# Validation sur appareil — à compléter

## Cissou's TV 1.2 — vérifié le 30 octobre 2026

- Titre et nom de l'application remplacés par `Cissou's TV`, package inchangé.
- Home on Fire 1.5.2 installé depuis sa release GitHub officielle. SHA256 APK : `87403C961264CC2E36E53CF571777EC20705EB87F46794CB0AC667135A98D9FE`.
- Configuration via l'interface de l'outil : cible `fr.local.voxelhome`, accessibilité activée, Replace Home activé, Launch on boot activé, raccourcis personnalisés et logs détaillés désactivés.
- État initial sauvegardé dans `reports/home-before.json` : aucun service d'accessibilité actif. Aucun launcher système désactivé ou désinstallé.
- Appui Maison injecté depuis les paramètres : retour sur Cissou's TV observé. Délai Fire OS 7 conservé ; arrivée instantanée non garantie.
- Double appui Maison avec pause courte : accueil Amazon observé au premier plan. L'appui long injecté affiche le panneau rapide et n'a pas validé l'échappement sur ce firmware : utiliser le double appui testé.
- Redémarrage réel du Stick effectué : `sys.boot_completed=1`, uptime 62 secondes, Cissou's TV au premier plan, service Home on Fire toujours activé. Aucun lancement manuel envoyé après ce redémarrage pour ce contrôle.
- Capture de contrôle : `reports/cissou-after-boot.png`.
- Receveur de boot interne désengagé quand Home on Fire est installé ; bouton Maison / démarrage ouvre les réglages de l'outil.
- Retour arrière fourni : `restore-home.ps1` (simulation par défaut). Aucune suppression.
- Sortie de veille et appuis physiques sur la télécommande : à confirmer par l'utilisateur. Aucun gain de performance revendiqué.

## Accueil Voxel 1.1 — vérifié le 30 octobre 2026

- Mise à jour ADB du package `fr.local.voxelhome` : Success, sans désinstallation.
- Lancement réel sur Fire TV AFTSS / Fire OS 7.7.1.7 / Android API 28 : Status ok.
- Capture réelle `reports/voxel-v1.1.png` inspectée : forêt et rivière voxel, titre, quatre applications, focus vert, commandes et options visibles, sans débordement.
- Rapport mémoire ponctuel : `reports/voxel-v1.1-memory.txt`. Aucun gain comparatif annoncé.
- Compilation Kotlin, signature locale, manifeste et tests PowerShell : validés.
- Réception BOOT_COMPLETED, maintien au premier plan après redémarrage, lancement de chacune des quatre applications et lecture vidéo : restent à vérifier manuellement.
- Extinction du téléviseur / sortie de veille : distincte d'un redémarrage complet ; pas de redirection automatique de veille.

Modèle / génération confirmée :
OS / firmware / API :
Applications conservées et packages :
Date / alimentation / réseau / conditions :

| Contrôle | Avant | Après | Observations |
|---|---|---|---|
| Démarrage normal | À tester | À tester | |
| Télécommande directions / OK / Retour | À tester | À tester | |
| Fluidité navigation | À tester | À tester | |
| Chaque application conservée | À tester | À tester | |
| Lecture vidéo / audio / DRM | À tester | À tester | |
| Wi-Fi | À tester | À tester | |
| Paramètres Amazon | À tester | À tester | |
| Accueil revient sur Amazon | À tester | À tester | |
| Stockage libre | À mesurer | À mesurer | |
| RAM au repos | À mesurer | À mesurer | |
| Médiane de 5 lancements par application | À mesurer | À mesurer | |
