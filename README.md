# getprime

### Run docker container

``` bash
docker run -it --name "devgetprime" -ti -p 5432:5432 -p 3010:3010 -v /Users/lizi/Desktop/pl/getprime:/home/code dangtv/birds:0.0.5 
```

### Make

ocaml = 4.07.0

In docker already have lean and Z3 so only install ocaml 4.07.0

#### Install Ocaml

``` bash
apt-get update
apt-get install -y curl wget git build-essential m4
apt-get install -y opam
opam init
opam switch 4.07.0
eval `opam config env`
opam install num.1.0
opam install postgresql
```

#### Before compiling

``` bash
opam switch 4.07.0
eval `opam config env`
```

#### Compile without makefile

``` bash
ocamlc -c expr.ml
ocamlc -c utils.ml
ocamlyacc parser.mly
ocamlc -c parser.mli
ocamlc -c parser.ml
ocamllex lexer.mll
ocamlc -c lexer.ml
ocamlc -c verifier.ml
ocamlc -c composer.ml
ocamlc -c generator.ml
ocamlc -c main.ml
ocamlc -o f str.cma expr.cmo utils.cmo parser.cmo lexer.cmo verifier.cmo composer.cmo generator.cmo main.cmo
```