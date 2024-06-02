# Variants

<style> code {background: beige;} </style>

## Résumé des types que l'on connait

Avant d'aller plus loin, et de découvrir une des fonctionalité les plus
importantes d'OCaml, il est utile de faire une pause et de résumer les types que
l'on connait.

{pause}

Nous avons vu les types "de base":

{.block title="Types de base" #type-base}
> - `bool` pour les booléens: "vrai" ou "faux".
> - `int` pour les entiers: `420`, `2`, ...
> - `float` pour les nombres à virgule: `4.14`, `2.0`, `3.33334`, ...
> - `char` pour les caractères: `a`, `\n`, `#`
> - `string` pour les chaînes de caractères: `"salut tout le monde"`, ...

{pause down=combi}

Mais aussi des types pour combiner des types en des types nouveaux:

{.block title="Combinaison de types" #combi}
> - Les types **fonction**: par exemple, à partir du type `int` et du type `float`, on
>   a le type fonction `int -> float`. {pause}
> - Le type des **listes** : à partir d'un type, on peut créer le type des listes
>   d'éléments de ce type. Par exemple, avec le type `float`, on peut créer le
>   type des listes de nombres à virgule : `float list`.

{pause up=type-base}

**Est-ce que ça suffit ?** {pause} Non ! **Pourquoi ?**

{pause up=combi .block}
> OCaml permet de créer des types personnalisés pour représenter ce que l'on veut
> ! Par exemple on pourra créer des types pour :
> - Un personnage de jeu de rôle,
> - Une recette de cuisine,
> - Une carte à jouer,
> - Un dictionaire,
> - ...

{pause}
Mais avant de créer ces types, nous allons nous concentrer sur les types que
l'on connait déjà, et voir comment ils ont été défini ! Et comment nous aurions
pu les définir nous-même !

{pause up}
## Anatomie d'un booléen

OCaml nous permet de jeter un oeil à la définition d'un type:

```ocaml
#show bool
```

et le résultat ne se fait pas attendre!

{#resultat-bool}
```ocaml
type bool = false | true
```

**Mais qu'est-ce que cela peut bien vouloir dire ?**

- "`type`" ?
- "`bool`" ?
- "`=`" ?
- "`false`" ?
- "`|`" ?
- "`true`" ?

{pause up=resultat-bool}

{.block #solution1}
> - `type` nous indique que l'on va déclarer un type, et non autre chose (une
>   valeur, un module, une pâte à tartiner, ...)
> - `bool` est le nom du type,
> - `false` et `true` sont les deux valeurs que peuvent prendre le type,
> - `|` sert à séparer les différentes valeurs possibles.

On appelle ça un **type énuméré** : un type dont la définition énumère les
différentes valeurs possibles.

{pause up=solution1 #creation}
### Création d'un type énuméré

Essayons tout d'abord de recréer le type booléen :

{#my_bool}
```ocaml
type mon_bool = true | false
```

Est-ce que ça marche ? {pause} Oui ! {pause up=creation}

Alors, mettons-le en français :

```ocaml
type mon_bool = vrai | faux
```

Est-ce que ça marche ? {pause} Non !

{.block #majuscules title="Et pourquoi ça ne marche pas ? "}
Pour éviter de "confondre" les "valeurs de base" des
valeurs normales, on force à utiliser des majuscules pour les nouvelles valeurs
de base.

{pause .definition up=my_bool #def-constr}
On appelle les "valeurs de base" définie lors de la création d'un type des "**constructeurs**". Rappelez-vous ce terme ! Ils sont toujours en majuscule.

```ocaml
type mon_bool = Vrai | Faux
```

{pause up=def-constr}

Mais plutôt que de reprendre un type existant, ce qui n'est pas très utile,
créens-on un nouveau !

{#tricot-titre}
## Du tricot en OCaml

{style="display:flex; align-items:center; margin-top: -70px"}
> {style="flex-grow: 1"}
> ```ocaml
> type maille = Endroit | Envers
> ```
>
> {style="margin-left: 10px" #tricot-img}
> ![tricot](https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSiVN4-begPwEgAgiCnUmKId9TnXifQ-1kuQg&usqp=CAU)

{pause focus-at-unpause=tricot-img}

{pause unfocus-at-unpause}

{pause}

{.block}
> **Note** : Il n'y a que deux possibilités, comme pour les booléens ! On aurait
> pu utiliser des booléens pour représenter ces valeurs, mais cela ne pourrait que
> nous mélanger les aiguilles, et générer des bugs !

{pause up=tricot-titre}

Nous pouvons maintenant filtrer et utiliser ces valeurs:

{#ex-utilisation}
```ocaml
let esthetique maille =
  match maille with
   | Endroit -> 1.3
   | Envers -> 1.2

let retournement maille =
  match maille with
   | Endroit -> Envers
   | Envers -> Endroit
```
{pause up=ex-utilisation}

Augmentons un peu le type...

{#tricot-augmente}
```ocaml
type maille =
  | Endroit
  | Envers
  | Glisse (** Passe une maille d'un côté à l'autre sans la tricoter *)
  | Jete (** "Jette" une maille *)
  | Augmente (** Crée deux mailles à partir d'une seule *)
```

Horreur ! Le filtrage n'est plus exhaustif ! Corrigeons cela tout de suite !

{pause .block}
Le fait que OCaml soit capable d'emettre un warning est un très bon point pour
la maintenance des projets.

{pause up=tricot-augmente}

Dans certains cas, on peut se permettre d'avoir un "cas joker":

```ocaml
let connu_de_paul_elliot maille =
  match maille with
   | Endroit -> true
   | Envers -> true
   | _ -> false
```

Même si on rajoute un nouveau genre de point, Paul-Elliot ne le connaitra pas
pour autant.

{pause}
## Exercices sur les variants énumérés

{pause up}
## Des constructeurs avec données

Les constructeurs permettent de créer des valeurs incompatibles. Cependant:
- Par moment, ce n'est pas très pratique de tout énumérer
- On peut en vouloir un nombre infini !

{pause}

{.block #donnes-to-constructeur title="Constructeurs avec données associées"}
> On peut ajouter des données à un constructeur.
>
> ```ocaml
> type temperature_dimensionnee =
>   | Celsius of float
>   | Farenheit of float
> ```

{pause}

```ocaml
let temp_corporelle = Celsius 37.

let en_farenheit t = match t with
  | Farenheit f -> f
  | Celsius c -> (c *. 9.) /. 5. +. 32.
```

{pause up=donnes-to-constructeur}

```ocaml
type json =
  | Null
  | Bool of bool
  | Int of int
  | Float of float
  | String of string
  | Array of json list
  | Object of (string * json) list;;
```

{pause down}
## Exercices sur les Variants avec données

{pause up}
## Enregistrements

On peut combiner des valeurs en une seule en utilisant des enregistrements. La syntaxe est la suivante :

{.block #def-enr}
> ```ocaml
> type ethique = Loyal | E_Neutre | Chaotique
>
> type moral = Bon | M_Neutre | Mauvais
> 
> type personnage_dd = {
>   nom : string
>   ethique : ethique;
>   moral : moral;
> }
>  ```

{pause}

```ocaml
let p = { nom = "Monsieur L" ; ethique = Loyal ; moral = Bon}
```

{pause}
```ocaml
let nom_de p = p.nom
```

{pause down}
```ocaml
let est_pire p = match p with
  | {nom = _ ; ethique = Chaotique ; moral = Mauvais} -> true
  | _ -> false
```

{pause down}
## Exercices sur les enregistrements

{pause up}
## Quelques types classiques

- Le type `option` permet de définir une valeur qui peut être présente, ou absente :

```ocaml
type 'a option = 
  | None   (** La valeur est absente *)
  | Some of 'a  (** La valeur est présente *)
```

{pause}

- Le type `list` permet de définir une liste de valeurs :

```ocaml
type 'a list = 
  | []   (** La liste est vide *)
  | ( :: ) of 'a * 'a ilst  (** Un élément en tête, et le reste de la liste *)
```

{pause}

- Le type `either` permet de définir l'union de deux types :

```ocaml
type ('a, 'b) either = 
  | Left of 'a   (** Un élément de type 'a *)
  | Right of 'b  (** Un élément de type 'b *)
```

{pause}

## Finir les exercices !
