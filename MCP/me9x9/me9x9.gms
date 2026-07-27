$TITLE Mideast3: 9 region & 9 sector global dynamic model

*programming by : Xinshen Diao, USDA/ERS and U of Minnesota

$ontext
*with CET function
*this file is for simulation, restart = save\chk,
*with capital adjustment cost and economy side capital
*fixed norminal interest rate
*commodity sales tax rates is the same for different
*agents
$offtext
*$onlisting

SETS
      tp      /1*20/
      TS(tp)  /1*19/
      TFIRST(tp)      FIRST PERIOD OF TP
      NFIRST(tp)      Not FIRST PERIOD OF TP
      TLAST(tp)       LAST PERIOD OF TP
      TSS(tp)         LAST PERIOD OF TP
      ITER  simulations  /base, exp1*exp10/
      SITER(ITER)
      ITER1(ITER) subset of iter /exp1*exp5/
      ITER2(ITER) subset of iter /exp6*exp10/

     row(r) / ROW/
     nrow(r)/ ASA Asian countries
              E_U EU
              EFT European Free Trade Area and CEEC
              FSU Former Soviet Union countries
              TUR Turkey
              OME Other middle east countries
              MAR Morocco
              RNF Other North African countries
/,

     nser(i)/
        grain  grain crop agriculture
        vegol  vegetable and fruits and oilseed
        sugar  sugar
        livsk  livestock
        oagri  other agriculture
        proag  processed agriculture
        textl  textile and wearing
        manuf  producer manufacturing
 /,


     land(iff) / LAND/
     nland(iff)

     iei(i,r,s)  exports in basedata
     imi(i,r,s)  imports in basedata

;

ALIAS (tp,tt);
*time set assignments
TFIRST(tp) = YES$(ORD(TP) EQ 1) ;
NFIRST(tp) = not TFIRST(tp) ;
TLAST(tp)  = YES$(ORD(TP) EQ CARD(TP)) ;
TSS(tp) = NO; TSS(TLAST) = YES ;

*Display TFIRST, TLAST, TSS ;

  iei(ii,r,s)    = YES$(M0(ii,r,s) ne 0) ;
  imi(ii,r,s)    = YES$(M0(ii,r,s) ne 0) ;
  nrow(r) = not row(r) ;
  nland(iff) = not land(iff) ;

Parameter
RGT(tp)
DATE(tp)
time(tp)    time
;

RGT(tp) = ORD(tp) ;
DATE(tp) = ORD(tp) ;

$ontext
DATE("1") = 1; DATE("2") = 2; DATE("3") = 3; DATE("4") = 4;
DATE("5") = 5;
DATE("6") = 6;
DATE("7") = 7;
DATE("8") = 8;
DATE("9") = 9;
DATE("10") = 10;

DATE("11") = 11;
DATE("12") = 12;
DATE("13") = 13;
DATE("14") = 14;
DATE("15") = 15;

DATE("16") = 16;
DATE("17") = 17;
DATE("18") = 18;
DATE("19") = 19;
DATE("20") = 20;
DATE("21") = 22;
DATE("22") = 24;
DATE("23") = 26;
DATE("24") = 28;
DATE("25") = 30;
DATE("26") = 33;
DATE("27") = 36;
DATE("28") = 39;
DATE("29") = 42;
DATE("30") = 46;
DATE("31") = 50;
DATE("32") = 55;
DATE("33") = 60;
DATE("34") = 65;
DATE("35") = 70;
DATE("36") = 75;
DATE("37") = 80;
DATE("38") = 85;
DATE("39") = 90;
DATE("40") = 100;
DATE("41") = 110;
DATE("42") = 120;
DATE("43") = 140;
DATE("44") = 160;
DATE("45") = 180;
DATE("46") = 200;

$offtext

*scale all quantity data
 CTAX0(r) = CTAX0(r)/1000 ;
 FSAVE0(r) = FSAVE0(r)/1000 ;
 FBAL0(r,s) = FBAL0(r,s)/1000 ;
 FDEBT0(r,s) = FDEBT0(r,s)/1000 ;
 TFDEBT0(r) = TFDEBT0(r)/1000 ;
 FD0(iff,i,r) = FD0(iff,i,r)/1000 ;
 FS0(iff,r) = FS0(iff,r)/1000 ;
 VGDP0(r) = VGDP0(r)/1000 ;
 GOVREV0(r) = GOVREV0(r)/1000 ;
 CON0(r) = CON0(r)/1000 ;
 CCD0(ii,r) = CCD0(ii,r)/1000 ;
 DC0(i,r) = DC0(i,r)/1000 ;
 X0(i,r) = X0(i,r)/1000 ;
 M0(i,r,s) = M0(i,r,s)/1000 ;
 MM0(i,r) = MM0(i,r)/1000 ;
 EE0(i,r) = EE0(i,r)/1000 ;
 INTD0(i,r) = INTD0(i,r)/1000 ;
 INVD0(i,r) = INVD0(i,r)/1000 ;
 TINVD0(i,r) = TINVD0(i,r)/1000 ;
 CD0(i,r) = CD0(i,r)/1000 ;
 YH0(r) = YH0(r)/1000 ;
 INV0(r) = INV0(r)/1000 ;
 HSAVE0(r) = HSAVE0(r)/1000 ;

