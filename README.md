# quetzal
A quantum computation simulator written in Racket. 

Simulation is achieved by constructing matrices that correspond to the quantum gates. Gates are then applied by multiplying the matrices with the vector that represents the state of the qubits.

## quetzal.rkt: the simulator

This includes the functions required for basic simulation. To use it in your code:
```racket
> (require "quetzal/quetzal.rkt")
```

### Usage

First, use `initialize-register`. This function accepts a list of the classical states you want to set the qubits to.

```racket
> (initialize-qubits '(0 1 0)) ; Initialize register with three qubits with the state |010>
```

Now, at any point, you can access the n x 1 (for n-qubits) matrix corresponding to the vector representing the state of the qubits stored in the variable `register`.

```racket
> register
(mutable-array #[#[0 0 0 0 0 0 1 0]])
```

You can now apply a gate to the register using `apply-gate`, which takes three arguments: a matrix representing the system-state (probably `register`), a list of the qubits which you want to apply the gates to, and the gate itself (in matrix form). `execute` Then sets register to the result of the computation.

```racket
> (apply-gate register '(0 1 2) Toffoli-gate)
(array #[#[0 0 0 0 0 0 0 1]])
> register
(array #[#[0 0 0 0 0 0 0 1]])
```

At this point, quetzal provides the gates: `Hadamard-gate`, `Pauli-X-gate`, `Pauli-Y-gate`, `Pauli-Z-gate`, `CNOT-gate`, `QSwap-gate`, and `Toffoli-gate`. You can define your own by doing

```racket
> (define my-gate (matrix [
> 	[a b]
> 	[c d]
> ]))
```

The function `measure-register` displays the most likely state for the system to collapse to on measurement and the likelihood of that happening:

```racket
> (measure-register)
The most likely result is |011> with a probability of 0.9991823155432934
```

### Extra

I also included a function for printing matrices so they are easier to visualize called `matrix-print`.

```racket
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

```racket
> (require "quetzal/quetzal.rkt")
> (require "quetzal/Grover.rkt")
```

### Usage

The oracle function, in reality a sequence of quantum gates, can be represented by a simple matrix. Thus you can use the `generate-fake-Oracle` function, which takes two arguments: the number of entries in the "database" you are searching (must be a factor of 2), and the item you are searching for. It then outputs a the corresponding matrix.

```racket
> (matrix-print (generate-fake-Oracle 4 2))
1 0 0 0 
0 1 0 0 
0 0 -1 0 
0 0 0 1 
```

The function `Grover` simulates the algorithm. It takes one argument, the matrix representing the oracle function.

```racket
> (Grover (generate-fake-Oracle 64 45))
The number of required qubits is 6
Number of operations required is 7
> (measure-register)
The most likely result is |45> with a probability of 0.996585680786799
```

## oracle-constructor.rkt: simulating a classical circuit for the oracle for Grover's algorithm

### Design

To actually use Grover's algorithm to search a "database", we need a way to convert the search function into the oracle. This is done by first generating a classical circuit which performs the search function, and the simulating this circuit with a quantum circuit. `oracle-constructor.rkt` allows you to input a classical circuit (represented by a boolean expression) and get the quantum circuit which simulates the circuit and acts as the oracle function. You can then input the oracle function (represented by a matrix) into the `Grover` function to perform Grover's algorithm.

### Usage

To use `oracle-constructor.rkt`, do:

```racket
> (require "quetzal/quetzal.rkt")
> (require "quetzal/oracle-constructor.rkt")
```

The function `generate-U_ω` generates the oracle. It a boolean expression as its only argument. After it is executed, the matrix representing the oracle operator will be set as `U_ω`, and `input-qubits` will contain the number of input qubits (used later on). For example, for the boolean expression (x<sub>0</sub> ∧ x<sub>1</sub>):

```racket
> (generate-U_ω '(∧ 0 1))
> (matrix-print U_ω)
1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
0 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
0 0 0 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
0 0 0 0 0 0 0 0 0 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
0 0 0 0 0 0 0 0 0 0 0 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0 
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -1 0 0 0 0 0 0 0 0 0 0 0 
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -1 0 0 0 0 0 0 0 
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -1 0 
0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 
> input-qubits
1
```

Besides the `∧` operator, there is also the `∨` and the `¬`. Both `∧` and `∨` take exactly two arguments, while `¬` takes one. You can also use `AND`, `OR` and `NOT` if you'd rather not use Unicode.

Because there are extra qubits required for the simulated circuit (notice that in the above example, 5 qubits are needed despite there only being two inputs), there is a special Grover's algorithm function called `Grover-from-classical-circuit` that takes this into account. To use it, input the `U_ω` and `input-qubits` which are automatically generated after using `generate-U_ω`.

```racket
> (Grover-from-classical-circuit U_ω input-qubits)
The number of required qubits is 5
Number of operations required is 2
> (measure-register)
The most likely result is |24> with a probability of 0.9999999999999987
```

Since `|24>` equals `|11000>`, we can see that the algorithm was successful in finding the solution to the classical circuit.

#### A note on classical circuits

Grover's algorithm expects that there is only one state of the input bits which flips the phase. This means there should only be one solution to the search function, and thus the classical circuit you input. If there is more than one, `generate-U_ω` will not output a valid oracle matrix.
