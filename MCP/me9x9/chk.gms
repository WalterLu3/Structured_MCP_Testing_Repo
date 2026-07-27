$TITLE  MIDEAST3: MULTI-REGION (9x9) DYNAMIC MODEL for MIDEAST
*$inlinecom{ }
* program, Oct. 1999

$offlisting

*programming by : Xinshen Diao, USDA/ERS and U of Minnesota
*this file is for calibration restart=save\data, save=save\chk

*with capital adjustment cost and economy-wide capital
*with CET funciton

SETS II(i) ALL COMMODITIES 
/       grain  grain crop agriculture
        vegol  vegetable fruits and oilseed
        sugar  sugar
        livsk  livestock
        oagri  other agriculture
        proag  processed agriculture
        textl  textile and wearing
        manuf  producer manufacturing
        othmf  others including energy mining and services
/

AGI(i) agricultural sector
/       grain  grain crop agriculture
        vegol  vegetable and fruits
        sugar  sugar
        livsk  livestock
        oagri  other agriculture
        proag  processed agriculture
/

PAGI(i) agricultural sector
/       grain  grain crop agriculture
        vegol  vegetable and fruits
        sugar  sugar
        livsk  livestock
        oagri  other agriculture
 /


NINVT(i) not including othmf
/       grain  grain crop agriculture
        vegol  vegetable and fruits
        sugar  sugar
        livsk  livestock
        oagri  other agriculture
        proag  processed agriculture
        textl  textile and wearing
        manuf  producer manufacturing
 /

     mid(r) /TUR, OME, MAR, RNF/,
     nmid(r) /ASA, E_U, EFT, FSU, ROW/,
     seu(r) /E_U, EFT/,
     leu(r) /E_U, EFT, FSU/,


      IFF factor endowments / LAND, NSLB, SKLB, CAPT, NRES /,
      LA(iff) labor categories/NSLB, SKLB/
      NK(iff) / LAND, NSLB, SKLB, NRES /

;


ALIAS (II, NN), (II,II2), (agi,agi2), (pagi,pagi2), (mid,mid2,mid3)
      (IFF, FF) , 
      (nk, nkk) , 
      (LA,LB) ;

* Do the assignments:

$ontext
*adjust factor data of Asian countries such that 
*capital flow is greater than inv't there
parameter
adjnslb(j,r)
adjsklb(j,r)
adjland(j,r)
adjnres(j,r)
;
adjland(j,"asa") = 0.5*EVFA("LAND",j,"asa") ;
adjnres(j,"asa") = 0.8*EVFA("NRES",j,"asa") ;
adjnslb(j,"asa") = 0.26*EVFA("NSLB",j,"asa") ;
adjsklb(j,"asa") = 0.2*EVFA("SKLB",j,"asa") ;
adjsklb(j,"asa") = 0;

EVFA("NSLB",j,"asa") = EVFA("NSLB",j,"asa") - adjnslb(j,"asa") ;
EVFA("SKLB",j,"asa") = EVFA("SKLB",j,"asa") - adjsklb(j,"asa") ;
EVFA("NRES",j,"asa") = EVFA("NRES",j,"asa") - adjnres(j,"asa") ;
EVFA("LAND",j,"asa") = EVFA("LAND",j,"asa") - adjland(j,"asa") ;
EVFA("CAPT",j,"asa") = EVFA("CAPT",j,"asa") + adjland(j,"asa")
              + adjnslb(j,"asa") + adjsklb(j,"asa") + adjnres(j,"asa") ;

$offtext

*adjust transportation data
* such that data VST(i,r) is merged into export of service
* from region r

parameter
VIPMN(i,r)
VIPAN(i,r)
VIGMN(i,r)
VIGAN(i,r)
VIFMN(i,j,r)
VIFAN(i,j,r)
VT(i,r)  the rate of demand for tran.serv by sector i in reg. r
VIM(i,r) total import of good i in reg. r 
chkVIM(i,r)
chkVIWS(i,r,s)
chkVIPM(r)
chkVIGM(r)
chkVIFM(i,r)
chkVIPA(r)
chkVIGA(r)
chkVIFA(i,r)
chkVIM2(i,r)
chkVIM3(i,r)
XTAXR(i,r,s)
MTAXR(i,r,s)
;


VTWR(ii,r,s) = VIWS(ii,r,s) - VXWD(ii,r,s) ;

VIM(ii,r) = VIPM(ii,r) + VIGM(ii,r) + sum(j$IP(J),VIFM(ii,j,r));
chkvim(ii,s) = VIM(ii,s) - sum(r,VIMS(ii,r,s)) ;

*display chkvim;

VIWS(ii,r,s) = VIWS(ii,r,s) - VTWR(ii,r,s) ;
VIWS("othmf",r,s) = VIWS("othmf",r,s) + sum(ii,VTWR(ii,r,s)) ;
VXWD("othmf",r,s) = VXWD("othmf",r,s) + sum(ii,VTWR(ii,r,s)) ;
VXMD("othmf",r,s) = VXMD("othmf",r,s) + sum(ii,VTWR(ii,r,s)) ;
VIMS(ii,r,s) = VIMS(ii,r,s) - VTWR(ii,r,s) ;
VIMS("othmf",r,s) = VIMS("othmf",r,s) + sum(ii,VTWR(ii,r,s)) ;


chkVIWS(ii,r,s) = VIWS(ii,r,s) - VXWD(ii,r,s) ;

VT(ii,s) = (sum(r,VTWR(ii,r,s))/VIM(ii,s))$(VIM(ii,s) NE 0) ;

VIM(ii,s) = VIM(ii,s) - sum(r,VTWR(ii,r,s)) ;
VIM("othmf",s) = VIM("othmf",s) + sum((ii,r),VTWR(ii,r,s)) ;

VIPMN(ii,r) = VIPM(ii,r)*(1-VT(ii,r)) ;
VIGMN(ii,r) = VIGM(ii,r)*(1-VT(ii,r)) ;
VIFMN(ii,j,r)$IP(J)= VIFM(ii,j,r)$(IP(J))*(1-VT(ii,r))
;

VIPMN("othmf",r) = VIPMN("othmf",r) + SUM(ii,VIPM(ii,r) - VIPMN(ii,r)) ;
VIGMN("othmf",r) = VIGMN("othmf",r) + SUM(ii,VIGM(ii,r) - VIGMN(ii,r)) ;
VIFMN("othmf",j,r) = VIFMN("othmf",j,r) + 
             SUM(ii,VIFM(ii,j,r) - VIFMN(ii,j,r)) ;

VIPAN(ii,r) = VIPA(ii,r)*(1-VT(ii,r)) ;

VIGAN(ii,r) = VIGA(ii,r)*(1-VT(ii,r)) ;
VIFAN(ii,j,r)$IP(J)= VIFA(ii,j,r)$(IP(J))*(1-VT(ii,r)) ;

*display vipan ;

VIPAN("othmf",r) = VIPAN("othmf",r) + SUM(ii,VIPA(ii,r) - VIPAN(ii,r))
;
VIGAN("othmf",r) = VIGAN("othmf",r) + SUM(ii,VIGA(ii,r) - VIGAN(ii,r))
;
VIFAN("othmf",j,r) = VIFAN("othmf",j,r) + 
             SUM(ii,VIFA(ii,j,r) - VIFAN(ii,j,r)) ;

chkVIPM(r) = sum(ii,VIPMN(ii,r) - VIPM(ii,r) ) ;
chkVIGM(r) = sum(ii,VIGMN(ii,r) - VIGM(ii,r) ) ;
chkVIFM(j,r) = sum(ii,VIFMN(ii,j,r) - VIFM(ii,j,r)$IP(J) ) ;

chkVIPA(r) = sum(ii,VIPAN(ii,r) - VIPA(ii,r) ) ;
chkVIGA(r) = sum(ii,VIGAN(ii,r) - VIGA(ii,r) ) ;
chkVIFA(j,r) = sum(ii,VIFAN(ii,j,r) - VIFA(ii,j,r)$IP(J) ) ;

display chkvipm, chkvipa ;

*display chkVIWS ,
*chkvipm, chkvigm, chkvifm, chkvipa, chkviga, chkvifa ;

VIPM(ii,r) = VIPMN(ii,r) ;
VIGM(ii,r) = VIGMN(ii,r) ;
VIFM(ii,j,r)$IP(J)= VIFMN(ii,j,r)$IP(J) ;

VIPA(ii,r) = VIPAN(ii,r) ;
VIGA(ii,r) = VIGAN(ii,r) ;
VIFA(ii,j,r)$IP(J)= VIFAN(ii,j,r)$IP(J) ;

chkvim2(ii,r) = VIM(ii,r) - VIPM(ii,r) - VIGM(ii,r) - 
    sum(j,VIFM(ii,j,r)) ;
chkvim3(ii,s) = VIM(ii,s) - sum(r,VIMS(ii,r,s)) ;

*Adjusting intra-regional trade first

PARAMETERS  INTEXPR(i,r)   INTRA-REGIONAL EXPORT RATE
            INTIMPR(i,r)   INTRA-REGIONAL IMPORT RATE
      ;

INTEXPR(ii,r) = VXMD(ii,r,r)/(VDPM(ii,r)+VDGM(ii,r)+
                 sum(j,VDFM(ii,j,r)$IP(J))) ;
INTIMPR(ii,r) = VIMS(ii,r,r)/VIM(ii,r) ;

VIPMN(ii,r) = VIPM(ii,r)*(1-INTIMPR(ii,r)) ;
VIGMN(ii,r) = VIGM(ii,r)*(1-INTIMPR(ii,r)) ;
VIFMN(ii,j,r)$IP(J)= VIFM(ii,j,r)$IP(J)*(1-INTIMPR(ii,r)) ;

VDPM(ii,r) = VDPM(ii,r) + VDPM(ii,r)*INTEXPR(ii,r) ;
VDGM(ii,r) = VDGM(ii,r) + VDGM(ii,r)*INTEXPR(ii,r) ;
VDFM(ii,j,r)$IP(J)= VDFM(ii,j,r)$IP(J) + 
                    VDFM(ii,j,r)$IP(J)*INTEXPR(ii,r) ;

VIPAN(ii,r) = VIPA(ii,r)*(1-INTIMPR(ii,r)) ;
VIGAN(ii,r) = VIGA(ii,r)*(1-INTIMPR(ii,r)) ;
VIFAN(ii,j,r)$IP(J)= VIFA(ii,j,r)$(IP(J))*(1-INTIMPR(ii,r))
;

VDPA(ii,r) = VDPA(ii,r) + VDPA(ii,r)*INTEXPR(ii,r) ;
VDGA(ii,r) = VDGA(ii,r) + VDGA(ii,r)*INTEXPR(ii,r) ;
VDFA(ii,j,r)$IP(J)= VDFA(ii,j,r)$IP(J) + 
                    VDFA(ii,j,r)$IP(J)*INTEXPR(ii,r) ;

VIPM(ii,r) = VIPMN(ii,r) ;  
VIGM(ii,r) = VIGMN(ii,r) ;  
VIFM(ii,j,r)$IP(J)= VIFMN(ii,j,r)$IP(J) ;

VIPA(ii,r) = VIPAN(ii,r) ;  
VIGA(ii,r) = VIGAN(ii,r) ;  
VIFA(ii,j,r)$IP(J)= VIFAN(ii,j,r)$IP(J) ;

VXMD(ii,r,r) = 0 ;

VXWD(ii,r,r) = 0 ;

VIMS(ii,r,r) = 0 ;
VIWS(ii,r,r) = 0 ;

VIM(ii,r) = VIPM(ii,r) + VIGM(ii,r) + sum(j$IP(j),VIFM(ii,j,r)) ;

chkvim3(ii,s) = VIM(ii,s) - sum(r,VIMS(ii,r,s)) ;

display intexpr, intimpr,vdfm ;
*chkvim3, intexp, intimp, inttaxm, inttaxe ;


*end of adjustment
VFA(I,J,R)$(F(I)*IP(J)) = EVFA(i,j,r) ;

VFA(i,j,s)$(IT(I)*IP(J)) = VDFA(i,j,s) + VIFA(i,j,s) ;

VOA(i,r)$F(I) = EVOA(i,r);

VOA(i,r)$IP(I) = sum(j$ID(J), VFA(j,i,r));

VDM(i,r)$IT(I) = VDPM(i,r) + VDGM(i,r) + sum(j$IP(J), VDFM(i,j,r))
;

VOM(i,r)$F(I) = sum(j$IP(J), EVFA(i,j,r)) ;

VOM(i,r)$IT(I) = VDM(i,r) + sum(s, VXMD(i,r,s)) ;

VOM(i,r)$IK(I) = VOA(i,r) ;

VPA(i,s)$IT(I) = VDPA(i,s) + VIPA(i,s) ;

PRIVEXP(r) = sum(i$IT(I), VPA(i,r)) ;

VGA(i,s)$IT(I) = VDGA(i,s) + VIGA(i,s) ;

GOVEXP(r) = sum(i$IT(i), VGA(i,r)) ;

INCOME(r) = PRIVEXP(r) + GOVEXP(r) + SAVE(r) ;

GVT = sum(i$IT(I), sum(r, sum(s, VTWR(i,r,s))));

REGINV(r) = sum(i$IK(i), VOA(i,r)) ;

GLOBINV = sum(r, REGINV(r) - VDEP(r) );

VWLDSALES(r) = sum(i$IT(I), sum(s, VXWD(i,r,s)) )
  + REGINV(r) - VDEP(r);

VEXPORTS(r) = sum(i$IT(i), sum(s, VXWD(i,r,s)) ) ;

VIMPORTS(s) = sum(i$IT(i), sum(r, VIWS(i,r,s))) ;

