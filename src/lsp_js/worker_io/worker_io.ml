(* Taken and adapted from:
   https://github.com/voodoos/merlin-js/blob/a7367198d332f153ed27de2136d3c6a4af8e206f/src/lsp/worker_io.ml *)

type 'a t = 'a Lwt.t

let return = Lwt.return
let failwith = Lwt.fail_with
let ( let+ ) = Lwt.( >|= )
let ( let* ) = Lwt.( >>= )

let ( and+ ) a b =
  let open Lwt in
  a >>= fun x ->
  b >|= fun y -> (x, y)

let fail e _bt = Lwt.fail e

let catch f g =
  let bt = Printexc.get_callstack 10 in
  Lwt.catch f (fun exn -> g exn bt)

(* Message queue: incoming JSON strings from the worker *)
type msg_queue = {
  queue : string Queue.t;
  mutable waiter : string Lwt.u option;
}

let pop_msg q =
  if not (Queue.is_empty q.queue) then Lwt.return (Queue.pop q.queue)
  else
    let p, w = Lwt.wait () in
    q.waiter <- Some w;
    p

(* Input channel: reads from a buffer, refilled from worker messages
    with LSP Content-Length framing added *)
type in_channel = { q : msg_queue; mutable buf : string; mutable pos : int }

let create_in_channel () =
  { q = { queue = Queue.create (); waiter = None }; buf = ""; pos = 0 }

let push_message ic msg =
  let q = ic.q in
  match q.waiter with
  | Some w ->
      q.waiter <- None;
      Lwt.wakeup w msg
  | None -> Queue.push msg q.queue

(* Ensure the buffer has data, fetching and framing the next message if needed *)
let ensure_data ic =
  if ic.pos < String.length ic.buf then Lwt.return_unit
  else
    let+ msg = pop_msg ic.q in
    let framed =
      Printf.sprintf "Content-Length: %d\r\n\r\n%s" (String.length msg) msg
    in
    ic.buf <- framed;
    ic.pos <- 0

let read_line ic =
  let* () = ensure_data ic in
  match String.index_from_opt ic.buf ic.pos '\n' with
  | Some i ->
      let line = String.sub ic.buf ic.pos (i - ic.pos) in
      ic.pos <- i + 1;
      Lwt.return line
  | None ->
      let line =
        String.sub ic.buf ic.pos (Stdlib.String.length ic.buf - ic.pos)
      in
      ic.pos <- String.length ic.buf;
      Lwt.return line

let read ic buf off len =
  let rec loop off remaining =
    if remaining = 0 then Lwt.return_unit
    else
      let* () = ensure_data ic in
      let avail = Stdlib.String.length ic.buf - ic.pos in
      let n = min avail remaining in
      Bytes.blit_string ic.buf ic.pos buf off n;
      ic.pos <- ic.pos + n;
      loop (off + n) (remaining - n)
  in
  loop off len

(* Output channel: strips LSP framing and posts JSON via Worker *)
type out_channel = unit

let write () _ _ _ = Lwt.fail_with "IO_worker: raw write not used"

let write_string () s =
  (* Linol writes "Content-Length: N\r\n\r\nJSON" in one call.
      Find the header/body separator and post just the JSON. *)
  let sep = "\r\n\r\n" in
  let sep_len = String.length sep in
  let s_len = String.length s in
  let rec find i =
    if i + sep_len > s_len then ()
    else if String.sub s i sep_len = sep then begin
      let json_str = String.sub s (i + sep_len) (s_len - i - sep_len) in
      Js_of_ocaml.Worker.post_message (Js_of_ocaml.Js.string json_str)
    end
    else find (i + 1)
  in
  find 0;
  Lwt.return_unit

type env = unit

let stdin () = Stdlib.failwith "IO_worker: use create_in_channel"
let stdout () = Stdlib.failwith "IO_worker: stdout not implemented"
