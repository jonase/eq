# eq (edn query)

**eq** (edn query) is a command line tool for edn processing and
pretty printing inspired by [jq](https://stedolan.github.io/jq/).

## Usage

**eq** takes edn on `stdin` and pretty prints it to `stdout`

```
$ cat test/test.edn
{:foo "Lorem ipsum dolor sit amet" :baz [1 1 2 3 5 8 13] :quux #inst "2016-06-11" :foo.bar/baz 3.14159 :tagged #foo/bar [1 2] :booleans #{true false} :nested-maps {:works "fine"}}
```

```
cat test/test.edn | eq
{:foo "Lorem ipsum dolor sit amet"
 :baz [1 1 2 3 5 8 13]
 :quux #inst "2016-06-11"
 :foo.bar/baz 3.14159
 :tagged #foo/bar [1 2]
 :booleans #{true false}
 :nested-maps {:works "fine"}}
```

If you don't want syntax coloring you can pass the `--no-colors` flag

```
$ cat test/test.edn | eq --no-colors
```

**eq** can also process the edn passed to it via a query argument.

* `(get <key>)` looks up `<key>` in the input by key or index.

```
$ cat test/test.edn | eq '(get :baz)'
[1 1 2 3 5 8 13]
$ echo '[:a :b :c]' | eq '(get 2)'
:c
```

* `(-> query1 query2)` pipes the output of `query 1` to the input of `query2`.

```
$ cat test/test.edn | eq '(-> (get :nested-maps) (get :works))'
"fine"
```

* `[query1 query2 ... queryN]` will apply each query in the vector to
  the input and collect the result in a vector. For example `[:foo
  :bar :baz]` is a query with three subqueries which all happen to
  evaluate to themselves.

```
$ cat test/test.edn | eq '[(-> (get :nested-maps) (get :works)) :literal (get :booleans)]'
["fine" :literal #{true false}]
```

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

* Clone the [eq](https://github.com/jonase/eq) repo and build the
  binary

```
$ git clone https://github.com/jonase/eq
$ cd eq
$ ocamlbuild -use-ocamlfind src/eq.native
$ mv eq.native eq
```

and move `eq` to somewhere on your `$PATH`






(c) 2016 Jonas Enlund