*ETAX(i,r)$F(i) = sum(j$IP(j),VFA(i,j,r)$F(i) - VFM(i,j,r)$F(i)) ;
PTAX(i,r) = VOM(i,r)$it(i) - VOA(i,r)$it(i) ;
DPTAX(i,r) = VDPA(i,r) - VDPM(i,r) ;
IPTAX(i,r) = VIPA(i,r) - VIPM(i,r) ;
DGTAX(i,r) = VDGA(i,r) - VDGM(i,r) ;
IGTAX(i,r) = VIGA(i,r) - VIGM(i,r) ;
DFTAX(i,j,r) = VDFA(i,j,r) - VDFM(i,j,r) ;
IFTAX(i,j,r) = VIFA(i,j,r) - VIFM(i,j,r) ;
XTAX(i,r) = sum(s, VXWD(i,r,s) - VXMD(i,r,s)) ;
MTAX(i,s) = sum(r,VIMS(i,r,s)) - sum(r, VIWS(i,r,s) ) ;
XTAXR(i,r,s) = ((VXWD(i,r,s) - VXMD(i,r,s))/VXWD(i,r,s))$
               (VXWD(i,r,s) NE 0) ;
XTAXR(i,r,s)$(VXWD(i,r,s) EQ 0) = 0 ;
MTAXR(i,r,s) = ((VIMS(i,r,s) - VIWS(i,r,s))/VIWS(i,r,s))$
                (VIWS(i,r,s) NE 0) ;
MTAXR(i,r,s)$(VIWS(i,r,s) EQ 0) = 0 ;
 

*display ptax, dptax, iptax, dgtax, igtax, dftax, 
*iftax, xtax, mtax ;
display mtaxr ;

GROSSTAXES(r) =
 + sum(i$(IN(I)$(VOM(i,r) - VOA(i,r) GT 0)), VOM(i,r) - VOA(i,r))
 + sum(i$(IT(I)$(VIPA(i,r) - VIPM(i,r) GT 0)), VIPA(i,r) -
VIPM(i,r))
 + sum(i$(IT(I)$(VDPA(i,r) - VDPM(i,r) GT 0)), VDPA(i,r) -
VDPM(i,r))
 + sum(i$(IT(I)$(VIGA(i,r) - VIGM(i,r) GT 0)), VIGA(i,r) -
VIGM(i,r))
 + sum(i$(IT(I)$(VDGA(i,r) - VDGM(i,r) GT 0)), VDGA(i,r) -
VDGM(i,r))
 + sum(j$IP(J), sum(i$(IT(I)$(VIFA(i,j,r) - VIFM(i,j,r) GT 0)),
                          VIFA(i,j,r) - VIFM(i,j,r)))
 + sum(j$IP(J), sum(i$(IT(I)$(VDFA(i,j,r) - VDFM(i,j,r) GT 0)),
                          VDFA(i,j,r) - VDFM(i,j,r)))
 + sum(i$IT(I), sum(s$(VXWD(i,r,s) - VXMD(i,r,s) GT 0),
                          VXWD(i,r,s) - VXMD(i,r,s)))
 + sum(i$IT(I), sum(s$(VIMS(i,s,r) - VIWS(i,s,r) GT 0),
                          VIMS(i,s,r) - VIWS(i,s,r))) ;

NETAXES(r) = sum(i,PTAX(i,r) + IPTAX(i,r) + DPTAX(i,r)
  + IGTAX(i,r) + DGTAX(i,r) + sum(j$IP(j), IFTAX(i,j,r)) 
  + sum(j$IP(j), DFTAX(i,j,r))) + sum(i$IT(i), XTAX(i,r))
 + sum(i$IT(i), MTAX(i,r)) ;

NFACTINC(r) = sum(i$F(I), VOA(i,r)) - VDEP(r);
     
NNPS(r) = NFACTINC(r) + NETAXES(r)  ;

BOT(r) = VEXPORTS(r) - VIMPORTS(r) ;
GBOT = sum(r, VEXPORTS(r) - VIMPORTS(r) ) ;

CCBOT(i) = sum(r,sum(s, VXWD(i,r,s) - VIWS(i,r,s)) ) ;
GCCBOT = sum(i,CCBOT(i)) ;
VIMPORTS(s) = sum(i$IT(i), sum(r, VIWS(i,r,s))) ;

parameter
rgchkdom(r)
gchkdom
saven(r)
chksave1(r)
chksave2
;

*re-calculate savings, since the initial SAVE cannot balance data

SAVEn(r) = NNPS(r) - PRIVEXP(r) - GOVEXP(r) ;
chksave1(r) = save(r) - saven(r) ;

NNPE(r) = PRIVEXP(r)+GOVEXP(r)+REGINV(r)-VDEP(r)+ BOT(r) ;

SURPLUS(r) = NNPS(r) - PRIVEXP(r) - GOVEXP(r) - SAVE(r) ;

BOP(r) = BOT(r) + sum(i$IK(i), VOA(i,r)) - VDEP(r)
         - SAVE(r) ;
CHKSAVE = sum(r, SAVE(r)) - sum(r, sum(i$IK(i), VOA(i,r)) -
VDEP(r)) ;
CHKSAVE2 = sum(r, SAVEn(r)) - sum(r, sum(i$IK(i), VOA(i,r)) -
VDEP(r)) ;

*CHKTRANS = sum(i$IT(i), sum(r, sum(s, VTWR(i,r,s))))
*          - sum(i$IT(i), sum(r, VST(i,r))) ;


CHKCLDOM(i,s)$IT(i) = sum(r, VIMS(i,r,s))
         - sum(j$IP(j), VIFM(i,j,s)) - VIPM(i,s) - VIGM(i,s) ;

rgCHKDOM(r) = sum(i,CHKCLDOM(i,r));
gCHKDOM = sum(r,rgCHKDOM(r));

display chkcldom, chksave, bop, surplus;

*$ontext
*display rgchkdom, gchkdom,vdep, CHKSAVE,CHKSAVE1,CHKSAVE2,BOP ;

*if data are balanced, do not need to run the following part
*##### re-run the following parameters
* since CHKLDOM(i,s) are not zero
* adjustment household import expenditure by these erro terms

display vipa;

VIPM(i,r) = VIPM(i,r) + CHKCLDOM(i,r) ;
VIPA(i,r) = VIPA(i,r) + CHKCLDOM(i,r) ;

VPA(i,s)$IT(I) = VDPA(i,s) + VIPA(i,s) ;

PRIVEXP(r) = sum(i$IT(I), VPA(i,r)) ;

IPTAX(i,r) = VIPA(i,r) - VIPM(i,r) ;

NETAXES(r) = sum(i,PTAX(i,r) + IPTAX(i,r) + DPTAX(i,r)
  + IGTAX(i,r) + DGTAX(i,r) + sum(j$IP(j), IFTAX(i,j,r)) 
  + sum(j$IP(j), DFTAX(i,j,r))) + sum(i$IT(i), XTAX(i,r))
 + sum(i$IT(i), MTAX(i,r)) ;

NNPS(r) = NFACTINC(r) + NETAXES(r)  ;

SAVE(r) = NNPS(r) - PRIVEXP(r) - GOVEXP(r) ;

INCOME(r) = PRIVEXP(r) + GOVEXP(r) + SAVE(r) ;

NNPE(r) = PRIVEXP(r)+GOVEXP(r)+REGINV(r)-VDEP(r)+ BOT(r) ;

SURPLUS(r) = NNPS(r) - PRIVEXP(r) - GOVEXP(r) - SAVE(r) ;

BOT(r) = VEXPORTS(r) - VIMPORTS(r) ;

GBOT = sum(r, VEXPORTS(r) - VIMPORTS(r) ) ;

CCBOT(i) = sum(r,sum(s, VXWD(i,r,s) - VIWS(i,r,s)) ) ;

GCCBOT = sum(i,CCBOT(i)) ;

BOP(r) = BOT(r) + sum(i$IK(i), VOA(i,r)) - VDEP(r)
         - SAVE(r) ;

CHKSAVE = sum(r, SAVE(r)) - sum(r, sum(i$IK(i), VOA(i,r)) -
VDEP(r)) ;

*CHKTRANS = sum(i$IT(i), sum(r, sum(s, VTWR(i,r,s))))
*          - sum(i$IT(i), sum(r, VST(i,r))) ;


CHKCLDOM(i,s)$IT(i) = sum(r, VIMS(i,r,s))
         - sum(j$IP(j), VIFM(i,j,s)) - VIPM(i,s) - VIGM(i,s) ;

rgCHKDOM(r) = sum(i,CHKCLDOM(i,r));
gCHKDOM = sum(r,rgCHKDOM(r));
*$offtext

DISPLAY GBOT, ccbot, gccbot,CHKSAVE,BOP,SURPLUS,CHKCLDOM,
rgchkdom, gchkdom, chkvim;
* chkvim2, chkvim3;

*=============construction of SAM=====================

SETS

  SI / ACT,COMD,FLD,FLB,FSL,FK,FNR,ENT,PH,GV,KA,WT,ITR,TOTAL/
  SIT(SI) /TOTAL/
  S1(SI) / ENT,GV,PH,KA,WT,ITR /
  SSI(S1) / WT,ITR /
  SI1(SI);

  ALIAS(SI1,SI2);
 
  PARAMETER
  
  ASASAM(SI,SI)     SOCIAL ACCOUNTING MATRIX
  E_USAM(SI,SI)     SOCIAL ACCOUNTING MATRIX
  EFTSAM(SI,SI)     SOCIAL ACCOUNTING MATRIX
  FSUSAM(SI,SI)     SOCIAL ACCOUNTING MATRIX
  TURSAM(SI,SI)     SOCIAL ACCOUNTING MATRIX
  OMESAM(SI,SI)     SOCIAL ACCOUNTING MATRIX
  MARSAM(SI,SI)     SOCIAL ACCOUNTING MATRIX
  RNFSAM(SI,SI)     SOCIAL ACCOUNTING MATRIX
  ROWSAM(SI,SI)     SOCIAL ACCOUNTING MATRIX

  ASARES(SI)     RESIDUAL OF REVENUE & EXPENDITURE, SHOULD ZERO
  E_URES(SI)     RESIDUAL OF REVENUE & EXPENDITURE, SHOULD ZERO
  EFTRES(SI)     RESIDUAL OF REVENUE & EXPENDITURE, SHOULD ZERO
  FSURES(SI)     RESIDUAL OF REVENUE & EXPENDITURE, SHOULD ZERO
  TURRES(SI)     RESIDUAL OF REVENUE & EXPENDITURE, SHOULD ZERO
  OMERES(SI)     RESIDUAL OF REVENUE & EXPENDITURE, SHOULD ZERO
  MARRES(SI)     RESIDUAL OF REVENUE & EXPENDITURE, SHOULD ZERO
  RNFRES(SI)     RESIDUAL OF REVENUE & EXPENDITURE, SHOULD ZERO
  ROWRES(SI)     RESIDUAL OF REVENUE & EXPENDITURE, SHOULD ZERO

;       

  SI1(SI) = NOT  SIT(SI);

* FIRST BLOCK: ACTIVITIES. DOMESTIC SUPPLY,EXPORT SUBSIDY, 
* EXPORTS AT MP
* EXPORTS FOR INTERNATIONAL TRANSPORTATION.

  ASASAM("ACT","COMD") = SUM(I, VDM(I,"ASA"));

  ASASAM("ACT","GV") = - SUM(I, XTAX(I,"ASA")); 
  ASASAM("ACT", "WT") = SUM((I,S), VXWD(I,"ASA",S)); 

* SECOND BLOCK: COMMODITIES. INTERMEDIATE DEMAND,
* HOUSEHOLD CONSUMPTION,
* GOVERNMENT CONSUMPTION,INVESTMENT. 

  ASASAM("COMD","ACT") = SUM((I,J)$(it(i)*it(j)),VFA(I,J,"ASA"));
  ASASAM("COMD","PH")  =  SUM(I, VPA(I,"ASA"));
  ASASAM("COMD","GV")  = SUM(I, VGA(I,"ASA"));  
  ASASAM("COMD","KA") = REGINV("ASA");

* THIRD BLOCK: VALUE ADDED  
  ASASAM("FLD","ACT") = SUM(I, EVFA("LAND",I,"ASA"));
  ASASAM("FLB","ACT") = SUM(I, EVFA("NSLB",I,"ASA"));   
  ASASAM("FSL","ACT") = SUM(I, EVFA("SKLB",I,"ASA"));   
  ASASAM("FK","ACT") = SUM(I, EVFA("CAPT",I,"ASA")); 
  ASASAM("FNR","ACT") = SUM(I, EVFA("NRES",I,"ASA"));   

* FOURTH BLOCK: ENTERPRISE. CAPITAL INCOME AND DEPRECIATION.     

  ASASAM("ENT","FK") = VOM("CAPT","ASA");
  ASASAM("ENT","PH") = VDEP("ASA");

* FIFTH BLOCK: HOUSEHOLDS. INCOME FROM FACTORS.

  ASASAM("PH","FLD") = VOM("LAND","ASA");    
  ASASAM("PH","FLB") = VOM("NSLB","ASA");
  ASASAM("PH","FSL") = VOM("SKLB","ASA");
  ASASAM("PH","ENT") = VOM("CAPT","ASA"); 
  ASASAM("PH","FNR") = VOM("NRES","ASA"); 

