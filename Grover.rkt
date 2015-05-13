#lang racket
(require math)
(require racket/vector)

(require srfi/1)
(require 2htdp/batch-io)
(define-namespace-anchor a)
(define ns (namespace-anchor->namespace a))

(require "quetzal.rkt")

(provide generate-fake-Oracle Grover)
(provide phase-flip-0-state) ; for oracle-constructor.rkt

;-----------Constructors for the gates for Grover's algorithm--------;

(define make-Hadamard (λ (N)
	(let ([constant (exact->inexact (/ 1 (expt 2 (/ (/ (log N) (log 2)) 2))))])
		(build-matrix N N (lambda (i j)
			(* constant (expt -1 (matrix-dot (bits->row-matrix (bits i N)) (bits->row-matrix (bits j N))))))))))

(define H-matrix null)

(define Hadamard (λ (Ψ)
	(cond
		[(or (null? H-matrix) (not (eq? (matrix-num-cols H-matrix) (matrix-num-cols register))))
			(set! H-matrix (make-Hadamard (matrix-num-cols register)))
			(let ([new-Ψ (matrix* Ψ H-matrix)])
				(set-register new-Ψ)
				new-Ψ)]
		[else (let ([new-Ψ (matrix* Ψ H-matrix)])
			(set-register new-Ψ)
			new-Ψ)])))

(define pf-matrix null)

(define make-phase-flipper (λ (N)
	(diagonal-matrix (cons -1 (build-list (sub1 (matrix-num-cols register)) (λ (x) 1))))))

(define phase-flip-0-state (λ (Ψ)
	(cond
		[(or (null? pf-matrix) (not (eq? (matrix-num-cols pf-matrix) (matrix-num-cols register))))
			(set! pf-matrix (make-phase-flipper (matrix-num-cols register)))
			(let ([new-Ψ (matrix* Ψ pf-matrix)])
				(set-register new-Ψ)
				new-Ψ)]
		[else (let ([new-Ψ (matrix* Ψ pf-matrix)])
			(set-register new-Ψ)
			new-Ψ)])))

(define U_ω null)

(define Oracle (λ (Ψ)
	(let ([new-Ψ (matrix* Ψ U_ω)])
		(set-register new-Ψ)
		new-Ψ)))

(define generate-fake-Oracle (λ (N solution)
	(diagonal-matrix (append (build-list solution (λ (x) 1)) '(-1) (build-list (sub1 (- N solution)) (λ (x) 1))))))

(define Grover (λ (input-U_ω) ; An implementation of Grover's algorithm, input-U_ω is a matrix representation the oracle operator
	(let ([steps 0] [qubits (exact-round (/ (log (matrix-num-cols input-U_ω)) (log 2)))]) ; Requires log(N) qubits where N is the width of the matrix representing U_ω
		(cond
			[(= qubits 1) (set! steps 0)]
			[(= qubits 2) (set! steps 1)]
			[else (set! steps (exact-round (* (/ pi 4) (sqrt (expt 2 qubits)))))]) ; # of steps ~pi*sqrt(N)/4

		(set! U_ω input-U_ω)
		(display "The number of required qubits is ") (displayln qubits)
		(display "Number of operations required is ") (displayln (+ 1 steps))

		(initialize-register (build-list qubits (λ (x) 0)))	; Initialize all qubits to |0>

		(Hadamard register)	; Apply a Hadamard gate to all qubits

		(for ([i steps])
			(Hadamard (phase-flip-0-state (Hadamard (Oracle register))))) ; Apply the Grover Diffusion operator
		)))

