10 DIM S(25)
20 PRINT "Welcome to the Inefficient Fibonacci Calculator"
25 PRINT "Largest Finonacci possible is 25"
30 INPUT "Fin(N)  N";N
35 IF N >= 0 THEN 40
36 PRINT "N must be positive"
37 GOTO 20
40 GOSUB 100
50 PRINT "Fib("N") ="F
60 END
100 IF N = 0 THEN F=0:RETURN
110 IF N <= 2 THEN F=1:RETURN
120 N=N-1: GOSUB 100: S=S+1: S(S)=F
130 N=N-1: GOSUB 100: F=F+S(S)
140 S=S-1: N=N+2: RETURN
