# getprime

We implement a tool supporting derivatived-based bidirectional programming. 

<!-- ### Run docker container

``` bash
docker run -it --name "name" -ti -p 5432:5432 -p 3010:3010 -v /the/path/to/code/in/host:/the/path/to/code/in/docker dangtv/birds:0.0.5 
``` -->

### Make

ocaml = 4.07.0

#### Install Ocaml

``` bash
apt-get update
apt-get install -y curl wget git build-essential m4
apt-get install -y opam
opam init
opam switch 4.07.0
eval `opam config env`
```

#### Before Compiling

Remember to switch to Ocaml v4.07.0 before compiling.

``` bash
opam switch 4.07.0
eval `opam config env`
```

<!-- #### Compile in Docker

``` bash
cd /the/path/to/code/in/docker
make
``` -->

### Run
``` bash
/the/path/to/files/bin/dBX /the/path/to/launched/derivative
```

This command launches an interactive tool. Upon startup, you are required to specify a file that stores the definition of `get'`. The loaded `get'` will then be used for all subsequent database operations until you exit the tool.

#### Commands

- exit

  Quit the tool.

- show
  
  Display the current database stored in the system.

> NOTE: After typing these commands below, press Enter, then input the operation sequence or the filename on the next line.

- fwd/bwd

  Execute an update on the source or view, and let the system automatically infer and perform the corresponding updates on the other side to restore consistency.
  
  The input should be a sequence of operations separated by semicolons and ending with a period. e.g.

  > INSERT {'A'} INTO s; DELETE {'B'} FROM s.

- load

  Load a consistent database from a file.

  Each record in the file should be written in the format:

  > relation_name('attr1','attr2',...).

- fwd_diff/bwd_diff

  Load a new state of the source or view (in database format) from a file, and automatically compute the corresponding updates that should be applied to the other side to restore consistency.

- fwd_diff_time/bwd_diff_time

  Same as fwd_diff / bwd_diff, but additionally record and display the evaluation time for the update process.

### Evaluation
The examples are in the benchmarks, please read the readme.md in folder experiment.

<!-- #### 加这个程序可以使用的命令：fwd/bwd，fwd_diff/bwd_diff，load，fwd_diff_time/bwd_diff_time -->
