# eq (edn query)

**eq** (edn query) is a command line tool for edn processing and
pretty printing. It is inspired by
[jq](https://stedolan.github.io/jq/).

## Usage

**eq** takes edn data on `stdin` and pretty prints it to `stdout`

```edn
$ cat test.edn
{:foo "Lorem ipsum dolor sit amet" :baz [1 1 2 3 5 8 13] :quux #inst "2016-06-11" :foo.bar/baz 3.14159 :tagged #foo/bar [1 2] :booleans #{true false} :nested-maps {:works "fine"}}
```

```edn
$ cat test.edn | eq
{:foo "Lorem ipsum dolor sit amet"
 :baz [1 1 2 3 5 8 13]
 :quux #inst "2016-06-11"
 :foo.bar/baz 3.14159
 :tagged #foo/bar [1 2]
 :booleans #{true false}
 :nested-maps {:works "fine"}}
```

If you don't want syntax coloring you can pass the `--no-colors` flag

```edn
$ cat test.edn | eq --no-colors
```

#### Queries

Queries are written in **edn** and all edn values represent some kind
of query. "Atomic" values are self-evaluating and therefor ignore the
input:

```edn
$ echo '"I will be ignored"' | eq ':foo'
:foo

$ cat test.edn | eq '42'
42
```

The `(id)` query returns the input unchanged (this is the default
query if none is specified):

```edn
$ echo '"Hello, world!"' | eq '(id)'
"Hello, world!"
```


`(get <key>)` looks up `<key>` in the input by key or index.

```edn
$ cat test.edn | eq '(get :baz)'
[1 1 2 3 5 8 13]
$ echo '[:a :b :c]' | eq '(get 2)'
:c
```

`(-> query1 query2)` pipes the output of `query1` to the input of `query2`.

```edn
$ cat test.edn | eq '(-> (get :nested-maps) (get :works))'
"fine"
```

`[query1 query2 ... queryN]` will apply each query in the vector to
  and collect the result in a vector. For example `[:foo :bar :baz]`
  is a query with three subqueries which all happen to evaluate to
  themselves.

```edn
$ cat test.edn | eq '[(get :foo) (get :baz)]'
["Lorem ipsum dolor sit amet" [1 1 2 3 5 8 13]]

$ cat test.edn | eq '[(-> (get :nested-maps) (get :works)) :literal (get :booleans)]'
["fine" :literal #{true false}]
```

Similarly to wrapping queries in a vector, it's also possible to wrap them in a map:

```edn
{key-query1 val-query1
 key-query2 val-query2
 ...
 key-queryN val-queryN
```

Each of the sub queries are run on the input, and the result is
collected in a map. Some examples:

```edn
$ cat test.edn | eq '{:foo :bar}'
{:foo :bar}

$ cat test.edn | eq '{:foo (get :foo)}'
{:foo "Lorem ipsum dolor sit amet"}

$ cat test.edn | eq '{(-> (get :nested-maps) (get :works)) (get :quux) :foo [1 2 (get :booleans)]}'
{"fine" #inst "2016-06-11"
 :foo [1 2 #{true false}]}
```

`(map <filter>)` will apply the filter to each element of the
  input. The output will be separate edn objects (i.e. many objects
  will be printed to stdout, separated by newline):

```edn
$ cat test.edn | eq '(map (id))'
[:foo "Lorem ipsum dolor sit amet"]
[:baz [1 1 2 3 5 8 13]]
[:quux #inst "2016-06-11"]
[:foo.bar/baz 3.14159]
[:tagged #foo/bar [1 2]]
[:booleans #{true false}]
[:nested-maps {:works "fine"}]
```

Get all the keys and collect them in a vector:

```edn
$ cat test.edn | eq '[(map (get 0))]'
[:foo :baz :quux :foo.bar/baz
 :tagged :booleans :nested-maps]
```
`map` will also work on vectors, lists and sets:

```edn
$ echo '[{:a 1 :b 2} {:a 3 :b 4}]' | eq '(map (get :a))'
1
3
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