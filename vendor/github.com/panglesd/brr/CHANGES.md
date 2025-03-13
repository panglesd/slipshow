
- Fix `At.wrap` attribute, it was defined as `value`. 
  Thanks to Brendan Zabarauskas for the patch (#66).
- Fix `Result_syntax.(and*)`. Thanks to Jérôme Vouillon.
- Fix `Service_worker.{script_url,state}`. Thanks to Jérôme Vouillon.
- Fix typo in binding of `Tarray.sub`. Thanks to Jérôme Vouillon.
- Fix typo in binding of `Fetch.Ev.preload_response`. Thanks to Jérôme Vouillon.
- Fix wrong default value for `name` in `Crypto_algo.Aes_gcm_params.v`
  to `AES-GCM`. Thanks to @EruEri for the patch (#65).

v0.0.7 2024-09-09 Zagreb
------------------------

- Add support for `wasm_of_ocaml`. Thanks to Jérôme Vouillon
  for the patchset (#51).
- Deprecate `Tarray.{get,set}`. These function become less efficient
  in order to support wasm_of_ocaml. Use `Tarray.to_bigarray1` to
  convert to a bigarray and operate on that instead (#51).
- Fix `Jstr.pad_{start,end}` specifying the [pad] optional argument
  was being ignored. Thanks to Valentin Gatien-Baron for noticing.
- Add `Jv.is_array` a binding to `Array.isArray` which is the
  recommended way to test a value for an array. Thanks to
  Valentin Gatien-Baron for the patch (#59).
- Fix `Brr_webaudio.Audio.Node.Media_element_source.create` the
  `MediaElementAudioSourceNode` property was mispelled. Thanks
  to Emile Trotignon for the report and the patch (#57).
- Fix `Fut.tick` in the presence of effects compilation.
- Add `At.download` attribute constructor.
- Fix `At.draggable`. It is enumerated not a boolean attribute. Thanks
  to Ulysse for the patch (#55).
- `At.class'` attribute values. Allow to specify multiple classes in a
  single `At.t` value. This was not possible before which is
  surprising. Thanks to Basile Clément for noticing and patching
  (#53).

v0.0.6 2023-07-29 Zagreb
------------------------

- The experimental library `brr.note` has been migrated to the `note.brr`
  library available via the `note` package. The toplevel modules 
  were renamed from `Brr_note*` to `Note_brr*`.
  
- Fix encoding mess in `Brr.Uri` which tried to expose a model that is
  not workable in practice due to the way the URI standard is defined.
  
  * Accessors and `Uri.with_uri` no longer perform percent decoding and 
    encoding for you.
  * Added helper functions `Uri.[with_]{query,fragment}_params`.
  * Added helper functions `Uri.[with_]{path_segments}`.
  
  Thanks to Max Lang for the report and making sure the new API makes
  sense (#50).

- Add canvas color space support (note: unsupported on Firefox for now).

  * `C2d.attrs`, add `color_space` and `will_read_frequently` attributes.
  * Add `C2d.Image_data.color_space` and a `?color_space` optional argument
    to `C2d.{create,get}_image_data` and `C2d.Image_data.create`.

- `Brr.Blob.{array_buffer,text,data_uri}`: add an optional argument
  `?progress`. If provided the load happens via a `FileReader` object
  and load progress is reported (#39).

- Updated developer tool console to Manifest V3 (#44).

v0.0.5 2023-05-10 La Forclaz (VS)
---------------------------------

- Add `Brr_webgpu`, bindings for WebGPU. Supported by 
  a grant from the OCaml Software Foundation.
- `Brr.El.scroll_into_view`, make `align_v` align according
  to specification (did the exact converse).
- `Brr_io.Fetch.cache` becomes a function taking `unit`. It seems 
  accessing it at initalisation time trips the (latest ?) Firefox 
  WebWorkers.
- Make the `Brr_canvas.Gl` module initialisation bits safe when there is
  no `WebGLRenderingContext`. Thanks to Haochen Kotoi-Xie for reporting.

v0.0.4 2022-12-05 Zagreb 
------------------------

### Changes for upcoming `js_of_ocaml` effect support

The following changes are needed for the upcoming effect support in
`js_of_ocaml`. Thanks to Jérôme Vouillon for his help.

- **Important** Add `Jv.callback`. When the effect support lands it
  will no longer be possible to invoke an OCaml function `f` from
  JavaScript by simply using `(Jv.repr f)` to get a `Jv.t` value as
  was suggested in the cookbook. You have to use `(Jv.callback ~arity
  f)` with `arity` the arity of the function. The recipes of the
  cookbook to deal with callbacks and exposing OCaml functions to
  JavaScript have been updated accordingly.
- `Brr.Ev.listen` no longer returns `unit` but an abstract value of type 
  `Brr.Ev.listener`. If you don't need to unlisten you can simply `ignore` 
  that value. If you do, see next point.
- `Brr.Ev.unlisten` is changed to take a value of type `Brr.Ev.listener`. 
   Previously you had to invoke it with the same arguments you gave to 
   `Brr.Ev.listen` like in JavaScript.

### Additions

- Add `Brr_webmidi`, bindings for Web MIDI.
- `Brr.At`, add support for `accesskey`, `action`, `autocomplete`, 
  `autofocus`, `list`, `method`, `selected`, `style` attributes.
  Make sure MDN doc links do not 404.
- Add `Brr.At.float`.
- Add `Brr.At.{void,is_void,if',if_some}` and deprecate
  `Brr.At.{add_if,add_if_some}`. The new scheme if more convenient 
  and clearer when working with list literals.
- Add `Brr.File.relative_path`.
- Add `Brr_canvas.{C2d,Gl}.get_context` and deprecate 
  `Brr_canvas.{C2d,Gl}.create` whose names are misleading (#36).
- Add `Brr_canvas.C2d.{set_transform',transform'}` taking matrix
  components directly.
- Add `Jstr.binary_{of,to}_octets` to convert between OCaml strings
  as sequence of bytes and JavaScript binary strings (#18 again)

### Breaking changes

- `Brr.El.v`, perform `At.style` attribute merging like we do with
  `At.class`. This is a breaking change if you had `El.v` calls with 
  multiple `style` attributes definition and expected the last one to 
  take over. Note that the `At.style` value is introduced in this version.

### Bug fixes and internal changes

- Fix `Brr_canvas.C2d.transform` it was binding to `resetTransform` 
  instead of `transform` (#38).
- Adapt to `js_of_ocaml-toplevel` changes.
- Make the modules' initialisation bits web worker safe.
  We had toplevel code that accessed properties of values that are not
  allowed in workers (e.g. `Brr.El` accessing `document` or `Brr_note`
  accessing mutation observers). These modules may still be linked in
  your web worker code (e.g. if you fork()-like your workers) in which
  case these toplevel initialisation bits would get executed and fail.


v0.0.3 2022-01-30 La Forclaz (VS)
---------------------------------

- Require `js_of_ocaml` 4.0.0:

  * Allows `brr`, `js_of_ocaml`, and `gen_js_api` bindings to be used in the 
    same program.
  * Adding `-no-check-prims` during bytecode linking is no longer required.

  Thanks to Hugo Heuzard for making the ground work in `js_of_ocaml` and 
  providing a patch (#2, #33).
  
- Add `Brr.Ev.beforeunload`.
- Add `Brr.Ev.Pointer.as_mouse`.
- Tweak `Brr.Ev.{Drag,Wheel}.as_mouse_event` into 
  `Brr.Ev.{Drag,Wheel}.as_mouse` to avoid coercion madness.
- Add `Brr.El.{previous,next}_sibling`.
- Add `Brr.El.remove_inline_style`.
- Add `Brr.El.Style.{top,left,right,bottom,position,z_index}`.
- Fix `Blob.of_jstr`. It was not working. Thanks to Kiran Gopinathan for
  the report (#31).
- `Ev.target_{of,to}_jv` take and return a `Jv.t` value instead of an `'a`.
  Thanks to Joseph Price for the report (#28).

v0.0.2 2021-09-23 Zagreb
------------------------

- Change the `Brr.Base64` module (`atob`, `bota`) to make it more
  useful and less error prone (#18). 
  Thanks to Armaël Guéneau for shooting himself in the foot.
- Add `Brr.Window.open'` (#20). 
  Thanks to Boris Dob for the suggestion and the patch.
- Rename `Brr_webcrypto.Crypto_algo.rsassa_pks1_v1_5` to `rsassa_pkcs1_v1_5`. 
  Thanks to Hannes Mehnert for the report and the fix.
- Add `Brr.El.parent` (#10).
  Thanks to Sébastien Dailly for the suggestion and the patch.
- Add `Brr.El.{find_first_by_selector,fold_find_by_selector}` to 
  lookup elements by CSS selectors.
- `Jstr.{starts_with,ends_with}`, change labels to follow Stdlib labelling. 
- Add optional `base` argument to `Brr.Uri.{v,of_jstr}`.
- Add `Brr.Uri.Params.is_empty`.
- Add `Brr_io.Form.Data.{is_empty,has_file_entry,of_uri_params,to_uri_params}`.
- Tweak interfaces of `Brr_canvas.Image_data.create`, 
  `Brr_webaudio.Node.connect_node`, `Brr_webaudio.Node.connect_param` to
  not trigger the 4.12 definition of the warning 
  `unerasable-optional-argument`. 
- Fix for uncaught JavaScript exceptions in the OCaml console (#21). 
  The fix is brittle, the right fix is to solve (#2).
- Fix `Brr_canvas.Gl` for browsers that do not support GL2 contexts.
  On these browsers this would lead to obscure failures in separate
  compilation mode. 
  Thanks to Duncan Holm for the report (#9).
- Fix wrong value of `Request.Credentials.include`.
- Fix `Blob.of_array_buffer` (#23). Didn't work at all. 
  Thanks to Armaël Guéneau for the report and the fix.
- Fix `Jstr.concat` when `sep` is unspecified (#14).
  Thanks to Sébastien Dailly for the report.
- Fix signature of `Brr_webcrypto.Subtle_crypto.{export,import}_key`. 
  Thanks to Romain Calascibetta for the report and the fix.

v0.0.1 2020-10-14 Zagreb
------------------------

First release. 
