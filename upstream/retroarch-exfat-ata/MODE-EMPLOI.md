# Mode d'emploi — pousser le correctif et récupérer les ELF

Les modifications sont **déjà écrites** dans tes deux dossiers locaux. Il ne
reste qu'à les envoyer sur GitHub et à laisser la CI compiler.

Fichiers modifiés, pour information :

**`D:\DOCS\Documents\GitHub\ps2_drivers`**

| Fichier | |
|---|---|
| `include/ps2_ata_bd_driver.h` | nouveau |
| `src/ps2_ata_bd_driver.c` | nouveau |
| `CMakeLists.txt` | modifié |
| `src/ps2_hdd_driver.c` | modifié |
| `src/ps2_filesystem_driver.c` | modifié |
| `include/ps2_filesystem_driver.h` | modifié |

**`D:\DOCS\Documents\GitHub\RetroArch`**

| Fichier | |
|---|---|
| `frontend/drivers/platform_ps2.c` | modifié |
| `.github/workflows/PS2-ata-bd.yml` | nouveau |

---

## Étape 0 — Avoir git dans le terminal

GitHub Desktop embarque git mais ne le rend pas accessible depuis PowerShell.
Vérifie :

```powershell
git --version
```

Si la commande n'est pas reconnue, installe-le une bonne fois :

```powershell
winget install --id Git.Git -e --source winget
```

Puis **ferme et rouvre PowerShell** — sinon il ne verra pas la nouvelle
installation — et revérifie `git --version`.

Solution de repli sans rien installer, valable uniquement pour la fenêtre
PowerShell en cours :

```powershell
$g = (Get-ChildItem "$env:LOCALAPPDATA\GitHubDesktop\app-*\resources\app\git\cmd\git.exe" | Select-Object -Last 1).DirectoryName
$env:Path = "$g;$env:Path"
git --version
```

---

## Étape 1 — Forker les deux dépôts sur GitHub

Dans le navigateur, connecté en tant que `soaresden` :

1. https://github.com/fjtrujy/ps2_drivers → bouton **Fork** → Create fork
2. https://github.com/libretro/RetroArch → bouton **Fork** → Create fork

Un fork, c'est ta copie personnelle du projet. Tu as le droit d'y pousser ce
que tu veux ; ça ne touche pas au dépôt d'origine.

Tu obtiens `soaresden/ps2_drivers` et `soaresden/RetroArch`.

---

## Étape 2 — Pousser ps2_drivers

Ouvre un terminal (PowerShell ou Git Bash), et colle ligne par ligne :

```bash
cd D:\DOCS\Documents\GitHub\ps2_drivers

git checkout -b ata-bd

git add include/ps2_ata_bd_driver.h src/ps2_ata_bd_driver.c CMakeLists.txt src/ps2_hdd_driver.c src/ps2_filesystem_driver.c include/ps2_filesystem_driver.h

git commit -m "Add ata_bd driver: expose the internal ATA disk as a BDM device" -m "ata_bd.irx is ps2atad built with ATA_ENABLE_BDM=1: on top of the atad library it calls bdm_connect_bd(), which combined with bdmfs_fatfs makes a FAT32/exFAT formatted internal drive reachable as massN:." -m "Since ata_bd exports the same atad library as ps2atad, the two cannot be loaded together, so ps2_hdd_driver now depends on this driver instead of embedding ps2atad.irx. The APA stack (ps2hdd/ps2fs) sits on that library unchanged, so hdd0: keeps working."

git remote add fork https://github.com/soaresden/ps2_drivers.git
git push -u fork ata-bd
```

Chaque `-m` devient un paragraphe du message. C'est plus lisible sous
PowerShell que d'ouvrir un guillemet sur plusieurs lignes.

Avant le `commit`, tu peux vérifier ce que git s'apprête à envoyer :

```bash
git status
git diff --cached --stat
```

Tu dois voir exactement les 6 fichiers du tableau plus haut, et rien d'autre.

---

## Étape 3 — Pousser RetroArch

```bash
cd D:\DOCS\Documents\GitHub\RetroArch

git checkout -b ata-bd

git add frontend/drivers/platform_ps2.c .github/workflows/PS2-ata-bd.yml

git commit -m "ps2: load ata_bd so cores can read an internal exFAT disk" -m "init_drivers() already loads the full BDM stack (bdm + bdmfs_fatfs) and dev9, but nothing ever hands the internal ATA drive over to BDM, so a FAT32/exFAT formatted internal disk is invisible to cores. Loading ata_bd.irx after the USB and MX4SIO drivers makes it appear as massN:." -m "Requires the matching ps2_drivers change."

git remote add fork https://github.com/soaresden/RetroArch.git
git push -u fork ata-bd
```