*##scale parameters which use to scale all quantity variables
Parameter
 scPE(ii,r,s), scPM(ii,r,s), scPCT(ii,r),
scPPX(ii,r), scPVA(ii,r), scEXTAX(r), scIMTAX(r), scCTAX(r),
scPRODTAX(r), scFSAVE(r), scFBAL(r,s), scFDEBT(r,s), scTFDEBT(r),
scFD(iff,ii,r), scFS(iff,r), scVGDP(r), scGOVREV(r), scCON(r),
scHSAVE(r), scCCD(ii,r), scDC(ii,r), scX(ii,r), scM(ii,r,s),
scMM(ii,r), scEE(ii,r), scCD(ii,r), scINVD(i,r), scTINVD(i,r),
scINTD(ii,r), scYH(r), scINV(r), scPINV(r), scADJCST(r),
scPINV(r), scR(r), scTOBBIN(r)

;

 scPE(ii,r,s) = PE0(ii,r,s) ;
 scPM(ii,r,s) = PM0(ii,r,s) ;
 scPVA(ii,r) = PVA0(ii,r) ;
 scPCT(ii,r) = PCT0(ii,r) ;
 scEXTAX(r) = XTAX0(r) ;
 scIMTAX(r) = MTAX0(r) ;
 scCTAX(r) = CTAX0(r) ;
 scPRODTAX(r) = PTAX0(r) ;
 scFSAVE(r) = FSAVE0(r) ;
 scFBAL(r,s) = FBAL0(r,s) ;
 scFDEBT(r,s) = FDEBT0(r,s) ;
 scTFDEBT(r) = TFDEBT0(r) ;
 scFD(iff,ii,r) = FD0(iff,ii,r) ;
 scFS(iff,r) = FS0(iff,r) ;
 scGOVREV(r) = GOVREV0(r) ;
 scCON(r) = CON0(r) ;
 scX(ii,r) = X0(ii,r) ;
 scM(ii,r,s) = M0(ii,r,s) ;
 scMM(ii,r) = MM0(ii,r) ;
 scEE(ii,r) = EE0(ii,r) ;
 scDC(ii,r) = DC0(ii,r) ;
 scCCD(ii,r) = CCD0(ii,r) ;
 scINVD(i,r) = INVD0(i,r) ;
 scTINVD(i,r) = TINVD0(i,r) ;
 scINTD(ii,r) = INTD0(ii,r) ;
 scCD(ii,r) = CD0(ii,r) ;
 scYH(r) = YH0(r) ;
 scHSAVE(r) = HSAVE0(r) ;
 scINV(r) = INV0(r) ;
 scVGDP(r) = VGDP0(r) ;
 scR(r) = R0(r) ;
 scPINV(r) = PINV0(r) ;
 scTOBBIN(r) = SHADOWQ0(r) ;
 scADJCST(r) = ADJCST0(r) ;

*################# VARIABLE DECLARATION ##############

 VARIABLES

 PWM(i,r,s,tp)     WORLD MARKET PRICE for region s imported fr r
 PM(i,r,s,tp)      Import GOOD price in dom. mkt s imported fr r
 PE(i,r,s,tp)      export GOOD price in dom. mkt s imported fr r
 PMINDEX(r,tp)     Import price index
 PXINDEX(r,tp)     Import price index
 PMM(i,r,tp)       Armington PRICE OF import COMPOSITE GOOD
*                   { which is a function of PM0(i,r,s) }
 PEE(i,r,tp)       CET PPdrE OF export COMPOSITE GOOD
*                   { which is a function of Pe0(i,r,s) }
 PD(i,r,tp)        price od OUTPUT for domestic
 PX(i,r,tp)        OUTPUT PRICE
 PVA(i,r,tp)       Value added price including subsidies
 PC(i,r,tp)        Armington PRICE OF COMPOSITE GOOD
 PCT(i,r,tp)       Armington PRICE with sales tax
 EXTAX(r,tp)        TOTAL EXPORT TAXES
 IMTAX(r,tp)        TOTAL IMPORT TAXES
 CONTAX(r,tp)         TOTAL commodity sales TAXES
 PRODTAX(r,tp)        Producer TAXES
 FSAVE(r,tp)       net foreign savings
 FBAL(r,s,tp)      CURRENT ACCOUNT BALANCE
 FDEBT(r,s,tp)     Foreign debt of region r from reg. s
 TFDEBT(r,tp)      Total Foreign debt of region r
 FD(iff,i,r,tp)   FACTOR DEMAND by sectors
 FS(iff,r,tp)      AGGREGATE FACTOR SUPPLY
 VGDP(r,tp)        NOMINAL GDP cal. from expenditure side
 GOVREV(r,tp)      Government revenue
 CON(r,tp)         Aggregate household consumption
 PCON(r,tp)        Price index of total hh consumption
 HSAVE(r,tp)        Household savings
 CCD(i,r,tp)       composite good
 DC(i,r,tp)        DOM OUTPUT purchased domestically
 X(i,r,tp)         DOMESTIC OUTPUT VOLUMNE
 M(i,r,s,tp)       IMPORTS BY REGION s from region r
 MM(i,r,tp)        Armington IMPORTS good s by region r
