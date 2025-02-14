# Slipshow

- Slipshow est un logiciel libre pour faire des présentations améliorées. {pause}

- Avec slipshow, pas besoin de gérer l'alignement du texte ! {pause}

- Une présentation slipshow prend la forme d'un fichier texte.

{pause}

{.example #example}
  ```markdown
  # Ceci n'est pas un titre

  Et ceci est un paragraphe.

  - Et ceci est une liste à points
  - Avec plusieurs points

  On peut aussi mettre du texte **en gras**, ou en *italique*.
  ```

{pause}

Mais le truc **VRAIMENT** cool, avec slipshow, c'est :

...

{.block #cool title="Le truc vraiment cool" pause}
> Supsense, suspense...
>
> ## **On peut faire dérouler un slide! {pause up=example}

{pause #vrai-sommaire up=cool}
## Sommaire

Cette présentation se fera en **quatre parties** :

{#sommaire}
- **Comparaison** avec les concurrents ✅

- **Qu'est-ce** qu'une présentation slipshow ?

- Comment **écrire** une présentation avec slipshow ?

- Comment **accéder** à slipshow ?

{pause up=sommaire style="text-align:center" #comment-presenter}

{#part1}
> ## **Qu'est-ce** qu'une présentation slipshow ?
>
> Voici [un exemple](https://choum.net/panglesd/slides/WDCM-2021-slips/wdcm-ada.html#2,21).
>
> {pause down #preslip .block}
> > Une présentation slipshow tient plus du **tableau noir** que des diapositives. {pause}
> >
> > Elle se contrôle avec les touches :
> >
> > {.flex}
> > > [`←`]{.touche} [`→`]{.touche} [`↑`]{.touche} [`↓`]{.touche} [`SPACE`]{.touche .space}
> > >
> > > **Avancer/Reculer**
> >
> > {.flex}
> > > [`w`]{.touche} [`W`]{.touche} [`h`]{.touche} [`H`]{.touche} [`x`]{.touche} [`X`]{.touche}
> > >
> > > **Mode dessin**
> >
> > {pause}
> >
> >
> > Une présentation slipshow permet de :
> >
> > - Compléter interactivement sa présentation avec le **mode dessin**.
> >
> > - Faire apparaître **la structure** de la présentation. {pause up=vrai-sommaire} {pause unstatic-at-unpause=part1} {pause static-at-unpause=part1 down=preslip}
> >
> > - Ouvrir de **nouvelles possibilités [pédagogiques]{step focus-at-unpause}**
>
> {pause unfocus-at-unpause}

{pause up=vrai-sommaire}

<style>
.flex {
  display: flex;
    justify-content: space-evenly;
}
.grow {
  flex-grow: 1;
}

.touche code {
  margin-left: 10px;
  display: inline-block;
  border: 3px solid black;
  padding: 9px;
  border-radius: 12px;
  width: 20px;
  height: 29px;
}
.touche.space code {
  width: 90px;
}
</style>

{#part3}
> {pause unstatic-at-unpause=part1 #part2}
> ## Comment écrire une présentation slipshow
>
> {pause}
>
> 1. On écrit dans un **fichier texte** {pause} du **markdown** {pause} avec des **annotations**. {pause}
>
> 2. Slipshow le transforme en un fichier `.html` ... **autosuffisant**
>
> {.flex}
> > {style="border: 2px solid black; border-radius: 10px; display: flex; align-items: center; background-color:#f3f3f3; text-align: center; padding:50px"}
> > [`ma-presentation.md`]{style="margin-left:20px;"}
> >
> > {.prrrouut style="text-align:center"}
> > > {style="margin-bottom:-10px"}
> > > compilation
> > >
> > > {style="margin:-50px"}
> > > [→]{style="font-size:6em"}
> > >
> > > {style="margin-top:-10px"}
> > > Slipshow
> >
> > {style="border: 2px solid black; border-radius: 10px; display: flex; align-items: center; background-color:#f3f3f3; text-align: center; padding:50px"}
> > [`ma-presentation.html`]{style="margin-left:20px;"}
> >
> >
>
>
> {.block up=part2 pause title="Example"}
> > {.flex}
> > > ```markdown
> > > ### Ceci est un titre
> > >
> > > Et _ceci_ est un **paragraphe**.
> > >
> > > {pause}
> > >
> > > - Une liste à `points` {pause}
> > > - Avec plusieurs points
> > > ```
> > > {pause}
> > > > ### Ceci est un titre
> > > >
> > > > Et _ceci_ est un **paragraphe**.
> > > >
> > > > {pause}
> > > >
> > > > - Une liste à `points` {pause}
> > > > - Avec plusieurs points
>
> {.block pause down title="Example"}
> > {.flex style="gap: 20px"}
> > > {style="width:60%"}
> > > ```markdown
> > > {.definition title="La définition"}
> > > $D$ tel que $D=\{x : x\in x\}$.
> > >
> > > {pause}
> > >
> > > Marche aussi avec `theorem`,
> > > `example`, `block`, `proof`, ...
> > > ```
> > >
> > > {pause}
> > > > {.definition title="La définition"}
> > > > $D$ tel que $D=\{x : x\in x\}$.
> > > >
> > > > {pause}
> > > >
> > > > Marche aussi avec `theorem`, `example`, `definition`, `proof`, ...
>
> {.block pause down title="Example"}
> > {.flex style="gap: 20px"}
> > > {style="width:56%"}
> > > ````markdown
> > > {.example title="Multi paragraph"}
> > > > Voici un bloc de code:
> > > >
> > > > ```ocaml
> > > > let rec fibo =
> > > >  function
> > > >  | 0 -> 0 | 1 -> 1
> > > >  | n ->
> > > >      fibo (n-1)
> > > >    + fibo (n-2);;
> > > > ```
> > > ````
> > >
> > > {pause}
> > > >  {.example title="Multi paragraph"}
> > > > > Voici un bloc de code:
> > > > >
> > > > > ```ocaml
> > > > > let rec fibo =
> > > > >  function
> > > > >  | 0 -> 0 | 1 -> 1
> > > > >  | n ->
> > > > >      fibo (n-1)
> > > > >    + fibo (n-2);;
> > > > > ```
>
> {pause up}
> {style="text-align:center"}
> ## Récapitulatif
>
> <style>
> .column-3 {
>   display:grid;
>   grid-template-columns: 0.5fr 1fr 1fr;
>   grid-column-gap: 80px;
>   align-items: center;
> }
> </style>
>
> {.column-3}
> > > Italique
> >
> > ```text
> > _contenu_
> > ```
> >
> > _contenu_
> >
> > Gras
> >
> > ```text
> > **contenu**
> > ```
> >
> > **contenu**
> >
> > Chasse fixe
> >
> > ```text
> > `contenu`
> > ```
> >
> > `contenu`
> >
> > Math
> >
> > ```text
> > $\sqrt x$
> > ```
> >
> > $\sqrt x$
> >
> > {pause down=fin-liste}
> > Paragraphe
> >
> > ```
> > Premier paragraphe.
> >
> > Après saut de ligne.
> > ```
> >
> > {.ddd}
> > > Premier paragraphe.
> > >
> > > Après saut de ligne.
> >
> > Titre
> >
> > ```text
> > ## Titre
> > ```
> >
> > ## Titre
> >
> > Listes
> >
> > ```text
> > - Point 1
> > - Point 2
> > - Point 3
> > ```
> >
> > {#fin-liste}
> > - Point 1
> > - Point 2
> > - Point 3
> >
> > {pause down=fin-attr}
> > [Attributs]{#attr-foc}
> >
> > ```text
> > {pause}
> >
> > {.block}
> > Hehe
> > ```
> >
> > {#fin-attr}
> > > {pause}
> > >
> > > {.block}
> > > Hehe
>
> {.remark pause center-at-unpause #tjrs-pas}
> On ne sait **toujours pas** comment **glisser**!!!
>
>
> {pause focus-at-unpause=attr-foc}
>
> {pause unfocus-at-unpause}
>
> {pause up=tjrs-pas}
> # Attributs
>
> Tout ce qui est entre accolades:
>
> {#attr-lg-ex}
> ```text
> {.theorem}
> Du texte
>
> {pause}
>
> Encore du [texte]{#reference}. {pause}
> Avec du [contenu special]{style="color:red"}.
> ```
>
> {pause #lgliste}
> - Certains sont **standalone**.
>
> - D'autres **s'appliquent à un bloc**.
>
> - D'autres **s'appliquent à du texte**. {pause down=lgliste}
>
> - `#nom-identifiant` pour définir un **identifiant** (unique)
>
> - `.nom-classe` pour définir une **classe** (multiple)
>
> - `name-attribut` et `nom-attribut="..."` pour définir **d'autres métadonnées**.
>
> {pause up=attr-lg-ex #id-titre-ex}
> # Attributs de présentation `{#attrs}`
>
> - `{pause}` **cache** le contenu qui suit, **jusqu'à** ce qu'on presse
>   [**`→`**]{style="background-color:beige;font-size: 1.3em"}. {pause}
>
> - `{pause up=nom-id}`, **au moment** de révéler, met `#nom-id` en **haut de
>   l'écran**.
>
>   **Exemple** `{pause up=attrs}` {pause up=id-titre-ex} {pause}
>
> - `center`, équivalent au **milieu de l'écran**. [`{.unrevealed
>   #youhou}`]{.unrevealed #youhou}
>
>   **Exemple** `{pause center}` {pause center-at-unpause} {pause}
>
> - `down`, équivalent au **bas de l'écran**.
>
>   **Exemple** `{pause down}` {pause down} {pause up=id-titre-ex} {pause}
>
> - `focus-at-unpause`, `static-at-unpause`, `unstatic-at-unpause`, `reveal-at-unpause`, ...
>
>   **Exemple** `{pause reveal-at-unpause=youhou}` {pause reveal-at-unpause=youhou}
>
> {pause up}
> # Slipshow
>
> - Slipshow est un logiciel libre pour faire des présentations améliorées. {pause}
>
> - Avec slipshow, pas besoin de gérer l'alignement du texte ! {pause}
>
> - Une présentation slipshow prend la forme d'un fichier texte.
>
> {pause}
>
> {.example #example-file}
>   ```markdown
>   # Ceci est un titre
>
>   Et ceci est un paragraphe.
>
>   - Et ceci est une liste à points
>   - Avec plusieurs points
>
>   On peut aussi mettre du texte **en gras**, ou en *italique*.
>   ```
>
> {pause}
>
> Mais le truc **VRAIMENT** cool, avec slipshow, c'est :
>
> ...
>
> {.block title="Le truc vraiment cool" pause}
> > Supsense, suspense...
> >
> > ## **On peut faire dérouler un slide! {pause up=example-file}
>
> <style>
> .max-size > code { font-size:0.85em; }
> </style>
>
> {pause down .max-size}
> ````markdown
> # Slipshow
>
> - Slipshow est un logiciel libre pour faire des présentations
>   améliorées. {pause}
>
> - Avec slipshow, pas besoin de gérer l'alignement du texte ! {pause}
>
> - Une présentation slipshow prend la forme d'un fichier texte.
>
> {pause}
>
> {.example #example-file}
> ```markdown
> # Ceci est un titre
>
> Et ceci est un paragraphe.
>
> - Et ceci est une liste à points
> - Avec plusieurs points
>
> On peut aussi mettre du texte **en gras**, ou en *italique*.
> ```
>
> {pause}
>
> Mais le truc **VRAIMENT** cool, avec slipshow, c'est :
>
> ...
>
> {.block title="Le truc vraiment cool" pause}
> > Supsense, suspense...
> >
> > ## **On peut faire dérouler un slide! {pause up=example-file}
> ````
>
> {pause down}
> # [Tutoriel](https://slipshow.readthedocs.io/en/latest/tutorial.html) et [référence](https://slipshow.readthedocs.io/en/latest/syntax.html)!

<style>
#youhou {
    font-size:1.5em
}
code {
  background-color:#f3f3f3;
}
</style>

{pause up=vrai-sommaire}

{pause unstatic-at-unpause=part3 #part4}
> # Accéder à Slipshow
>
> De nombreuses possibilités :
>
> - ["Sliphub"](https://sliphub.choum.net) **pour tester**.
>
>   - ✅ Rien à installer
>
>   - ✅ Collaboratif
>
>   - ❌❌✅ En ligne {pause up=part4}
>
> - [VSCode](https://open-vsx.org/extension/Slipshow/slipshow) [extension](https://marketplace.visualstudio.com/items?itemName=Slipshow.slipshow) (par exemple si **sous windows**.)
>
>   - ✅✅❌ Facile à installer si VS Code.
>
>   - ❌ Support moins avancé. {pause}
>
> - [Binaire Slipshow](https://github.com/panglesd/slipshow/releases)
>
>   - ✅ Marche uniquement sous Linux et Mac.
>
>   - ✅ Meilleurs support et performance.
>
> {pause up=vrai-sommaire}

{pause unstatic-at-unpause=part4}

{#merci}
# Merci de votre attention !

{style="margin-top:200px"}
- Site du projet : <https://github.com/panglesd/slipshow/>

- Documentation : <https://slipshow.readthedocs.io/>

- Source de ces slides : <https://choum.net/panglesd/slides/campus_du_libre.md>

- Sliphub : <https://sliphub.choum.net/>

<style>
#merci {
  margin-top: 100px;
  animation: growShrink 2s infinite;
}
@keyframes growShrink {
    0%, 100% {
      transform: scale(1); /* Original size */
    }
    50% {
      transform: scale(1.5); /* Enlarged size */
    }
  }
</style>
