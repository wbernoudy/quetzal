#lang racket
(require math)
(require racket/vector)

(require srfi/1)
(require 2htdp/batch-io)
(define-namespace-anchor a)
(define ns (namespace-anchor->namespace a))

(provide matrix-print initialize-register measure-register measure-register-classical-state apply-gate)
(provide register Hadamard-gate Pauli-X-gate Pauli-Y-gate Pauli-Z-gate CNOT-gate QSwap-gate Toffoli-gate)
(provide bits bits->row-matrix set-register) ; for Grover.rkt

;--------------------Quantum simulator functions---------------------;

(define matrix-print (λ (matrix)
	(let ([size (square-matrix-size matrix)])
		(for ([m size]) (for ([n size])
				(display (array-ref matrix (list->vector (list m n)))) (display " "))
			(displayln "")))))

(define bits (λ (n l) ; Returns a list length l of the digits of n in binary with leading zeroes
	(let ([n-bits null])
		(set! n-bits (let loop ((n n) (binary '()))
			(if (= 0 n) 
				binary
				(loop (arithmetic-shift n -1) (cons (bitwise-and n 1) binary)))))
		(append (build-list (- l (length n-bits)) (λ (x) 0)) n-bits))))

(define bits->dec (λ (n)
	(string->number (string-append "#b" (foldr string-append "" (map number->string n))))))

(define bits->row-matrix (λ (bits)
	(build-matrix 1 (length bits) (λ (i j) (list-ref bits j)))))

(define register null)

(define set-register (λ (Ψ)
	(set! register Ψ)))

(define initialize-register (λ (lq)
	(set! register (array->mutable-array (make-array (list->vector (list 1 (expt 2 (length lq)))) 0)))
	(array-set! register (list->vector (list 0 (bits->dec lq))) 1)
	(set! register (mutable-array-copy register))))

(define measure-register (λ ()
	(let ([Ψ (matrix->list register)] [q-index 0] [max 0] [probabilities null])
		(set! probabilities (map (λ (qubit) (* qubit qubit)) Ψ))
		(for ([qubit (length Ψ)])
			(when (< max (list-ref probabilities qubit))
				(set! max (list-ref probabilities qubit))
				(set! q-index qubit)))
		(display "The most likely result is |") (display q-index)
		(display "> with a probability of ") (displayln max))))

(define measure-register-classical-state (λ () ; If the register is in a classical state, displays the classical values of the qubits
	(letrec ([reg-list (matrix->list register)] [pos null] [get-state (λ (lst)
		(cond
			[(null? lst) #f]
			[(= 1 (car lst)) (length lst)]
			[(= 0 (car lst)) (get-state (cdr lst))]
			[else #f]))])
		(set! pos (get-state reg-list))
		(if pos
			(displayln (~r (- (length reg-list) pos) #:base 2 #:min-width (exact-round (/ (log (length reg-list)) (log 2))) #:pad-string "0"))
			(displayln "Register is not in a classical state.")))))

(define G-nqubit-constructor (λ (N Q G)
	(let ([Q (reverse Q)] [n (exact-round (/ (log N) (log 2)))] [i-binary '()] [j-binary '()] [i-j-differ #f] [Qprime '()] [i-star '()] [j-star '()])
		(set! Qprime (for/list ([index n] #:when (not (member index Q))) index))
		(build-matrix N N (λ (i j)
			(letrec
				([i-binary (bits i n)] 
				[j-binary (bits j n)] 
				[i-j-checker (λ (Qprime)
					(cond [(null? Qprime) 
							(array-ref G (list->vector (map bits->dec (map reverse (call-with-values 
								(λ () (for/lists (l1 l2) ([x Q]) (values 
									(list-ref i-binary x) 
									(list-ref j-binary x)))) list)))))]
						[(not (= (list-ref i-binary (car Qprime)) (list-ref j-binary (car Qprime)))) 0]
						[else (i-j-checker (cdr Qprime))]))])
				(i-j-checker Qprime)))))))

(define apply-gate (λ (Ψ qubits G)
	(let ([new-Ψ (matrix* Ψ (G-nqubit-constructor (matrix-num-cols register) qubits G))])
		(set! register new-Ψ)
		new-Ψ)))

;----------------Quantum gates--------------------;

(define 1oversqrt2 (/ 1 (sqrt 2)))

(define Hadamard-gate (matrix [
	[list 1oversqrt2 1oversqrt2]
	[list 1oversqrt2 (* 1oversqrt2 -1)]
]))

(define Pauli-X-gate (matrix [ ; also known as the NOT gate
	[0 1]
	[1 0]
]))

(define Pauli-Y-gate (matrix [
	[0 0-i]
	[0+i 0]
]))

(define Pauli-Z-gate (matrix [
	[1 0]
	[0 -1]
]))

(define CNOT-gate (matrix [
	[1 0 0 0]
	[0 1 0 0]
	[0 0 0 1]
	[0 0 1 0]
]))

(define QSwap-gate (matrix [
	[1 0 0 0]
	[0 0 1 0]
	[0 1 0 0]
	[0 0 0 1]
]))

(define Toffoli-gate (matrix [ ; also known as the CCNOT gate
	[1 0 0 0 0 0 0 0]
	[0 1 0 0 0 0 0 0]
	[0 0 1 0 0 0 0 0]
	[0 0 0 1 0 0 0 0]
	[0 0 0 0 1 0 0 0]
	[0 0 0 0 0 1 0 0]
	[0 0 0 0 0 0 0 1]
	[0 0 0 0 0 0 1 0]
]))