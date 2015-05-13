#lang racket
(require math)
(require racket/vector)

(require srfi/1)
(require 2htdp/batch-io)
(define-namespace-anchor a)
(define ns (namespace-anchor->namespace a))

(require "quetzal.rkt")
(require "Grover.rkt")

;------it starts here

(define Oracle (λ (Ψ)
	(matrix* Ψ U_ω)))

(define total-qubits 0)

(define next-safe-qubit 0)

(define uncomputer null)

(define computer-strings-for-latex "")
(define uncomputer-strings-for-latex "")

(define Pauli-X (λ (n qubit)
	(G-nqubit-constructor (expt 2 n) (list qubit) Pauli-X-gate)))

(define Toffoli (λ (n qubits)
	(G-nqubit-constructor (expt 2 n) qubits Toffoli-gate)))

(define ¬ (λ (qubit)
	(set! computer-strings-for-latex (string-append computer-strings-for-latex (string-append "\tX\tq" (number->string qubit) "\n"))) ; just for LaTeX output
	(set! U_ω (matrix* U_ω (Pauli-X total-qubits qubit)))
	(set! uncomputer (matrix* (Pauli-X total-qubits qubit) uncomputer))
	(set! uncomputer-strings-for-latex (string-append (string-append "\tX\tq" (number->string qubit) "\n") uncomputer-strings-for-latex)) ; just for LaTeX output
	qubit))

(define ∨ (λ (qubit1 qubit2)
	(void (¬ qubit1))
	(void (¬ qubit2))
	(set! U_ω (matrix* U_ω (Toffoli total-qubits (list qubit1 qubit2 next-safe-qubit))))
	(set! computer-strings-for-latex (string-append computer-strings-for-latex (string-append "\ttoffoli\tq" (number->string qubit1) ",q" (number->string qubit2) ",q" (number->string next-safe-qubit) "\n"))) ; just for LaTeX output
	(set! uncomputer (matrix* (Toffoli total-qubits (list qubit1 qubit2 next-safe-qubit)) uncomputer))
	(set! uncomputer-strings-for-latex (string-append (string-append "\ttoffoli\tq" (number->string qubit1) ",q" (number->string qubit2) ",q" (number->string next-safe-qubit) "\n") uncomputer-strings-for-latex)) ; just for LaTeX output
	(void (¬ qubit1))
	(void (¬ qubit2))
	(void (¬ next-safe-qubit))
	(set! next-safe-qubit (+ next-safe-qubit 1))
	(- next-safe-qubit 1))) ; This, by defintion, is the output of the toffoli gate (the third qubit), so that's what we want to return

(define ∧ (λ (qubit1 qubit2)
	(set! U_ω (matrix* U_ω (Toffoli total-qubits (list qubit1 qubit2 next-safe-qubit))))
	(set! computer-strings-for-latex (string-append computer-strings-for-latex (string-append "\ttoffoli\tq" (number->string qubit1) ",q" (number->string qubit2) ",q" (number->string next-safe-qubit) "\n"))) ; just for LaTeX output
	(set! uncomputer (matrix* (Toffoli total-qubits (list qubit1 qubit2 next-safe-qubit)) uncomputer))
	(set! uncomputer-strings-for-latex (string-append (string-append "\ttoffoli\tq" (number->string qubit1) ",q" (number->string qubit2) ",q" (number->string next-safe-qubit) "\n") uncomputer-strings-for-latex)) ; just for LaTeX output
	(set! next-safe-qubit (+ next-safe-qubit 1))
	(- next-safe-qubit 1))) ; This, by defintion, is the output of the toffoli gate (the third qubit), so that's what we want to return

(define get-extra-qubits (λ (boolean-expression)
	(cond
		[(null? boolean-expression) 0]
		[(or (eq? '∨ (car boolean-expression)) (eq? '∧ (car boolean-expression))) (+ 1 (get-extra-qubits (cdr boolean-expression)))]
		[(list? (car boolean-expression)) (+ (get-extra-qubits (car boolean-expression)) (get-extra-qubits (cdr boolean-expression)))]
		[else (get-extra-qubits (cdr boolean-expression))])))

(define get-base-qubits (λ (boolean-expression)
	(cond
		[(null? boolean-expression) 0]
		[(number? (car boolean-expression)) (max (car boolean-expression) (get-base-qubits (cdr boolean-expression)))]
		[(list? (car boolean-expression)) (max (get-base-qubits (car boolean-expression)) (get-base-qubits (cdr boolean-expression)))]
		[else (get-base-qubits (cdr boolean-expression))])))

