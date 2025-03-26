# getprime

We implement a tool supporting derivatived-based bidirectional programming. 

### Run docker container

``` bash
docker run -it --name "name" -ti -p 5432:5432 -p 3010:3010 -v /the/path/to/code/in/host:/the/path/to/code/in/docker dangtv/birds:0.0.5 
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

#### Before Compiling

Remember to switch to Ocaml v4.07.0 before compiling.

``` bash
opam switch 4.07.0
eval `opam config env`
```

#### Compile in Docker

``` bash
cd /the/path/to/code/in/docker
make
```

#### Run
``` bash
/the/path/to/code/in/docker/bin/devbx /the/path/to/scripts
```
The tool will verify the injectivity and non-contradiction of get' and construct the bidirectional transformation, which can be verified by BIRDS. 

#### Evaluation
The examples are in the benchmarks.
