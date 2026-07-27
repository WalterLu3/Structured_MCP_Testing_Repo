*include file
*name: LOADSOL0.INC for exp1

*$onlisting
MACROTAB("walras",r,tp,siter)$(RGT(tp) lt 3) = WALRAS.L(r,tp) ;
PRODTAB("walras2",ii,r,tp,siter)$(RGT(tp) lt 2) = WALRAS2.L(ii,r,tp) ;
MACROTAB("walras3","row",tp,siter)$(RGT(tp) lt 3) = 
        sum(r,scTFDEBT(r)*TFDEBT.L(r,tp)) ;
MACROTAB("walras4","row","1",siter) =  OBJECT.L ;

MACROTAB("PWINDEX","row",tp, siter)$(RGT(tp) lt 16) =
               sum((ii,r,s),M0(ii,r,s)*PWM0(ii,r,s)*PWM.L(ii,r,s,tp))/
					sum((ii,r,s),PWM0(ii,r,s)*M0(ii,r,s)) ;
MACROTAB("PWINDEX","row",tp, siter)$(RGT(tp) eq card(tp)) =
               sum((ii,r,s),M0(ii,r,s)*PWM0(ii,r,s)*PWM.L(ii,r,s,tp))/
					sum((ii,r,s),PWM0(ii,r,s)*M0(ii,r,s)) ;

MACROTAB("PWAGINDEX","row",tp, siter)$(RGT(tp) lt 16) =
               sum((agi,r,s),M0(agi,r,s)*PWM0(agi,r,s)*PWM.L(agi,r,s,tp))/
					sum((agi,r,s),PWM0(agi,r,s)*M0(agi,r,s)) ;
MACROTAB("PWAGINDEX","row",tp, siter)$(RGT(tp) eq card(tp)) =
               sum((agi,r,s),M0(agi,r,s)*PWM0(agi,r,s)*PWM.L(agi,r,s,tp))/
					sum((agi,r,s),PWM0(agi,r,s)*M0(agi,r,s)) ;

MACROTAB("PWPAGINDEX","row",tp, siter)$(RGT(tp) lt 16) =
               sum((pagi,r,s),M0(pagi,r,s)*PWM0(pagi,r,s)*PWM.L(pagi,r,s,tp))/
					sum((pagi,r,s),PWM0(pagi,r,s)*M0(pagi,r,s)) ;
MACROTAB("PWPAGINDEX","row",tp, siter)$(RGT(tp) eq card(tp)) =
               sum((pagi,r,s),M0(pagi,r,s)*PWM0(pagi,r,s)*PWM.L(pagi,r,s,tp))/
					sum((pagi,r,s),PWM0(pagi,r,s)*M0(pagi,r,s)) ;

MACROTAB("PWMINDEX",r,tp,siter)$(RGT(tp) lt 16) =
       sum((ii,s),M0(ii,s,r)*PWM0(ii,s,r)*PWM.l(ii,s,r,tp))/
      sum((ii,s),M0(ii,s,r)*PWM0(ii,s,r)) ;   
MACROTAB("PWMINDEX",r,tp,siter)$(RGT(tp) eq card(tp)) =
       sum((ii,s),M0(ii,s,r)*PWM0(ii,s,r)*PWM.l(ii,s,r,tp))/
      sum((ii,s),M0(ii,s,r)*PWM0(ii,s,r)) ;    

MACROTAB("PWEINDEX",r,tp,siter)$(RGT(tp) lt 16) =
       sum((ii,s),M0(ii,r,s)*PWM0(ii,r,s)*PWM.l(ii,r,s,tp))/
      sum((ii,s),M0(ii,r,s)*PWM0(ii,r,s)) ;    
MACROTAB("PWEINDEX",r,tp,siter)$(RGT(tp) eq card(tp)) =
       sum((ii,s),M0(ii,r,s)*PWM0(ii,r,s)*PWM.l(ii,r,s,tp))/
      sum((ii,s),M0(ii,r,s)*PWM0(ii,r,s)) ;    

MACROTAB("AGPWE",r,tp,siter)$(RGT(tp) lt 16) =
               sum((agi,s),M0(agi,r,s)*PWM0(agi,r,s)*PWM.L(agi,r,s,tp))/
					sum((agi,s),M0(agi,r,s)*PWM0(agi,r,s)) ;
MACROTAB("AGPWE",r,tp,siter)$(RGT(tp) eq card(tp)) =
               sum((agi,s),M0(agi,r,s)*PWM0(agi,r,s)*PWM.L(agi,r,s,tp))/
					sum((agi,s),M0(agi,r,s)*PWM0(agi,r,s)) ;