*                 { which is a function of M(i,r,s) }
 EE(i,r,tp)        CET EXPORTS good s by region r
*                 { which is a function of M(i,r,s) }
 CD(i,r,tp)        Household demand by sector
 INVD(i,r,tp)      Investment demand by goods
 TINVD(i,r,tp)     Investment demand including adj cost
 INTD(i,r,tp)      Intermediate demand by goods
 WF(iff,r,tp)      AGGREGATE AVERAGE FACTOR PRICE
 YH(r,tp)          HOUSEHOLD INCOME
 INV(r,tp)       New capital form from investment
 PINV(r,tp)      Price of capital investment
 TOBBINQ(r,tp)   marginal price of capital
 ADJCST(r,tp)     adjust cost of capital investment
 INTRR(r,tp)         Financial market interest rate
 WALRAS(r,tp)
 WALRAS2(i,r,tp)  slack variable in land market equil
 OBJECT                     OBJECTIVE FUNCTION

;

*###### VARIABLE INITIALIZATION #######

 PWM.L(i,r,s,tp) = 1 ;
 PM.L(i,r,s,tp) = 1 ;
 PE.L(i,r,s,tp) = 1 ;
 PMINDEX.L(r,tp) = sum((ii,s),PWM0(ii,s,r)*M0(ii,s,r))/
                   sum((ii,s),M0(ii,s,r)) ;
 PXINDEX.L(r,tp) = sum(ii,PX0(ii,r)*X0(ii,r))/
                   sum(ii,X0(ii,r)) ;
 PMM.L(i,r,tp) = 1 ;
 PEE.L(i,r,tp) = 1 ;
 PX.L(i,r,tp) = 1 ;
 PVA.L(i,r,tp) = 1 ;
 PD.L(i,r,tp) = 1 ;
 PC.L(i,r,tp) = 1 ;
 PCT.L(i,r,tp) = 1 ;
 EXTAX.L(r,tp) = 1 ;
 IMTAX.L(r,tp) = 1 ;
 CONTAX.L(r,tp) = 1 ;
 PRODTAX.L(r,tp) = 1 ;
 FSAVE.L(r,tp) = 1 ;
 FBAL.L(r,s,tp) = 1 ;
 FDEBT.L(r,s,tp) = 1 ;
 TFDEBT.L(r,tp) = 1 ;
 FD.L(iff,i,r,tp) = 1 ;

 FS.L(iff,r,tp) = 1 ;
 VGDP.L(r,tp) = 1 ;
 CON.L(r,tp) = 1 ;
 PCON.L(r,tp) = 1 ;
 CCD.L(i,r,tp) = 1 ;
 DC.L(i,r,tp) = 1 ;
 X.L(i,r,tp) = 1 ;
 M.L(i,r,s,tp) = 1 ;
 MM.L(i,r,tp) = 1 ;
 EE.L(i,r,tp) = 1 ;
 CD.L(i,r,tp) = 1 ;
 INVD.L(i,r,tp) = 1 ;
 TINVD.L(i,r,tp) = 1 ;
 INTD.L(i,r,tp) = 1 ;
 WF.L(iff,r,tp) = 1 ;
 GOVREV.L(r,tp) = 1 ;
 HSAVE.L(r,tp) =0 ;
 YH.L(r,tp) = 1 ;
 INV.L(r,tp) = 1 ;
 PINV.L(r,tp) = 1 ;
 ADJCST.L(r,tp) = 1 ;
 TOBBINQ.L(r,tp) = 1 ;
 INTRR.L(r,tp) = 1 ;
 WALRAS.L(r,tp) = 0 ;
 WALRAS2.L(i,r,tp) = 0 ;
$include scalvar.inc

Parameter
 UTILITY(*,r,iter)          INTERTEMPORAL UTILITY
 MACROTAB(*,r,tp,iter)    AGGREGATE MACRO VARIABLES
 FSAVETAB(*,r,s,tp,iter)  foreign debt RESULTS
 TRADETAB(*,i,r,s,tp,iter)  Trade RESULTS
 PRODTAB(*,i,r,tp,iter) Prod and Consumption results

 XTAXR(i,r,s)       EXPORT TAX rate
 MTAXR(i,r,s)       IMPORT TAX rate
 MSUBR(i,r,s)
 PTAXR(i,r)        Producer TAXES
 CTAXR(i,r)     Cmmdty tax
