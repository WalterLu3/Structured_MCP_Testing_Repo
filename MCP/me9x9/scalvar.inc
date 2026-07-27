*$include scalevar.inc

loop(r,    if( XTAX0(r) eq 0, 
            EXTAX.L(r,tp) = XTAX0(r);  scEXTAX(r) = 1;
       ELSE
            scEXTAX(r) = XTAX0(r); EXTAX.L(r,tp)  = 1; ) ;

          if( MTAX0(r) eq 0, 
            IMTAX.L(r,tp) = MTAX0(r);  scIMTAX(r) = 1;
       ELSE
            scIMTAX(r) = MTAX0(r); IMTAX.L(r,tp)  = 1; ) ;

          if( CTAX0(r) eq 0,
            CONTAX.L(r,tp) = CTAX0(r);  scCTAX(r) = 1;
       ELSE
            scCTAX(r) = CTAX0(r); CONTAX.L(r,tp)  = 1; ) ;

          if( PTAX0(r) eq 0, 
            PRODTAX.L(r,tp) = PTAX0(r);  scPRODTAX(r) = 1;
       ELSE
            scPRODTAX(r) = PTAX0(r); PRODTAX.L(r,tp)  = 1; ) ;

          if(abs(HSAVE0(r)) LT 1.0E-5, 
           HSAVE.L(r,tp) = HSAVE0(r);  scHSAVE(r) = 1;
      ELSE
            scHSAVE(r) = HSAVE0(r); HSAVE.L(r,tp)  = 1; ) ;


) ;

loop((ii,r,s),if(M0(ii,r,s)  EQ 0, 
                      M.L(ii,r,s,tp) = M0(ii,r,s) ;
                      scM(ii,r,s) = 1 ; 
      else
                      scM(ii,r,s) = M0(ii,r,s) ;
                      M.L(ii,r,s,tp) = 1 ;     ) ;

                if( PE0(ii,r,s) eq 0,
                     PE.L(ii,r,s,tp) = PE0(ii,r,s) ;
                     scPE(ii,r,s) = 1 ;
       else          scPE(ii,r,s) = PE0(ii,r,s) ;
                     PE.L(ii,r,s,tp) = 1 ; ) ;

                if( PM0(ii,r,s) eq 0,
                     PM.L(ii,r,s,tp) = PM0(ii,r,s) ;
                     scPM(ii,r,s) = 1 ;
       else          scPM(ii,r,s) = PM0(ii,r,s) ;
                     PM.L(ii,r,s,tp) = 1 ; ) ;

                
) ;

loop((iff,ii,r), if (FD0(iff,ii,r) eq 0,
                   FD.L(iff,ii,r,tp) = FD0(iff,ii,r) ;
                   scFD(iff,ii,r) = 1 ;
       ELSE
                   scFD(iff,ii,r) = FD0(iff,ii,r);
                   FD.L(iff,ii,r,tp) = 1 ;  ) ;
) ;


loop((r,s), if (FBAL0(r,s) eq 0,
                    FBAL.L(r,s,tp)  = FBAL0(r,s)  ;
                    scFBAL(r,s) = 1 ;
       else
                    scFBAL(r,s)  = FBAL0(r,s)  ;
                    FBAL.L(r,s,tp)  = 1  ;   ) ;

          if( FDEBT0(r,s) eq 0,
            FDEBT.L(r,s,tp) = FDEBT0(r,s) ;
              scFDEBT(r,s) = 1;
       ELSE
            scFDEBT(r,s) = FDEBT0(r,s) ;
            FDEBT.L(r,s,tp) = 1; ) ;

) ;


loop((ii,r),   if (INVD0(ii,r) eq 0 ,
               INVD.L(ii,r,tp) = INVD0(ii,r) ;
               scINVD(ii,r) = 1 ;
else
               scINVD(ii,r) = INVD0(ii,r) ;
               INVD.L(ii,r,tp) = 1; ) ;

                   if (TINVD0(ii,r) eq 0 ,
               TINVD.L(ii,r,tp) = TINVD0(ii,r) ;
               scTINVD(ii,r) = 1 ;
else
               scTINVD(ii,r) = TINVD0(ii,r) ;
               TINVD.L(ii,r,tp) = 1; ) ;

) ;