Note : ton fork `soaresden/RetroArch` descend de `OsirizX/RetroArch`, pas
directement de libretro. Ça ne gêne rien ici — on pousse une branche neuve
basée sur le `master` actuel de libretro. Ça compte seulement au moment de la
PR (étape 6).

---

## Étape 4 — Lancer la compilation

1. Va sur `https://github.com/soaresden/RetroArch`
2. Onglet **Actions**. GitHub affiche un bandeau jaune la première fois :
   clique sur **I understand my workflows, go ahead and enable them**.
   (Les forks ont les Actions désactivées par défaut, c'est normal.)
3. Dans la colonne de gauche, choisis **CI PS2 (ata_bd / internal exFAT)**,
   puis **Run workflow** → branche `ata-bd` → **Run workflow**.
4. Attends. Le job `build` prend une quinzaine de minutes, le job `core` un peu
   plus.
5. Quand c'est vert, clique sur le run, descends jusqu'à **Artifacts**, et
   télécharge `RA-PS2-atabd-dummy-xxxxxxx`.

Si le workflow échoue, ouvre le job en rouge : les deux causes d'échec prévues
affichent un message explicite (`ata_bd.irx` absent du conteneur, ou le fork
ps2_drivers ne contient pas le driver).

---

## Étape 5 — Tester sur la console

L'artefact `dummy` contient `retroarchps2.elf` : c'est RetroArch **sans
émulateur** — pas de jeu jouable, mais tout le menu et le navigateur de
fichiers. C'est exactement ce qu'il faut pour répondre à la seule question qui
compte : est-ce que le disque interne apparaît ?

Copie-le sur ta clé, lance-le, puis **Load Content** → tu dois voir les
périphériques listés.

Fais les trois essais dans cet ordre, et note à chaque fois ce que tu vois :

1. **Clé USB seule**, disque interne débranché ou vide → la clé doit toujours
   être `mass0:`. Si elle a changé de numéro, on a un problème.
2. **Disque interne seul**, sans clé → il doit apparaître.
3. **Les deux branchés** → lequel est `mass0:` ? Et est-ce que RetroArch
   retrouve bien sa configuration ?

Le cas 3 est le vrai test. Les périphériques `mass` sont numérotés dans l'ordre
où ils se connectent, donc ajouter une source de disques peut décaler ta clé
USB. Si ça décale, il faudra proposer le correctif en option plutôt qu'activé
en dur — et c'est mieux de le dire soi-même dans la PR.

Une fois le cas 3 validé, l'artefact `RA-PS2-atabd-fceumm-xxxxxxx` te donne un
vrai émulateur NES pour tester avec une ROM posée sur le disque interne.

---

## Étape 6 — Les Pull Requests

**Oui, deux PR, mais seulement une fois l'étape 5 concluante.** Proposer un
correctif qu'on n'a pas testé sur la vraie machine, c'est le meilleur moyen de
se le faire refuser.

Et dans cet ordre, parce que le second dépend du premier :

1. **`fjtrujy/ps2_drivers`** d'abord. Sur la page de ton fork, GitHub propose
   **Compare & pull request**. Comme texte, reprends les sections 2, 3 et 4 du
   `README.md` d'à côté — le pourquoi, le comment, et les questions ouvertes.
2. **`libretro/RetroArch`** ensuite, une fois la première acceptée (sinon les
   cores ne compileront pas chez eux). Mentionne dans le texte les deux tickets
   déjà ouverts, `#14346` et `#16010`, avec la formule `Closes #14346` si tu
   penses que ça les règle.

   **Attention sur celle-ci :** GitHub proposera `OsirizX/RetroArch` comme
   cible par défaut, puisque c'est le parent direct de ton fork. Il faut
   changer le **base repository** en `libretro/RetroArch` dans le menu
   déroulant, en haut de la page de création de la PR. Ton fork appartient bien
   au réseau de libretro, donc c'est proposé — il faut juste le sélectionner.

Ne mets **pas** `.github/workflows/PS2-ata-bd.yml` dans la PR RetroArch : c'est
ton outil de compilation personnel, pas quelque chose que le projet veut. Au
moment de la PR, retire-le de la branche :

```bash
cd D:\DOCS\Documents\GitHub\RetroArch
git checkout -b ata-bd-pr ata-bd
git rm .github/workflows/PS2-ata-bd.yml
git commit -m "Remove local CI workflow"
git push -u fork ata-bd-pr
```

et ouvre la PR depuis `ata-bd-pr`.

---

## À retenir

Tu n'as **pas besoin des PR** pour toi-même. Ton fork + les Actions te donnent
déjà des ELF qui marchent. Les PR servent à ce que les autres en profitent, et
à ce que tu n'aies plus à recompiler à chaque version de RetroArch.