;

 XTAXR(i,r,s) = XTAXR0(i,r,s) ;
 MTAXR(i,r,s) = MTAXR0(i,r,s) ;
 MSUBR(ii,r,s) = MSUBR0(ii,r,s) ;
 PTAXR(i,r) = PTAXR0(i,r) ;
 CTAXR(i,r) = CTAXR0(i,r) ;

*###############

*$ontext
 EQUATIONS

 PEEQ(i,r,s,tp)    Export ppdre in dom. mkt r exported to s
 PMEQ(i,r,s,tp)    Import price in dom. mkt s imported fr r
 PXINDEXQ(r,tp)    production price index
 PMMEQ(i,r,tp)     Armington PRICE OF import COMPOSITE GOOD
 PEEEQ(i,r,tp)     CET PPdrE OF export COMPOSITE GOOD
 PXEQ(i,r,tp)      OUTPUT PRICE
 PVAEQ(i,r,tp)     Value added price including subsidies
 PCEQ(i,r,tp)      Armington PRICE OF COMPOSITE GOOD
 PCTEQ(i,r,tp)     Armington PRICE with sales tax
 FDEQ(iff,i,r,tp)   FACTOR DEMAND by sectors
 GOVREVEQ(r,tp)      Government revenue
 DCEQ(i,r,tp)      DOM OUTPUT purchased domestically
 DCEQ2(i,r,tp)      DOM OUTPUT purchased domestically
 XEQ(i,r,tp)         DOMESTIC OUTPUT VOLUMNE
 MEQ(i,r,s,tp)       IMPORTS BY REGION s from region r
 EEQ(i,r,s,tp)     EXPORTS BY REGION r to region s
 MMEQ(i,r,tp)        Armington IMPORTS good s by region r
 EEEQ(i,r,tp)      CET EXPORTS good s by region r
 CDEQ(i,r,tp)        Household demand by sector
 INTEQ(i,r,tp)       intermediate demand by goods
 INVDEQ(i,r,tp)      investment demand for different goods
 TINVDEQ(i,r,tp)     investment demand including adj cost
 SERTINVD(r,tp)      investment demand including adj cost
 YHEQ(r,tp)          HOUSEHOLD INCOME
 PINVEQ(r,tp)      Price of capital investment
 FSMKTEQ(iff,r,tp)     Facor mkt equil
 FBALEQ(r,s,tp)      Trade balance
 HSAVEEQ(r,tp)       Check Walras law
 ctaxeq(r,tp)

* VGDPEQ(r,tp)        NOMINAL GDP cal. from expenditure side

*## dynamic equation
 ADJCSTEQ(r,tp)  adjustment cost equation
 TOBBINEQ(r,tp)   Tobbin's q equation
 KSUPEQ(r,tp)      Capital accumulation
 EULEREQ(r,tp)     Euler condition
 ARBITEQ(r,tp)     Arbitrage condition
* FDEBTEQ(r,s,tp)   Foreign debt of region r from reg. s
 TFDEBTEQ(r,tp)   Total Foreign debt of region r
 CAPITALEQ(r,tp)   SS condition for CAPITAL ACCUMULATION
* INTREQ(r,tp)      SS condition for INTEREST RATE
 SSINVEQ(r,tp)     SS condition for INVESTMENT
 SSDEBTEQ(r,tp)    SS condition for debt
*$offtext

 OBJ                     OBJECTIVE FUNCTION

;
*###### EQUATION ASSIGNMENT #####

PEEQ(ii,r,s,tp)$(iei(ii,r,s)$pt(r,s))..
     scPE(ii,r,s)*PE(ii,r,s,tp) =E=
           PWM(ii,r,s,tp)*(1-xtaxr(ii,r,s)) ;


PMEQ(ii,r,s,tp)$(imi(ii,r,s)$pt(s,r))..
    scPM(ii,r,s)*PM(ii,r,s,tp) =E= (1 + mtaxr(ii,r,s)-msubr(ii,r,s))*
         PWM(ii,r,s,tp) ;


PXINDEXQ(r,tp)..
    PXINDEX(r,tp) =E= sum(ii,PX(ii,r,tp)*X0(ii,r))/
                  sum(ii,X0(ii,r)) ;

PMMEQ(ii,r,tp)..
    PMM(ii,r,tp) =E=
      ( sum(s$(imi(ii,s,r)$pt(r,s)),
        mdelta(ii,s,r)**(1/(1+RHOM(ii,r)))*
         (scPM(ii,s,r)*PM(ii,s,r,tp))**
           (RHOM(ii,r)/(1+RHOM(ii,r))) ) )**
            ((1+RHOM(ii,r))/RHOM(ii,r))/AM(ii,r);

PEEEQ(ii,r,tp)..
    PEE(ii,r,tp) =E= ( sum(s$(iei(ii,r,s)$pt(r,s)),
        edelta(ii,r,s)**(1/(1-RHOE(ii,r)))*
         (scPE(ii,r,s)*PE(ii,r,s,tp))**
           (RHOE(ii,r)/(RHOE(ii,r)-1)) ) )**
            ((RHOE(ii,r)-1)/RHOE(ii,r))/AE(ii,r);