MACROTAB("AGPWM",r,tp,siter)$(RGT(tp) lt 16) =
               sum((agi,s),M0(agi,s,r)*PWM0(agi,s,r)*PWM.L(agi,s,r,tp))/
					sum((agi,s),M0(agi,s,r)*PWM0(agi,s,r)) ;
MACROTAB("AGPWM",r,tp,siter)$(RGT(tp) eq card(tp)) =
               sum((agi,s),M0(agi,s,r)*PWM0(agi,s,r)*PWM.L(agi,s,r,tp))/
					sum((agi,s),M0(agi,s,r)*PWM0(agi,s,r)) ;

MACROTAB("PDINDEX",r,tp,siter)
          = sum(ii,PD.l(ii,r,tp)*DC0(ii,r))/sum(ii,PD0(ii,r)*DC0(ii,r))  ;

MACROTAB("PWMEINDEX",r,tp,siter)$(RGT(tp) lt 16) = 
              (sum((ii,s),M0(ii,s,r)*PWM0(ii,s,r)*PWM.l(ii,s,r,tp)) + 
				   sum((ii,s),M0(ii,r,s)*PWM0(ii,r,s)*PWM.l(ii,r,s,tp)))/
				   (sum((ii,s),M0(ii,s,r)*PWM0(ii,s,r)) + 
				   sum((ii,s),M0(ii,r,s)*PWM0(ii,r,s))) ;
MACROTAB("PWMEINDEX",r,tp,siter)$(RGT(tp) eq card(tp)) = 
              (sum((ii,s),M0(ii,s,r)*PWM0(ii,s,r)*PWM.l(ii,s,r,tp)) + 
				   sum((ii,s),M0(ii,r,s)*PWM0(ii,r,s)*PWM.l(ii,r,s,tp)))/
				   (sum((ii,s),M0(ii,s,r)*PWM0(ii,s,r)) + 
				   sum((ii,s),M0(ii,r,s)*PWM0(ii,r,s))) ;

MACROTAB("PWE/PWM",r,tp,siter)$(RGT(tp) lt 16) =
         MACROTAB("PWEINDEX",r,tp,siter)/
     ( sum((ii,s),M0(ii,s,r)*PWM.l(ii,s,r,tp))/
      sum((ii,s),M0(ii,s,r)*PWM0(ii,s,r)) ) ;    
MACROTAB("PWE/PWM",r,tp,siter)$(RGT(tp) eq card(tp)) =
         MACROTAB("PWEINDEX",r,tp,siter)/
     ( sum((ii,s),M0(ii,s,r)*PWM.l(ii,s,r,tp))/
      sum((ii,s),M0(ii,s,r)*PWM0(ii,s,r)) ) ;  
  
MACROTAB("realexchr",r,tp,siter)$(MACROTAB("PWMEINDEX",r,tp,siter) ne 0) = 
           MACROTAB("PDINDEX",r,tp,siter)/MACROTAB("PWMEINDEX",r,tp,siter);
 
MACROTAB("PCINDEX",r,tp,siter)$(RGT(tp) lt 16)
          = sum(ii,PC.l(ii,r,tp)*(CD0(ii,r) + TINVD0(ii,r)))/
           sum(ii,CD0(ii,r) + TINVD0(ii,r))  ;
MACROTAB("PCINDEX",r,tp,siter)$(RGT(tp) eq card(tp))
          = sum(ii,PC.l(ii,r,tp)*(CD0(ii,r) + TINVD0(ii,r)))/
           sum(ii,CD0(ii,r) + TINVD0(ii,r))  ;

MACROTAB("REALGDP",r,tp,siter)$(MACROTAB("PCINDEX",r,tp,siter) ne 0) =
        (sum(ii, scPCT(ii,r)*PCT.L(ii,r,tp)*
        (scCD(ii,r)*CD.L(ii,r,tp) + scTINVD(ii,r)*TINVD.L(ii,r,tp))) -
          sum(s,scFBAL(s,r)*FBAL.L(s,r,tp)))/
           ((sum(ii, PCT0(ii,r)*(CD0(ii,r) + TINVD0(ii,r))) -
          sum(s,FBAL0(s,r)))*MACROTAB("PCINDEX",r,tp,siter)) ;

MACROTAB("nomGDP",r,tp,siter)$(MACROTAB("PCINDEX",r,tp,siter) ne 0) =
        (sum(ii, scPCT(ii,r)*PCT.L(ii,r,tp)*
        (scCD(ii,r)*CD.L(ii,r,tp) + scTINVD(ii,r)*TINVD.L(ii,r,tp))) -
          sum(s,scFBAL(s,r)*FBAL.L(s,r,tp)))/
           (sum(ii, PCT0(ii,r)*(CD0(ii,r) + TINVD0(ii,r))) -
          sum(s,FBAL0(s,r))) ;

