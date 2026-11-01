$TITLE  Electric Equilibrium - NLP and MCP Formulations

$ontext

This model has been slightly altered to avoid computational
problems related to poor scaling etc:

(i) I have set up an NLP formulation of the model to double
check the MCP model.

(ii) I have altered the value of eta from 0.1 to 0.4 in order
to avoid numerical overflow in functional evaluation.

(iii) I scale c(t) and beta(i) to achive equilibrium prices closer
to unity.

(iv) I have added a switch (nlpcalc) which determines whether the
NLP formulation is solved first.

The model appears to be fairly degenerate at the equilibrium.

$offtext


scalar nlpcalc /0/;

SETS i regions
       / A  Ontario,
         B  Quebec,
         C  NYPP,
         D  NEPOOL,
         E  MAIN,
         F  ECAR,
         G  PJM,
         H  TVA,
         I  VACAR /

     t generating plant types
       / NU    Nuclear,
         HY    Hydro,
         CL    Steam Coal,
         ST_O  Steam Oil,
         ST_G  Steam Gas,
         ST_D  Steam Dual,
         CT_O  Tubin Oil,
         CT_G  Tubin Gas,
         CT_D  Tubin Dual,
         CC_O  Combined Cycle Oil,
         CC_G  Combined Cycle Gad,
         CC_D  Combined Cycle Dual,
         IPP   IPP,
         FT    Future capacity, Other /

     a arc in the network
       / AC, AF, BC, BD, EF, FG, FI, GC, HE, HF, HI, IG /

     p path in the network
       / AC, AF, AFG, AFGC, AFI, AFIG, AFIGC,
         BC, BD,
         EF, EFG, EFGC, EFI, EFIG, EFIGC,
         FG, FGC, FI, FIG, FIGC,
         GC,
         HE, HEF, HEFG, HEFGC, HEFI, HEFIG, HEFIGC,
         HF, HFG, HFGC, HFI, HFIG, HFIGC,
         HI, HIG, HIGC,
         IG, IGC /;

SET patho(p,i) the origin of a path p

 / AC.A
   AF.A
   AFG.A
   AFGC.A
   AFI.A
   AFIG.A
   AFIGC.A
   BC.B
   BD.B
   EF.E
   EFG.E
   EFGC.E
   EFI.E
   EFIG.E
   EFIGC.E
   FG.F
   FGC.F
   FI.F
   FIG.F
   FIGC.F
   GC.G
   HE.H
   HEF.H
   HEFG.H
   HEFGC.H
   HEFI.H
   HEFIG.H
   HEFIGC.H
   HF.H
   HFG.H
   HFGC.H
   HFI.H
   HFIG.H
   HFIGC.H
   HI.H
   HIG.H
   HIGC.H
   IG.I
   IGC.I /;

SET pathd(p, i) the destination of a path p

 / AC.C
   AF.F
   AFG.G
   AFGC.C
   AFI.I
   AFIG.G
   AFIGC.C
   BC.C
   BD.D
   EF.F
   EFG.G
   EFGC.C
   EFI.I
   EFIG.G
   EFIGC.C
   FG.G
   FGC.C
   FI.I
   FIG.G
   FIGC.C
   GC.C
   HE.E
   HEF.F
   HEFG.G
   HEFGC.C
   HEFI.I
   HEFIG.G
   HEFIGC.C
   HF.F
   HFG.G
   HFGC.C
   HFI.I
   HFIG.G
   HFIGC.C
   HI.I
   HIG.G
   HIGC.C
   IG.G
   IGC.C /;

alias (i,j,k);

SCALARS eta  /0.4/
        forate Forced Outrage Rate /0.15/;

PARAMETER c(t) marginal cost of type t plant
  / NU     5550,
    HY        0,
    CL    14250,
    ST_O  36000,
    ST_G  30000,
    ST_D  30000,
    CT_O  77000,
    CT_G  35000,
    CT_D  35000,
    CC_O  60500,
    CC_G  25000,
    CC_D  26250,
    IPP   25000,
    FT    25000 /;

