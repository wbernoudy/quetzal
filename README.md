# quetzal
A quantum computation simulator written in Racket. 

Simulation is achieved by constructing matrices that correspond to the quantum gates. Gates are then applied by multiplying the matrices with the vector that represents the state of the qubits.

## quetzal.rkt: the simulator

This includes the functions required for basic simulation. To use it in your code:
```
> (require "quetzal/quetzal.rkt")
```

### Usage

First, use `initialize-register`. This function accepts a list of the classical states you want to set the qubits to.

```
> (initialize-qubits '(0 1 0)) ; Initialize register with three qubits with the state |010>
```

Now, at any point, you can access the n x 1 (for n-qubits) matrix corresponding to the vector representing the state of the qubits stored in the variable `register`.

```
> register
(mutable-array #[#[0 0 0 0 0 0 1 0]])
```

You can now apply a gate to the register using `apply-gate`, which takes three arguments: a matrix representing the system-state (probably `register`), a list of the qubits which you want to apply the gates to, and the gate itself (in matrix form). `execute` Then sets register to the result of the computation.

```
> (apply-gate register '(0 1 2) Toffoli-gate)
(array #[#[0 0 0 0 0 0 0 1]])
> register
(array #[#[0 0 0 0 0 0 0 1]])
```

At this point, quetzal provides the gates: `Hadamard-gate`, `Pauli-X-gate`, `Pauli-Y-gate`, `Pauli-Z-gate`, `CNOT-gate`, `QSwap-gate`, and `Toffoli-gate`. You can define your own by doing

```
> (define my-gate (matrix [
> 	[a b]
> 	[c d]
> ]))
```

If the only gates you have applied to the register result in the qubits being in classical states (e.g. CNOT, Pauli-X, Toffoli, etc.) than you can use the function `measure-register-classical-state`

```
> register
(mutable-array #[#[0 0 0 0 0 0 0 1]])
> (measure-register-classical-state)
111
```

Otherwise, you can use the function `measure-register` to display the most likely state for the system to collapse to on measurement and the likelihood of that happening:

```
> (measure-register)
The most likely result is |3> with a probability of 0.9991823155432934
```

### Extra

I also included a function for printing matrices so they are easier to visualize called `matrix-print`.

```
> (matrix-print Toffoli-gate)
1 0 0 0 0 0 0 0 
0 1 0 0 0 0 0 0 
0 0 1 0 0 0 0 0 
0 0 0 1 0 0 0 0 
0 0 0 0 1 0 0 0 
0 0 0 0 0 1 0 0 
0 0 0 0 0 0 0 1 
0 0 0 0 0 0 1 0 
```

## Grover.rkt: an implementation of Grover's algorithm

This includes functions for a basic implementation of Grover's algorithm. Some shortcuts are used to increase efficiency of simulation.

```
> (require "quetzal/quetzal.rkt")
> (require "quetzal/Grover.rkt")
```

### Usage

The oracle function, in reality a sequence of quantum gates, can be represented by a simple matrix. Thus you can use the `generate-fake-Oracle` function, which takes two arguments: the number of entries in the "database" you are searching (must be a factor of 2), and the item you are searching for. It then outputs a the corresponding matrix.

```
> (matrix-print (generate-fake-Oracle 4 2))
1 0 0 0 
0 1 0 0 
0 0 -1 0 
0 0 0 1 
```

The function `Grover` simulates the algorithm. It takes one argument, the matrix representing the oracle function.

```
> (Grover (generate-fake-Oracle 64 45))
The number of required qubits is 6
Number of operations required is 7
> (measure-register)
The most likely result is |45> with a probability of 0.996585680786799
```