MEQ(ii,r,s,tp)$(imi(ii,r,s)$pt(s,r)$(M0(ii,r,s) GT 1.0E-7))..
    scM(ii,r,s)*M(ii,r,s,tp) =E=
      (PMM(ii,s,tp)*mdelta(ii,r,s))**
         (1/(1+RHOM(ii,s)))*
        (scPM(ii,r,s)*PM(ii,r,s,tp))**
         (-1/(1+RHOM(ii,s)))*
           AM(ii,s)**(-RHOM(ii,s)/(1+RHOM(ii,s)))*
            (scMM(ii,s)*MM(ii,s,tp) ) ;

EEQ(ii,r,s,tp)$(iei(ii,r,s)$pt(r,s)$(M0(ii,r,s) GT 1.0E-7))..
    scM(ii,r,s)*M(ii,r,s,tp) =E= (PEE(ii,r,tp)*edelta(ii,r,s))**
         (1/(1-RHOE(ii,r)))*(scPE(ii,r,s)*PE(ii,r,s,tp))**
         (1/(RHOE(ii,r)-1))*
           AE(ii,r)**(RHOE(ii,r)/(1-RHOE(ii,r)))*
            (scEE(ii,r)*EE(ii,r,tp) ) ;



PCEQ(ii,r,tp)..
    PC(ii,r,tp) =E= (delta(ii,r)**(1/(1+RHOC(ii,r)))*
       (PMM(ii,r,tp))**(RHOC(ii,r)/(1+RHOC(ii,r)))
       + (1-delta(ii,r))**(1/(1+RHOC(ii,r)))*PD(ii,r,tp)**
        (RHOC(ii,r)/(1+RHOC(ii,r))) )**
         ((1+RHOC(ii,r))/RHOC(ii,r))/AC(ii,r) ;

PXEQ(ii,r,tp)..
    PX(ii,r,tp) =E= (tdelta(ii,r)**(1/(1-RHOT(ii,r)))*
       (PEE(ii,r,tp))**(RHOT(ii,r)/(RHOT(ii,r)-1))
       + (1-tdelta(ii,r))**(1/(1-RHOT(ii,r)))*PD(ii,r,tp)**
        (RHOT(ii,r)/(RHOT(ii,r)-1)) )**
         ((RHOT(ii,r)-1)/RHOT(ii,r))/AT(ii,r) ;


PCTEQ(ii,r,tp)..
     scPCT(ii,r)*PCT(ii,r,tp) =E= (1 + ctaxr(ii,r))*PC(ii,r,tp);

DCEQ(ii,r,tp)..
   scDC(ii,r)*DC(ii,r,tp) =E= ((1-delta(ii,r))*
     PC(ii,r,tp)/PD(ii,r,tp))**(1/(1+RHOC(ii,r)))*
     AC(ii,r)**(-RHOC(ii,r)/(1+RHOC(ii,r)))*
     (scCD(ii,r)*CD(ii,r,tp) +
     scTINVD(ii,r)*TINVD(ii,r,tp) + scINTD(ii,r)*INTD(ii,r,tp)) ;

MMEQ(ii,r,tp)..
  scMM(ii,r)*MM(ii,r,tp) =E=(delta(ii,r)*PC(ii,r,tp)/
     PMM(ii,r,tp))**(1/(1+RHOC(ii,r)))*
     AC(ii,r)**(-RHOC(ii,r)/(1+RHOC(ii,r)))*
     (scCD(ii,r)*CD(ii,r,tp) +
     scTINVD(ii,r)*TINVD(ii,r,tp) + scINTD(ii,r)*INTD(ii,r,tp)) ;

DCEQ2(ii,r,tp)..
*{from CET}
   scDC(ii,r)*DC(ii,r,tp) =E= ((1-tdelta(ii,r))*
     PX(ii,r,tp)/PD(ii,r,tp))**(1/(1-RHOT(ii,r)))*
     AT(ii,r)**(RHOT(ii,r)/(1-RHOT(ii,r)))*
     (scX(ii,r)*X(ii,r,tp) ) ;

EEEQ(ii,r,tp)..
  scEE(ii,r)*EE(ii,r,tp) =E=(tdelta(ii,r)*PX(ii,r,tp)/
     PEE(ii,r,tp))**(1/(1-RHOT(ii,r)))*
     AT(ii,r)**(RHOT(ii,r)/(1-RHOT(ii,r)))*
     (scX(ii,r)*X(ii,r,tp)) ;

PVAEQ(ii,r,tp)..
  PX(ii,r,tp)/(1+ptaxr(ii,r)) - SUM(nn,IO(nn,ii,r)*
  scPCT(nn,r)*PCT(nn,r,tp))=E= scPVA(ii,r)*PVA(ii,r,tp) ;