MACROTAB("CON0",r,tp,"exp1") = 
      HSHP(r)*prod(ii,CD0(ii,r)**CLES(ii,r)) ; 

MACROTAB("CON",r,tp,siter) = 
      HSHP(r)*prod(ii,(scCD(ii,r)*CD.l(ii,r,tp))**CLES(ii,r)) ; 

MACROTAB("Utility0",r,tp,siter)$(RGT(tp) EQ CARD(tp) and
        MACROTAB("CON0",r,tp,siter) ne 0) 
       = sum((tt)$(RGT(tt) LT CARD(tt)),
       (1+ru(r)*(date(tt+1)-date(tt)))**(1-RGT(tt))*
       log(MACROTAB("CON0",r,tt,"exp1"))) +
       sum((tt)$(RGT(tt) LT CARD(tt)),
       (1+ru(r)*(date(tt+1)-date(tt)))**(1-RGT(tt) - card(tt) + 1)*
       log(MACROTAB("CON0",r,tt,"exp1"))) +
((1+ru(r)*(date(tp+1) -
       date(tp)))**(2 - 2*RGT(tp))/ru(r))
       $(RGT(tp) EQ CARD(tp)-1)*
       (log(MACROTAB("CON0",r,tp,"exp1")))
       $(RGT(tp) EQ CARD(tp))    ; 

MACROTAB("Utility",r,tp,siter)$(RGT(tp) EQ CARD(tp)) 
       = sum((tt)$(RGT(tt) LT CARD(tt)),
       (1+ru(r)*(date(tt+1)-date(tt)))**(1-RGT(tt))*
       log(MACROTAB("CON",r,tt,siter))) +
       (log(MACROTAB("CON",r,tp,siter))$(RGT(tp) EQ CARD(tp)))*
       sum((tt)$(RGT(tt) LT CARD(tt)),
       (1+ru(r)*(date(tt+1)-date(tt)))**(1-RGT(tt)- card(tt) + 1) ) +
      ((1+ru(r)*(date(tp+1)-
       date(tp)))**(2-2*RGT(tp))/ru(r))
       $(RGT(tp) EQ CARD(tp)-1)*
       (log(MACROTAB("CON",r,tp,siter)))
       $(RGT(tp) EQ CARD(tp))    ; 

MACROTAB("lnEUV",r,tp,siter)$(RGT(tp) EQ CARD(tp)) 
      = (MACROTAB("UTILITY",r,tp,siter) -   
         MACROTAB("UTILITY0",r,tp,"exp1"))*RU(r)/(1+RU(r)) ;

MACROTAB("EUV",r,tp,siter)$(RGT(tp) EQ CARD(tp)) 
     = EXP(MACROTAB("lnEUV",r,tp,siter)) - 1 ;

MACROTAB("KSUP",r,tp,siter) = FS.L("CAPT",r,tp) ;

MACROTAB("INV",r,tp,siter)$(RGT(tp) lt 16) = INV.L(r,tp) ;

MACROTAB("totex",r,tp,siter)$(RGT(tp) lt 16) =
        sum((ii,s),scM(ii,r,s)*M.L(ii,r,s,tp)*
      PWM.L(ii,r,s,tp))/sum((ii,s),M0(ii,r,s)*PWM0(ii,r,s)) ;
MACROTAB("totex",r,tp,siter)$(RGT(tp) eq card(tp)) =
        sum((ii,s),scM(ii,r,s)*M.L(ii,r,s,tp)*
      PWM.L(ii,r,s,tp))/sum((ii,s),M0(ii,r,s)*PWM0(ii,r,s)) ;

MACROTAB("totim",r,tp,siter)$(RGT(tp) lt 16) =
        sum((ii,s),scM(ii,s,r)*M.L(ii,s,r,tp)*
      PWM.L(ii,s,r,tp))/sum((ii,s),M0(ii,s,r)*PWM0(ii,s,r)) ;
MACROTAB("totim",r,tp,siter)$(RGT(tp) eq card(tp)) =
        sum((ii,s),scM(ii,s,r)*M.L(ii,s,r,tp)*
      PWM.L(ii,s,r,tp))/sum((ii,s),M0(ii,s,r)*PWM0(ii,s,r)) ;

MACROTAB("totagex",r,tp,siter)$(RGT(tp) lt 16) =
        sum((agi,s),M0(agi,r,s)*M.L(agi,r,s,tp)*
      PWM.L(agi,r,s,tp))/sum((agi,s),M0(agi,r,s)*PWM0(agi,r,s)) ;
MACROTAB("totagex",r,tp,siter)$(RGT(tp) eq card(tp)) =
        sum((agi,s),M0(agi,r,s)*M.L(agi,r,s,tp)*
      PWM.L(agi,r,s,tp))/sum((agi,s),M0(agi,r,s)*PWM0(agi,r,s)) ;