* SIXTH BLOCK: GOVERNMENT. INDIRECT TAX,TARIFFS,
* FACTOR TAX,CAPITAL RETURN
* HOUSEHOLD TAX,NET TRANSFER AMONG GOVERNMENT.  

  ASASAM("GV","PH") =  GOVEXP("ASA") - NETAXES("ASA");


  ASASAM("GV","ACT") = SUM(I, PTAX(I,"ASA"));
  ASASAM("GV","COMD") = SUM(I, MTAX(I,"ASA") + DPTAX(I,"ASA")
       + IPTAX(I,"ASA") + DGTAX(I,"ASA") + IGTAX(I,"ASA") + 
       sum(j, DFTAX(I,J,"ASA") + IFTAX(I,J,"ASA")) ); 

* SEVENTH BLOCK: CAPITAL ACCOUNT. ENTERPRISE SAVEINGS,
* HOUSEHOLD SAVEINGS, 
* GOVERNMENT SAVEING AND NET CAPITAL INFLOW
* (BANLANCE OF TRADE + NET FOREIGHN INVESTMENT) 

  ASASAM("KA","ENT") = VDEP("ASA");
  ASASAM("KA","PH") = SAVE("ASA");
  ASASAM("KA", "WT") = - BOT("ASA") ;

* EIGTH BLOCK: REST OF THE WORLD. IMPORTS  

  ASASAM("WT","COMD") = SUM((I,R), VIWS(I,R,"ASA"));

*NINTH BLOCK: INTERNATIONAL TRANSPORTATION SEVERCE. COST


* TENTH BLOCK: SUM OF COLUMN. EXPENDITURE

  ASASAM("TOTAL","ACT") = SUM(SI1,ASASAM(SI1,"ACT"));
  ASASAM("TOTAL","COMD") = SUM(SI1,ASASAM(SI1,"COMD"));
  ASASAM("TOTAL","FLD") = SUM(SI1,ASASAM(SI1,"FLD"));
  ASASAM("TOTAL","FLB") = SUM(SI1,ASASAM(SI1,"FLB"));
  ASASAM("TOTAL","FSL") = SUM(SI1,ASASAM(SI1,"FSL"));
  ASASAM("TOTAL","FK") = SUM(SI1,ASASAM(SI1,"FK"));
  ASASAM("TOTAL","FNR") = SUM(SI1,ASASAM(SI1,"FNR"));
  ASASAM("TOTAL","ENT") = SUM(SI1,ASASAM(SI1,"ENT"));
  ASASAM("TOTAL","PH") = SUM(SI1,ASASAM(SI1,"PH"));
  ASASAM("TOTAL","GV") = SUM(SI1,ASASAM(SI1,"GV"));
  ASASAM("TOTAL","KA") = SUM(SI1,ASASAM(SI1,"KA"));
  ASASAM("TOTAL","WT") = SUM(SI1,ASASAM(SI1,"WT"));

* SUM OF ROW: REVENUE

  ASASAM(SI2,"TOTAL") = SUM(SI1,ASASAM(SI2,SI1));
  ASARES(SI) = ASASAM("TOTAL",SI) - ASASAM(SI,"TOTAL"); 

  OPTION ASASAM:3:1:1; 
  DISPLAY  ASASAM;
  OPTION DECIMALS=3; 
  DISPLAY ASARES;

  PARAMETER ASASRES;
  ASASRES = SUM(SI1, ASARES(SI1));

  DISPLAY ASASRES;

* FIRST BLOCK: ACTIVITIES. DOMESTIC SUPPLY,EXPORT SUBSIDY, 
* EXPORTS AT MP
* EXPORTS FOR INTERNATIONAL TRANSPORTATION.

  E_USAM("ACT","COMD") = SUM(I, VDM(I,"E_U"));

  E_USAM("ACT","GV") = - SUM(I, XTAX(I,"E_U")); 
  E_USAM("ACT", "WT") = SUM((I,S), VXWD(I,"E_U",S)); 

* SECOND BLOCK: COMMODITIES. INTERMEDIATE DEMAND,
* HOUSEHOLD CONSUMPTION,
* GOVERNMENT CONSUMPTION,INVESTMENT. 

  E_USAM("COMD","ACT") = SUM((I,J)$(it(i)*it(j)),VFA(I,J,"E_U"));
  E_USAM("COMD","PH")  =  SUM(I, VPA(I,"E_U"));
  E_USAM("COMD","GV")  = SUM(I, VGA(I,"E_U"));  
*  E_USAM("COMD","KA") = SUM(I$id(i), VFA(I,"CGDS","E_U"));
  E_USAM("COMD","KA") = REGINV("E_U");

* THIRD BLOCK: VALUE ADDED  
  E_USAM("FLD","ACT") = SUM(I, EVFA("LAND",I,"E_U"));
  E_USAM("FLB","ACT") = SUM(I, EVFA("NSLB",I,"E_U"));   
  E_USAM("FSL","ACT") = SUM(I, EVFA("SKLB",I,"E_U"));   
  E_USAM("FK","ACT") = SUM(I, EVFA("CAPT",I,"E_U")); 
  E_USAM("FNR","ACT") = SUM(I, EVFA("NRES",I,"E_U"));   

* FOURTH BLOCK: ENTERPRISE. CAPITAL INCOME AND DEPRECIATION.     

  E_USAM("ENT","FK") = VOM("CAPT","E_U");
  E_USAM("ENT","PH") = VDEP("E_U");

* FIFTH BLOCK: HOUSEHOLDS. INCOME FROM FACTORS.

  E_USAM("PH","FLD") = VOM("LAND","E_U");    
  E_USAM("PH","FLB") = VOM("NSLB","E_U");
  E_USAM("PH","FSL") = VOM("SKLB","E_U");
  E_USAM("PH","ENT") = VOM("CAPT","E_U"); 
  E_USAM("PH","FNR") = VOM("NRES","E_U"); 

* SIXTH BLOCK: GOVERNMENT. INDIRECT TAX,TARIFFS,
* FACTOR TAX,CAPITAL RETURN
* HOUSEHOLD TAX,NET TRANSFER AMONG GOVERNMENT.  

  E_USAM("GV","PH") =  GOVEXP("E_U") - NETAXES("E_U");


  E_USAM("GV","ACT") = SUM(I, PTAX(I,"E_U"));
  E_USAM("GV","COMD") = SUM(I, MTAX(I,"E_U") + DPTAX(I,"E_U")
       + IPTAX(I,"E_U") + DGTAX(I,"E_U") + IGTAX(I,"E_U") + 
       sum(j, DFTAX(I,J,"E_U") + IFTAX(I,J,"E_U")) ); 

* SEVENTH BLOCK: CAPITAL ACCOUNT. ENTERPRISE SAVEINGS,
* HOUSEHOLD SAVEINGS, 
* GOVERNMENT SAVEING AND NET CAPITAL INFLOW
* (BANLANCE OF TRADE + NET FOREIGHN INVESTMENT) 

  E_USAM("KA","ENT") = VDEP("E_U");
  E_USAM("KA","PH") = SAVE("E_U");
  E_USAM("KA", "WT") = - BOT("E_U") ;

* EIGTH BLOCK: REST OF THE WORLD. IMPORTS  

  E_USAM("WT","COMD") = SUM((I,R), VIWS(I,R,"E_U"));

*NINTH BLOCK: INTERNATIONAL TRANSPORTATION SEVERCE. COST


* TENTH BLOCK: SUM OF COLUMN. EXPENDITURE

  E_USAM("TOTAL","ACT") = SUM(SI1,E_USAM(SI1,"ACT"));
  E_USAM("TOTAL","COMD") = SUM(SI1,E_USAM(SI1,"COMD"));
  E_USAM("TOTAL","FLD") = SUM(SI1,E_USAM(SI1,"FLD"));
  E_USAM("TOTAL","FLB") = SUM(SI1,E_USAM(SI1,"FLB"));
  E_USAM("TOTAL","FSL") = SUM(SI1,E_USAM(SI1,"FSL"));
  E_USAM("TOTAL","FK") = SUM(SI1,E_USAM(SI1,"FK"));
  E_USAM("TOTAL","FNR") = SUM(SI1,E_USAM(SI1,"FNR"));
  E_USAM("TOTAL","ENT") = SUM(SI1,E_USAM(SI1,"ENT"));
  E_USAM("TOTAL","PH") = SUM(SI1,E_USAM(SI1,"PH"));
  E_USAM("TOTAL","GV") = SUM(SI1,E_USAM(SI1,"GV"));
  E_USAM("TOTAL","KA") = SUM(SI1,E_USAM(SI1,"KA"));
  E_USAM("TOTAL","WT") = SUM(SI1,E_USAM(SI1,"WT"));

* SUM OF ROW: REVENUE

  E_USAM(SI2,"TOTAL") = SUM(SI1,E_USAM(SI2,SI1));
  E_URES(SI) = E_USAM("TOTAL",SI) - E_USAM(SI,"TOTAL"); 

  OPTION E_USAM:3:1:1; 
  DISPLAY  E_USAM;
  OPTION DECIMALS=3; 
  DISPLAY E_URES;

  PARAMETER E_USRES;
  E_USRES = SUM(SI1, E_URES(SI1));

  DISPLAY E_USRES;

* FIRST BLOCK: ACTIVITIES. DOMESTIC SUPPLY,EXPORT SUBSIDY, 
* EXPORTS AT MP
* EXPORTS FOR INTERNATIONAL TRANSPORTATION.

  EFTSAM("ACT","COMD") = SUM(I, VDM(I,"EFT"));

  EFTSAM("ACT","GV") = - SUM(I, XTAX(I,"EFT")); 
  EFTSAM("ACT", "WT") = SUM((I,S), VXWD(I,"EFT",S)); 

* SECOND BLOCK: COMMODITIES. INTERMEDIATE DEMAND,
* HOUSEHOLD CONSUMPTION,
* GOVERNMENT CONSUMPTION,INVESTMENT. 

  EFTSAM("COMD","ACT") = SUM((I,J)$(it(i)*it(j)),VFA(I,J,"EFT"));
  EFTSAM("COMD","PH")  =  SUM(I, VPA(I,"EFT"));
  EFTSAM("COMD","GV")  = SUM(I, VGA(I,"EFT"));  
*  EFTSAM("COMD","KA") = SUM(I$id(i), VFA(I,"CGDS","EFT"));
  EFTSAM("COMD","KA") = REGINV("EFT");

* THIRD BLOCK: VALUE ADDED  
  EFTSAM("FLD","ACT") = SUM(I, EVFA("LAND",I,"EFT"));
  EFTSAM("FLB","ACT") = SUM(I, EVFA("NSLB",I,"EFT"));   
  EFTSAM("FSL","ACT") = SUM(I, EVFA("SKLB",I,"EFT"));   
  EFTSAM("FK","ACT") = SUM(I, EVFA("CAPT",I,"EFT")); 
  EFTSAM("FNR","ACT") = SUM(I, EVFA("NRES",I,"EFT"));   

* FOURTH BLOCK: ENTERPRISE. CAPITAL INCOME AND DEPRECIATION.     

  EFTSAM("ENT","FK") = VOM("CAPT","EFT");
  EFTSAM("ENT","PH") = VDEP("EFT");

* FIFTH BLOCK: HOUSEHOLDS. INCOME FROM FACTORS.

  EFTSAM("PH","FLD") = VOM("LAND","EFT");    
  EFTSAM("PH","FLB") = VOM("NSLB","EFT");
  EFTSAM("PH","FSL") = VOM("SKLB","EFT");
  EFTSAM("PH","ENT") = VOM("CAPT","EFT"); 
  EFTSAM("PH","FNR") = VOM("NRES","EFT"); 

* SIXTH BLOCK: GOVERNMENT. INDIRECT TAX,TARIFFS,
* FACTOR TAX,CAPITAL RETURN
* HOUSEHOLD TAX,NET TRANSFER AMONG GOVERNMENT.  

  EFTSAM("GV","PH") =  GOVEXP("EFT") - NETAXES("EFT");


  EFTSAM("GV","ACT") = SUM(I, PTAX(I,"EFT"));
  EFTSAM("GV","COMD") = SUM(I, MTAX(I,"EFT") + DPTAX(I,"EFT")
       + IPTAX(I,"EFT") + DGTAX(I,"EFT") + IGTAX(I,"EFT") + 
       sum(j, DFTAX(I,J,"EFT") + IFTAX(I,J,"EFT")) ); 

* SEVENTH BLOCK: CAPITAL ACCOUNT. ENTERPRISE SAVEINGS,
* HOUSEHOLD SAVEINGS, 
* GOVERNMENT SAVEING AND NET CAPITAL INFLOW
* (BANLANCE OF TRADE + NET FOREIGHN INVESTMENT) 

  EFTSAM("KA","ENT") = VDEP("EFT");
  EFTSAM("KA","PH") = SAVE("EFT");
  EFTSAM("KA", "WT") = - BOT("EFT") ;

* EIGTH BLOCK: REST OF THE WORLD. IMPORTS  

  EFTSAM("WT","COMD") = SUM((I,R), VIWS(I,R,"EFT"));

*NINTH BLOCK: INTERNATIONAL TRANSPORTATION SEVERCE. COST


* TENTH BLOCK: SUM OF COLUMN. EXPENDITURE

  EFTSAM("TOTAL","ACT") = SUM(SI1,EFTSAM(SI1,"ACT"));
  EFTSAM("TOTAL","COMD") = SUM(SI1,EFTSAM(SI1,"COMD"));
  EFTSAM("TOTAL","FLD") = SUM(SI1,EFTSAM(SI1,"FLD"));
  EFTSAM("TOTAL","FLB") = SUM(SI1,EFTSAM(SI1,"FLB"));
  EFTSAM("TOTAL","FSL") = SUM(SI1,EFTSAM(SI1,"FSL"));
  EFTSAM("TOTAL","FK") = SUM(SI1,EFTSAM(SI1,"FK"));
  EFTSAM("TOTAL","FNR") = SUM(SI1,EFTSAM(SI1,"FNR"));
  EFTSAM("TOTAL","ENT") = SUM(SI1,EFTSAM(SI1,"ENT"));
  EFTSAM("TOTAL","PH") = SUM(SI1,EFTSAM(SI1,"PH"));
  EFTSAM("TOTAL","GV") = SUM(SI1,EFTSAM(SI1,"GV"));
  EFTSAM("TOTAL","KA") = SUM(SI1,EFTSAM(SI1,"KA"));
  EFTSAM("TOTAL","WT") = SUM(SI1,EFTSAM(SI1,"WT"));