XEQ(ii,r,tp)..
   scPVA(ii,r)*PVA(ii,r,tp) + WALRAS2(ii,r,tp) =E=
   PROD(iff$alpha(iff,ii,r),WF(iff,r,tp)**ALPHA(iff,ii,r))/(AD(ii,r)*
     prod(iff$alpha(iff,ii,r),ALPHA(iff,ii,r)**ALPHA(iff,ii,r))) ;


FDEQ(iff,ii,r,tp)$(FD0(iff,ii,r) ne 0)..
      scFD(iff,ii,r)*FD(iff,ii,r,tp) =E=
         ALPHA(iff,ii,r)*PROD(ff,WF(ff,r,tp)**ALPHA(ff,ii,r))*
         prod(ff,ALPHA(ff,ii,r)**(-ALPHA(ff,ii,r)))*
       ( scX(ii,r)*X(ii,r,tp) )/(WF(iff,r,tp)*AD(ii,r)) ;

ctaxeq(r,tp)..
        scCTAX(r)*CONTAX(r,tp) =E= sum(ii,ctaxr(ii,r)*PC(ii,r,tp)*(
       scCD(ii,r)*CD(ii,r,tp) + scTINVD(ii,r)*TINVD(ii,r,tp) +
       scINTD(ii,r)*INTD(ii,r,tp)) ) ;

GOVREVEQ(r,tp)..
   scGOVREV(r)*GOVREV(r,tp) =E= sum((ii,s),xtaxr(ii,r,s)*
     PWM(ii,r,s,tp)*scM(ii,r,s)*M(ii,r,s,tp)) +
     sum((ii,s),(mtaxr(ii,s,r)-msubr(ii,s,r))*PWM(ii,s,r,tp)*scM(ii,s,r)*M(ii,s,r,tp)) +
     scCTAX(r)*CONTAX(r,tp) + sum(ii, (ptaxr(ii,r)/
     (1+ptaxr(ii,r)))*PX(ii,r,tp)*scX(ii,r)*X(ii,r,tp)) ;


CDEQ(ii,r,tp)..
    scPCT(ii,r)*PCT(ii,r,tp)*scCD(ii,r)*CD(ii,r,tp) =E=
       CLES(ii,r)*(scYH(r)*YH(r,tp) - HSAVE(r,tp)) ;

INTEQ(ii,r,tp)..
  scINTD(ii,r)*INTD(ii,r,tp) =E=
         sum(nn,IO(ii,nn,r)*scX(nn,r)*X(nn,r,tp));

YHEQ(r,tp)..
   scYH(r)*YH(r,tp) =E= sum(iff, WF(iff,r,tp)*
     scFS(iff,r)*FS(iff,r,tp)) - (scADJCST(r)*
     ADJCST(r,tp) + scPINV(r)*PINV(r,tp))*
     scINV(r)*INV(r,tp) + scGOVREV(r)*GOVREV(r,tp) -
    scR(r)*INTRR(r,tp)*scTFDEBT(r)*TFDEBT(r,tp);

PINVEQ(r,tp)..
   scPINV(r)*PINV(r,tp) =E= 1/AINV(r)*prod(nn,
         (scPCT(nn,r)*PCT(nn,r,tp))**zshr(nn,r)*
          zshr(nn,r)**(-zshr(nn,r)) ) ;

INVDEQ(ii,r,tp)$(INVD0(ii,r) GT 1.0E-7)..
     scINVD(ii,r)*INVD(ii,r,tp) =E=
          zshr(ii,r)*scINV(r)*INV(r,tp)*
          scPINV(r)*PINV(r,tp)/
        (scPCT(ii,r)*PCT(ii,r,tp));

 TINVDEQ(ninvt,r,tp)..
        scTINVD(ninvt,r)*TINVD(ninvt,r,tp) =E=
        scINVD(ninvt,r)*INVD(ninvt,r,tp) ;

 SERTINVD(r,tp)..
        scTINVD("othmf",r)*TINVD("othmf",r,tp) =E=
        scINVD("othmf",r)*INVD("othmf",r,tp) +
        (FA(r)*(scINV(r)*INV(r,tp))**2/
   (scFS("capt",r)*FS("capt",r,tp))) ;

  FSMKTEQ(iff,r,tp)..
    sum(ii$(FD0(iff,ii,r) ne 0),scFD(iff,ii,r)*
    FD(iff,ii,r,tp) ) =E=
             scFS(iff,r)*FS(iff,r,tp) ;

FBALEQ(s,r,tp)$pt(r,s)..
   scFBAL(s,r)*FBAL(s,r,tp) =E= sum(ii,
    PWM(ii,s,r,tp)*scM(ii,s,r)*M(ii,s,r,tp) -
    PWM(ii,r,s,tp)*scM(ii,r,s)*M(ii,r,s,tp)) ;

