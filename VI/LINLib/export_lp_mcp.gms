* Included by generate_mcp_for_lp.gms after loading a continuous LP.
* Export the same affine VI's KKT system directly when JAMS cannot scalarize it.
* Ranged rows use a bounded auxiliary variable and a free multiplier.

set exportRows(i);
exportRows(i) = ig(i) or il(i) or ie(i) or ir(i);
scalar exportN, exportOffset, exportFirst;
exportN = card(j);
exportOffset = card(j) + card(i);

file exportMCP / 'mcp_formulation.gms' /;
exportMCP.pc = 2;
exportMCP.nr = 0;
exportMCP.nd = 17;
exportMCP.nw = 0;
put exportMCP;
put '* Standalone continuous LP MCP; direct export because JAMS could not export it.'/;
put '* Fixed bounds, constant constraints, and ranged rows are retained.'/ /;

loop(jc,
    put 'Variable x' ord(jc):0:0 ';'/;
    put 'x' ord(jc):0:0 '.lo = ' xc.lo(jc) ';'/;
    put 'x' ord(jc):0:0 '.up = ' xc.up(jc) ';'/;
    put 'x' ord(jc):0:0 '.l = ' xc.l(jc) ';'/;
);
loop(i$ir(i),
    put 'Variable x' (exportN + ord(i)):0:0 ';'/;
    put 'x' (exportN + ord(i)):0:0 '.lo = ' r.lo(i) ';'/;
    put 'x' (exportN + ord(i)):0:0 '.up = ' r.up(i) ';'/;
    put 'x' (exportN + ord(i)):0:0 '.l = ' r.l(i) ';'/;
);
loop(i$exportRows(i),
    put 'Variable u' (exportOffset + ord(i)):0:0 ';'/;
    if(ig(i), put 'u' (exportOffset + ord(i)):0:0 '.lo = 0;'/;);
    if(il(i), put 'u' (exportOffset + ord(i)):0:0 '.up = 0;'/;);
);

loop(jc,
    put 'Equation e' ord(jc):0:0 ';'/;
    put 'e' ord(jc):0:0 '.. eps*x' ord(jc):0:0 /;
    loop(i$(exportRows(i) and ac(i,jc)),
        put ' - (' ac(i,jc) ')*u' (exportOffset + ord(i)):0:0 /;
    );
    put ' =N= ' (-c(jc)) ';'/ /;
);
loop(i$ir(i),
    put 'Equation e' (exportN + ord(i)):0:0 ';'/;
    put 'e' (exportN + ord(i)):0:0 '.. u' (exportOffset + ord(i)):0:0 ' =N= 0;'/ /;
);
loop(i$exportRows(i),
    put 'Equation e' (exportOffset + ord(i)):0:0 ';'/;
    put 'e' (exportOffset + ord(i)):0:0 '.. 0'/;
    loop(jc$ac(i,jc),
        put ' + (' ac(i,jc) ')*x' ord(jc):0:0 /;
    );
    if(ir(i),
        put ' - x' (exportN + ord(i)):0:0 ' =E= 0;'/ /;
    elseif ig(i),
        put ' =G= ' b(i) ';'/ /;
    elseif il(i),
        put ' =L= ' b(i) ';'/ /;
    else
        put ' =E= ' b(i) ';'/ /;
    );
);

* Maintain a valid model even for an entirely empty instance.
if(card(j) + card(ir) + card(exportRows) = 0,
    put 'Variable x1; Equation e1; e1.. x1 =N= 0;'/;
);
put 'Model m /'/;
exportFirst = 1;
loop(jc,
    if(not exportFirst, put ',';);
    put 'e' ord(jc):0:0 '.x' ord(jc):0:0 /;
    exportFirst = 0;
);
loop(i$ir(i),
    if(not exportFirst, put ',';);
    put 'e' (exportN + ord(i)):0:0 '.x' (exportN + ord(i)):0:0 /;
    exportFirst = 0;
);
loop(i$exportRows(i),
    if(not exportFirst, put ',';);
    put 'e' (exportOffset + ord(i)):0:0 '.u' (exportOffset + ord(i)):0:0 /;
    exportFirst = 0;
);
if(exportFirst, put 'e1.x1'/;);
put '/;'/ /;
put 'm.limrow=0; m.limcol=0;'/ /;
put 'Solve m using MCP;'/;
putclose exportMCP;
