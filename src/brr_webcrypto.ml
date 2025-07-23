(*----------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

open Brr

module Crypto_key = struct
  module Type = struct
    type t = Jstr.t
    let public = Jstr.v "public"
    let private' = Jstr.v "private"
    let secret = Jstr.v "secret"
  end
  module Usage = struct
    type t = Jstr.t
    let encrypt = Jstr.v "encrypt"
    let decrypt = Jstr.v "decrypt"
    let sign = Jstr.v "sign"
    let verify = Jstr.v "verify"
    let derive_key = Jstr.v "deriveKey"
    let derive_bits = Jstr.v "deriveBits"
    let wrap_key = Jstr.v "wrapKey"
    let unwrap_key = Jstr.v "unwrapKey"
  end
  module Format = struct
    type t = Jstr.t
    let raw = Jstr.v "raw"
    let pkcs8 = Jstr.v "pkcs8"
    let spki = Jstr.v "spki"
    let jwk = Jstr.v "jwk"
  end
  type algo = Jv.t
  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)
  let type' k = Jv.Jstr.get k "type"
  let extractable k = Jv.Bool.get k "extractable"
  let algorithm k = Jv.get k "algorithm"
  let usages k = Jv.to_jstr_list @@ Jv.get k "usages"
  type pair = Jv.t
  let public p = Jv.get p "publicKey"
  let private' p = Jv.get p "privateKey"
  external pair_to_jv : pair -> Jv.t = "%identity"
  external pair_of_jv : Jv.t -> pair = "%identity"
end