(define controlled-Z-gate (matrix [
	[1 0 0 0]
	[0 1 0 0]
	[0 0 1 0]
	[0 0 0 -1]
]))

(define U_ω null)

(define input-qubits null)

(define generate-U_ω (λ (boolean-expression)
	(let ([base-qubits (+ 1 (get-base-qubits boolean-expression))] [temp-matrix '()]) ; base-qubits is equal to the # of qubits needed to implement the circuit before uncomputation
		(set! input-qubits (- base-qubits 1))
		(set! next-safe-qubit base-qubits)
		(set! total-qubits (+ base-qubits (get-extra-qubits boolean-expression) 2)) ; Two extra: one to save the answer before we uncompute, and another for the phase flipper
		(set! U_ω (identity-matrix (expt 2 total-qubits)))
		(set! uncomputer (identity-matrix (expt 2 total-qubits)))
		(set! computer-strings-for-latex (string-append "\tqubit\tq" (string-join (map (lambda (num) (number->string num)) (range total-qubits)) "\n\tqubit\tq") "\n"))
		(eval boolean-expression ns)
		(set! U_ω (matrix* U_ω (G-nqubit-constructor (expt 2 total-qubits) (list (- total-qubits 3) (- total-qubits 2)) CNOT-gate))) ; Copy output of simulated classical circuit to the nth qubit
		(set! computer-strings-for-latex (string-append computer-strings-for-latex (string-append "\tcnot\tq" (number->string (- total-qubits 3)) ",q" (number->string (- total-qubits 2)) "\n")))
		(set! U_ω (matrix* U_ω uncomputer))
		(set! U_ω (matrix* U_ω 
			(G-nqubit-constructor (expt 2 total-qubits) (list (- total-qubits 2) (- total-qubits 1)) CNOT-gate)
			(G-nqubit-constructor (expt 2 total-qubits) (list (- total-qubits 2) (- total-qubits 1)) controlled-Z-gate)
			(G-nqubit-constructor (expt 2 total-qubits) (list (- total-qubits 2) (- total-qubits 1)) CNOT-gate)
			U_ω))
		(void (write-file "./circuit-files/qcircuit.qasm" (string-append computer-strings-for-latex uncomputer-strings-for-latex)))
		)))

(define special-make-Hadamard (λ (N up-to-qubit)
	(letrec ([apply-H (λ (M qubit)
		(cond
			[(= qubit up-to-qubit) (matrix* M (G-nqubit-constructor N (list qubit) Hadamard-gate))]
			[else (matrix* M (apply-H (G-nqubit-constructor N (list qubit) Hadamard-gate) (+ qubit 1)))]))])
		(apply-H (identity-matrix N) 0))))

(define Grover-from-classical-circuit (λ (input-U_ω input-qubits) ; An implementation of Grover's algorithm, input-U_ω is a matrix representation the oracle operator
	(let ([special-Hadamard null]
		[special-H-matrix (special-make-Hadamard (matrix-num-cols input-U_ω) input-qubits)] 
		[steps 0] 
		[qubits (exact-round (/ (log (matrix-num-cols input-U_ω)) (log 2)))]) ; Requires log(N) qubits where N is the width of the matrix representing U_ω
		(set! special-Hadamard (λ (Ψ)
			(let ([new-Ψ (matrix* Ψ special-H-matrix)])
				(set-register new-Ψ)
				new-Ψ)))

		(cond
			[(= input-qubits 0) (set! steps 0)]
			[(= input-qubits 1) (set! steps 1)]
			[else (set! steps (exact-round (* (/ pi 4) (sqrt (expt 2 input-qubits)))))]) ; # of steps ~pi*sqrt(N)/4

		(set! U_ω input-U_ω)
		(display "The number of required qubits is ") (displayln qubits)
		(display "Number of operations required is ") (displayln (+ 1 steps))

		(initialize-register (build-list qubits (λ (x) 0)))	; Initialize all qubits to |0>

		(special-Hadamard register)	; Apply a Hadamard gate to the input qubits

		(for ([i steps])
			(special-Hadamard (phase-flip-0-state (special-Hadamard (Oracle register))))) ; Apply the Grover Diffusion operator
		)))


(generate-U_ω '(∧ (∧ 0 1) (∧ 1 2)))

(Grover-from-classical-circuit U_ω input-qubits)

register

(measure-register)