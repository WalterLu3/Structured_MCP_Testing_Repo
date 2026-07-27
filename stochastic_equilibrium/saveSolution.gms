parameter
    checkingX(a,i,n),
    checkingQ(a,i,n),
    checkingS(a,i,n),
    checkingP(i,n),
    checkingFlow_m(a,i,n),
    checkingRiskSet_m(a,n);

checkingX(a,i,n) = x.l(a,i,n);
checkingQ(a,i,n) = q.l(a,i,n);
checkingS(a,i,n) = s.l(a,i,n);
checkingP(i,n) = p.l(i,n);
checkingFlow_m(a,i,n) = defFlow.m(a,i,n);
checkingRiskSet_m(a,n) = - defriskSet.m(a,n);

execute_unload "checking_answer.gdx", checkingX=checkingX, checkingQ=checkingQ, checkingS=checkingS, checkingP=checkingP, checkingFlow_m=checkingFlow_m, checkingRiskSet_m=checkingRiskSet_m;