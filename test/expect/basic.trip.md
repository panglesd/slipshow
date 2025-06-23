Basic tests
===========

Basic tests for all CommonMark constructs.

## Testing autolinks 

This is an <http://example.org> and another one <you@example.org>.


## Testing breaks 

A line ending (not in a code span or HTML tag) that is preceded by two 
   or more spaces and does not occur at the end of a block is parsed as a
 hard line break.

So this means we had softbreaks so far and now we get  \
  a hard break     
 and another one.

> So this means we had softbreaks so far and now we get  \
>   a hard break     
>     and another one.
> This is very soooft.

## Testing code spans 

This is a multi-line code`
    code span `` it has backticks
  in there`

Sometimes code spans `` `can have
   really ```
 strange
      layout ``. Do you fancy `` `A_polymorphic_variant `` ? 


## Testing emphasis

There is _more_ than *one syntax* for __emphasis__ and **strong
emphasis**.  We should be careful about **embedded \* marker**. This
will be **tricky \* to handle**. This *is not \*\* what* you want ?


## Testing links, images and link reference definitions

This is an ![inline image](
  /heyho    (The
    multine title))

  That is totally [colla    psed][] and 
    that is [`short cuted`]

Shortcuts can be better than [full references][`short 
cuted`] but not
     always and we'd like to trip their [label][`short    cuted`].

> [colla psed]: /hohoho "And again these 
>   multi
>     line titles"

 [`short cuted`]:    /veryshort   "But very
    important"
  

## Testing raw HTML

Haha <a>a</a><b2
               data="foo" > hihi this is not the end yet.

foo <a href="\*" />u</a>

>  Haha <a>a</a><b2
>               data="foo" > hihi this is not the end yet.

## Testing blank lines

    
     
Impressive isn't it ?

## Testing block quotes 


  >   > How is 
  >   > Nestyfing going on 
  >   > These irregularities **will** normalize
  >   > We keep only the first block quote indent 

>  ## Further tests #######  

  We need a little quote here
>  It's warranted.


## Testing code blocks

``` layout after info is not kept
```

 ``` ocaml module M
 
 type t = 
 | A of int
 | B of string
 
 let square x = x *. x
 ````   

The indented code block: 

    a b c d 
     a b c d
     a b c d
      
    
    a
       a b c


> ``` ocaml module M
> 
> type t = 
> | A of int
> | B of string
> 
> let square x = x *. x
> ````   


## Testing headings 

aaa
aaaa
========

> bbb `hey`
> bbbb
> --------

  # That's one way     
  
   ### It's a long way to the heading   

## Testing HTML block 

<aside>
<p>There is no aside</p>
</aside>

* <aside>
  <p>There is no aside</p>
  </aside>

## Testing lists 

The `square` function is the root. There are reasons for this:

 1. There is no reason. There should be a reason or an <http://example.org> 
2. Maybe that's the reason. But it may not be the reason. 
 3. Is reason the only tool ? 

> Quoted bullets
> * Is this important ? 
* * Well it's in the spec
* 
Empty list item above

## Testing paragraphs 

   We really want your paragraph layout preserved. 
        Really ? 
      Really.
    Really.
Really.		


>   We really want your paragraph layout preserved. 
>        Really ? 
>      Really.
>    Really.
> Really.		
 


## Testing thematic breaks

 ***
  ---
   ___

_ _ _ _ _ 

>  *******
