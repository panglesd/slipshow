# Effets de bord

Considérez l'expressions suivante :

```ocaml
carre 2 + carre 10
```

Qu'est-ce qui est executé avant : `carre 2` ou `carre 10` ?

{pause} **Et comment le vérifier ?**

{pause .definition}
>  Une fonction qui n'a aucun effet sur son environement est appelée
> **pure**. Dans ce cas là, l'ordre d'execution n'a pas d'importance, ce qui est
> un très grand avantage.
>
> Sinon, on dit qu'elle a des **effets de bord**.

{pause down=ex-eff-bd}

{.example title="Exemples d'effets de bord" #ex-eff-bd}
> - Écrire sur la sortie standard,
> - Lire sur l'entrée standard,
> - Écrire ou lire un fichier,
> - Renommer un fichier ou un dossier
> - Envoyer un paquet réseau

{pause up=ex-eff-bd}
## Imprimer des caractères

OCaml possède des librairies semblables à `printf` pour imprimer à l'écran, mais
nous allons nous restreindre à des fonctions plus basiques.

{#print_string}
```ocaml
val print_int : int -> unit
val print_string : string -> unit
val print_endline : string -> unit
```

{pause}
## Le type `unit`

```ocaml
#show unit ;;
```

Le type `unit` est un type qui n'a qu'une valeur possible : `()`. Il sert au
fonction qu'un souhaiteraient ne rien retourner car leur unique but est de faire
un effet de bord.

{pause up=print_string #retour-au-sources}
## Retour aux sources

Considérez l'expressions suivante :

```ocaml
carre 2 + carre 10
```

Qu'est-ce qui est executé avant : `carre 2` ou `carre 10` ?

{pause up=retour-au-sources}
## Manipuler le type unit

```ocaml
let scope =
  let _ignored_returned_value = print_string "Hello world" in
  ...
```
```ocaml
let scope =
  let () = print_string "Hello world" in
  ...
```
```ocaml
let scope =
  print_string "Hello world" ;
  ...
```

{pause down}
## Exercices sur l'impression de valeurs

{pause up}
## Structures de données mutables

Un autre effet de bord possible est la mutation de structures de données mutables.

{.block title="Important !"}
Sauf mention explicite, les structures de données fonctionnelles ne sont pas mutables !


Nous allons voir deux structures de données mutables : les **tableaux** et les **références**.

{pause}
### Tableaux

Les tableaux sont une structure de donnée classique en programmation impérative.

```ocaml
let mon_tableau = [| 1; 2; 3 |]
let x = mon_tableau.(1)
let () = mon_tableau.(1) <- 5
let y = mon_tableau.(1)
```

{#questions-tableaux}
Quelle valeur à `x` à ligne 2 ? Quelle valeur à `y` ? Quelle valeur à `x` à ligne 4 ?

{pause}
```ocaml
val Array.make : int -> 'a -> 'a array
val Array.init : int -> (int -> 'a) -> 'a array
```

{pause up=questions-tableaux}
### Références

Une référence est similaire à un tableau qui ne pourrait contenir qu'une seule entrée.

```ocaml
let reference = ref 5

let x = !reference

let () = reference := 10

let y = !reference
```

{pause}
```ocaml
let reference = ref 5

let reference_2 = reference

let () = reference := 10

let y = !reference_2
```

{pause down}
## Exercices sur les tableaux et les références
