(*BEGIN INJECTIVITY*)
type !+'a t =
(*ELSE*)
type +'a t =
(*END*)
  | Nil
  | Leaf of { mutable mark: int; v: 'a; }
  | Join of { mutable mark: int; l: 'a t; r: 'a t; }

type 'a seq = 'a t

let empty = Nil

let element v = Leaf { mark = 0; v }

let mask_bits = 2

let maxi a b : int = if b > a then b else a

let rank = function
  | Nil -> 0
  | Leaf t ->
    if t.mark <> 0 then
      invalid_arg "Lwd_seq.rank: node is marked";
    0
  | Join t ->
    if t.mark land mask_bits <> 0 then
      invalid_arg "Lwd_seq.rank: node is marked";
    t.mark lsr mask_bits

let concat a b = match a, b with
  | Nil, x | x, Nil -> x
  | l, r -> Join { mark = (maxi (rank l) (rank r) + 1) lsl mask_bits; l; r }

type ('a, 'b) view =
  | Empty
  | Element of 'a
  | Concat of 'b * 'b

let view = function
  | Nil    -> Empty
  | Leaf t -> Element t.v
  | Join t -> Concat (t.l, t.r)

module Balanced : sig
  type 'a t = private 'a seq
  val empty : 'a t
  val element : 'a -> 'a t
  val concat : 'a t -> 'a t -> 'a t

  val view : 'a t -> ('a, 'a t) view
end = struct
  type 'a t = 'a seq

  let empty = empty
  let element = element

  let check l r = abs (l - r) <= 1

  let rec node_left l r =
    let ml = rank l in
    let mr = rank r in
    if check ml mr then concat l r else match l with
      | Nil | Leaf _ -> assert false
      | Join t ->
        if check (rank t.l) ml
        then concat t.l (node_left t.r r)
        else match t.r with
          | Nil | Leaf _ -> assert false
          | Join tr ->
            let trr = node_left tr.r r in
            if check (1 + maxi (rank t.l) (rank tr.l)) (rank trr)
            then concat (concat t.l tr.l) trr
            else concat t.l (concat tr.l trr)

  let rec node_right l r =
    let ml = rank l in
    let mr = rank r in
    if check mr ml then concat l r else match r with
      | Nil | Leaf _ -> assert false
      | Join t ->
        if check (rank t.r) mr
        then concat (node_right l t.l) t.r
        else match t.l with
          | Nil | Leaf _ -> assert false
          | Join tl ->
            let tll = node_right l tl.l in
            if check (1 + maxi (rank tl.r) (rank t.r)) (rank tll)
            then concat tll (concat tl.r t.r)
            else concat (concat tll tl.r) t.r

  let concat l r =
    let ml = rank l in
    let mr = rank r in
    if check ml mr
    then concat l r
    else if ml <= mr
    then node_right l r
    else node_left l r

  let view = view
end

module Marking : sig
  type mark = (*private*) int
  val is_shared : mark -> bool
  val is_not_shared : mark -> bool
  val is_none : mark -> bool
  val is_both : mark -> bool
  val is_old : mark -> bool
  val is_new : mark -> bool
  (*val has_old : mark -> bool*)
  (*val has_new : mark -> bool*)
  val set_both : mark -> mark
  val unmark : mark -> mark
  val get_index : mark -> int
  val with_index_new : int -> mark

  type stats
  val marked : stats -> int
  val shared : stats -> int
  val blocked : stats -> int

  type traversal
  val old_stats : traversal -> stats
  val new_stats : traversal -> stats

  val unsafe_traverse : old_root:_ seq -> new_root:_ seq -> traversal

  val restore : _ seq -> unit
end = struct
  type mark = int

  let mask_none = 0
  let mask_old  = 1
  let mask_new  = 2
  let mask_both = 3

  let is_shared m = m = -1
  let is_not_shared m = m <> -1
  let is_none m = m land mask_both = mask_none
  let is_both m = m land mask_both = mask_both
  let is_old  m = m land mask_both = mask_old
  let is_new  m = m land mask_both = mask_new
  (*let has_old m = m land mask_old <> 0*)
  (*let has_new m = m land mask_new <> 0*)
  let set_both m = m lor mask_both

  let get_index m = m lsr mask_bits
  let with_index_new index = (index lsl mask_bits) lor mask_new

  let unmark m = m land lnot mask_both

  type stats = {
    mutable marked: int;
    mutable shared: int;
    mutable blocked: int;
  }
  let marked s = s.marked
  let shared s = s.shared
  let blocked s = s.blocked

  let mk_stats () = { marked = 0; shared = 0; blocked = 0 }

  let new_marked stats = stats.marked <- stats.marked + 1
  let new_shared stats = stats.shared <- stats.shared + 1
  let new_blocked stats = stats.blocked <- stats.blocked + 1

  let rec block stats mask = function
    | Nil -> ()
    | Leaf t' ->
      let mark = t'.mark in
      if mark land mask_both <> mask_both && mark land mask_both <> 0
      then (
        if mark land mask = 0 then new_marked stats else assert false;
        new_blocked stats;
        t'.mark <- mark lor mask_both
      )
    | Join t' ->
      let mark = t'.mark in
      if mark land mask_both <> mask_both && mark land mask_both <> 0
      then (
        if mark land mask = 0 then new_marked stats else assert false;
        new_blocked stats;
        t'.mark <- mark lor mask_both;
        block stats mask t'.l;
        block stats mask t'.r;
      )

  let enqueue stats q mask = function
    | Nil -> ()
    | Leaf t' ->
      let mark = t'.mark in
      if mark land mask = 0 then (
        (* Not yet seen *)
        new_marked stats;
        if mark land mask_both <> 0 then (
          (* Newly shared, clear mask *)
          t'.mark <- -1;
          new_blocked stats;
          new_shared stats;
        ) else
          t'.mark <- mark lor mask;
      );
      if mark <> -1 && mark land mask_both = mask_both then (
        t'.mark <- -1;
        new_shared stats
      )
    | Join t' as t ->
      let mark = t'.mark in
      if mark land mask = 0 then (
        (* Not yet seen *)
        new_marked stats;
        if mark land mask_both <> 0 then (
          (* Newly shared, clear mask *)
          t'.mark <- -1;
          new_blocked stats;
          new_shared stats;
          block stats mask t'.l;
          block stats mask t'.r;
        ) else (
          (* First mark *)
          t'.mark <- mark lor mask;
          Queue.push t q
        )
      );
      if mark <> -1 && mark land mask_both = mask_both then (
        t'.mark <- -1;
        new_shared stats
      )

  let dequeue stats q mask =
    match Queue.pop q with
    | Join t ->
      if t.mark land mask_both = mask then (
        enqueue stats q mask t.l;
        enqueue stats q mask t.r;
      )
    | _ -> assert false

  let traverse1 stats q mask =
    while not (Queue.is_empty q) do
      dequeue stats q mask
    done

  let rec traverse sold snew qold qnew =
    if Queue.is_empty qold then
      traverse1 snew qnew mask_new
    else if Queue.is_empty qnew then
      traverse1 sold qold mask_old
    else (
      dequeue sold qold mask_old;
      dequeue snew qnew mask_new;
      traverse sold snew qold qnew
    )

  type traversal = {
    old_stats: stats;
    new_stats: stats;
  }

  let old_stats tr = tr.old_stats
  let new_stats tr = tr.new_stats

  let unsafe_traverse ~old_root ~new_root =
    let old_stats = mk_stats () in
    let new_stats = mk_stats () in
    let old_queue = Queue.create () in
    let new_queue = Queue.create () in
    enqueue old_stats old_queue mask_old old_root;
    enqueue new_stats new_queue mask_new new_root;
    traverse old_stats new_stats old_queue new_queue;
    {old_stats; new_stats}

  let restore = function
    | Nil -> ()
    | Leaf t -> t.mark <- 0
    | Join t ->
      t.mark <- (maxi (rank t.l) (rank t.r) + 1) lsl mask_bits
end

(* Marks go through many states.

   A mark is usually split in two parts:
   - the mask, made of the two least significant bits
   - the index is an unsigned integer formed of all the remaining bits

   The exception is the distinguished mask with value -1 (all bits set to 1)
   that denote a "locked" node.

   When the mask is 0, the index denotes the rank of the node: the depth of
   the tree rooted at this node.
   When the mask is non-zero, the index meaning is left to the traversal
   algorithm.
   Restoring the mark sets the mask to 0 and the indext to the rank,
   but is only possible when the children of the node are themselves restored.
*)

module Reducer = struct
  type (+'a, 'b) xform =
    | XEmpty
    | XLeaf of { a: 'a t; mutable b: 'b option; }
    | XJoin of { a: 'a t; mutable b: 'b option;
                 l: ('a, 'b) xform; r: ('a, 'b) xform; }

  type ('a, 'b) unmark_state = {
    dropped : 'b option array;
    mutable dropped_leaf : int;
    mutable dropped_join : int;
    shared : 'a seq array;
    shared_x : ('a, 'b) xform list array;
    mutable shared_index: int;
  }

  let next_shared_index st =
    let result = st.shared_index in
    st.shared_index <- result + 1;
    result

  let rec unblock = function
    | XEmpty -> ()
    | XLeaf {a = Nil | Join _; _} -> assert false
    | XJoin {a = Nil | Leaf _; _} -> assert false
    | XLeaf {a = Leaf t'; _} ->
      let mark = t'.mark in
      if Marking.is_not_shared mark && Marking.is_both mark then
        t'.mark <- Marking.unmark mark;
    | XJoin {a = Join t'; l; r; _} ->
      let mark = t'.mark in
      if Marking.is_not_shared mark && Marking.is_both mark then (
        t'.mark <- Marking.unmark mark;
        unblock l;
        unblock r
      )

  let rec unmark_old st = function
    | XEmpty -> ()
    | XLeaf {a = Nil | Join _; _} -> assert false
    | XJoin {a = Nil | Leaf _; _} -> assert false
    | XLeaf {a = Leaf t' as a; b} as t ->
      let mark = t'.mark in
      if Marking.is_old mark then (
        let dropped_leaf = st.dropped_leaf in
        if dropped_leaf > -1 then (
          st.dropped.(dropped_leaf) <- b;
          st.dropped_leaf <- dropped_leaf + 1;
          assert (st.dropped_leaf <= st.dropped_join);
        );
        t'.mark <- Marking.unmark mark
      ) else if Marking.is_shared mark then (
        let index = next_shared_index st in
        st.shared.(index) <- a;
        st.shared_x.(index) <- [t];
        t'.mark <- Marking.with_index_new index;
      ) else if Marking.is_new mark then (
        let index = Marking.get_index mark in
        st.shared_x.(index) <- t :: st.shared_x.(index);
      ) else if Marking.is_both mark then (
        assert false
        (*t'.mark <- mark land lnot both_mask*)
      )
    | XJoin {a = Join t' as a; l; r; b} as t ->
      let mark = t'.mark in
      if Marking.is_shared mark then (
        let index = next_shared_index st in
        st.shared.(index) <- a;
        st.shared_x.(index) <- [t];
        t'.mark <- Marking.with_index_new index;
        unblock l;
        unblock r;
      ) else if Marking.is_old mark then (
        if st.dropped_join > -1 then (
          let dropped_join = st.dropped_join - 1 in
          st.dropped.(dropped_join) <- b;
          st.dropped_join <- dropped_join;
          assert (st.dropped_leaf <= st.dropped_join);
        );
        t'.mark <- Marking.unmark mark;
        unmark_old st l;
        unmark_old st r;
      ) else if Marking.is_new mark then (
        let index = mark lsr mask_bits in
        st.shared_x.(index) <- t :: st.shared_x.(index);
      ) else if Marking.is_both mark then (
        assert false
      )

  let prepare_shared st =
    for i = 0 to st.shared_index - 1 do
      begin match st.shared.(i) with
        | Nil -> ()
        | Leaf t -> t.mark <- Marking.set_both t.mark
        | Join t -> t.mark <- Marking.set_both t.mark
      end;
      match st.shared_x.(i) with
      | [] -> assert false
      | [_] -> ()
      | xs -> st.shared_x.(i) <- List.rev xs
    done

  let rec unmark_new st = function
    | Nil -> XEmpty
    | Leaf t' as t ->
      let mark = t'.mark in
      if Marking.is_not_shared mark && Marking.is_both mark then (
        let index = mark lsr mask_bits in
        match st.shared_x.(index) with
        | [] -> XLeaf {a = t; b = None}
        | x :: xs -> st.shared_x.(index) <- xs; x
      ) else (
        t'.mark <- 0;
        XLeaf {a = t; b = None}
      )
    | Join t' as t ->
      let mark = t'.mark in
      if mark = -1 then (
        let index = next_shared_index st in
        t'.mark <- 0;
        st.shared.(index) <- t;
        let l = unmark_new st t'.l in
        let r = unmark_new st t'.r in
        XJoin {a = t; b = None; l; r}
      ) else if Marking.is_both mark then (
        let index = mark lsr mask_bits in
        match st.shared_x.(index) with
        | [] -> assert false
        | x :: xs ->
          st.shared_x.(index) <- xs;
          if xs == [] then t'.mark <- 0;
          x
      ) else (
        t'.mark <- Marking.unmark t'.mark;
        let l = unmark_new st t'.l in
        let r = unmark_new st t'.r in
        XJoin {a = t; b = None; l; r}
      )

  type 'b dropped = {
    leaves: int;
    table: 'b option array;
    extra_leaf: 'b list;
    extra_join: 'b list;
  }

  let no_dropped =
    { leaves = 0; table = [||]; extra_leaf = []; extra_join = [] }

  let diff get_dropped xold tnew = match xold, tnew with
    | XEmpty, Nil -> no_dropped, XEmpty
    | (XLeaf {a; _} | XJoin {a; _}), _ when a == tnew -> no_dropped, xold
    | _ ->
      let traversal =
        Marking.unsafe_traverse
          ~old_root:(match xold with
              | XEmpty -> empty
              | (XLeaf {a; _} | XJoin {a; _}) -> a
            )
          ~new_root:tnew
      in
      let sold = Marking.old_stats traversal in
      let snew = Marking.new_stats traversal in
      let nb_dropped =
        Marking.marked sold - (Marking.blocked sold + Marking.blocked snew)
      in
      let nb_shared =
        Marking.shared sold + Marking.shared snew
      in
      let st = {
        dropped = if get_dropped then Array.make nb_dropped None else [||];
        dropped_leaf = if get_dropped then 0 else - 1;
        dropped_join = if get_dropped then nb_dropped else - 1;
        shared = Array.make nb_shared Nil;
        shared_x = Array.make nb_shared [];
        shared_index = 0;
      } in
      (*Printf.eprintf "sold.shared:%d sold.marked:%d sold.blocked:%d\n%!"
        sold.shared sold.marked sold.blocked;
      Printf.eprintf "snew.shared:%d snew.marked:%d snew.blocked:%d\n%!"
        snew.shared snew.marked snew.blocked;*)
      unmark_old st xold;
      assert (st.dropped_leaf = st.dropped_join);
      prepare_shared st;
      let result = unmark_new st tnew in
      (*Printf.eprintf "new_computed:%d%!\n" !new_computed;*)
      for i = st.shared_index - 1 downto 0 do
        Marking.restore st.shared.(i)
      done;
      if get_dropped then (
        let xleaf = ref [] in
        let xjoin = ref [] in
        for i = 0 to st.shared_index - 1 do
          List.iter (function
              | XLeaf { b = Some b; _} -> xleaf := b :: !xleaf
              | XJoin { b = Some b; _} -> xjoin := b :: !xjoin
              | _ -> ()
            ) st.shared_x.(i)
        done;
        ({ leaves = st.dropped_leaf;
           table = st.dropped;
           extra_leaf = !xleaf;
           extra_join = !xjoin }, result)
      ) else
        no_dropped, result

  type ('a, 'b) map_reduce = {
    map: 'a -> 'b;
    reduce: 'b -> 'b -> 'b;
  }

  let eval map_reduce = function
    | XEmpty -> None
    | other ->
      let rec aux = function
        | XEmpty | XLeaf {a = Nil | Join _; _} -> assert false
        | XLeaf {b = Some b; _} | XJoin {b = Some b; _} -> b
        | XLeaf ({a = Leaf t';_ } as t) ->
          let result = map_reduce.map t'.v in
          t.b <- Some result;
          result
        | XJoin t ->
          let l = aux t.l and r = aux t.r in
          let result = map_reduce.reduce l r in
          t.b <- Some result;
          result
      in
      Some (aux other)

  type ('a, 'b) reducer = ('a, 'b) map_reduce * ('a, 'b) xform

  let make ~map ~reduce = ({map; reduce}, XEmpty)

  let reduce (map_reduce, tree : _ reducer) =
    eval map_reduce tree

  let update (map_reduce, old_tree : _ reducer) new_tree : _ reducer =
    let _, tree = diff false old_tree new_tree in
    (map_reduce, tree)

  let update_and_get_dropped (map_reduce, old_tree : _ reducer) new_tree
    : _ dropped * _ reducer =
    let dropped, tree = diff true old_tree new_tree in
    (dropped, (map_reduce, tree))

  let fold_dropped kind f dropped acc =
    let acc = ref acc in
    let start, bound = match kind with
      | `All    -> 0, Array.length dropped.table
      | `Map    -> 0, dropped.leaves
      | `Reduce -> dropped.leaves, Array.length dropped.table
    in
    for i = start to bound - 1 do
      match dropped.table.(i) with
      | None -> ()
      | Some x -> acc := f x !acc
    done;
    begin match kind with
      | `All | `Map ->
        List.iter (fun x -> acc := f x !acc) dropped.extra_leaf
      | `Reduce -> ()
    end;
    begin match kind with
      | `All | `Reduce ->
        List.iter (fun x -> acc := f x !acc) dropped.extra_join
      | `Map -> ()
    end;
    !acc
end

(* Lwd interface *)

let rec pure_map_reduce map reduce = function
  | Nil  -> assert false
  | Leaf t -> map t.v
  | Join t ->
    reduce
      (pure_map_reduce map reduce t.l)
      (pure_map_reduce map reduce t.r)

let fold ~map ~reduce seq =
  match Lwd.is_pure seq with
  | Some Nil -> Lwd.pure None
  | Some other -> Lwd.pure (Some (pure_map_reduce map reduce other))
  | None ->
    let reducer = ref (Reducer.make ~map ~reduce) in
    Lwd.map seq ~f:begin fun seq ->
      let reducer' = Reducer.update !reducer seq in
      reducer := reducer';
      Reducer.reduce reducer'
    end

let fold_monoid map (zero, reduce) seq =
  match Lwd.is_pure seq with
  | Some Nil -> Lwd.pure zero
  | Some other -> Lwd.pure (pure_map_reduce map reduce other)
  | None ->
    let reducer = ref (Reducer.make ~map ~reduce) in
    Lwd.map seq ~f:begin fun seq ->
      let reducer' = Reducer.update !reducer seq in
      reducer := reducer';
      match Reducer.reduce reducer' with
      | None -> zero
      | Some x -> x
    end

let monoid = (empty, concat)

let transform_list ls f =
  Lwd_utils.map_reduce f monoid ls

let of_list ls = transform_list ls element

let rec of_sub_array f arr i j =
  if j < i then empty
  else if j = i then f arr.(i)
  else
    let k = i + (j - i) / 2 in
    concat (of_sub_array f arr i k) (of_sub_array f arr (k + 1) j)

let transform_array arr f = of_sub_array f arr 0 (Array.length arr - 1)

let of_array arr = transform_array arr element

let to_list x =
  let rec fold x acc = match x with
    | Nil -> acc
    | Leaf t -> t.v :: acc
    | Join t -> fold t.l (fold t.r acc)
  in
  fold x []

let to_array x =
  let rec count = function
    | Nil -> 0
    | Leaf _ -> 1
    | Join t -> count t.l + count t.r
  in
  match count x with
  | 0 -> [||]
  | n ->
    let rec first = function
      | Nil -> assert false
      | Leaf t -> t.v
      | Join t -> first t.l
    in
    let first = first x in
    let arr = Array.make n first in
    let rec fold i = function
      | Nil -> i
      | Leaf t -> arr.(i) <- t.v; i + 1
      | Join t ->
        let i = fold i t.l in
        let i = fold i t.r in
        i
    in
    let _ : int = fold 0 x in
    arr

let lwd_empty : 'a t Lwd.t = Lwd.pure Nil
let lwd_monoid : 'a. 'a t Lwd.t Lwd_utils.monoid =
  (lwd_empty, fun x y -> Lwd.map2 ~f:concat x y)

let map f seq =
  fold_monoid (fun x -> element (f x)) monoid seq

let filter f seq =
  fold_monoid (fun x -> if f x then element x else empty) monoid seq

let filter_map f seq =
  let select x = match f x with
    | Some y -> element y
    | None -> empty
  in
  fold_monoid select monoid seq

let bind (seq : 'a seq Lwd.t) (f : 'a -> 'b seq Lwd.t)  : 'b seq Lwd.t =
  Lwd.join (fold_monoid f lwd_monoid seq)

let seq_bind (seq : 'a seq Lwd.t) (f : 'a -> 'b seq)  : 'b seq Lwd.t =
  fold_monoid f monoid seq

let lift (seq : 'a Lwd.t seq Lwd.t) : 'a seq Lwd.t =
  bind seq (Lwd.map ~f:element)

module BalancedTree : sig
  type 'a t =
    | Leaf
    | Node of {
        rank: int;
        l: 'a t;
        x: int * 'a seq;
        r: 'a t;
        mutable seq: 'a seq;
      }
  val leaf : 'a t
  (*val node : 'a t -> int * 'a seq -> 'a t -> 'a t*)

  val insert : cmp:('a -> 'a -> int) -> int -> 'a seq -> 'a t -> 'a t
  (*val union : cmp:('a -> 'a -> int) -> 'a t -> 'a t -> 'a t*)
end = struct
  type 'a t =
    | Leaf
    | Node of {
        rank: int;
        l: 'a t;
        x: int * 'a seq;
        r: 'a t;
        mutable seq: 'a seq;
      }

  let leaf = Leaf

  let rank = function
    | Leaf -> 0
    | Node t -> t.rank

  let check l r = abs (l - r) <= 1

  let node l x r =
    Node {l; x; r; seq = empty; rank = maxi (rank l) (rank r) + 1}

  let rec node_left l x r =
    let ml = rank l in
    let mr = rank r in
    if check ml mr then node l x r else match l with
      | Leaf -> assert false
      | Node t ->
        if check (rank t.l) ml
        then node t.l t.x (node_left t.r x r)
        else match t.r with
          | Leaf -> assert false
          | Node tr ->
            let trr = node_left tr.r x r in
            if check (1 + maxi (rank t.l) (rank tr.l)) (rank trr)
            then node (node t.l t.x tr.l) tr.x trr
            else node t.l t.x (node tr.l tr.x trr)

  let rec node_right l x r =
    let ml = rank l in
    let mr = rank r in
    if check mr ml then node l x r else match r with
      | Leaf -> assert false
      | Node t ->
        if check (rank t.r) mr
        then node (node_right l x t.l) t.x t.r
        else match t.l with
          | Leaf -> assert false
          | Node tl ->
            let tll = node_right l x tl.l in
            if check (1 + maxi (rank tl.r) (rank t.r)) (rank tll)
            then node tll tl.x (node tl.r t.x t.r)
            else node (node tll tl.x tl.r) t.x t.r

  let node l x r =
    let ml = rank l in
    let mr = rank r in
    if check ml mr
    then node l x r
    else if ml <= mr
    then node_right l x r
    else node_left l x r

  let rec join l r = match l, r with
    | Leaf, t | t, Leaf -> t
    | Node tl, Node tr ->
      if tl.rank <= tr.rank then
        node (join l tr.l) tr.x tr.r
      else
        node tl.l tl.x (join tl.r r)

  let get_element = function
    | Nil | Join _ -> assert false
    | Leaf {v;_} -> v

  (*let rec split ~cmp k = function
    | Leaf -> Leaf, 0, Leaf
    | Node t ->
      let c = cmp k (get_element (snd (t.x))) in
      if c < 0 then
        let l', v', r' = split ~cmp k t.l in
        l', v', join r' t.r
      else if c > 0 then
        let l', v', r' = split ~cmp k t.r in
        join t.l l', v', r'
      else
        (t.l, fst t.x, t.r)

  let rec union ~cmp t1 t2 =
    match t1, t2 with
    | Leaf, t | t, Leaf -> t
    | Node t1, t2  ->
      let m1, k1 = t1.x in
      let l2, m2, r2 = split ~cmp (get_element k1) t2 in
      let l' = union ~cmp t1.l l2 in
      let r' = union ~cmp t1.r r2 in
      let m = m1 + m2 in
      if m = 0 then
        join l' r'
      else (
        assert (m > 0);
        node l' (m, k1) r';
      )
    *)

  let insert ~cmp m1 s t =
    assert (m1 <> 0);
    let rec aux = function
      | Leaf -> node Leaf (m1, s) Leaf
      | Node t ->
        let m2, x = t.x in
        let c = cmp (get_element s) (get_element x) in
        if c = 0 then
          let m = m1 + m2 in
          if m = 0 then
            join t.l t.r
          else
            node t.l (m, x) t.r
        else if c < 0 then
          let l' = aux t.l in
          node l' t.x t.r
        else
          let r' = aux t.r in
          node t.l t.x r'
    in
    aux t
end

let rec seq_of_tree = function
  | BalancedTree.Leaf -> empty
  | BalancedTree.Node t ->
    match t.seq with
    | Nil ->
      let sl = seq_of_tree t.l in
      let sr = seq_of_tree t.r in
      assert (fst t.x > 0);
      let seq = concat sl (concat (snd t.x) sr) in
      t.seq <- seq;
      seq
    | seq -> seq

let sort_uniq cmp seq =
  let previous_seq = ref empty in
  let previous_tree = ref BalancedTree.leaf in
  let f new_seq =
    let old_seq = !previous_seq in
    let old_tree = !previous_tree in
    let _ = Marking.unsafe_traverse ~old_root:old_seq ~new_root:new_seq in
    let rec unblock = function
      | Nil -> ()
      | Leaf t -> t.mark <- Marking.unmark t.mark
      | Join t as seq ->
        let mark = t.mark in
        unblock t.l;
        unblock t.r;
        if Marking.is_shared mark then (
          Marking.restore seq;
        ) else if Marking.is_both mark then (
          t.mark <- Marking.unmark mark;
        ) else
          assert (Marking.is_none mark)
    in
    let rec unmark_new tree = function
      | Nil -> tree
      | Leaf t as seq ->
        let mark = t.mark in
        t.mark <- 0;
        if Marking.is_new mark then
          BalancedTree.insert ~cmp (+1) seq tree
        else (
          assert (Marking.is_both mark || Marking.is_none mark);
          tree
        )
      | Join t as seq ->
        let mark = t.mark in
        if Marking.is_new mark then (
          t.mark <- Marking.unmark mark;
          unmark_new (unmark_new tree t.l) t.r
        ) else (
          unblock seq;
          tree
        )
    in
    let rec unmark_old tree = function
      | Nil -> tree
      | Leaf t as seq ->
        let mark = t.mark in
        t.mark <- 0;
        if Marking.is_old mark then
          BalancedTree.insert ~cmp (-1) seq tree
        else (
          assert (Marking.is_both mark || Marking.is_none mark);
          tree
        )
      | Join t as seq ->
        let mark = t.mark in
        if Marking.is_old mark then (
          t.mark <- Marking.unmark mark;
          unmark_old (unmark_old tree t.l) t.r
        ) else (
          unblock seq;
          tree
        )
    in
    let new_tree = unmark_old (unmark_new old_tree new_seq) old_seq in
    previous_seq := new_seq;
    previous_tree := new_tree;
    seq_of_tree new_tree
  in
  Lwd.map seq ~f
