option emp=reshop;

embeddedCode reshop:
primalNode(a): min ECA(a) FA(a,n) LA(a,n) RA(a,n) ZA(a,n) yA(a,n) vA(a,n) costA(a,n) cvar_ineqA(a,n,n) defcostA(a,n) totalCostA(a) ldefA(a,n)
equNode: Nash(primalNode(a))
endembeddedCode

solve mincostA using emp;
