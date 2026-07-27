$TITLE A LITERAL TRANSLATION OF data3.dat (9x9) INTO GAMS.
$OFFSYMLIST OFFSYMXREF OFFUPPER
OPTIONS LIMROW=0,LIMCOL=0,RESLIM=10000000

$offlisting

SET I ALL COMMODITIES AND FACTORS OF PRODUCTION
 
/       LAND   Land,
        NSLB   Unskilled Labor,
        SKLB   Skilled Labor,
        CAPT   Capital,
        NRES   Natural resources,
        grain  grain crop agriculture
        vegol  vegetable and fruits
        sugar  sugar
        livsk  livestock
        oagri  other agriculture
        proag  processed agriculture
        textl  textile and wearing
        manuf  producer manufacturing
        othmf  others including energy mining and services
        CGDS Savings good/,

 
   R region /
        ASA Asian countries
        E_U EU
        EFT European Free Trade Area and CEEC
        FSU Former Soviet Union countries
        TUR Turkey
        OME Other middle east countries
        MAR Morocco
        RNF Other North African countries
        ROW Rest of world
        / ,

       F(I) PRIMARY FACTORS (ENDOWMENT COMMODITIES)
      /LAND Land,
       NSLB Unskilled Labor,
       SKLB Skilled Labor,
       CAPT Capital,
       NRES Natural resources
       /,

       IK(I) CAPITAL GOODS /CGDS/,

       IT(I) TRADED COMMODITIES
       IN(I) NON-SAVINGS COMMODITIES,
       ID(I) DEMANDED COMMODITIES,
       IP(I) PRODUCED COMMODITIES;

* Set up commodity subsets:

IT(I) = YES;  IT(F) = NO; IT(IK) = NO;
IN(I) = YES;  IN(IK) = NO;
ID(I) = YES;  ID(IK) = NO;
IP(I) = YES;  IP(F) = NO;

ALIAS (I,J,JJ,K), 
      (R,S,RR,RR1);


SETS
  PT(r,s)   Country trading partners
/ASA.(     E_U, EFT, FSU, TUR, OME, MAR, RNF, ROW)
 E_U.(ASA,      EFT, FSU, TUR, OME, MAR, RNF, ROW)
 EFT.(ASA, E_U,      FSU, TUR, OME, MAR, RNF, ROW)
 FSU.(ASA, E_U, EFT,      TUR, OME, MAR, RNF, ROW)
 TUR.(ASA, E_U, EFT, FSU,      OME, MAR, RNF, ROW)
 OME.(ASA, E_U, EFT, FSU, TUR,      MAR, RNF, ROW)
 MAR.(ASA, E_U, EFT, FSU, TUR, OME,      RNF, ROW)
 RNF.(ASA, E_U, EFT, FSU, TUR, OME, MAR,      ROW)
 ROW.(ASA, E_U, EFT, FSU, TUR, OME, MAR, RNF     )
 
 / ;


PARAMETER

MFRV(i,r,s) Export tax MFA for comm i from reg r to reg s
PURV(i,r,s) Export tax PU  for comm i from reg r to reg s
VRRV(i,r,s) Export tax VER  for comm i from reg r to reg s
XTRV(i,r,s) Export tax proper for comm i from reg r to reg s
ADRV(i,r,s) Import tax anti dumping of comm i from reg r to s
TFRV(i,r,s) Import tax Proper  for comm i from reg r to reg s

EVOA(i,r) Value of commodity i output in region r
EVFA(i,j,r) Producer expenditure on i by industry
SAVE(r)  Expenditure on net savings in region
VIFA(i,j,r) Purchases of imported i r for use in j in region r
VDFA(i,j,r) Purchases of domestic i r for use i
VIPA(i,r) Private household expenditure on imported i
VDPA(i,r) Private household expenditure on domestic i in r
VIGA(i,r) Government household expenditure on imported i
VDGA(i,r) Government household expenditure on domestic i in r
VKB(r)  Value of beginning-of-period capital stock in region r
VDEP(r)  Value of capital depreciation in region r
VXMD(i,r,s) Exports of commodity i from region r
VST(i,r) Exports of commodity i from region r intern. transport
VFM(i,j,r) Producer expend on i by j in reg r at market prices
VIFM(i,j,r) Purchases of imports i for use in j in region r
VDFM(i,j,r) Purchases of domestic i r for use in j in region r
VIPM(i,r) Private household expenditure on i in r
VDPM(i,r) Private household expenditure on domestic i in r
VIGM(i,r) Government expenditure on i in r
VDGM(i,r) Government expenditure on domestic i in r
VIMS(i,r,s) Imports of commodity i fr reg r to s (mkt prices)
VXWD(i,r,s) Exports of commodity i from region r to s (fob)
VIWS(i,r,s) Imports of commodity i from region r to s (cif)