HSAVEEQ(r,tp)..
*    scPINV(r)*PINV(r,tp)*scINV(r)*INV(r,tp) =E=
*       scHSAVE(r)*HSAVE(r,tp)+sum(s, scFBAL(s,r)*FBAL(s,r,tp)) +
*       sum(s,scFDEBT(s,r)*FDEBT(s,r,tp)*scR(r)*INTRR(r,tp))
*      + WALRAS(r,tp) ;

    HSAVE(r,tp) + sum(s,scFBAL(s,r)*FBAL(s,r,tp)) +
  scTFDEBT(r)*TFDEBT(r,tp)*scR(r)*INTRR(r,tp) + WALRAS(r,tp)
  =E= 0 ;

$ontext
VGDPEQ(r,tp)..
  scVGDP(r)*VGDP(r,tp) =E=
  sum(ii, scPCT(ii,r)*PCT(ii,r,tp)*(scCD(ii,r)*CD(ii,r,tp) +
          scTINVD(ii,r)*TINVD(ii,r,tp))) -
          sum(s,scFBAL(s,r)*FBAL(s,r,tp)) ;
$offtext

*## dynamic equation

ADJCSTEQ(r,tp)..
 scADJCST(r)*ADJCST(r,tp) =E=
         scPCT("othmf",r)*PCT("othmf",r,tp)*
    FA(r)*scINV(r)*INV(r,tp)/
    (scFS("capt",r)*FS("capt",r,tp)) ;

TOBBINEQ(r,tp)..
 scTOBBIN(r)*TOBBINQ(r,tp) =E= scPINV(r)*PINV(r,tp) +
    2*FA(r)*scPCT("othmf",r)*PCT("othmf",r,tp)*
    scINV(r)*INV(r,tp)/(scFS("capt",r)*FS("capt",r,tp)) ;

KSUPEQ(r,tp+1)..
    scFS("CAPT",r)*(FS("CAPT",r,tp+1) - FS("CAPT",r,tp)) =E=
      (date(tp+1)-date(tp))*(scINV(r)*INV(r,tp) -
         dpr(r)*scFS("CAPT",r)*FS("CAPT",r,tp)) ;

EULEREQ(r,tp)$(RGT(tp) GT 1)..
    (1+scR(r)*INTRR(r,tp))/(1+ru(r))*(scYH(r)*YH(r,tp-1) -
     HSAVE(r,tp-1)) =E=
     (scYH(r)*YH(r,tp) - HSAVE(r,tp))  ;

 ARBITEQ(r,ts)$(RGT(ts) GT 1)..
     (1+scR(r)*INTRR(r,ts)*(date(ts+1)-date(ts)))*
       scTOBBIN(r)*TOBBINQ(r,ts-1) =E=
      (WF("capt",r,ts) + FA(r)*scPCT("othmf",r)*PCT("othmf",r,ts)*
     (scINV(r)*INV(r,ts)/(scFS("capt",r)*
 FS("capt",r,ts)))**2)*(date(ts+1)-date(ts)) + (1 - dpr(r)*
 (date(ts+1)-date(ts)))*scTOBBIN(r)*TOBBINQ(r,ts) ;


*FDEBTEQ(r,s,tp+1)$pt(s,r)..
*    scFDEBT(r,s)*(FDEBT(r,s,tp+1) - FDEBT(r,s,tp)) =E=
*      (date(tp+1)-date(tp))*( scFDEBT(r,s)*FDEBT(r,s,tp)*
*        scR(s)*INTRR(s,tp) + scFBAL(r,s)*FBAL(r,s,tp) ) ;

TFDEBTEQ(r,tp+1)..
    -scTFDEBT(r)*(TFDEBT(r,tp+1) - TFDEBT(r,tp)) =E=
      (date(tp+1)-date(tp))*HSAVE(r,tp) ;

CAPITALEQ(r,tss)..
     dpr(r)*scFS("CAPT",r)*FS("CAPT",r,tss) =E=
        scINV(r)*INV(r,tss);

*INTREQ(r,tss)..
*    scR(r)*INTRR(r,tss) =E= ru(r) ;

SSINVEQ(r,tp)$(RGT(tp) EQ CARD(tp))..
     scR(r)*INTRR(r,tp)*scTOBBIN(r)*TOBBINQ(r,tp-1) =E=
      WF("capt",r,tp) + FA(r)*
         scPCT("othmf",r)*PCT("othmf",r,tp)*
     (scINV(r)*INV(r,tp)/
     (scFS("capt",r)*FS("capt",r,tp)))**2
     - dpr(r)*scTOBBIN(r)*TOBBINQ(r,tp) ;

SSDEBTEQ(r,tss)..
*    sum(s,scFBAL(s,r)*FBAL(s,r,tss)) =E=
*      -sum(s,scFDEBT(s,r)*FDEBT(s,r,tss)*scR(r)*INTRR(r,tss)) ;

      HSAVE(r,tss) =E= 0 ;

*$offtext

OBJ..    OBJECT =E= SUM((r,tp),WALRAS(r,tp) +
            sum(ii,WALRAS2(ii,r,tp))) ;


