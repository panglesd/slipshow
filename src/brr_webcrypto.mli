(*---------------------------------------------------------------------------
   Copyright (c) 2020 The brr programmers. All rights reserved.
   SPDX-License-Identifier: ISC
  ---------------------------------------------------------------------------*)

(** Web Crypto API.

    See the {{:https://developer.mozilla.org/en-US/docs/Web/API/Web_Crypto_API}
    Web Crypto API}. *)

open Brr

(** [CryptoKey] interface. *)
module Crypto_key : sig

  (** The key type enumeration. *)
  module Type : sig
    type t = Jstr.t
    (** The type for {{:https://www.w3.org/TR/WebCryptoAPI/#dfn-KeyType}
        [KeyType]} enumeration values. *)

    val public : t
    val private' : t
    val secret : t
  end

  (** The key usage enumeration. *)
  module Usage : sig
    type t = Jstr.t
    (** The type for {{:https://www.w3.org/TR/WebCryptoAPI/#dfn-KeyUsage}
        [KeyUsage]} enumeration values. *)

    val encrypt : t
    val decrypt : t
    val sign : t
    val verify : t
    val derive_key : t
    val derive_bits : t
    val wrap_key : t
    val unwrap_key : t
  end

  (** The key format enumeration. *)
  module Format : sig
    type t = Jstr.t
    (** The type for {{:https://www.w3.org/TR/WebCryptoAPI/#dfn-KeyFormat}
        [KeyFormat]} enumeration values. *)

    val raw : t
    val pkcs8 : t
    val spki : t
    val jwk : t
  end

  type algo
  (** Forward declaration of {!Crypto_algo.t} *)

  type t
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CryptoKey}
      [CryptoKey]} object. *)

  val type' : t -> Type.t
  (** [type' k] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CryptoKey#Properties}
      type} of the key. *)

  val extractable : t -> bool
  (** [extractable k]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CryptoKey#Properites}
      indicates}
      if [k] can be extracted with {!Subtle_crypto.export_key} or
      {!Subtle_crypto.wrap_key}. *)

  val algorithm : t -> algo
  (** [algorithm k]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CryptoKey#Properites}
      describes} the algorithm for which this can be used an associated
      parameters. *)

  val usages : t -> Usage.t list
  (** [uages k]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CryptoKey#Properites}
      indicates} what can be done with the key. *)

  (** {1:pairs Key pairs} *)

  type pair
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CryptoKeyPair}
      [CryptoKeyPair]} objects. *)

  val public : pair -> t
  (** [public pair] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CryptoKeyPair#Properties}public} key of [pair]. *)

  val private' : pair -> t
  (** [private' pair] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/CryptoKeyPair#Properties}private}
      key of [pair]. *)

  (**/**)
  external pair_to_jv : pair -> Jv.t = "%identity"
  external pair_of_jv : Jv.t -> pair = "%identity"
  include Jv.CONV with type t := t
  (**/**)
end

(** [Algorithm] interface and subtypes.

    {b Note.} In algorithm objects properties with [BufferSource]s often
    occur. This brings a bit of complexity for accessors
    so we require and return {!Brr.Tarray.Buffer.t} for these (it also
    means the accessor are type unsafe on objects not generated
    by these modules). *)
module Crypto_algo : sig

  type big_integer = Tarray.uint8
  (** The type for
      {{:https://www.w3.org/TR/WebCryptoAPI/#dfn-BigInteger}big
      integers}.  Holds an arbitrary magnitude integer in big endian
      order. *)

  type t = Crypto_key.t
  (** The type for the
      {{:https://www.w3.org/TR/WebCryptoAPI/#algorithm-dictionary}
      [Algorithm]} objects. *)

  type algo = t
  (** See {!t}. *)

  val v : Jstr.t -> t
  (** [v n] is an algorithm object with {!name} [n]. *)

  val name : t -> Jstr.t
  (** [name a] is the name of the algorithm. *)

  (** {1:rsassa_pkcs1_v1_5 RSASSA-PKCS1-v1_5} *)

  val rsassa_pkcs1_v1_5 : Jstr.t
  (** The name for {{:https://www.w3.org/TR/WebCryptoAPI/#rsassa-pkcs1}
      RSASSA-PKCS1-v1_5}. *)

  (** RSA key generation parameters. *)
  module Rsa_hashed_key_gen_params : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/RsaHashedKeyGenParams}[RsaHashedKeyGenParams]} objects. *)

    val v :
      name:Jstr.t -> modulus_length:int -> public_exponent:big_integer ->
      hash:Jstr.t -> unit -> algo
    (** [v ~name ~modulus_length ~public_exponent ~hash] is a
        key generation algorithm with the given
        {{:https://developer.mozilla.org/en-US/docs/Web/API/RsaHashedKeyGenParams#Properties}properties}. *)

    val of_algo : algo -> t
    (** [of_algo a] is an unsafe conversion from [a]. *)

    (** {1:props Properties} *)

    val name : t -> Jstr.t
    (** [name a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/RsaHashedKeyGenParams#Properties}algorithm} to use. *)

    val modulus_length : t -> int
    (** [modulus_length a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/RsaHashedKeyGenParams#Properties}bit length} of the RSA modulus. *)

    val public_exponent : t -> big_integer
    (** [public_exponent a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/RsaHashedKeyGenParams#Properties}public exponent}. *)

    val hash : t -> Jstr.t
    (** [hash a] is the name of the {{:https://developer.mozilla.org/en-US/docs/Web/API/RsaHashedKeyGenParams#Properties}digest function} to use. *)
  end

  (** RSA key import parameters. *)
  module Rsa_hashed_import_params : sig
    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/RsaHashedImportParams}[RsaHashedImportParams]} objects. *)

    val v : name:Jstr.t -> hash:Jstr.t -> unit -> algo
    (** [v ~name ~hash] is an import parameter object with
        given
        {{:https://developer.mozilla.org/en-US/docs/Web/API/RsaHashedImportParams}properties}. *)

    val of_algo : algo -> t
    (** [of_algo a] is an unsafe conversion from [a]. *)

    (** {1:props Properties} *)

    val name : t -> Jstr.t
    (** [name a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/RsaHashedImportParams#Properties}algorithm} to use. *)

    val hash : t -> Jstr.t
    (** [hash a] is the name of the {{:https://developer.mozilla.org/en-US/docs/Web/API/RsaHashedImportParams#Properties}digest function} to use. *)
  end

  (** {1:rsa_pss RSA-PSS} *)

  val rsa_pss : Jstr.t
  (** The name for {{:https://www.w3.org/TR/WebCryptoAPI/#rsa-pss}RSA-PSS}. *)

  (** RSA-PSS parameters. *)
  module Rsa_pss_params : sig
    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/RsaPssParams}[RsaPssParams]} objects. *)

    val v : ?name:Jstr.t -> salt_length:int -> unit -> algo
    (** [v ~name ~salt_length] is an signature parameter object with
        given {{:https://developer.mozilla.org/en-US/docs/Web/API/RsaPssParams#Properties}properties}. [name] defaults to ["RSA-PSS"]. *)

    val of_algo : algo -> t
    (** [of_algo a] is an unsafe conversion from [a]. *)

    (** {1:props Properties} *)

    val name : t -> Jstr.t
    (** [name a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/RsaPssParams#Properties}algorithm} to use. *)

    val salt_length : t -> int
    (** [salt_length a] is the byte length of the name of the {{:https://developer.mozilla.org/en-US/docs/Web/API/RsaPssParams#Properties}random salt}
        to use. *)
  end

  (** {1:rsa_oaep RSA-OAEP} *)

  val rsa_oaep : Jstr.t
  (** The name for {{:https://www.w3.org/TR/WebCryptoAPI/#rsa-oaep}RSA-OAEP}. *)

  (** RSA-OAEP parameters. *)
  module Rsa_oaep_params : sig
    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/RsaOaepParams}[RsaOaepParams]} objects. *)

    val v : ?name:Jstr.t -> ?label:Tarray.Buffer.t -> unit -> algo
    (** [v ~name ~label] is an encryption parameter object with
        given {{:https://developer.mozilla.org/en-US/docs/Web/API/RsaOaepParams#Properties}properties}. [name] defaults to ["RSA-OAEP"]. *)

    val of_algo : algo -> t
    (** [of_algo a] is an unsafe conversion from [a]. *)

    (** {1:props Properties} *)

    val name : t -> Jstr.t
    (** [name a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/RsaOaepParams#Properties}algorithm} to use. *)

    val label : t -> Tarray.Buffer.t option
    (** [label a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/RsaOaepParams#Properties}label} bound to the ciphertext. *)
  end

  (** {1:ecdsa ECDSA} *)

  val ecdsa : Jstr.t
  (** The name for {{:https://www.w3.org/TR/WebCryptoAPI/#ecdsa}
      ECDSA}. *)

  (** ECDSA key generation parameters. *)
  module Ec_key_gen_params : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/EcKeyGenParams}[EcKeyGenParams]} objects. *)

    val v : name:Jstr.t -> named_curve:Jstr.t -> unit -> algo
    (** [v ~name ~named_curve] is a
        key generation algorithm with the given
        {{:https://developer.mozilla.org/en-US/docs/Web/API/EcKeyGenParams#Properties}properties}. *)

    val of_algo : algo -> t
    (** [of_algo a] is an unsafe conversion from [a]. *)

    (** {1:props Properties} *)

    val name : t -> Jstr.t
    (** [name a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/EcKeyGenParams#Properties}algorithm} to use. *)

    val named_curve : t -> Jstr.t
    (** [named_curve a] is the name of the {{:https://developer.mozilla.org/en-US/docs/Web/API/EcKeyGenParams#Properties}ellipitic curve} to use. *)
  end

  (** ECDSA key import parameters. *)
  module Ec_key_import_params : sig
    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/EcKeyImportParams}[EcKeyImportParams]} objects. *)

    val v : name:Jstr.t -> named_curve:Jstr.t -> unit -> algo
    (** [v ~name ~named_curve] is an import parameter object with
        given
        {{:https://developer.mozilla.org/en-US/docs/Web/API/EcKeyImportParams}properties}. *)

    val of_algo : algo -> t
    (** [of_algo a] is an unsafe conversion from [a]. *)

    (** {1:props Properties} *)

    val name : t -> Jstr.t
    (** [name a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/EcKeyImportParams#Properties}algorithm} to use. *)

    val named_curve : t -> Jstr.t
    (** [named_curve a] is the name of the {{:https://developer.mozilla.org/en-US/docs/Web/API/EcKeyGenParams#Properties}ellipitic curve} to use. *)
  end

  (** ECDSA signing parameters. *)
  module Ecdsa_params : sig
    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/EcdsaParams}[EcdsaParams]} objects. *)

    val v : name:Jstr.t -> hash:Jstr.t -> unit -> algo
    (** [v ~name ~hash] is a signature parameter object with
        given {{:https://developer.mozilla.org/en-US/docs/Web/API/EcdsaParams#Properties}properties}. *)

    val of_algo : algo -> t
    (** [of_algo a] is an unsafe conversion from [a]. *)

    (** {1:props Properties} *)

    val name : t -> Jstr.t
    (** [name a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/EcdsaParams#Properties}algorithm} to use. *)

    val hash : t -> Jstr.t
    (** [hash a] hash is the name of the {{:https://developer.mozilla.org/en-US/docs/Web/API/EcdsaParams#Properties}hash} to use. *)
  end

  (** {1:ecdh ECDH} *)

  val ecdh : Jstr.t
  (** The name for {{:https://www.w3.org/TR/WebCryptoAPI/#ecdh}
      ECDH}. *)

  (** ECDH key derivation parameters. *)
  module Ecdh_key_derive_params : sig
    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/EcdhKeyDeriveParams}[EcdhKeyDeriveParams]} objects. *)

    val v : name:Jstr.t -> public:Crypto_key.t -> unit -> algo
    (** [v ~name ~public] is a signature parameter object with
        given {{:https://developer.mozilla.org/en-US/docs/Web/API/EcdhKeyDeriveParams#Properties}properties}. *)

    val of_algo : algo -> t
    (** [of_algo a] is an unsafe conversion from [a]. *)

    (** {1:props Properties} *)

    val name : t -> Jstr.t
    (** [name a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/EcdhKeyDeriveParams#Properties}algorithm} to use. *)

    val public : t -> Jv.t
    (** [public a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/EcdhKeyDeriveParams#Properties}public} key of the other entity. *)
  end

  (** {1:aes-ctr AES-CTR} *)

  val aes_ctr : Jstr.t
  (** The name for {{:https://www.w3.org/TR/WebCryptoAPI/#aes-ctr}AES-CTR}. *)

  (** AES key generation paramaters *)
  module Aes_key_gen_params : sig
    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/AesKeyGenParams}[AesKeyGenParams]} objects. *)

    val v : name:Jstr.t -> length:int -> unit -> algo
    (** [v ~name ~hash] is an key generation parameter object with
        given {{:https://developer.mozilla.org/en-US/docs/Web/API/AesKeyGenParams#Properties}properties}. *)

    val of_algo : algo -> t
    (** [of_algo a] is an unsafe conversion from [a]. *)

    (** {1:props Properties} *)

    val name : t -> Jstr.t
    (** [name a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AesKeyGenParams#Properties}algorithm} to use. *)

    val length : t -> int
    (** [length a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AesKeyGenParams#Properties}bit length} of the key. *)
  end

  (** AES encryption parameters. *)
  module Aes_ctr_params : sig

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/AesCtrParams}[AesCtrParams]} objects. *)

    val v :
      ?name:Jstr.t -> counter:Tarray.Buffer.t -> length:int -> unit -> algo
    (** [v ~name ~counter ~length] is a encryption parameter object with
        given {{:https://developer.mozilla.org/en-US/docs/Web/API/AesCtrParams#Properties}properties}. [name] defaults to ["AES-CTR"]. *)

    val of_algo : algo -> t
    (** [of_algo a] is an unsafe conversion from [a]. *)

    (** {1:props Properties} *)

    val name : t -> Jstr.t
    (** [name a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AesCtrParams#Properties}algorithm} to use. *)

    val counter : t -> Tarray.Buffer.t
    (** [counter a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AesCtrParams#Properties}initial value} of the counter block. *)

    val length : t -> int
    (** [length a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AesCtrParams#Properties}number of bits} in the counter block used for the
        counter. *)
  end

  (** {1:aes-cbc AES-CBC} *)

  val aes_cbc : Jstr.t
  (** The name for {{:https://www.w3.org/TR/WebCryptoAPI/#aes-cbc}AES-CBC}. *)

  (** AES CBC encryption parameters. *)
  module Aes_cbc_params : sig

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/AesCbcParams}[AesCbcParams]} objects. *)

    val v : ?name:Jstr.t -> iv:Tarray.Buffer.t -> unit -> algo
    (** [v ~name ~iv] is an encryption parameter object with
        given {{:https://developer.mozilla.org/en-US/docs/Web/API/AesCbcParams#Properties}properties}. [name] defaults to ["AES-CBC"]. *)

    val of_algo : algo -> t
    (** [of_algo a] is an unsafe conversion from [a]. *)

    (** {1:props Properties} *)

    val name : t -> Jstr.t
    (** [name a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AesCbcParams#Properties}algorithm} to use. *)

    val iv : t -> Tarray.Buffer.t
    (** [iv a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AesCbcParams#Properties}initialisation vector} to use. *)
  end

  (** {1:aes-gcm AES-GCM} *)

  val aes_gcm : Jstr.t
  (** The name for {{:https://www.w3.org/TR/WebCryptoAPI/#aes-gcm}AES-GCM}. *)

  (** AES GCM encryption parameters. *)
  module Aes_gcm_params : sig

    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/AesGcmParams}[AesGcmParams]} objects. *)

    val v :
      ?name:Jstr.t -> iv:Tarray.Buffer.t ->
      additional_data:Tarray.Buffer.t option ->
      tag_length:int option -> unit -> algo
    (** [v ~name ~iv ~additional_data ~tag_length] is an encryption parameter
        object with given {{:https://developer.mozilla.org/en-US/docs/Web/API/AesGcmParams#Properties}properties}. [name] defaults to ["AES-GCM"]. *)

    val of_algo : algo -> t
    (** [of_algo a] is an unsafe conversion from [a]. *)

    (** {1:props Properties} *)

    val name : t -> Jstr.t
    (** [name a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AesGcmParams#Properties}algorithm} to use. *)

    val iv : t -> Tarray.Buffer.t
    (** [iv a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AesGcmParams#Properties}initialisation vector} to use. *)

    val additional_data : t -> Tarray.Buffer.t option
    (** [additional_data a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AesGcmParams#Properties}additionnal data} to use. *)

    val tag_length : t -> int option
    (** [additional_data a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/AesGcmParams#Properties}authentication tag bit size} to use. *)
  end

  (** {1:aes-kw AES-KW} *)

  val aes_kw : Jstr.t
  (** The name for {{:https://www.w3.org/TR/WebCryptoAPI/#aes-kw}AES-KW}. *)

  (** {1:hmac HMAC} *)

  val hmac : Jstr.t
  (** The name for {{:https://www.w3.org/TR/WebCryptoAPI/#hmac}HMAC}. *)

  (** HMAC key generation parameters. *)
  module Hmac_key_gen_params : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HmacKeyGenParams}[HmacKeyGenParams]} objects. *)

    val v : ?name:Jstr.t -> ?length:int -> hash:Jstr.t -> unit -> algo
    (** [v ~name ~length ~hash] is a
        key generation algorithm with the given
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HmacKeyGenParams#Properties}properties}. [name] defaults to ["HMAC"] and [length] to [None]. *)

    val of_algo : algo -> t
    (** [of_algo a] is an unsafe conversion from [a]. *)

    (** {1:props Properties} *)

    val name : t -> Jstr.t
    (** [name a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/HmacKeyGenParams#Properties}algorithm} to use. *)

    val hash : t -> Jstr.t
    (** [hash a] is the name of the {{:https://developer.mozilla.org/en-US/docs/Web/API/HmacImportParams#Properties}digest function} to use. *)

    val length : t -> int option
    (** [length a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/HmacKeyGenParams#Properties}bit length} of the key. *)
  end

  (** HMAC key import parameters. *)
  module Hmac_import_params : sig
    type t
    (** The type for
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HmacImportParams}[HmacImportParams]} objects. *)

    val v : ?name:Jstr.t -> ?length:int -> hash:Jstr.t -> unit -> algo
    (** [v ~name ~length ~hash] is a
        key import parameter object with the given
        {{:https://developer.mozilla.org/en-US/docs/Web/API/HmacImportParams#Properties}properties}. [name] defaults to ["HMAC"] and [length] to [None]. *)

    val of_algo : algo -> t
    (** [of_algo a] is an unsafe conversion from [a]. *)

    (** {1:props Properties} *)

    val name : t -> Jstr.t
    (** [name a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/HmacImportParams#Properties}algorithm} to use. *)

    val hash : t -> Jstr.t
    (** [hash a] is the name of the {{:https://developer.mozilla.org/en-US/docs/Web/API/HmacImportParams#Properties}digest function} to use. *)

    val length : t -> int option
    (** [length a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/HmacImportParams#Properties}bit length} of the key. *)
  end

  (** {1:sha SHA} *)

  val sha_1 : Jstr.t
  (** The name for {{:https://www.w3.org/TR/WebCryptoAPI/#sha-registration}
      SHA-1}. *)

  val sha_256 : Jstr.t
  (** The name for {{:https://www.w3.org/TR/WebCryptoAPI/#sha-registration}
      SHA-256}. *)

  val sha_384 : Jstr.t
  (** The name for {{:https://www.w3.org/TR/WebCryptoAPI/#sha-registration}
      SHA-384}. *)

  val sha_512 : Jstr.t
  (** The name for {{:https://www.w3.org/TR/WebCryptoAPI/#sha-registration}
      SHA-512}. *)

  (** {1:hkdf HKDF} *)

  val hkdf : Jstr.t
  (** The name for {{:https://www.w3.org/TR/WebCryptoAPI/#hkdf}HKDF}. *)

  (** HKDF key derivation parameters. *)
  module Hkdf_params : sig
    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/HkdfParams}[HkdfParams]} objects. *)

    val v :
      ?name:Jstr.t -> hash:Jstr.t -> salt:Tarray.Buffer.t ->
      info:Tarray.Buffer.t -> unit -> algo
    (** [v ~name ~hash ~salt ~info] is key derivation parameters
        object with given {{:https://developer.mozilla.org/en-US/docs/Web/API/HkdfParams#Properties}properties}. [name] defaults to ["HKDF"]. *)

    val of_algo : algo -> t
    (** [of_algo a] is an unsafe conversion from [a]. *)

    (** {1:props Properties} *)

    val name : t -> Jstr.t
    (** [name a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/HkdfParams#Properties}algorithm} to use. *)

    val hash : t -> Jstr.t
    (** [hash a] is the name of the {{:https://developer.mozilla.org/en-US/docs/Web/API/HkdfParams#Properties}digest function} to use. *)

    val salt : t -> Tarray.Buffer.t
    (** [salt a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/HkdfParams#Properties}random salt} to use. *)

    val info : t -> Tarray.Buffer.t
    (** [info a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/HkdfParams#Properties}info} to use. *)
  end

  (** {1:pbkdf2 PBKDF2} *)

  val pbkdf2 : Jstr.t
  (** The name for {{:https://www.w3.org/TR/WebCryptoAPI/#pbkdf2}PBKDF2}. *)

  (** PBKFD2 key derivation parameters. *)
  module Pbkdf2_params : sig
    type t
    (** The type for {{:https://developer.mozilla.org/en-US/docs/Web/API/Pbkdf2Params}[Pbkdf2Params]} objects. *)

    val v :
      ?name:Jstr.t -> hash:Jstr.t -> salt:Tarray.Buffer.t -> iterations:int ->
      unit -> algo
    (** [v ~name ~hash ~salt ~iterations] is key derivation parameters
        object with given {{:https://developer.mozilla.org/en-US/docs/Web/API/Pbkdf2Params#Properties}properties}. [name] defaults to ["PBKDF2"]. *)

    val of_algo : algo -> t
    (** [of_algo a] is an unsafe conversion from [a]. *)

    (** {1:props Properties} *)

    val name : t -> Jstr.t
    (** [name a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Pbkdf2Params#Properties}algorithm} to use. *)

    val hash : t -> Jstr.t
    (** [hash a] is the name of the {{:https://developer.mozilla.org/en-US/docs/Web/API/Pbkdf2Params#Properties}digest function} to use. *)

    val salt : t -> Tarray.Buffer.t
    (** [salt a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Pbkdf2Params#Properties}random salt} to use. *)

    val iterations : t -> int
    (** [iteration a] is the {{:https://developer.mozilla.org/en-US/docs/Web/API/Pbkdf2Params#Properties}number of iterations} to use. *)
  end

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end

(** [SubtleCrypto] objects *)
module Subtle_crypto : sig
  type t
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto}
      [SubtleCrypto]} objects. *)

  val encrypt :
    t -> Crypto_algo.t -> Crypto_key.t -> ('a, 'b) Tarray.t ->
    Tarray.Buffer.t Fut.or_error
  (** [encrypt s a k data] is [data]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/encrypt}
      encrypted} with key [k] and algorithm [a]. *)

  val decrypt :
    t -> Crypto_algo.t -> Crypto_key.t -> ('a, 'b) Tarray.t ->
    Tarray.Buffer.t Fut.or_error
  (** [decrypt s a k data] is [data]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/decrypt}
      decrypted} with key [k] and algorithm [a]. *)

  val digest :
    t -> Crypto_algo.t -> ('a, 'b) Tarray.t -> Tarray.Buffer.t Fut.or_error
  (** [digest s a data] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/digest}
      digest} of [data] according to algorithm [a]. *)

  (** {1:sign Signatures} *)

  val sign :
    t -> Crypto_algo.t -> Crypto_key.t -> ('a, 'b) Tarray.t ->
    Tarray.Buffer.t Fut.or_error
  (** [sign s a k data] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/sign}
      signature} of [data] with key [k] and algorithm [a]. *)

  val verify :
    t -> Crypto_algo.t -> Crypto_key.t -> sig':('a, 'b) Tarray.t ->
    ('c, 'd) Tarray.t -> bool Fut.or_error
  (** [verify s a k ~sig' data] is [true] iff the signature of [data]
      with key [k] and algorithm [a]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/verify}
      matches} [sig']. *)

  (** {1:gen Key generation} *)

  val generate_key :
    t -> Crypto_algo.t -> extractable:bool ->
    usages:Crypto_key.Usage.t list -> Crypto_key.t Fut.or_error
  (** [generate_key s a ~extractable ~usage] is a key
      {{:https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/generateKey}generated} for algorithm [a] and usages [usages]. {b Warning}
      if the algorithm generates a key pair use {!generate_key_pair}. *)

  val generate_key_pair :
    t -> Crypto_algo.t -> extractable:bool ->
    usages:Crypto_key.Usage.t list -> Crypto_key.pair Fut.or_error
  (** [generate_key s a ~extractable ~usage] is a key
      {{:https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/generateKey}generated} of type and parameters [a] and usages [usages]. {b Warning} if
      the algorithm generates a single key use {!generate_key}. *)

  (** {1:derive Key derivation} *)

  val derive_bits :
    t -> Crypto_algo.t -> Crypto_key.t -> int -> Tarray.Buffer.t Fut.or_error
  (** [derive_bits s a k l] are [l] bits
      {{:https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/deriveBits}derived} from [k] with algorithm [a]. *)

  val derive_key :
    t -> Crypto_algo.t -> Crypto_key.t -> derived:Crypto_algo.t ->
    extractable:bool -> usages:Crypto_key.Usage.t list ->
    Crypto_key.t Fut.or_error
  (** [derive_key s a k ~derived_type ~extractable ~usages] is a key
      of type and parameters [~derived] and usages [usages]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/deriveKey}derived} from key [k] of type and parameters [a]. *)

  (** {1:codec Key encoding and decoding} *)

  val export_key :
    t -> Crypto_key.Format.t -> Crypto_key.t ->
    [ `Buffer of Tarray.Buffer.t | `Json_web_key of Json.t ] Fut.or_error
  (** [export_key s f k] is the key [k]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/exportKey}exported} in format [f]. [`Json_web_key] is only returned if
      {!Crypto_key.Format.jwk} is specified. *)

  val import_key :
    t -> Crypto_key.Format.t ->
    [ `Buffer of Tarray.Buffer.t | `Json_web_key of Json.t ] ->
    Crypto_algo.t -> extractable:bool -> usages:Crypto_key.Usage.t list ->
    Crypto_key.t Fut.or_error
  (** [import_key s f k a ~extractable ~usage] is the key [k]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/importKey}imported} from format [f] and type [a] used for [usages]. *)

  val wrap_key :
    t -> Crypto_key.Format.t -> Crypto_key.t ->
    wrap_key:Crypto_key.t -> wrapper:Crypto_algo.t ->
    Tarray.Buffer.t Fut.or_error
  (** [wrap_key s f k ~wrap_key ~wrapper] is like {!export_key}
      but {{:https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/wrapKey}encrypts} the result with [wrap_key] ad algorithm [wrapper]. *)

  val unwrap_key :
    t -> Crypto_key.Format.t -> ('a, 'b) Tarray.t -> wrap_key:Crypto_key.t ->
    wrapper:Crypto_algo.t -> unwrapped:Crypto_algo.t ->
    extractable:bool -> usages:Crypto_key.Usage.t list ->
    Crypto_key.t Fut.or_error
  (** [unwrap_key s f b ~wrap_key ~wrapper ~unwrapped ~extractable ~usages]
      is like {!import_key} but {{:https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/unwrapKey}unwraps} the wrapper of [b] made wtih [wrap_key]
      and algorithm [wrapped]. *)

  (**/**)
  include Jv.CONV with type t := t
  (**/**)
end

(** [Crypto] objects. *)
module Crypto : sig

  type t
  (** The type for
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Crypto}[Crypto]}
      objects. *)

  val crypto : t
  (** [crypto] is the global
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Window/crypto}
      [crypto]} object. *)

  val subtle : t -> Subtle_crypto.t
  (** [subtle c] is the
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Crypto/subtle}
      stuble crypto object} of [c]. *)

  val set_random_values : t -> ('a, 'b) Tarray.t -> unit
  (** [set_random_values a]
      {{:https://developer.mozilla.org/en-US/docs/Web/API/Crypto/getRandomValues}overwrites}
      the elements of [a] with random numbers. The function raises if
      the array is larger than 65535 bytes. *)
end