VFA(i,j,r) Producer expend on i by j in reg r at agent's prices
VOA(i,r) Value of commodity i output in region r
VDM(i,r) Domestic sales of commodity i in region r  market prices
VOM(i,r) Value of commodity i output in region r
VPA(i,r) Private household expenditure on iin  r at agent's prices
PRIVEXP(r) Private consumption expenditure in region r
VGA(i,r) Government expenditure on i in region r at agent's prices
GOVEXP(r) Government expenditure in region r
INCOME(r) Aggregate household expenditure in region r
VTWR(i,r,s) Transportation services for shipment of i from r to s
GVT  The value of total international transportation services.
REGINV(r) regional gross investment in region r
GLOBINV  Global expenditures on net investment
VWLDSALES(r) Value of sales (purch) to (fr) the world market by r.
VEXPORTS(r) Value of sales to the world market from r.
VIMPORTS(s) value of purchases from world market by s.
NNPE(r)  Net national product in r from the expenditures side
ETAX(i,r)  Value of factor tax
PTAX(i,r)  Value of product tax
DPTAX(i,r) Value of conmmodity tax of dom. gooby by household
IPTAX(i,r) Value of conmmodity tax of imp. gooby by household
DGTAX(i,r) Value of conmmodity tax of dom. gooby by gov't
IGTAX(i,r) Value of conmmodity tax of imp. gooby by gov't
DFTAX(i,j,r) Value of conmmodity tax of dom. gooby by firm
IFTAX(i,j,r) Value of conmmodity tax of imp. gooby by firm
XTAX(i,r) Value of export tax
MTAX(i,r) Value of import tax
SXTAX(i,r,s) Value of export tax
SMTAX(i,r,s) Value of import tax

GROSSTAXES(r) Gross tax revenues in region r.
NETAXES(r) Net tax revenues in r.
NFACTINC(r) Factor income, net of depreciation.
NNPS(r)  Net national product in r based on sources of income
PROFITS(j,r) Preliminary estimate of profits in j of r.
BOT(r) imbalance of trade by region
CCBOT(i) balance of trade by goods, 
*  -- should be zero after tran. data adjustment
GCCBOT global balance of trade by goods, should be zero
GBOT global balance of trade by region, should be zero
SURPLUS(s) Economic surplus in region s, should equal zero.
BOP(r)  Balance of payments in region r, should equal zero.
CHKTRANS Difference btw demand & supply of transport services.
* -- after adjusting tran. data, this equation should be dropped
CHKSAVE  Checking equality of global savings & investment
CHKCLDOM(i,s) Check on traded commodities supply and demand, zero
CHKCLENDW(i,r) Check on factor supply and demand, zero
CHKCLTRD(i,r) Check on traded commodities supply and demand, zero

;

$include data3.DAT

MFRV(i,r,s) = CMFAREV(i,r,s) ;
PURV(i,r,s) = CPUREV(i,r,s) ;
VRRV(i,r,s) = CVERREV(i,r,s) ;
XTRV(i,r,s) = CXTREV(i,r,s) ;
ADRV(i,r,s) = CADREV(i,r,s) ;
TFRV(i,r,s) = CTARIFREV(i,r,s) ;

EVOA(i,r) = CEVOA(i,r)     ;
EVFA(i,j,r) = CEVFA(i,j,r) ;
SAVE(r)  = CSAVE(r)        ;
VIFA(i,j,r) = CVIFA(i,j,r) ;
VDFA(i,j,r) = CVDFA(i,j,r) ;
VIPA(i,r) = CVIPA(i,r)     ;
VDPA(i,r) = CVDPA(i,r)     ;
VIGA(i,r) = CVIGA(i,r)     ;
VDGA(i,r) = CVDGA(i,r)     ;
VKB(r) = CVKB(r)           ;
VDEP(r) = CVDEP(r)         ;
VXMD(i,r,s) = CVXMD(i,r,s) ;
VST(i,r) = CVST(i,r)       ;
VFM(i,j,r) = CVFM(i,j,r)   ;
VIFM(i,j,r) = CVIFM(i,j,r) ;
VDFM(i,j,r) = CVDFM(i,j,r) ;
VIPM(i,r) = CVIPM(i,r)     ;
VDPM(i,r)  = CVDPM(i,r)    ;
VIGM(i,r) = CVIGM(i,r)     ;
VDGM(i,r) = CVDGM(i,r)     ;
VIMS(i,r,s) = CVIMS(i,r,s) ;
VXWD(i,r,s) = CVXWD(i,r,s) ;
VIWS(i,r,s) = CVIWS(i,r,s) ;


display evfa, vdpa, vifm, vxmd ;