PARAMETER beta(i) region i s beta parameter in demand function
  / A  28653,
    B  25953,
    C  37722,
    D  28491,
    E  61696,
    F 122294,
    G  62224,
    H  34681,
    I  67168 /;

PARAMETER peakdemand(i) peak demand
  / A  20767,
    B  18810,
    C  27340,
    D  20650,
    E  44716,
    F  88636,
    G  45099,
    H  25136,
    I  48682 /;

TABLE pcap(i, t) production capacity of plant type t at region i

       NU    HY    CL  ST_O  ST_G  ST_D  CT_O  CT_G
  A 14164  6248  9710  2220   196     0   230     0
  B   670 27950     0   550     0     0   800     0
  C  4871  4016  4525  1987   228  9332  1982    45
  D  6375  1407  2612  4516     0  3116  1107     0
  E 14843   549 27555  1658   161  2260  1219   755
  F  7668   678  3628 81416  1845  1108     0  1695
  G 12932  1150 11623  5426     0  9606  4181   245
  H  6582  4704 14685     0     0     0  1096     0
  I 14472  3018 23367  1021     0   818  2902    25

  +  CT_D  CC_O  CC_G  CC_D   IPP    FT
  A     0     0     0     0  1015     0
  B     0     0     0     0   330     0
  C  1563     0     0   136  5347     6
  D   210     0   150   905  2744    52
  E  1670     0     0     0    84   146
  F  3342     0   109    25  2045   143
  G  3740   233   235  1373  4149   351
  H   840     0     0     0     0     0
  I  1421     0     0   397  4122     0 ;

PARAMETER pumpstag(i) pumped storage

/ A    0
  B    0
  C 1040
  D 1682
  E  350
  F 3628
  G 1361
  H 1532
  I 3597 /;

TABLE delta(p, a) path-arc incidence matrix

            AC  AF  BC  BD  EF  FG  FI  GC  HE  HF  HI  IG
   AC        1   0   0   0   0   0   0   0   0   0   0   0
   AF        0   1   0   0   0   0   0   0   0   0   0   0
   AFG       0   1   0   0   0   1   0   0   0   0   0   0
   AFGC      0   1   0   0   0   1   0   1   0   0   0   0
   AFI       0   1   0   0   0   0   1   0   0   0   0   0
   AFIG      0   1   0   0   0   0   1   0   0   0   0   1
   AFIGC     0   1   0   0   0   0   1   1   0   0   0   1
   BC        0   0   1   0   0   0   0   0   0   0   0   0
   BD        0   0   0   1   0   0   0   0   0   0   0   0
   EF        0   0   0   0   1   0   0   0   0   0   0   0
   EFG       0   0   0   0   1   1   0   0   0   0   0   0
   EFGC      0   0   0   0   1   1   0   1   0   0   0   0
   EFI       0   0   0   0   1   0   1   0   0   0   0   0
   EFIG      0   0   0   0   1   0   1   0   0   0   0   1
   EFIGC     0   0   0   0   1   0   1   1   0   0   0   1
   FG        0   0   0   0   0   1   0   0   0   0   0   0
   FGC       0   0   0   0   0   1   0   1   0   0   0   0
   FI        0   0   0   0   0   0   1   0   0   0   0   0
   FIG       0   0   0   0   0   0   1   0   0   0   0   1
   FIGC      0   0   0   0   0   0   1   1   0   0   0   1
   GC        0   0   0   0   0   0   0   1   0   0   0   0
   HE        0   0   0   0   0   0   0   0   1   0   0   0
   HEF       0   0   0   0   1   0   0   0   1   0   0   0
   HEFG      0   0   0   0   1   1   0   0   1   0   0   0
   HEFGC     0   0   0   0   1   1   0   1   1   0   0   0
   HEFI      0   0   0   0   1   0   1   0   1   0   0   0
   HEFIG     0   0   0   0   1   0   1   0   1   0   0   1
   HEFIGC    0   0   0   0   1   0   1   1   1   0   0   1
   HF        0   0   0   0   0   0   0   0   0   1   0   0
   HFG       0   0   0   0   0   1   0   0   0   1   0   0
   HFGC      0   0   0   0   0   1   1   0   0   1   0   0
   HFI       0   0   0   0   0   0   1   0   0   1   0   0
   HFIG      0   0   0   0   0   0   1   0   0   1   0   1
   HFIGC     0   0   0   0   0   0   1   1   0   1   0   1
   HI        0   0   0   0   0   0   0   0   0   0   1   0
   HIG       0   0   0   0   0   0   0   0   0   0   1   1
   HIGC      0   0   0   0   0   0   0   1   0   0   1   1
   IG        0   0   0   0   0   0   0   0   0   0   0   1
   IGC       0   0   0   0   0   0   0   1   0   0   0   1 ;