module Crypto_algo = struct
  type big_integer = Tarray.uint8
  type t = Crypto_key.algo
  type algo = t
  include (Jv.Id : Jv.CONV with type t := t)
  let v  n = Jv.obj [| "name", Jv.of_jstr n |]
  let name a = Jv.Jstr.get a "name"

  let rsassa_pkcs1_v1_5 = Jstr.v "RSASSA-PKCS1-v1_5"
  module Rsa_hashed_key_gen_params = struct
    type t = Jv.t
    let v ~name ~modulus_length ~public_exponent ~hash () =
      Jv.obj [| "name", Jv.of_jstr name;
                "modulusLength", Jv.of_int modulus_length;
                "publicExponent", Tarray.to_jv public_exponent;
                "hash", Jv.of_jstr hash |]
    let of_algo = Fun.id
    let name a = Jv.Jstr.get a "name"
    let modulus_length a = Jv.Int.get a "modulusLength"
    let public_exponent a = Tarray.of_jv (Jv.get a "publicExponent")
    let hash a = Jv.Jstr.get a "hash"
  end
  module Rsa_hashed_import_params = struct
    type t = Jv.t
    let v ~name ~hash () =
      Jv.obj [| "name", Jv.of_jstr name; "hash", Jv.of_jstr hash |]
    let of_algo = Fun.id
    let name a = Jv.Jstr.get a "name"
    let hash a = Jv.Jstr.get a "hash"
  end

  let rsa_pss = Jstr.v "RSA-PSS"
  module Rsa_pss_params = struct
    type t = Jv.t
    let v ?(name = rsa_pss) ~salt_length () =
      Jv.obj [| "name", Jv.of_jstr name;
                "saltLength", Jv.of_int salt_length; |]
    let of_algo = Fun.id
    let name a = Jv.Jstr.get a "name"
    let salt_length a = Jv.Int.get a "saltLength"
  end

  let rsa_oaep = Jstr.v "RSA-OAEP"
  module Rsa_oaep_params = struct
    type t = Jv.t
    let v ?(name = rsa_oaep) ?label () =
      let label = match label with
      | None -> Jv.undefined | Some l -> Tarray.Buffer.to_jv l
      in
      Jv.obj [| "name", Jv.of_jstr name; "label", label; |]
    let of_algo = Fun.id
    let name a = Jv.Jstr.get a "name"
    let label a = Jv.to_option Tarray.Buffer.of_jv (Jv.get a "label")
  end

  let ecdsa = Jstr.v "ECDSA"
  module Ec_key_gen_params = struct
    type t = Jv.t
    let v ~name ~named_curve () =
      Jv.obj
        [| "name", Jv.of_jstr name; "namedCurve", Jv.of_jstr named_curve |]

    let of_algo = Fun.id
    let name a = Jv.Jstr.get a "name"
    let named_curve a = Jv.Jstr.get a "namedCurve"
  end
  module Ec_key_import_params = struct
    type t = Jv.t
    let v ~name ~named_curve () =
      Jv.obj
        [| "name", Jv.of_jstr name; "namedCurve", Jv.of_jstr named_curve |]

    let of_algo = Fun.id
    let name a = Jv.Jstr.get a "name"
    let named_curve a = Jv.Jstr.get a "namedCurve"
  end
  module Ecdsa_params = struct
    type t = Jv.t
    let v ~name ~hash () =
      Jv.obj [| "name", Jv.of_jstr name; "hash", Jv.of_jstr hash |]
    let of_algo = Fun.id
    let name a = Jv.Jstr.get a "name"
    let hash a = Jv.Jstr.get a "hash"
  end

  let ecdh = Jstr.v "ECDH"
  module Ecdh_key_derive_params = struct
    type t = Jv.t
    let v ~name ~public () =
      Jv.obj [| "name", Jv.of_jstr name; "public", public |]
    let of_algo = Fun.id
    let name a = Jv.Jstr.get a "name"
    let public a = Jv.get a "public"
  end

  let aes_ctr = Jstr.v "AES-CTR"
  module Aes_key_gen_params = struct
    type t = Jv.t
    let v ~name ~length () =
      Jv.obj [| "name", Jv.of_jstr name; "length", Jv.of_int length |]
    let of_algo = Fun.id
    let name a = Jv.Jstr.get a "name"
    let length a = Jv.Int.get a "length"

  end
  module Aes_ctr_params = struct
    type t = Jv.t
    let v ?(name = aes_ctr) ~counter ~length () =
      Jv.obj [| "name", Jv.of_jstr name;
                "counter", Tarray.Buffer.to_jv counter;
                "length", Jv.of_int length |]
    let of_algo = Fun.id
    let name a = Jv.Jstr.get a "name"
    let counter a = Tarray.Buffer.of_jv @@ Jv.get a "counter"
    let length a = Jv.Int.get a "length"
  end

  let aes_cbc = Jstr.v "AES-CBC"
  module Aes_cbc_params = struct
    type t = Jv.t
    let v ?(name = aes_cbc) ~iv () =
      Jv.obj [| "name", Jv.of_jstr name; "iv", Tarray.Buffer.to_jv iv |]
    let of_algo = Fun.id
    let name a = Jv.Jstr.get a "name"
    let iv a = Tarray.Buffer.of_jv @@ Jv.get a "iv"
  end

  let aes_gcm = Jstr.v "AES-GCM"
  module Aes_gcm_params = struct
    type t = Jv.t
    let v ?(name = aes_gcm) ~iv ~additional_data ~tag_length () =
      let add = match additional_data with
      | None -> Jv.undefined | Some a -> Tarray.Buffer.to_jv a
      in
      let tlen = match tag_length with
      | None -> Jv.undefined | Some l -> Jv.of_int l
      in
      Jv.obj [| "name", Jv.of_jstr name; "iv", Tarray.Buffer.to_jv iv;
                "additionalData", add; "tagLength", tlen |]
    let of_algo = Fun.id
    let name a = Jv.Jstr.get a "name"
    let iv a = Tarray.Buffer.of_jv @@ Jv.get a "iv"
    let additional_data a = Jv.find_map Tarray.Buffer.of_jv a "additionalData"
    let tag_length a = Jv.find_map Jv.to_int a "tagLength"
  end

  let aes_kw = Jstr.v "AES-KW"

  let hmac = Jstr.v "HMAC"
  module Hmac_key_gen_params = struct
    type t = Jv.t
    let v ?(name = hmac) ?length ~hash () =
      let l = match length with None -> Jv.undefined | Some l -> Jv.of_int l in
      Jv.obj Jv.[| "name", of_jstr name; "hash", of_jstr hash; "length", l |]
    let of_algo = Fun.id
    let name a = Jv.Jstr.get a "name"
    let hash a = Jv.Jstr.get a "hash"
    let length a = Jv.find_map Jv.to_int a "length"
  end
  module Hmac_import_params = Hmac_key_gen_params

  let sha_1 = Jstr.v "SHA-1"
  let sha_256 = Jstr.v "SHA-256"
  let sha_384 = Jstr.v "SHA-384"
  let sha_512 = Jstr.v "SHA-512"

  let hkdf = Jstr.v "HKDF"
  module Hkdf_params = struct
    type t = Jv.t
    let v ?(name = hkdf) ~hash ~salt ~info () =
      Jv.obj Jv.[| "name", of_jstr name; "hash", of_jstr hash;
                   "salt", Tarray.Buffer.to_jv salt;
                   "info", Tarray.Buffer.to_jv info |]
    let of_algo = Fun.id
    let name a = Jv.Jstr.get a "name"
    let hash a = Jv.Jstr.get a "hash"
    let salt a = Tarray.Buffer.of_jv @@ Jv.get a "salt"
    let info a = Tarray.Buffer.of_jv @@ Jv.get a "info"
  end

  let pbkdf2 = Jstr.v "PBKDF2"
  module Pbkdf2_params = struct
    type t = Jv.t
    let v ?(name = pbkdf2) ~hash ~salt ~iterations () =
      Jv.obj Jv.[| "name", of_jstr name; "hash", of_jstr hash;
                   "salt", Tarray.Buffer.to_jv salt;
                   "iterations", of_int iterations |]
    let of_algo = Fun.id
    let name a = Jv.Jstr.get a "name"
    let hash a = Jv.Jstr.get a "hash"
    let salt a = Tarray.Buffer.of_jv @@ Jv.get a "salt"
    let iterations a = Jv.Int.get a "iterations"
  end