*Fixing undetermined variables
  FD.FX(iff,ii,r,tp)$(FD0(iff,ii,r) EQ 0)   = 0 ;
  FDEBT.FX(r,r,tp)        = 0 ;
  INTRR.FX(r,tp)   = INTRR.L(r,"1") ;
  INVD.FX(i,r,tp)$(INVD0(i,r) LE 1.0E-7) = 0 ;
  M.FX(ii,r,s,tp)$(M0(ii,r,s) LE 1.0E-7) = M.L(ii,r,s,tp) ;
  PWM.FX(ii,r,s,tp)$(M0(ii,r,s) eq 0)     = 0.0 ;
  PM.FX(ii,r,s,tp)$(M0(ii,r,s) eq 0)     = 0.0 ;
  PE.FX(ii,r,s,tp)$(M0(ii,r,s) eq 0)     = 0.0 ;
  PWM.FX(ii,r,r,tp)       = 0.0 ;
  PM.FX(ii,r,r,tp)       = 0.0 ;
  PE.FX(ii,r,r,tp)       = 0.0 ;
  M.FX(ii,r,r,tp)         = 0.0 ;
  FBAL.FX(r,r,tp)         = 0 ;

*Fixing labor and land supply
  FS.FX(nk,r,tp)   = FS.L(nk,r,tp) ;

*Fixing first period capital and debt
  FS.FX("CAPT",r,tfirst)   = FS.L("CAPT",r,tfirst) ;
*  FDEBT.FX(r,s,tfirst)$pt(s,r) = FDEBT.L(r,s,tfirst) ;
  TFDEBT.FX(r,tfirst) = TFDEBT.L(r,tfirst) ;

*Fixing price index px in the first period for row and creating a
*Fixing price index px in all periods for row and creating a
*slack variable walras2 in mkt equil for row
* PMINDEX.FX("row",tfirst) = PMINDEX.L("row",tfirst) ;
* PXINDEX.FX("row",tfirst) = PXINDEX.L("row",tfirst) ;
  PWM.FX("manuf","asa","row",tfirst) = PWM.L("manuf","asa","row",tfirst) ;

 WALRAS2.FX(i,nrow,tp) = 0 ;
 WALRAS2.FX(i,"row",nfirst) = 0 ;
 WALRAS2.FX(ninvt,"row","1") = 0 ;

*##MODEL DEFINITION

MODEL  DGE9x9  Dynamic GENERAL EQUILIBRIUM MODEL /ALL/  ;

OPTIONS  ITERLIM =100000, RESLIM = 1000000,
LIMROW = 0,
LIMCOL = 0,
SOLPRINT = Off ,
decimals=8, DOMLIM=1000 ;
dge9x9.holdfixed = 1;
dge9x9.optfile    = 1;

*dge7x6.workspace= 52 ;

*option NLP = MINOS5 ;
option NLP = CONOPT ;
* option mcp=path ;

$ontext
SITER(ITER) = NO ;
SITER("base") = yes ;

SOLVE DGE9x9 USING MCP ;
*SOLVE DGE9x9 MAXIMIZING OBJECT USING NLP;

$INCLUDE LOADSOL0.INC
$offtext

*$ontext
SITER(ITER) = NO ;
SITER("exp1") = yes ;

MTAXR(ii,r,s)$(MTAXR0(ii,r,s) gt 0) = 0.9*MTAXR0(ii,r,s) ;

option mcp=path;

DGE9x9.optfile=1;

SOLVE DGE9x9 USING MCP ;
*SOLVE DGE9x9 MAXIMIZING OBJECT USING NLP;

$INCLUDE LOADSOL0.INC

$ontext
SITER(ITER) = NO ;
SITER("exp1") = yes ;

MTAXR(ii,r,s)$(MTAXR0(ii,r,s) gt 0) = 0.0 ;

SOLVE DGE9x9 USING MCP ;
*SOLVE DGE9x9 MAXIMIZING OBJECT USING NLP;

$INCLUDE LOADSOL0.INC

SITER(ITER) = NO ;
SITER("exp2") = yes ;

XTAXR(ii,r,s)$(XTAXR0(ii,r,s) lt 0) = 0.7*XTAXR0(ii,r,s) ;

SOLVE DGE9x9 USING MCP ;
*SOLVE DGE9x9 MAXIMIZING OBJECT USING NLP;

SITER(ITER) = NO ;
SITER("exp2") = yes ;

XTAXR(ii,r,s)$(XTAXR0(ii,r,s) lt 0) = 0.0 ;

SOLVE DGE9x9 USING MCP ;
*SOLVE DGE9x9 MAXIMIZING OBJECT USING NLP;


$INCLUDE LOADSOL0.INC

*$ontext

SITER(ITER) = NO ;
SITER("exp3") = yes ;

MTAXR(ii,mid,mid2)$(MTAXR0(ii,mid,mid2) gt 0) = 0.0 ;

SOLVE DGE9x9 USING MCP ;
*SOLVE DGE9x9 MAXIMIZING OBJECT USING NLP;

$INCLUDE LOADSOL0.INC

$offtext

Display  MACROTAB, PRODTAB;


*#################### THE END #################
