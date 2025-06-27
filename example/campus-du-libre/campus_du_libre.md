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

Cette présentation se fera en **trois parties** :

{pause style="text-align:center" #comment-presenter}

{style="display: flex; position:relative"}
> {#part1 slip include src="what-is-a-presentation.md"}
>
> {up=vrai-sommaire}
>
> {#part3 include src=how-to-write.md slip enter}
>
> {step}
>
> {enter #part4 include src="access-slipshow.md" slip}
>
> {pause}
>
> {#merci pause}
> > {#merci-2}
> > ---
> > # Merci de votre attention !
> >
> > - Site du projet : <https://github.com/panglesd/slipshow/>
> >
> > - Documentation : <https://slipshow.readthedocs.io/>
> >
> > - Source de ces slides : <https://github.com/panglesd/slipshow/tree/main/example/campus-du-libre>
> >
> > - Sliphub : <https://sliphub.choum.net/>

<style>
#merci {
  position:absolute;
  padding-right:200px;
  padding-left:200px;
  padding-top: 50px;
  padding-bottom: 50px;
  background-color: yellowgreen;
  top: 303px;
  border-radius: 30px;
}
#merci-2 {
  animation: growShrink 2s infinite;
}
@keyframes growShrink {
    0%, 100% {
      transform: scale(1); /* Original size */
    }
    50% {
      transform: scale(1.15); /* Enlarged size */
    }
  }
</style>


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



<style>
#youhou {
    font-size:1.5em
}
code {
  background-color:#f3f3f3;
}
</style>

