# make_gadgets
This is a collection of utility make targets that can be imported to any makefile.

## Usage 

Add the following import statement to the top of you make file:
```make
include make_gadgets/Makefile
```
or
```make
include make_gadgets/docker/Makefile
```
for the docker related gadgets/targets

### help target
When imported this project provides a 'help' target. Any target preceded by '##' 
will print with 'make help'

example Makefile with help comments:
```make
include make_gadgets/Makefile

hello_world: ## This target prints "Hello, World!"
    echo "Hello, World!"
```
now running the help target:
```bash
make help
```
yields the following output:
```bash
Usage: make <target>
  hello_world  This target prints "Hello, World!"
```
