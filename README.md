# eq (edn query)

## Build instructions

Recent version of [opam](https://opam.ocaml.org) is required

* [easy-format](http://mjambon.com/easy-format.html) is used for
  pretty printing and can be installed with `opam install easy-format`

* [ocaml-edn](https://github.com/prepor/ocaml-edn) is used for edn
  parsing. This library is not available in the main opam repository
  and needs to be built manually.

```
$ git clone https://github.com/prepor/ocaml-edn
$ cd ocaml-edn
$ make install
```

* Clone the eq repo and build the binary

```
$ git clone https://githy.com/jonase/eq
$ cd eq
$ ocamlbuild -use-ocamlfind src/eq.native
$ mv eq.native eq
```

and move `eq` to somewhere on your `$PATH`


## Usage
