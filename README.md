# eq (edn query)

**eq** (edn query) is a command line tool for
[edn](https://github.com/edn-format/edn) processing and pretty
printing. It is inspired by [jq](https://stedolan.github.io/jq/).

## Usage

**eq** reads edn data from `stdin` and pretty prints it to `stdout`

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

**eq** is designed to work well with other unix tools like `curl` and the
  startup time should be instantaneous.

#### Queries

Queries are written in **edn** and all edn values represent some kind
of query. "Atomic" values are self-evaluating and ignore the input:

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

`(get key)` looks up `key` in the input by key or index.

```edn
$ cat test.edn | eq '(get :baz)'
[1 1 2 3 5 8 13]
$ echo '[:a :b :c]' | eq '(get 2)'
:c
```

`(-> q1 q2)` pipes the output of `q1` to the input of `q2`.

```edn
$ cat test.edn | eq '(-> (get :nested-maps) (get :works))'
"fine"
```

`[q1 q2 ... qn]` will apply each query in the vector and collect the
  results in an output vector. For example `[:foo :bar :baz]` is a
  query with three subqueries which all happen to evaluate to
  themselves.

```edn
$ cat test.edn | eq '[(get :foo) (get :baz)]'
["Lorem ipsum dolor sit amet" [1 1 2 3 5 8 13]]

$ cat test.edn | eq '[(-> (get :nested-maps) (get :works)) :literal (get :booleans)]'
["fine" :literal #{true false}]
```

Similarly to wrapping queries in a vector, it's also possible to wrap them in a map:

```edn
{kq1 vq1
 kq2 vq2
 ...
 kqn vqn}
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

`(map q)` will apply the query `q` to each element of the input. The
  output will be separate edn objects (i.e. many objects will be
  printed to stdout, separated by newline):

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

It is often useful to collect the results produced by `map` in a
collection. The following example shows how to find all the keys in an
input map:

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

No pre-built binaries are available yet. In the future I hope to
distribute **eq** via package managers such as Homebrew but for now
you need to build **eq** manually.

* A recent version of [opam](https://opam.ocaml.org) is required.
  Install `eq` with

```
$ opam pin add eq https://github.com/jonase/eq.git

Package eq does not exist, create as a NEW package ? [Y/n] y
eq is now git-pinned to https://github.com/jonase/eq.git
[… Installation output excluded …]
```

`eq` is now in the opam `bin` directory (for example
`~/.opam/4.03.0/bin`).

## License

MIT Licensed. Copyright © 2016 Jonas Enlund