* SUM OF ROW: REVENUE

  EFTSAM(SI2,"TOTAL") = SUM(SI1,EFTSAM(SI2,SI1));
  EFTRES(SI) = EFTSAM("TOTAL",SI) - EFTSAM(SI,"TOTAL"); 

  OPTION EFTSAM:3:1:1; 
  DISPLAY  EFTSAM;
  OPTION DECIMALS=3; 
  DISPLAY EFTRES;

  PARAMETER EFTSRES;
  EFTSRES = SUM(SI1, EFTRES(SI1));

  DISPLAY EFTSRES;

* FIRST BLOCK: ACTIVITIES. DOMESTIC SUPPLY,EXPORT SUBSIDY, 
* EXPORTS AT MP
* EXPORTS FOR INTERNATIONAL TRANSPORTATION.

  FSUSAM("ACT","COMD") = SUM(I, VDM(I,"FSU"));

  FSUSAM("ACT","GV") = - SUM(I, XTAX(I,"FSU")); 
  FSUSAM("ACT", "WT") = SUM((I,S), VXWD(I,"FSU",S)); 

* SECOND BLOCK: COMMODITIES. INTERMEDIATE DEMAND,
* HOUSEHOLD CONSUMPTION,
* GOVERNMENT CONSUMPTION,INVESTMENT. 

  FSUSAM("COMD","ACT") = SUM((I,J)$(it(i)*it(j)),VFA(I,J,"FSU"));
  FSUSAM("COMD","PH")  =  SUM(I, VPA(I,"FSU"));
  FSUSAM("COMD","GV")  = SUM(I, VGA(I,"FSU"));  
*  FSUSAM("COMD","KA") = SUM(I$id(i), VFA(I,"CGDS","FSU"));
  FSUSAM("COMD","KA") = REGINV("FSU");

* THIRD BLOCK: VALUE ADDED  
  FSUSAM("FLD","ACT") = SUM(I, EVFA("LAND",I,"FSU"));
  FSUSAM("FLB","ACT") = SUM(I, EVFA("NSLB",I,"FSU"));   
  FSUSAM("FSL","ACT") = SUM(I, EVFA("SKLB",I,"FSU"));   
  FSUSAM("FK","ACT") = SUM(I, EVFA("CAPT",I,"FSU")); 
  FSUSAM("FNR","ACT") = SUM(I, EVFA("NRES",I,"FSU"));   

* FOURTH BLOCK: ENTERPRISE. CAPITAL INCOME AND DEPRECIATION.     

  FSUSAM("ENT","FK") = VOM("CAPT","FSU");
  FSUSAM("ENT","PH") = VDEP("FSU");

* FIFTH BLOCK: HOUSEHOLDS. INCOME FROM FACTORS.

  FSUSAM("PH","FLD") = VOM("LAND","FSU");    
  FSUSAM("PH","FLB") = VOM("NSLB","FSU");
  FSUSAM("PH","FSL") = VOM("SKLB","FSU");
  FSUSAM("PH","ENT") = VOM("CAPT","FSU"); 
  FSUSAM("PH","FNR") = VOM("NRES","FSU"); 

* SIXTH BLOCK: GOVERNMENT. INDIRECT TAX,TARIFFS,
* FACTOR TAX,CAPITAL RETURN
* HOUSEHOLD TAX,NET TRANSFER AMONG GOVERNMENT.  

  FSUSAM("GV","PH") =  GOVEXP("FSU") - NETAXES("FSU");


  FSUSAM("GV","ACT") = SUM(I, PTAX(I,"FSU"));
  FSUSAM("GV","COMD") = SUM(I, MTAX(I,"FSU") + DPTAX(I,"FSU")
       + IPTAX(I,"FSU") + DGTAX(I,"FSU") + IGTAX(I,"FSU") + 
       sum(j, DFTAX(I,J,"FSU") + IFTAX(I,J,"FSU")) ); 

* SEVENTH BLOCK: CAPITAL ACCOUNT. ENTERPRISE SAVEINGS,
* HOUSEHOLD SAVEINGS, 
* GOVERNMENT SAVEING AND NET CAPITAL INFLOW
* (BANLANCE OF TRADE + NET FOREIGHN INVESTMENT) 

  FSUSAM("KA","ENT") = VDEP("FSU");
  FSUSAM("KA","PH") = SAVE("FSU");
  FSUSAM("KA", "WT") = - BOT("FSU") ;

* EIGTH BLOCK: REST OF THE WORLD. IMPORTS  

  FSUSAM("WT","COMD") = SUM((I,R), VIWS(I,R,"FSU"));

*NINTH BLOCK: INTERNATIONAL TRANSPORTATION SEVERCE. COST


* TENTH BLOCK: SUM OF COLUMN. EXPENDITURE

  FSUSAM("TOTAL","ACT") = SUM(SI1,FSUSAM(SI1,"ACT"));
  FSUSAM("TOTAL","COMD") = SUM(SI1,FSUSAM(SI1,"COMD"));
  FSUSAM("TOTAL","FLD") = SUM(SI1,FSUSAM(SI1,"FLD"));
  FSUSAM("TOTAL","FLB") = SUM(SI1,FSUSAM(SI1,"FLB"));
  FSUSAM("TOTAL","FSL") = SUM(SI1,FSUSAM(SI1,"FSL"));
  FSUSAM("TOTAL","FK") = SUM(SI1,FSUSAM(SI1,"FK"));
  FSUSAM("TOTAL","FNR") = SUM(SI1,FSUSAM(SI1,"FNR"));
  FSUSAM("TOTAL","ENT") = SUM(SI1,FSUSAM(SI1,"ENT"));
  FSUSAM("TOTAL","PH") = SUM(SI1,FSUSAM(SI1,"PH"));
  FSUSAM("TOTAL","GV") = SUM(SI1,FSUSAM(SI1,"GV"));
  FSUSAM("TOTAL","KA") = SUM(SI1,FSUSAM(SI1,"KA"));
  FSUSAM("TOTAL","WT") = SUM(SI1,FSUSAM(SI1,"WT"));

* SUM OF ROW: REVENUE

  FSUSAM(SI2,"TOTAL") = SUM(SI1,FSUSAM(SI2,SI1));
  FSURES(SI) = FSUSAM("TOTAL",SI) - FSUSAM(SI,"TOTAL"); 

  OPTION FSUSAM:3:1:1; 
  DISPLAY  FSUSAM;
  OPTION DECIMALS=3; 
  DISPLAY FSURES;

  PARAMETER FSUSRES;
  FSUSRES = SUM(SI1, FSURES(SI1));

  DISPLAY FSUSRES;

* FIRST BLOCK: ACTIVITIES. DOMESTIC SUPPLY,EXPORT SUBSIDY, 
* EXPORTS AT MP
* EXPORTS FOR INTERNATIONAL TRANSPORTATION.

  TURSAM("ACT","COMD") = SUM(I, VDM(I,"TUR"));

  TURSAM("ACT","GV") = - SUM(I, XTAX(I,"TUR")); 
  TURSAM("ACT", "WT") = SUM((I,S), VXWD(I,"TUR",S)); 

* SECOND BLOCK: COMMODITIES. INTERMEDIATE DEMAND,
* HOUSEHOLD CONSUMPTION,
* GOVERNMENT CONSUMPTION,INVESTMENT. 

  TURSAM("COMD","ACT") = SUM((I,J)$(it(i)*it(j)),VFA(I,J,"TUR"));
  TURSAM("COMD","PH")  =  SUM(I, VPA(I,"TUR"));
  TURSAM("COMD","GV")  = SUM(I, VGA(I,"TUR"));  
*  TURSAM("COMD","KA") = SUM(I$id(i), VFA(I,"CGDS","TUR"));
  TURSAM("COMD","KA") = REGINV("TUR");

* THIRD BLOCK: VALUE ADDED  
  TURSAM("FLD","ACT") = SUM(I, EVFA("LAND",I,"TUR"));
  TURSAM("FLB","ACT") = SUM(I, EVFA("NSLB",I,"TUR"));   
  TURSAM("FSL","ACT") = SUM(I, EVFA("SKLB",I,"TUR"));   
  TURSAM("FK","ACT") = SUM(I, EVFA("CAPT",I,"TUR")); 
  TURSAM("FNR","ACT") = SUM(I, EVFA("NRES",I,"TUR"));   

* FOURTH BLOCK: ENTERPRISE. CAPITAL INCOME AND DEPRECIATION.     

  TURSAM("ENT","FK") = VOM("CAPT","TUR");
  TURSAM("ENT","PH") = VDEP("TUR");

* FIFTH BLOCK: HOUSEHOLDS. INCOME FROM FACTORS.

  TURSAM("PH","FLD") = VOM("LAND","TUR");    
  TURSAM("PH","FLB") = VOM("NSLB","TUR");
  TURSAM("PH","FSL") = VOM("SKLB","TUR");
  TURSAM("PH","ENT") = VOM("CAPT","TUR"); 
  TURSAM("PH","FNR") = VOM("NRES","TUR"); 

* SIXTH BLOCK: GOVERNMENT. INDIRECT TAX,TARIFFS,
* FACTOR TAX,CAPITAL RETURN
* HOUSEHOLD TAX,NET TRANSFER AMONG GOVERNMENT.  

  TURSAM("GV","PH") =  GOVEXP("TUR") - NETAXES("TUR");


  TURSAM("GV","ACT") = SUM(I, PTAX(I,"TUR"));
  TURSAM("GV","COMD") = SUM(I, MTAX(I,"TUR") + DPTAX(I,"TUR")
       + IPTAX(I,"TUR") + DGTAX(I,"TUR") + IGTAX(I,"TUR") + 
       sum(j, DFTAX(I,J,"TUR") + IFTAX(I,J,"TUR")) ); 

* SEVENTH BLOCK: CAPITAL ACCOUNT. ENTERPRISE SAVEINGS,
* HOUSEHOLD SAVEINGS, 
* GOVERNMENT SAVEING AND NET CAPITAL INFLOW
* (BANLANCE OF TRADE + NET FOREIGHN INVESTMENT) 

  TURSAM("KA","ENT") = VDEP("TUR");
  TURSAM("KA","PH") = SAVE("TUR");
  TURSAM("KA", "WT") = - BOT("TUR") ;

* EIGTH BLOCK: REST OF THE WORLD. IMPORTS  

  TURSAM("WT","COMD") = SUM((I,R), VIWS(I,R,"TUR"));

*NINTH BLOCK: INTERNATIONAL TRANSPORTATION SEVERCE. COST


* TENTH BLOCK: SUM OF COLUMN. EXPENDITURE

  TURSAM("TOTAL","ACT") = SUM(SI1,TURSAM(SI1,"ACT"));
  TURSAM("TOTAL","COMD") = SUM(SI1,TURSAM(SI1,"COMD"));
  TURSAM("TOTAL","FLD") = SUM(SI1,TURSAM(SI1,"FLD"));
  TURSAM("TOTAL","FLB") = SUM(SI1,TURSAM(SI1,"FLB"));
  TURSAM("TOTAL","FSL") = SUM(SI1,TURSAM(SI1,"FSL"));
  TURSAM("TOTAL","FK") = SUM(SI1,TURSAM(SI1,"FK"));
  TURSAM("TOTAL","FNR") = SUM(SI1,TURSAM(SI1,"FNR"));
  TURSAM("TOTAL","ENT") = SUM(SI1,TURSAM(SI1,"ENT"));
  TURSAM("TOTAL","PH") = SUM(SI1,TURSAM(SI1,"PH"));
  TURSAM("TOTAL","GV") = SUM(SI1,TURSAM(SI1,"GV"));
  TURSAM("TOTAL","KA") = SUM(SI1,TURSAM(SI1,"KA"));
  TURSAM("TOTAL","WT") = SUM(SI1,TURSAM(SI1,"WT"));

* SUM OF ROW: REVENUE

  TURSAM(SI2,"TOTAL") = SUM(SI1,TURSAM(SI2,SI1));
  TURRES(SI) = TURSAM("TOTAL",SI) - TURSAM(SI,"TOTAL"); 

  OPTION TURSAM:3:1:1; 
  DISPLAY  TURSAM;
  OPTION DECIMALS=3; 
  DISPLAY TURRES;

  PARAMETER TURSRES;
  TURSRES = SUM(SI1, TURRES(SI1));

  DISPLAY TURSRES;

* FIRST BLOCK: ACTIVITIES. DOMESTIC SUPPLY,EXPORT SUBSIDY, 
* EXPORTS AT MP
* EXPORTS FOR INTERNATIONAL TRANSPORTATION.

  ROWSAM("ACT","COMD") = SUM(I, VDM(I,"ROW"));

  ROWSAM("ACT","GV") = - SUM(I, XTAX(I,"ROW")); 
  ROWSAM("ACT", "WT") = SUM((I,S), VXWD(I,"ROW",S)); 

* SECOND BLOCK: COMMODITIES. INTERMEDIATE DEMAND,
* HOUSEHOLD CONSUMPTION,
* GOVERNMENT CONSUMPTION,INVESTMENT. 

  ROWSAM("COMD","ACT") = SUM((I,J)$(it(i)*it(j)),VFA(I,J,"ROW"));
  ROWSAM("COMD","PH")  =  SUM(I, VPA(I,"ROW"));
  ROWSAM("COMD","GV")  = SUM(I, VGA(I,"ROW"));  