PARAMETER transcap(a)
  / AC   300,
    AF   500,
    BC   800,
    BD  1550,
    EF   325,
    FG  1894,
    FI  1311,
    GC   361,
    HE    28,
    HF   277,
    HI   214,
    IG     0 /;

scalar gamma; gamma = (eta-1)/eta;

variables
    surplus     maximand
    d(i)        demand at region i;

positive variables
    y(i,t)      production from plant type t at region i
    h(p)        flow on path p
    x(a)        flow on arc a;

equations
    objdef      define the sum of consumer and producer surplus
    market(i)   market clearance condition at region i
    flow(a)     flow on arc a;

*-----------------------------------------------------------------

objdef..        surplus =e= sum(i, beta(i)**(1/eta) *
                                d(i)**gamma / gamma)
                                - sum((i,t), y(i,t) * c(t));

market(i)..       sum(t, y(i,t)) + sum(p$pathd(p,i), h(p))
                        =e= d(i) + sum(p$patho(p,i), h(p)) ;

flow(a)..       sum(p$delta(p,a), h(p)) =e= x(a);

*-----------------------------------------------------------------

y.up(i,t) = (1-forate) * pcap(i,t);
x.up(a) = transcap(a)+50;  
x.lo(a) = max(transcap(a)-50, 0);

d.l(i) = 1;
d.lo(i) = 0.01;

model pathnlp /all/;

positive
variables       pi(i)   market prices;
variables       mu(a)   shadow price on arc a;
equations
        xopt(a)         optimality condition for x
        yopt(i,t)       optimality condition for y
        hopt(p)         optimality condition for h
        mkt(i)          market clearance condition (with demand function);

*-----------------------------------------------------------------

yopt(i,t)$pcap(i,t)..   c(t) =e= pi(i);

xopt(a)..       mu(a) =e= 0;

hopt(p)..       sum(i$patho(p,i), pi(i)) =g= sum(i$pathd(p,i), pi(i)) +
                                             sum(a$delta(p,a), mu(a));

mkt(i)..     sum(t$pcap(i,t), y(i,t)) + sum(p$pathd(p,i), h(p))

                =g= beta(i) * pi(i)**(-eta) + sum(p$patho(p,i), h(p));

*-----------------------------------------------------------------

model pathmcp / mkt.pi, flow.mu, xopt.x, yopt.y, hopt.h/;

pi.lo(i) = 0.001;


*       Do some scaling to produce prices which are closer to
*       unity:

beta(i) = beta(i) * 1000**(-eta);
c(t) = c(t) / 1000;

if (nlpcalc,

        solve pathnlp using nlp maximizing surplus;
        pathmcp.iterlim = 0;
        pi.l(i) = max(-market.m(i), 0.0001);
        mu.l(a) = flow.m(a);
        solve pathmcp using mcp;
else
        y.l(i,t) = 1;
        h.l(p)  = 1;
        x.l(a)  = 1;
        pi.l(i) = 1;
        mu.l(a) = 1;
);

*       Now check the MCP solution:

pathmcp.iterlim = 4000;

file polystructure / 'poly.txt' /;
put polystructure;
loop ( (a),
   put flow(a)/;
);
*loop ((i),
*   put mkt(i)/;
*);


putclose polystructure;

solve pathmcp using mcp;