MACROTAB("totagim",r,tp,siter)$(RGT(tp) lt 16) =
        sum((agi,s),M0(agi,s,r)*M.L(agi,s,r,tp)*
      PWM.L(agi,s,r,tp))/sum((agi,s),M0(agi,s,r)*PWM0(agi,s,r)) ;
MACROTAB("totagim",r,tp,siter)$(RGT(tp) eq card(tp)) =
        sum((agi,s),M0(agi,s,r)*M.L(agi,s,r,tp)*
      PWM.L(agi,s,r,tp))/sum((agi,s),M0(agi,s,r)*PWM0(agi,s,r)) ;

MACROTAB("ex-eu",r,tp,siter)$(sum(ii,M0(ii,r,"e_u")*PWM0(ii,r,"e_u")) ne 0 
       and RGT(tp) lt 16) =
        sum(ii,scM(ii,r,"e_u")*M.L(ii,r,"e_u",tp)*PWM.L(ii,r,"e_u",tp))/
        sum(ii,M0(ii,r,"e_u")*PWM0(ii,r,"e_u")) ;
MACROTAB("ex-eu",r,tp,siter)$(sum(ii,M0(ii,r,"e_u")*PWM0(ii,r,"e_u")) ne 0 
       and RGT(tp) eq card(tp)) =
        sum(ii,scM(ii,r,"e_u")*M.L(ii,r,"e_u",tp)*PWM.L(ii,r,"e_u",tp))/
        sum(ii,M0(ii,r,"e_u")*PWM0(ii,r,"e_u")) ;

MACROTAB("im-eu",r,tp,siter)$(sum(ii,M0(ii,"e_u",r)*PWM0(ii,"e_u",r)) ne 0 
       and RGT(tp) lt 16) =
        sum(ii,scM(ii,"e_u",r)*M.L(ii,"e_u",r,tp)*PWM.L(ii,"e_u",r,tp))/
        sum(ii,M0(ii,"e_u",r)*PWM0(ii,"e_u",r)) ;
MACROTAB("im-eu",r,tp,siter)$(sum(ii,M0(ii,"e_u",r)*PWM0(ii,"e_u",r)) ne 0 
       and RGT(tp) eq card(tp)) =
        sum(ii,scM(ii,"e_u",r)*M.L(ii,"e_u",r,tp)*PWM.L(ii,"e_u",r,tp))/
        sum(ii,M0(ii,"e_u",r)*PWM0(ii,"e_u",r)) ;

MACROTAB("agex-eu",r,tp,siter)$(sum(agi,M0(agi,r,"e_u")*PWM0(agi,r,"e_u")) ne 0 
        and RGT(tp) lt 16) =
        sum(agi,M0(agi,r,"e_u")*M.L(agi,r,"e_u",tp)*PWM.L(agi,r,"e_u",tp))/
        sum(agi,M0(agi,r,"e_u")*PWM0(agi,r,"e_u")) ;
MACROTAB("agex-eu",r,tp,siter)$(sum(agi,M0(agi,r,"e_u")*PWM0(agi,r,"e_u")) ne 0 
        and RGT(tp) eq card(tp)) =
        sum(agi,M0(agi,r,"e_u")*M.L(agi,r,"e_u",tp)*PWM.L(agi,r,"e_u",tp))/
        sum(agi,M0(agi,r,"e_u")*PWM0(agi,r,"e_u")) ;

MACROTAB("agim-eu",r,tp,siter)$(sum(agi,M0(agi,"e_u",r)*PWM0(agi,"e_u",r)) ne 0 
        and RGT(tp) lt 16) =
        sum(agi,M0(agi,"e_u",r)*M.L(agi,"e_u",r,tp)*PWM.L(agi,"e_u",r,tp))/
        sum(agi,M0(agi,"e_u",r)*PWM0(agi,"e_u",r)) ;
MACROTAB("agim-eu",r,tp,siter)$(sum(agi,M0(agi,"e_u",r)*PWM0(agi,"e_u",r)) ne 0 
        and RGT(tp) eq card(tp)) =
        sum(agi,M0(agi,"e_u",r)*M.L(agi,"e_u",r,tp)*PWM.L(agi,"e_u",r,tp))/
        sum(agi,M0(agi,"e_u",r)*PWM0(agi,"e_u",r)) ;

PRODTAB("X",ii,mid,tp,siter)$(RGT(tp) lt 16) = X.L(ii,mid,tp) ;
PRODTAB("X",ii,mid,tp,siter)$(RGT(tp) eq card(tp)) = X.L(ii,mid,tp) ;