*  ROWSAM("COMD","KA") = SUM(I$id(i), VFA(I,"CGDS","ROW"));
  ROWSAM("COMD","KA") = REGINV("ROW");

* THIRD BLOCK: VALUE ADDED  
  ROWSAM("FLD","ACT") = SUM(I, EVFA("LAND",I,"ROW"));
  ROWSAM("FLB","ACT") = SUM(I, EVFA("NSLB",I,"ROW"));   
  ROWSAM("FSL","ACT") = SUM(I, EVFA("SKLB",I,"ROW"));   
  ROWSAM("FK","ACT") = SUM(I, EVFA("CAPT",I,"ROW")); 
  ROWSAM("FNR","ACT") = SUM(I, EVFA("NRES",I,"ROW"));   

* FOURTH BLOCK: ENTERPRISE. CAPITAL INCOME AND DEPRECIATION.     

  ROWSAM("ENT","FK") = VOM("CAPT","ROW");
  ROWSAM("ENT","PH") = VDEP("ROW");

* FIFTH BLOCK: HOUSEHOLDS. INCOME FROM FACTORS.

  ROWSAM("PH","FLD") = VOM("LAND","ROW");    
  ROWSAM("PH","FLB") = VOM("NSLB","ROW");
  ROWSAM("PH","FSL") = VOM("SKLB","ROW");
  ROWSAM("PH","ENT") = VOM("CAPT","ROW"); 
  ROWSAM("PH","FNR") = VOM("NRES","ROW"); 

* SIXTH BLOCK: GOVERNMENT. INDIRECT TAX,TARIFFS,
* FACTOR TAX,CAPITAL RETURN
* HOUSEHOLD TAX,NET TRANSFER AMONG GOVERNMENT.  

  ROWSAM("GV","PH") =  GOVEXP("ROW") - NETAXES("ROW");


  ROWSAM("GV","ACT") = SUM(I, PTAX(I,"ROW"));
  ROWSAM("GV","COMD") = SUM(I, MTAX(I,"ROW") + DPTAX(I,"ROW")
       + IPTAX(I,"ROW") + DGTAX(I,"ROW") + IGTAX(I,"ROW") + 
       sum(j, DFTAX(I,J,"ROW") + IFTAX(I,J,"ROW")) ); 

* SEVENTH BLOCK: CAPITAL ACCOUNT. ENTERPRISE SAVEINGS,
* HOUSEHOLD SAVEINGS, 
* GOVERNMENT SAVEING AND NET CAPITAL INFLOW
* (BANLANCE OF TRADE + NET FOREIGHN INVESTMENT) 

  ROWSAM("KA","ENT") = VDEP("ROW");
  ROWSAM("KA","PH") = SAVE("ROW");
  ROWSAM("KA", "WT") = - BOT("ROW") ;

* EIGTH BLOCK: REST OF THE WORLD. IMPORTS  

  ROWSAM("WT","COMD") = SUM((I,R), VIWS(I,R,"ROW"));

*NINTH BLOCK: INTERNATIONAL TRANSPORTATION SEVERCE. COST


* TENTH BLOCK: SUM OF COLUMN. EXPENDITURE

  ROWSAM("TOTAL","ACT") = SUM(SI1,ROWSAM(SI1,"ACT"));
  ROWSAM("TOTAL","COMD") = SUM(SI1,ROWSAM(SI1,"COMD"));
  ROWSAM("TOTAL","FLD") = SUM(SI1,ROWSAM(SI1,"FLD"));
  ROWSAM("TOTAL","FLB") = SUM(SI1,ROWSAM(SI1,"FLB"));
  ROWSAM("TOTAL","FSL") = SUM(SI1,ROWSAM(SI1,"FSL"));
  ROWSAM("TOTAL","FK") = SUM(SI1,ROWSAM(SI1,"FK"));
  ROWSAM("TOTAL","FNR") = SUM(SI1,ROWSAM(SI1,"FNR"));
  ROWSAM("TOTAL","ENT") = SUM(SI1,ROWSAM(SI1,"ENT"));
  ROWSAM("TOTAL","PH") = SUM(SI1,ROWSAM(SI1,"PH"));
  ROWSAM("TOTAL","GV") = SUM(SI1,ROWSAM(SI1,"GV"));
  ROWSAM("TOTAL","KA") = SUM(SI1,ROWSAM(SI1,"KA"));
  ROWSAM("TOTAL","WT") = SUM(SI1,ROWSAM(SI1,"WT"));

* SUM OF ROW: REVENUE

  ROWSAM(SI2,"TOTAL") = SUM(SI1,ROWSAM(SI2,SI1));
  ROWRES(SI) = ROWSAM("TOTAL",SI) - ROWSAM(SI,"TOTAL"); 

  OPTION ROWSAM:3:1:1; 
  DISPLAY  ROWSAM;
  OPTION DECIMALS=3; 
  DISPLAY ROWRES;

  PARAMETER ROWSRES;
  ROWSRES = SUM(SI1, ROWRES(SI1));

  DISPLAY ROWSRES;

Parameter
chkact(i,r),
chkcom(ii,r)
chkacts(r),
chkcoms(r)

;

chkact(i,r) = VDM(i,r) - XTAX(i,r) + SUM(S, VXWD(i,r,S)) -
        SUM(j$(it(j)*it(i)), VFA(j,i,r)) - EVFA("LAND",i,r) - EVFA("NRES",i,r) -
        EVFA("NSLB",i,r) - EVFA("SKLB",i,r) - EVFA("CAPT",i,r) - PTAX(i,r); 

chkcom(ii,r) = SUM(j, VFA(ii,j,r)) + VPA(ii,r) + VGA(ii,r)
    - VDM(ii,r) - MTAX(ii,r) - DPTAX(ii,r)
       - IPTAX(ii,r) - DGTAX(ii,r) - IGTAX(ii,r) - 
       sum(jj, DFTAX(ii,jj,r) + IFTAX(ii,jj,r)) - SUM(s, 
      VIWS(ii,s,r));

chkacts(r) = sum(ii,chkact(ii,r)) ;
chkcoms(r) = sum(ii,chkcom(ii,r)) ;

display chkact, chkcom, chkacts, chkcoms ;


*########### PARAMETER DECLARATION ############

 PARAMETERS

*## Read in or calculated and used for initialization of variables

 PWM0(i,r,s)     WORLD MARKET PRICE for region s imported fr r
 PM0(i,r,s)      Import GOOD price in dom. mkt s imported fr r
 PE0(i,r,s)        Exort GOOD price in dom. mkt r export to s
 PMM0(i,r)       Armington PRICE OF import COMPOSITE GOOD
*                   { which is a function of PM0(i,r,s) }
 PEE0(i,r)       CET PRICE OF export COMPOSITE GOOD
*                   { which is a function of PM0(i,r,s) }
 PX0(i,r)        OUTPUT PRICE
 PPX0(i,r)       Producer PRICE
 PVA0(i,r)       Value added price including subsidies
 PD0(i,r)        DOMESTIC GOODS PRICE for users
 PC0(i,r)        ARMINGTON GOODS PRICE 
 PCT0(i,r)       ARMINGTON PRICE WITH SALES TAX
 PINDEX0(r)      OUTPUT (PX) PRICE INDEX
 XTAX0(r)        TOTAL EXPORT TAXES
 MTAX0(r)        TOTAL IMPORT TAXES
 CTAX0(r)        TOTAL commodity TAXES
 PTAX0(r)        Producer TAXES
 FSAVE0(r)       net foreign savings
 FBAL0(r,s)      CURRENT ACCOUNT BALANCE
 FDEBT0(r,s)     Foreign debt of region r from reg. s
 TFDEBT0(r)      Total foreign debt of region r
 FD0(iff,i,r)   FACTOR DEMAND by sectors
 FS0(iff,r)      AGGREGATE FACTOR SUPPLY
 GDTOT0(r)       Government consumption
 CDTOT0(r)       household consumption expenditure
 VGDP0(r)        NOMINAL GDP cal. from expenditure side
 GOVREV0(r)      Government revenue
 GOVEXP0(r)      Government expenditure
 CON0(r)         Aggregate household consumption
 PCON0(r)        Price index of total hh consumption
 HHT0(r)         Govt transfers to households
 HSAVE0(r)        Household savings
 X0(i,r)         DOMESTIC OUTPUT VOLUMNE
 M0(i,r,s)       IMPORTS BY REGION s from region r
 MM0(i,r)        Armington IMPORTS good s by region r
*                 { which is a function of M0(i,r,s) }
 EE0(i,r)        CET EXPORTS good s by region r
*                 { which is a function of M0(i,r,s) }
 CCD0(i,r)       total Armington demand by sector
 DC0(i,r)        Armington domestic demand by sector
 CD0(i,r)        Household demand by sector
 GD0(i,r)        Government demand by sector
 INVD0(i,r)      Investment demand by goods
 TINVD0(i,r)     Investment demand by goods including adj cost
 INTD0(i,r)      Intermediate demand
 WF0(iff,r)      AGGREGATE AVERAGE FACTOR PRICE
 WFDIST0(i,iff,r) FACTOR PRICE SECTORAL PROPORT CONSTANTS
 WFLDIFF0(iff,r) LABOR PRICE DIFFERENCE FROM AVERAGE
 YH0(r)          HOUSEHOLD INCOME
 ZTOT0(r)        Aggregate nominal investment

*## Model parameters

 CLES(i,r)          HOUSEHOLD CONSUMPTION SHARES
 HSHP(r)            HOUSEHOLD CONSUMPTION SHIFT PARAMETER
 gles(i,r)          Govt expenditure shares
 zshr(i,r)          Investment demand shares
 FA(r)              Shift parameter in adjust cost function
 ainv(r)            Shift parameter in new capital prod. function
 XTAXR0(i,r,s)      EXPORT TAX rate
 MTAXR0(i,r,s)      IMPORT TAX rate
 MSUBR0(i,r,s)      Import subsity rate
 PTAXR0(i,r)        Producer TAXES
 CTAXR0(i,r)        Cmmdty sales tax rate 
 PWTX(i,r)          PX WEIGHTS
 PWTC(i,r)          Consumer price weights

*## Define parameters used to hold country data

IO(i,j,r)            INPUT-OUTPUT BY COUNTRY
COMPRELAS(i,r,s)  COMPENSATED PRICE ELASTICITY OF DEMAND

*## READ IN PARAMETERS AS RATES, SHARES, ELASTICITIES
 SIGMAP(i,r)    ELASTICITY OF SUB BTW FACTORS OF PRODUCTION
 RHOM(i,r)      ARMINGTON FUNCTION EXPONENT for imports
 RHOC(i,r)      ARMINGTON FUNCTION EXPONENT for composite
 RHOE(i,r)      CET FUNCTION EXPONENT for exports
 RHOT(i,r)      CET FUNCTION EXPONENT for composite


*## COMPUTED FUNCTION PARAMETERS
 AM(i,r)      ARMINGTON FUNCTION SHIFT PARAMETER in imports
 AC(i,r)      ARMINGTON FUNCTION SHIFT PARAMETER in composite
 AE(i,r)      CET FUNCTION SHIFT PARAMETER in exports
 AT(i,r)      CET FUNCTION SHIFT PARAMETER in composite
 AD(i,r)      C-D PRODUCTION FUNCTION SHIFT PARAMETER
 ALPHA(iff,i,r)  C-D FACTOR SHARE PARAMETER
 MDELTA(i,r,s)  ARMINGTON SHARE PARAMETER in imports
 EDELTA(i,r,s)  CET SHARE PARAMETER in exports
 TDELTA(ii,r)   CET share parameter in composite
 DELTA(i,r)   ARMINGTON SHARE PARAMETER in composite