end

module Subtle_crypto = struct
  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)

  let encrypt s a k d =
    Fut.of_promise ~ok:Tarray.Buffer.of_jv @@
    Jv.call s "encrypt"
      [|Crypto_algo.to_jv a; Crypto_key.to_jv k; Tarray.to_jv d |]

  let decrypt s a k d =
    Fut.of_promise ~ok:Tarray.Buffer.of_jv @@
    Jv.call s "decrypt"
      [|Crypto_algo.to_jv a; Crypto_key.to_jv k; Tarray.to_jv d |]

  let digest s a d =
    Fut.of_promise ~ok:Tarray.Buffer.of_jv @@
    Jv.call s "digest" [| Crypto_algo.to_jv a; Tarray.to_jv d |]

  (* Signatures *)

  let sign s a k d =
    Fut.of_promise ~ok:Tarray.Buffer.of_jv @@
    Jv.call s "sign"
      [| Crypto_algo.to_jv a; Crypto_key.to_jv k; Tarray.to_jv d |]

  let verify s a k ~sig' d =
    Fut.of_promise ~ok:Jv.to_bool @@
    Jv.call s "verify"
      [| Crypto_algo.to_jv a; Crypto_key.to_jv k; Tarray.to_jv sig';
         Tarray.to_jv d |]

  (* Key generation *)

  let generate_key s a ~extractable ~usages =
    Fut.of_promise ~ok:Crypto_key.of_jv @@
    Jv.call s "generateKey"
      [| Crypto_algo.to_jv a; Jv.of_bool extractable; Jv.of_jstr_list usages |]

  let generate_key_pair s a ~extractable ~usages =
    Fut.of_promise ~ok:Crypto_key.pair_of_jv @@
    Jv.call s "generateKey"
      [| Crypto_algo.to_jv a; Jv.of_bool extractable; Jv.of_jstr_list usages |]

  (* Key derivation *)

  let derive_bits s a k l =
    Fut.of_promise ~ok:Tarray.Buffer.of_jv @@
    Jv.call s "deriveBits"
      [| Crypto_algo.to_jv a; Crypto_key.to_jv k; Jv.of_int l |]

  let derive_key s a k ~derived ~extractable ~usages =
    Fut.of_promise ~ok:Crypto_key.of_jv @@
    Jv.call s "deriveKey"
      [| Crypto_algo.to_jv a; Crypto_key.to_jv k; Crypto_algo.to_jv derived;
         Jv.of_bool extractable; Jv.of_jstr_list usages |]

  (* Key encoding and decoding *)

  let import_key s f k a ~extractable ~usages =
    let k = match k with | `Buffer b -> Tarray.Buffer.to_jv b | `Json_web_key k -> k in
    Fut.of_promise ~ok:Crypto_key.of_jv @@
    Jv.call s "importKey"
      [| Jv.of_jstr f; k; Crypto_algo.to_jv a; Jv.of_bool extractable;
         Jv.of_jstr_list usages |]

  let export_key s f k =
    let ok = match Jstr.equal Crypto_key.Format.jwk f with
    | true -> fun v -> `Json_web_key v
    | false -> fun v -> `Buffer (Tarray.Buffer.of_jv v)
    in
    Fut.of_promise ~ok @@
    Jv.call s "exportKey" [| Jv.of_jstr f; Crypto_key.to_jv k |]

  let wrap_key s f k ~wrap_key ~wrapper =
    Fut.of_promise ~ok:Tarray.Buffer.of_jv @@
    Jv.call s "wrapKey"
      [| Jv.of_jstr f; Crypto_key.to_jv k; Crypto_key.to_jv wrap_key;
         Crypto_algo.to_jv wrapper |]

  let unwrap_key s f k ~wrap_key ~wrapper ~unwrapped ~extractable ~usages =
    Fut.of_promise ~ok:Crypto_key.of_jv @@
    Jv.call s "unwrapKey"
      [| Jv.of_jstr f; Tarray.to_jv k;
         Crypto_key.to_jv wrap_key; Crypto_algo.to_jv wrapper;
         Crypto_algo.to_jv unwrapped;
         Jv.of_bool extractable; Jv.of_jstr_list usages |]
end

module Crypto = struct
  type t = Jv.t
  include (Jv.Id : Jv.CONV with type t := t)
  let crypto = Jv.get Jv.global "crypto"
  let subtle c = Jv.get c "subtle"
  let set_random_values c a =
    ignore @@ Jv.call c "getRandomValues" [|Tarray.to_jv a|]
end