*## parameters and initial value of variables for steady state
 INV0(r)       New capital form from investment
 PINV0(r)      Price of capital investment
 VINV0(r)
 DIV0(r)       dividend 
 VFIRM0(r)     total value of total firm
 SHADOWQ0(r)   shadow price of capital (Tobbin's q)
 ADJCST0(r)    adjustment cost of unit investment
 R0(r)         Financial market interest rate
 ru(r)         Discount rate in intertemporal utility
 dpr(r)        Depreciation rate
 lgr(r)        labor growth rate
 RISK0(r)      Risk premium

;

*## BEGIN  READING AND CALIBRATION OF DATA

 TABLE BASELAST(*,ii) Base elasticities

       GRAIN    VEGOL   SUGAR   LIVSK   OAGRI   PROAG   TEXTL   MANUF   OTHMF          
RHOM   4.00     4.000   4.000   4.000   4.000   4.000   3.500   3.000   2.000
RHOC   3.00     3.000   3.000   3.000   3.000   2.000   2.000   2.000   1.500
RHOE   4.00     4.000   4.000   4.000   4.000   4.000   3.500   3.000   2.000
RHOT   3.00     3.000   3.000   2.000   2.000   2.000   2.000   2.000   1.500
;

 RHOM(ii,r)  = (1/BASELAST("rhom",ii)) - 1 ;
 RHOC(ii,r)  = (1/BASELAST("rhoc",ii)) - 1 ;
 RHOE(ii,r)  = (1/BASELAST("rhoe",ii)) + 1 ;
 RHOT(ii,r)  = (1/BASELAST("rhot",ii)) + 1 ;

*## calibrating prices pe0, pd0, px0, pwm0, pm
*## and quantitiy m0, mm0

*{ choosing PWM(ii,r,s) = 1 
*  such that VXWD(ii,r,s) = VIWS(ii,r,s) = M0(ii,r,s) }

PWM0(ii,r,s)$(VXWD(ii,r,s) ne 0) = 1 ;
PWM0(ii,r,s)$(VXWD(ii,r,s) eq 0) = 0 ;
M0(ii,r,s) = VXWD(ii,r,s) ;

*{ using VXMD(ii,r,s) to calculate PE(ii,r,s) }  
PE0(ii,r,s) = 0 ;
PE0(ii,r,s) = (VXMD(ii,r,s)/M0(ii,r,s))$(M0(ii,r,s) NE 0) ;

*{ using VIMS(ii,r,s) to calculate PM(ii,r,s) }  
PM0(ii,r,s) = (VIMS(ii,r,s)/M0(ii,r,s))$(M0(ii,r,s) NE 0) ;

display pm0, pe0 ;

*## export subsidy rate
XTAXR0(ii,r,s) = (1 - PE0(ii,r,s)/PWM0(ii,r,s))$
                 (PWM0(ii,r,s) NE 0) ;
XTAXR0(ii,r,r) = 0 ;
XTAXR0(ii,r,s)$(M0(ii,r,s) eq 0) = 0 ;

*## import tariff rate
MTAXR0(ii,r,s) = (PM0(ii,r,s)/PWM0(ii,r,s))$
                 (PWM0(ii,r,s) NE 0) - 1 ;

MTAXR0(ii,r,s)$(M0(ii,r,s) eq 0) = 0 ;

MTAXR0(ii,r,r) = 0 ;
MSUBR0(ii,r,s) = 0 ;

MSUBR0(ii,r,s)$(MTAXR0(ii,r,s) lt 0) = -MTAXR0(ii,r,s) + 0.1;

MTAXR0(ii,r,s)$(MTAXR0(ii,r,s) lt 0) = 0.1;

*## composite of import and export and their prices
PMM0(ii,r) = 1 ;
MM0(ii,r) = sum(s,PM0(ii,s,r)*M0(ii,s,r))/PMM0(ii,r) ;

PEE0(ii,r) = 1 ;
EE0(ii,r) = sum(s,PE0(ii,r,s)*M0(ii,r,s))/PEE0(ii,r) ;

*### domestic prices, demand and total supply

PD0(ii,r) = 1 ;
PX0(ii,r) = 1 ;
PC0(ii,r) = 1 ;

*### domestic goods and total supply

DC0(ii,r) = (VDPM(ii,r) + VDGM(ii,r) + 
            SUM(j, VDFM(ii,j,r)))/PD0(ii,r) ;

parameter 
chkmtax1(ii,r,s)
chkxtax1(ii,r) 
chkmtax2(ii,r)
chkxtax2(ii,r,s) 
;

chkmtax1(ii,s,r) = pm0(ii,s,r) - (1+mtaxr0(ii,s,r)-msubr0(ii,s,r))*
           pwm0(ii,s,r) ;
chkxtax1(ii,r) = xtax(ii,r) - sum(s,xtaxr0(ii,r,s)*
           pwm0(ii,r,s)*m0(ii,r,s)) ;

chkmtax2(ii,s) = sum(r,(mtaxr0(ii,r,s)-msubr0(ii,r,s)) - MTAXR(ii,r,s)) ;
chkxtax2(ii,r,s) = xtaxr0(ii,r,s) - XTAXR(ii,r,s) ;

display mtaxr0, chkmtax1, chkxtax1, chkmtax2, chkxtax2 ;

*##Armington of imports by sources:
* mdelta is coefficient on imports by regions
* amm is share parameter
 parameter DENOM1(ii,r)  denominator in mdelta equation ;

 DENOM1(ii,s) = sum(r,PM0(ii,r,s)*M0(ii,r,s)**(1+RHOM(ii,s)) ) ;
 MDELTA(ii,r,s) = 0 ;
 MDELTA(ii,r,s) = (PM0(ii,r,s)*M0(ii,r,s)**(1+RHOM(ii,s)))/
                  DENOM1(ii,s) ;

 AM(ii,r) = MM0(ii,r)/SUM(s,mdelta(ii,s,r)*M0(ii,s,r)**
           (-RHOM(ii,r)) )**(-1/RHOM(ii,r))  ;

*##CET of exports by destination:
* edelta is coefficient on exports by regions
* ae is share parameter
 parameter DENOE1(ii,r)  denominator in edelta equation ;

 DENOE1(ii,r) = sum(s,(PE0(ii,r,s)*M0(ii,r,s)**(1-RHOE(ii,r)))$
                      (M0(ii,r,s) ne 0)) ;
 EDELTA(ii,r,s) = 0 ;
 EDELTA(ii,r,s) = (PE0(ii,r,s)*M0(ii,r,s)**(1-RHOE(ii,r)))$
                   (M0(ii,r,s) ne 0)/DENOE1(ii,r) ;

 AE(ii,r) = EE0(ii,r)/SUM(s,edelta(ii,r,s)*M0(ii,r,s)**
           RHOE(ii,r) )**(1/RHOE(ii,r))  ;

parameter
chkpmm(ii,r)
chkpee(ii,r)
chkm1(ii,r,s)
chkm2(ii,r,s)
;

chkpmm(ii,r) = PMM0(ii,r) -  
           (sum(s$(PM0(ii,s,r) ne 0),
       mdelta(ii,s,r)**(1/(1+RHOM(ii,r)))*
       PM0(ii,s,r)**(RHOM(ii,r)/(1+RHOM(ii,r))) ) )**
       ((1+RHOM(ii,r))/RHOM(ii,r))/AM(ii,r) ;

chkpee(ii,r) = PEE0(ii,r) -  
           (sum(s$(PE0(ii,r,s) ne 0),
       edelta(ii,r,s)**(1/(1-RHOE(ii,r)))*
       PE0(ii,r,s)**(RHOE(ii,r)/(RHOE(ii,r)-1)) ) )**
       ((RHOE(ii,r)-1)/RHOE(ii,r))/AE(ii,r) ;

chkm1(ii,s,r) = M0(ii,s,r) -    
     (PMM0(ii,r)*mdelta(ii,s,r))**(1/(1+RHOM(ii,r)))*
        (PM0(ii,s,r)**(-1/(1+RHOM(ii,r))))$
        (PM0(ii,s,r) ne 0)*
     AM(ii,r)**(-RHOM(ii,r)/(1+RHOM(ii,r)))*MM0(ii,r) ;

chkm2(ii,r,s) = M0(ii,r,s) -    
     (PEE0(ii,r)*edelta(ii,r,s))**(1/(1-RHOE(ii,r)))*
        (PE0(ii,r,s)**(1/(RHOE(ii,r)-1)))$
        (PE0(ii,r,s) ne 0)*
     AE(ii,r)**(RHOE(ii,r)/(1-RHOE(ii,r)))*EE0(ii,r) ;

display chkpmm, chkpee, chkm1, chkm2, mm0, ee0 ;

parameter
chkmdel(ii,r)
chkedel(ii,r)
;
chkmdel(ii,s) = sum(r,mdelta(ii,r,s)) ;
chkedel(ii,r) = sum(s,edelta(ii,r,s)) ;
display chkmdel, chkedel ;

*### Armington good 
CCD0(ii,r) = (PD0(ii,r)*DC0(ii,r) + PMM0(ii,r)*MM0(ii,r))/
              PC0(ii,r) ;

*### commodity sales tax rate
CTAXR0(ii,r) = 0 ;
CTAXR0(ii,r) = ( DPTAX(ii,r) + IPTAX(ii,r) + DGTAX(ii,r) +
                IGTAX(ii,r)
              + sum(j$IP(j),DFTAX(ii,j,r) + IFTAX(ii,j,r)) )/
               ( PD0(ii,r)*(VDPM(ii,r) + VDGM(ii,r) + 
            sum(j$IP(j), VDFM(ii,j,r))) + PMM0(ii,r)*MM0(ii,r) ) ;

display ctaxr0 ;

 parameter 
 DENOC(ii,r)  denominator in delta equation
 ;

 DENOC(ii,r) = PMM0(ii,r)*MM0(ii,r)**(1+RHOC(ii,r)) +
               PD0(ii,r)*DC0(ii,r)**(1+RHOC(ii,r))  ;

 DELTA(ii,r) = 0 ;
 DELTA(ii,r) = (PMM0(ii,r)*MM0(ii,r)**(1+RHOC(ii,r)))/
                DENOC(ii,r) ;
AC(ii,r) = CCD0(ii,r)/(delta(ii,r)*
           MM0(ii,r)**(-RHOC(ii,r)) + 
           (1-delta(ii,r))*DC0(ii,r)**(-RHOC(ii,r)) )
            **(-1/RHOC(ii,r))  ;

PCT0(ii,r) = (1 + CTAXR0(ii,r))*PC0(ii,r) ;

parameter
chkpc(ii,r)
chkccd0(ii,r)
chkpcccd(ii,r)
chkpct0(ii,r)
;

chkpc(ii,r) = PC0(ii,r) - (delta(ii,r)**(1/(1+RHOC(ii,r)))*
       PMM0(ii,r)**(RHOC(ii,r)/(1+RHOC(ii,r))) +
         (1-delta(ii,r))**(1/(1+RHOC(ii,r)))*
       PD0(ii,r)**(RHOC(ii,r)/(1+RHOC(ii,r))))**
       ((1+RHOC(ii,r))/RHOC(ii,r))/AC(ii,r) ;

chkccd0(ii,r) = ccd0(ii,r) -AC(ii,r)*(delta(ii,r)*
           MM0(ii,r)**(-RHOC(ii,r)) + 
           (1-delta(ii,r))*DC0(ii,r)**(-RHOC(ii,r)) )
            **(-1/RHOC(ii,r))  ;

chkpcccd(ii,r) = pc0(ii,r)*ccd0(ii,r) - pd0(ii,r)*dc0(ii,r) -
          pmm0(ii,r)*mm0(ii,r) ;


display pct0, DELTA, chkpc, chkccd0, chkpcccd ;

*## production and CET

X0(ii,r) = (PD0(ii,r)*DC0(ii,r) + PEE0(ii,r)*EE0(ii,r))/
            PX0(ii,r) ;

*pp0 is producer's price after producer tax
PPX0(ii,r) = VOA(ii,r)/X0(ii,r) ;

*## production tax rates
PTAXR0(ii,r) = 0 ;
PTAXR0(ii,r) = PX0(ii,r)/PPX0(ii,r) - 1 ;

parameter 
chkx0(ii,r)
chkx02(ii,r)
chkptax1(ii,r)
chkptax2(ii,r)
;

chkx0(ii,r) = px0(ii,r)*x0(ii,r) - vom(ii,r) ;
chkx02(ii,r) = ppx0(ii,r)*x0(ii,r) - voa(ii,r) ;
chkptax1(ii,r) = ptax(ii,r) - ptaxr0(ii,r)*ppx0(ii,r)*x0(ii,r) ;
chkptax2(ii,r) = px0(ii,r)*x0(ii,r) - (1 + ptaxr0(ii,r))*
               ppx0(ii,r)*x0(ii,r) ;

display chkx0, chkx02,
chkptax1, chkptax2 ;

*### CET

 parameter 
 DENOT(ii,r)  denominator in tdelta equation
 ;

 DENOT(ii,r) = PEE0(ii,r)*EE0(ii,r)**(1-RHOT(ii,r)) +
               PD0(ii,r)*DC0(ii,r)**(1-RHOT(ii,r))  ;

 TDELTA(ii,r) = 0 ;
 TDELTA(ii,r) = (PEE0(ii,r)*EE0(ii,r)**(1-RHOT(ii,r)))/
                DENOT(ii,r) ;
AT(ii,r) = X0(ii,r)/(tdelta(ii,r)*
           EE0(ii,r)**RHOT(ii,r) + 
           (1-tdelta(ii,r))*DC0(ii,r)**RHOT(ii,r) )
            **(1/RHOT(ii,r))  ;

parameter
chkpx(ii,r)
chkee(ii,r)
;

chkpx(ii,r) = PX0(ii,r) - 
          (tdelta(ii,r)**(1/(1-RHOT(ii,r)))*
       PEE0(ii,r)**(RHOT(ii,r)/(RHOT(ii,r)-1)) +
         (1-tdelta(ii,r))**(1/(1-RHOT(ii,r)))*
       PD0(ii,r)**(RHOT(ii,r)/(RHOT(ii,r)-1)))**
       ((RHOT(ii,r)-1)/RHOT(ii,r))/AT(ii,r) ;

chkee(ii,r) = EE0(ii,r) - 
     (PX0(ii,r)*tdelta(ii,r))**(1/(1-RHOT(ii,r)))*
        (PEE0(ii,r)**(1/(RHOT(ii,r)-1)))*
     AT(ii,r)**(RHOT(ii,r)/(1-RHOT(ii,r)))*X0(ii,r) ;

display chkpx, chkee;

*### factor endowments and prices
WF0(iff,r) = 1 ;
FD0("LAND",ii,r) = VFA("LAND",ii,r)/WF0("LAND",r) ;
FD0("NRES",ii,r) = VFA("NRES",ii,r)/WF0("NRES",r) ;

FD0("LAND",ii,r)$(VFA("LAND",ii,r) eq 0) = 0 ;
FD0("NRES",ii,r)$(VFA("NRES",ii,r) eq 0) = 0 ;

FD0("NSLB",ii,r) = VFA("NSLB",ii,r)/WF0("NSLB",r) ;
FD0("SKLB",ii,r) = VFA("SKLB",ii,r)/WF0("NSLB",r) ;
FD0("CAPT",ii,r) = VFA("CAPT",ii,r)/WF0("CAPT",r) ;
FS0("LAND",r) = sum(ii,FD0("LAND",ii,r)) ;
FS0("nres",r) = sum(ii,FD0("nres",ii,r)) ;
FS0("NSLB",r) = sum(ii,FD0("NSLB",ii,r)) ;
FS0("SKLB",r) = sum(ii,FD0("SKLB",ii,r)) ;
FS0("CAPT",r) = sum(ii,FD0("CAPT",ii,r)) ;

parameter
chkfs(iff,r)
;
chkfs("LAND",r) = FS0("LAND",r)*WF0("LAND",r) - sum(ii,EVFA("LAND",ii,r)) ;
chkfs("NRES",r) = FS0("nres",r)*WF0("nres",r) - sum(ii,EVFA("nres",ii,r));
chkfs("NSLB",r) = FS0("NSLB",r)*WF0("NSLB",r) - sum(ii,EVFA("NSLB",ii,r));
chkfs("SKLB",r) = FS0("SKLB",r)*WF0("SKLB",r) - sum(ii,EVFA("SKLB",ii,r));
chkfs("CAPT",r) = FS0("CAPT",r)*WF0("CAPT",r) - sum(ii,EVFA("CAPT",ii,r));
display chkfs ;

*## Calculating dynamic paramter
*## investment
TINVD0(ii,r) =  (VDFA(ii,"CGDS",r) + VIFA(ii,"CGDS",r))/PCT0(ii,r) ;
ZTOT0(r) =  sum(ii,VDFA(ii,"CGDS",r) + VIFA(ii,"CGDS",r)) ;

 ru(r) = 0.05 ;
 R0(r) = ru(r) ;
 dpr(r) = 0.06 ;
 dpr("asa") = 0.17 ;
 dpr("e_u") = 0.085 ;
 dpr("eft") = 0.14 ;
 dpr("fsu") = 0.08 ;
 dpr("mar") = 0.11 ;
 dpr("rnf") = 0.10 ;
 dpr("tur") = 0.04 ;
 dpr("ome") = 0.045 ;
 
 DIV0(r) = sum(ii,EVFA("CAPT",ii,r)) - ZTOT0(r) ;
 
 VFIRM0(r) = DIV0(r)/R0(r) ;
 SHADOWQ0(r) = VFIRM0(r)/FS0("capt",r) ;


 risk0(r) = 0 ;

 FA(r) = ((dpr(r) + r0(r))*SHADOWQ0(r) - WF0("capt",r))/
                (PCT0("othmf",r)*dpr(r)**2) ;

display shadowq0, fa ;

 ADJCST0(r) =PCT0("othmf",r)*FA(r)*dpr(r) ;

 INV0(r) = FS0("capt",r)*dpr(r) ;

 PINV0(r) = ZTOT0(r)/INV0(r) - ADJCST0(r)  ;

INVD0(ii,r) = TINVD0(ii,r) ;

INVD0("othmf",r) = TINVD0("othmf",r) - ADJCST0(r)*INV0(r)/PCT0("othmf",r);

display invd0 ;

display adjcst0, fd0, dpr,VFIRM0,div0, tinvd0 ; 


parameter
chkr0(r)
chkadjcst(r)
chkdpr(r)

;

chkdpr(r) = dpr(r) - INV0(r)/FS0("capt",r) ;
chkadjcst(r) = adjcst0(r) - PCT0("othmf",r)*FA(r)*dpr(r) ;
chkr0(r) = DIV0(r)/VFIRM0(r) ;

display inv0, pinv0, chkr0, chkdpr, chkadjcst ;  

parameter
chkinvser(i,r)
;

chkadjcst(r) = adjcst0(r) -  
        PCT0("othmf",r)*FA(r)*INV0(r)/FS0("capt",r) ;


chkinvser("othmf",r) =  TINVD0("othmf",r) -
         (INVD0("othmf",r) + FA(r)*INV0(r)**2/FS0("capt",r)) ;

display chkadjcst, chkinvser ;

parameter
chkvinvc(r)
;

chkvinvc(r) = pinv0(r)*inv0(r) - sum(ii,pct0(ii,r)*invd0(ii,r)) ; 

display chkvinvc ;


parameter
chkvinv2(r)
chkpinv(r)
chktinvd0(i,r)
chkpinv2(r)
chkzshr(r)
chkshadow(r)
chkdiv(r)
chkinv(r)
;

ZSHR(ii,r) = PCT0(ii,r)*INVD0(ii,r)/(pinv0(r)*inv0(r)) ;

ainv(r) = INV0(r)/prod(ii,INVD0(ii,r)**zshr(ii,r));

chkpinv(r) = PINV0(r) - 1/(ainv(r)* prod(nn,zshr(nn,r)**zshr(nn,r)))*
          prod(nn,PCT0(nn,r)**zshr(nn,r));
chkzshr(r) = sum(ii,zshr(ii,r));

chkshadow(r) = SHADOWQ0(r) - 1/(r0(r) + dpr(r))*
 (WF0("capt",r) + PCT0("othmf",r)*FA(r)*dpr(r)**2) ;

display zshr, ainv, chkpinv, chkzshr, chkshadow ;


chkshadow(r) = SHADOWQ0(r) - div0(r)/(r0(r)*FS0("capt",r)) ;

chkvinv2(r) = ZTOT0(r) - (PCT0("othmf",r)*FA(r)*
        INV0(r)**2/FS0("capt",r) + PINV0(r)*INV0(r)) ;

chkdiv(r) = div0(r) - (WF0("capt",r)*FS0("capt",r) - ZTOT0(r)) ;

display chkshadow, chkvinv2, chkdiv ;


chkpinv(r) = (pinv0(r) + adjcst0(r))*inv0(r) - ZTOT0(r) ;

display chkpinv ;

*### trade account
*fbal0 is trade deficit of region r imports from region s
*fsave0 is foreign inflow into region r

Parameter
totvex(r)
totvim(r)
;

totvex(r) = sum((ii,s),PWM0(ii,r,s)*M0(ii,r,s)) ;
totvim(s) = sum((ii,r),PWM0(ii,r,s)*M0(ii,r,s)) ;

FBAL0(s,r) = sum(ii,PWM0(ii,s,r)*M0(ii,s,r) - 
                    PWM0(ii,r,s)*M0(ii,r,s)) ;
FSAVE0(r) = sum(s, FBAL0(s,r)) ;

 FDEBT0(r,s) = -FBAL0(r,s)/r0(s) ;
 TFDEBT0(r) = sum(s, FDEBT0(s,r)) ;

display totvex, totvim, fsave0, fdebt0, tfdebt0 ;
parameter
chkfsav
chkfdebt(r)
chkgoldb
chkinvt(r)
;
chkinvt(r) = ZTOT0(r) - VOA("CGDS",r) ;
chkfsav = sum(r, fsave0(r));
chkfdebt(r) = tfdebt0(r)*r0(r) + fsave0(r) ;
chkgoldb = sum(r,tfdebt0(r));


display fbal0, chkinvt,
chkfsav, chkfdebt, chkgoldb ; 

*##production and value added
alpha(iff,i,r)$it(i) = WF0(iff,r)*FD0(iff,i,r)/
           sum(ff, WF0(ff,r)*FD0(ff,i,r)) ;

AD(i,r)$it(i) = X0(i,r)/prod(iff,(FD0(iff,i,r)$
                      it(i))**alpha(iff,i,r)) ;

PVA0(i,r)$it(i) = 1/((AD(i,r)$it(i))*
         prod(iff,(alpha(iff,i,r)$it(i))**alpha(iff,i,r)))*
         prod(iff,WF0(iff,r)**alpha(iff,i,r) ) ;

IO(ii,nn,r) = (VDFA(ii,nn,r) + VIFA(ii,nn,r))/PCT0(ii,r) ;

INTD0(ii,r) = sum(nn,IO(ii,nn,r)) ; 
IO(ii,nn,r) = IO(ii,nn,r)/X0(nn,r) ;
 
parameter
chkpva(i,r)
chkpva2(i,r)
chkio(ii,r)
;

chkpva(i,r) = PVA0(i,r)*X0(i,r) - sum(iff,WF0(iff,r)*FD0(iff,i,r)) ;
chkpva2(ii,r) = PVA0(ii,r) - (PX0(ii,r)/(PTAXR0(ii,r)+1) - 
               sum(nn,IO(nn,ii,r)*PCT0(nn,r)) ) ;

display chkpva, chkpva2 ;

*## household and gov't income and consumption

CD0(ii,r) = (VDPA(ii,r)+ VIPA(ii,r))/PCT0(ii,r) ;
*GD0(ii,r) = (VDGA(ii,r) + VIGA(ii,r))/PCT0(ii,r) ;
*GDTOT0(r) = sum(ii,PCT0(ii,r)*GD0(ii,r));
*GOVEXP0(r) = GDTOT0(r) ;

display vdpa, vipa, cd0;

CD0(ii,r) = (VDPA(ii,r)+ VIPA(ii,r) + 
             VDGA(ii,r) + VIGA(ii,r))/PCT0(ii,r) ;
CDTOT0(r) = sum(ii,PCT0(ii,r)*CD0(ii,r));

CLES(ii,r) = (PCT0(ii,r)*CD0(ii,r))/CDTOT0(r) ;
*GLES(ii,r) = (PCT0(ii,r)*GD0(ii,r))/GDTOT0(r) ;

PCON0(r) = 1 ;
CON0(r) = sum(ii,PCT0(ii,r)*CD0(ii,r))/PCON0(r) ;
HSHP(r) = CON0(r)/prod(ii$CLES(ii,r),CD0(ii,r)**CLES(ii,r)) ;

parameter
chkccd(ii,r)
chkgexp(r)
chkhexp(r)
chkpcon(r)
;

chkccd(ii,r) = cd0(ii,r) + INTD0(ii,r) + tinvd0(ii,r) - ccd0(ii,r) ;

chkpcon(r) = PCON0(r) -
            1/(HSHP(r)*prod(ii$CLES(ii,r),CLES(ii,r)**CLES(ii,r)))*
             prod(ii$CLES(ii,r),PCt0(ii,r)**CLES(ii,r)) ;

*chkgexp(r) = govexp0(r) - govexp(r) ;
chkhexp(r) = cdtot0(r) - privexp(r) ;

display cd0, cles, chkccd, chkhexp, chkpcon ;

*### gov't revenues & transfer
XTAX0(r) = 0 ;
XTAX0(r) = sum((ii,s),xtaxr0(ii,r,s)*PWM0(ii,r,s)*M0(ii,r,s)) ;

MTAX0(r) = 0 ;
MTAX0(r) = sum((ii,s),(mtaxr0(ii,s,r)-msubr0(ii,s,r))*PWM0(ii,s,r)*M0(ii,s,r)) ;

CTAX0(r) = 0 ;
CTAX0(r) = sum(ii,ctaxr0(ii,r)*PC0(ii,r)*(CD0(ii,r)
               + TINVD0(ii,r) + sum(nn,IO(ii,nn,r)*X0(nn,r)) ) );

PTAX0(r) = 0 ;
PTAX0(r) = sum(ii, ptaxr0(ii,r)*PPX0(ii,r)*X0(ii,r));

GOVREV0(r) = XTAX0(r) + MTAX0(r) + CTAX0(r) + PTAX0(r) ;
*HHT0(r) = GOVREV0(r) - GOVEXP0(r) ;

YH0(r) = sum(iff, WF0(iff,r)*FS0(iff,r)) - 
        (PINV0(r) + ADJCST0(r))*INV0(r) + GOVREV0(r);

HSAVE0(r) = YH0(r) - sum(ii,PCT0(ii,r)*CD0(ii,r));

display yh0, hsave0;

parameter
chkyh(r)
chkhsav(r)
shgdp(i,r)

;
chkhsav(r) = HSAVE0(r) + VOA("CGDS",r) - (SAVE(r) + VDEP(r)) ;
chkyh(r) = YH0(r) + VOA("CGDS",r) - (NFACTINC(r) + VDEP(r) + 
                   (NETAXES(r) - GOVEXP(r)) );
display chkyh, chkhsav ; 

YH0(r) = sum(iff, WF0(iff,r)*FS0(iff,r)) - (PINV0(r) + ADJCST0(r))*
         INV0(r) + GOVREV0(r) - r0(r)*TFDEBT0(r);

HSAVE0(r) = YH0(r) - sum(ii,PCT0(ii,r)*CD0(ii,r));


VGDP0(r) = sum(ii, PCT0(ii,r)*(CD0(ii,r) + TINVD0(ii,r))) - FSAVE0(r) ;

shgdp(ii,r) = PVA0(ii,r)*X0(ii,r)/sum(nn,PVA0(nn,r)*X0(nn,r));

display yh0, hsave0, shgdp ;

parameter
chkctax(ii,r)
chkxtax(r)
chkmtax(r)
chkptax(r)
chktax(r)
;
chktax(r) = netaxes(r) - xtax0(r) - mtax0(r) - ctax0(r) -ptax0(r)
;
chkptax(r) = sum(ii,ptax(ii,r)) - ptax0(r) ;
chkxtax(r) = sum(ii,xtax(ii,r)) - xtax0(r) ;
chkmtax(r) = sum(ii,mtax(ii,r)) - mtax0(r) ;
chkctax(ii,r) = dptax(ii,r) + dgtax(ii,r) + 
                    iptax(ii,r) + igtax(ii,r) +
                    sum(j,dftax(ii,j,r) + iftax(ii,j,r))
              - ctaxr0(ii,r)*PC0(ii,r)*(CD0(ii,r) 
              + TINVD0(ii,r) + sum(nn,IO(ii,nn,r)*X0(nn,r)) );

display chktax, chkmtax, chkxtax, 
        chkptax, chkctax ;

*===========construction of SAM after calibration============
* FIRST BLOCK: ACTIVITIES. DOMESTIC SUPPLY,EXPORT SUBSIDY, 
* EXPORTS AT MP
* EXPORTS FOR INTERNATIONAL TRANSPORTATION.

  ASASAM("ACT","COMD") = SUM(ii, PD0(ii,"ASA")*DC0(ii,"ASA"));
  ASASAM("ACT","GV") = - XTAX0("ASA"); 
  ASASAM("ACT", "WT") = SUM((ii,s), PWM0(ii,"ASA",s)*
                            M0(ii,"ASA",s)); 

* SECOND BLOCK: COMMODITIES. INTERMEDIATE DEMAND,
* HOUSEHOLD CONSUMPTION,
* GOVERNMENT CONSUMPTION,INVESTMENT. 

  ASASAM("COMD","ACT") = SUM(ii, PCT0(ii,"ASA")*
                        INTD0(ii,"ASA"));
  ASASAM("COMD","PH") = SUM(ii, PCT0(ii,"ASA")*CD0(ii,"ASA"));
  ASASAM("COMD","GV") = 0; 

  ASASAM("COMD","KA") = SUM(ii, PCT0(ii,"ASA")*TINVD0(ii,"ASA")) ;
*  ASASAM("COMD","KA") = REGINV("ASA");

* THIRD BLOCK: VALUE ADDED  
  ASASAM("FLD","ACT") = SUM(i, WF0("LAND","ASA")*FD0("LAND",i,"ASA"));
  ASASAM("FNR","ACT") = SUM(i, WF0("NRES","ASA")*FD0("NRES",i,"ASA"));   
  ASASAM("FLB","ACT") = SUM(i, WF0("NSLB","ASA")*FD0("NSLB",i,"ASA"));   
  ASASAM("FSL","ACT") = SUM(i, WF0("SKLB","ASA")*FD0("SKLB",i,"ASA"));   
  ASASAM("FK","ACT") =  sum(i, WF0("CAPT","ASA")*FD0("CAPT",i,"ASA")) ; 

* FOURTH BLOCK: ENTERPRISE. CAPITAL INCOME AND DEPRECIATION.     

  ASASAM("ENT","FK") = sum(ii,WF0("CAPT","ASA")*FD0("CAPT",ii,"ASA"));
  ASASAM("ENT","PH") = 0 ;

* FIFTH BLOCK: HOUSEHOLDS. INCOME FROM FACTORS.

  ASASAM("PH","FLD") = WF0("LAND","ASA")*FS0("LAND","ASA");    
  ASASAM("PH","FNR") = WF0("NRES","ASA")*FS0("NRES","ASA") ;
  ASASAM("PH","FLB") = WF0("NSLB","ASA")*FS0("NSLB","ASA") ;
  ASASAM("PH","FSL") = WF0("SKLB","ASA")*FS0("SKLB","ASA") ;
  ASASAM("PH","FK") = 0 ;
  ASASAM("PH","ENT") = sum(ii,WF0("CAPT","ASA")*FD0("CAPT",ii,"ASA") - 
               PCt0(ii,"ASA")*TINVD0(ii,"ASA")) ;
  ASASAM("PH", "WT") = FSAVE0("ASA") ;

* SIXTH BLOCK: GOVERNMENT. INDIRECT TAX,TARIFFS,
* FACTOR TAX,CAPITAL RETURN
* HOUSEHOLD TAX,NET TRANSFER AMONG GOVERNMENT.  

  ASASAM("GV","PH") =  - GOVREV0("ASA") ;
  ASASAM("GV","ACT") = PTAX0("ASA");
  ASASAM("GV","COMD") = MTAX0("ASA") + CTAX0("ASA"); 

* SEVENTH BLOCK: CAPITAL ACCOUNT. ENTERPRISE SAVEINGS,
* HOUSEHOLD SAVEINGS, 
* GOVERNMENT SAVEING AND NET CAPITAL INFLOW
* (BANLANCE OF TRADE + NET FOREIGHN INVESTMENT) 

  ASASAM("KA","ENT") = SUM(ii,PCT0(ii,"ASA")*TINVD0(ii,"ASA")) ;
  ASASAM("KA","PH") = 0;
  ASASAM("KA", "WT") = 0 ;

* EIGTH BLOCK: REST OF THE WORLD. IMPORTS  

  ASASAM("WT","COMD") = SUM((ii,s), PWM0(ii,s,"ASA")*
                  M0(ii,s,"ASA"));

*NINTH BLOCK: INTERNATIONAL TRANSPORTATION SEVERCE. COST


* TENTH BLOCK: SUM OF COLUMN. EXPENDITURE

  ASASAM("TOTAL","ACT") = SUM(SI1,ASASAM(SI1,"ACT"));
  ASASAM("TOTAL","COMD") = SUM(SI1,ASASAM(SI1,"COMD"));
  ASASAM("TOTAL","FLD") = SUM(SI1,ASASAM(SI1,"FLD"));
  ASASAM("TOTAL","FNR") = SUM(SI1,ASASAM(SI1,"FNR"));
  ASASAM("TOTAL","FLB") = SUM(SI1,ASASAM(SI1,"FLB"));
  ASASAM("TOTAL","FSL") = SUM(SI1,ASASAM(SI1,"FSL"));
  ASASAM("TOTAL","FK") = SUM(SI1,ASASAM(SI1,"FK"));
  ASASAM("TOTAL","ENT") = SUM(SI1,ASASAM(SI1,"ENT"));
  ASASAM("TOTAL","PH") = SUM(SI1,ASASAM(SI1,"PH"));
  ASASAM("TOTAL","GV") = SUM(SI1,ASASAM(SI1,"GV"));
  ASASAM("TOTAL","KA") = SUM(SI1,ASASAM(SI1,"KA"));
  ASASAM("TOTAL","WT") = SUM(SI1,ASASAM(SI1,"WT"));

* SUM OF rich: REVENUE

  ASASAM(SI2,"TOTAL") = SUM(SI1,ASASAM(SI2,SI1));
  ASARES(SI) = ASASAM("TOTAL",SI) - ASASAM(SI,"TOTAL"); 

  OPTION ASASAM:3:1:1; 
  DISPLAY  ASASAM;
  OPTION DECIMALS=3; 
  DISPLAY ASARES;

  PARAMETER ASASRES;
  ASASRES = SUM(SI1, ASARES(SI1));

  DISPLAY ASASRES;


chkact(ii,r) = sum(nn,PCT0(nn,r)*IO(nn,ii,r)*X0(ii,r)) + 
   sum(iff,FD0(iff,ii,r)*WF0(iff,r)) +
   ptaxr0(ii,r)*PX0(ii,r)/(1+ptaxr0(ii,r))*X0(ii,r) -
   PX0(ii,r)*DC0(ii,r) + sum(s, xtaxr0(ii,r,s)*
   PWM0(ii,r,s)*M0(ii,r,s)) - SUM(s, PWM0(ii,r,s)*M0(ii,r,s)) ;

chkcom(ii,s) = PD0(ii,s)*DC0(ii,s) + sum(r,(mtaxr0(ii,r,s)-msubr0(ii,r,s))*
   PWM0(ii,r,s)*M0(ii,r,s)) + ctaxr0(ii,s)*PC0(ii,S)*CCD0(ii,s)
   + SUM(r, PWM0(ii,r,s)*M0(ii,r,s)) - 
   PCT0(ii,s)*(INTD0(ii,s) + CD0(ii,s) + TINVD0(ii,s)) ;

chkacts(r) = sum(ii,chkact(ii,r)) ;
chkcoms(r) = sum(ii,chkcom(ii,r)) ;

display chkact, chkcom, chkacts, chkcoms ;
 
Parameter

eshare(ii,r,s)
mshare(ii,r,s)
mtaxmid(ii,r)
mtaxseu(ii,r)
mtaxleu(ii,r)
mtaxe_u(ii,r)
mtaxnmid(ii,r)
mmidsh(ii,r)
emidsh(ii,r)
mseush(ii,r)
eseush(ii,r)
mleush(ii,r)
eleush(ii,r)
me_ush(ii,r)
ee_ush(ii,r)
tmtaxr(ii,r)
pagmtaxr(r)
pagmtreu(r)
pagmtrmd(r)
pagmtrrw(r)

;

eshare(ii,mid,mid2) = PWM0(ii,mid,mid2)*M0(ii,mid,mid2)/
                sum(s,PWM0(ii,mid,s)*M0(ii,mid,s)) ;

mshare(ii,mid,mid2) = PWM0(ii,mid,mid2)*M0(ii,mid,mid2)/
                sum(s,PWM0(ii,s,mid2)*M0(ii,s,mid2)) ;

emidsh(ii,mid) = sum(mid2,PWM0(ii,mid,mid2)*M0(ii,mid,mid2))/
                sum(s,PWM0(ii,mid,s)*M0(ii,mid,s)) ;

eseush(ii,mid) = sum(seu,PWM0(ii,mid,seu)*M0(ii,mid,seu))/
                sum(s,PWM0(ii,mid,s)*M0(ii,mid,s)) ;

eleush(ii,mid) = sum(leu,PWM0(ii,mid,leu)*M0(ii,mid,leu))/
                sum(s,PWM0(ii,mid,s)*M0(ii,mid,s)) ;

ee_ush(ii,mid) = PWM0(ii,mid,"e_u")*M0(ii,mid,"e_u")/
                sum(s,PWM0(ii,mid,s)*M0(ii,mid,s)) ;

mmidsh(ii,mid) = sum(mid2,PWM0(ii,mid2,mid)*M0(ii,mid2,mid))/
                sum(s,PWM0(ii,s,mid)*M0(ii,s,mid)) ;

mseush(ii,mid) = sum(seu,PWM0(ii,seu,mid)*M0(ii,seu,mid))/
                sum(s,PWM0(ii,s,mid)*M0(ii,s,mid)) ;

mleush(ii,mid) = sum(leu,PWM0(ii,leu,mid)*M0(ii,leu,mid))/
                sum(s,PWM0(ii,s,mid)*M0(ii,s,mid)) ;

me_ush(ii,mid) = PWM0(ii,"e_u",mid)*M0(ii,"e_u",mid)/
                sum(s,PWM0(ii,s,mid)*M0(ii,s,mid)) ;

mtaxmid(ii,mid)$(sum(mid2,PWM0(ii,mid2,mid)*M0(ii,mid2,mid)) ne 0) = 
                sum(mid2,MTAXR0(ii,mid2,mid)*PWM0(ii,mid2,mid)*M0(ii,mid2,mid))/
                sum(mid2,PWM0(ii,mid2,mid)*M0(ii,mid2,mid)) ;

mtaxseu(ii,mid) = sum(seu,MTAXR0(ii,seu,mid)*PWM0(ii,seu,mid)*M0(ii,seu,mid))/
                sum(seu,PWM0(ii,seu,mid)*M0(ii,seu,mid)) ;

mtaxleu(ii,mid) = sum(leu,MTAXR0(ii,leu,mid)*PWM0(ii,leu,mid)*M0(ii,leu,mid))/
                sum(leu,PWM0(ii,leu,mid)*M0(ii,leu,mid)) ;

mtaxe_u(ii,mid) = MTAXR0(ii,"e_u",mid) ;

mtaxnmid(ii,mid) = sum(nmid,MTAXR0(ii,nmid,mid)*PWM0(ii,nmid,mid)*M0(ii,nmid,mid))/
                sum(nmid,PWM0(ii,nmid,mid)*M0(ii,nmid,mid)) ;

tmtaxr(ii,r) = sum(s,MTAXR0(ii,s,r)*PWM0(ii,s,r)*M0(ii,s,r))/
                sum(s,PWM0(ii,s,r)*M0(ii,s,r)) ;

pagmtaxr(r) = sum((pagi,s),MTAXR0(pagi,s,r)*PWM0(pagi,s,r)*M0(pagi,s,r))/
                sum((pagi,s),PWM0(pagi,s,r)*M0(pagi,s,r)) ;
pagmtreu(mid) = sum(pagi,MTAXR0(pagi,"e_u",mid)*PWM0(pagi,"e_u",mid)*M0(pagi,"e_u",mid))/
                sum(pagi,PWM0(pagi,"e_u",mid)*M0(pagi,"e_u",mid)) ;
pagmtreu("e_u") = sum((pagi,mid),MTAXR0(pagi,mid,"e_u")*PWM0(pagi,mid,"e_u")*M0(pagi,mid,"e_u"))/
                sum((pagi,mid),PWM0(pagi,mid,"e_u")*M0(pagi,mid,"e_u")) ;
pagmtrmd(r)$(sum((pagi,mid),PWM0(pagi,mid,r)*M0(pagi,mid,r)) ne 0) = 
                sum((pagi,mid),MTAXR0(pagi,mid,r)*PWM0(pagi,mid,r)*M0(pagi,mid,r))/
                sum((pagi,mid),PWM0(pagi,mid,r)*M0(pagi,mid,r)) ;
pagmtrrw(r)$(sum((pagi,nmid),PWM0(pagi,nmid,r)*M0(pagi,nmid,r)) ne 0) =
                sum((pagi,nmid),MTAXR0(pagi,nmid,r)*PWM0(pagi,nmid,r)*M0(pagi,nmid,r))/
                sum((pagi,nmid),PWM0(pagi,nmid,r)*M0(pagi,nmid,r)) ;


display eshare, mshare, emidsh, eseush, eleush, ee_ush, mmidsh, mseush, mleush, me_ush, 
        mtaxmid, mtaxseu, mtaxleu, mtaxe_u,  mtaxnmid,
		  tmtaxr,  pagmtaxr, pagmtreu, pagmtrmd, pagmtrrw ;




