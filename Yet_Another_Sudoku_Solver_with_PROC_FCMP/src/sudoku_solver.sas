proc fcmp;
 function parseProblem(p $);
  length puzzle $82;
  puzzle=p || ' ';
  array problem[9,9] /nosymbols;
  k=1;
  do i=1 to 9;
   do j=1 to 9;
    problem[i,j]=input(substr(puzzle,k,1),1.);
	k+1;
   end;
  end;
  rc=write_array('sudoku',problem);
  return(rc);
 endsub;

 function solveProblem(u,p[*,*]);
   if u then do;
    if solveForward(1,1,p) then do;
     array f[9,9] /nosymbols;
     rc+read_array('sudoku_f',f);
    end;
    if solveReverse(9,9,p) then do;
     array r[9,9] /nosymbols;
     rc+read_array('sudoku_r',r);
    end;
	m=0;
	if rc=0 then
     do i=1 to 9;
      do j=1 to 9;
	   z=(f[i,j]=r[i,j]);
       m+z;
      end;
     end;
   end;
   else do;
    r1=0;
	r9=0;
	do i=1 to 9;
     r1+ifn(p[i,1]=0,1,0);
     r9+ifn(p[i,9]=0,1,0);
	end;
	if r1<r9 then do;
     if solveForward(1,1,p) then do;
      array f[9,9] /nosymbols;
	  m=81+read_array('sudoku_f',f);
     end;
    end;
    else do;
     if solveReverse(9,9,p) then do;
      array f[9,9] /nosymbols;
      m=81+read_array('sudoku_r',f);
     end;
    end;
   end;
   if m=81 then z=writeMatrix(f);
  return(ifn(m=81,1,0));
 endsub;

 function solveForward(_i,_j,c[*,*]);
  array cells[9,9] /nosymbols;
  do a=1 to 9;
   do b=1 to 9;
    cells[a,b]=c[a,b];
   end;
  end;
  i=_i; j=_j;

  if i>9 then do;
   i=1; j+1;
   if(j>9) then do;
    rc=write_array('sudoku_f',cells);
    return(1);
   end;
  end;

  if cells[i,j] ne 0 then
   return(solveForward(i+1,j,cells));

  do val=1 to 9;
   if legal(i,j,val,cells) then do;
    cells[i,j]=val;
    if (solveForward(i+1,j,cells)) then return(1);
   end;
  end;

  cells[i,j]=0;
  return(0);
 endsub;

 function solveReverse(_i,_j,c[*,*]);
  array cells[9,9] /nosymbols;
  do a=1 to 9;
   do b=1 to 9;
    cells[a,b]=c[a,b];
   end;
  end;
  i=_i; j=_j;

  if i<1 then do;
   i=9; j=j-1;
   if(j<1) then do;
    rc=write_array('sudoku_r',cells);
    return(1);
   end;
  end;

  if cells[i,j] ne 0 then
   return(solveReverse(i-1,j,cells));

  do val=1 to 9;
   if legal(i,j,val,cells) then do;
    cells[i,j]=val;
    if (solveReverse(i-1,j,cells)) then return(1);
   end;
  end;

  cells[i,j]=0;
  return(0);
 endsub;

 function legal(i,j,val,cells[*,*]);
 do k=1 to 9; *scan row;
  if val=cells[k,j] then
   return(0);
 end;
 do k=1 to 9; *scan col;
  if val=cells[i,k] then
   return(0);
 end;
 roffset=i-mod(i-1,3);
 coffset=j-mod(j-1,3);
 do k=0 to 2; *scan box;
  do m=0 to 2;
   if val=cells[roffset+k,coffset+m] then
        return(0);
  end;
 end;
 return(1);
 endsub;

 function writeMatrix(solution[*,*]);
 put "   -----------------------";
 do i=1 to 9;
  put @2 '|' @;
  h=4;
  do j=1 to 9;
       x=ifc(solution[i,j]=0,' ',put(solution[i,j],1.));
       put @h x $2. @; h+2;
       if mod(j,3)=0 then do; put @h "| " @; h+2; end;
  end;
  put /;
  if mod(i,3)=0 then put @1 "   -----------------------";
 end;
 return(rc);
 endsub;

array args[11] $81 ( 
  '100007090030020008009600500005300900010080002600004000300000010040000007007000300'
  '000000070060010004003400200800003050002900700040080009020060007000100900700008060'
  '100500400009030000070008005001000030800600500090007008004020010200800600000001002'
  '080000001007004020600300700002009000100060008030400000001700600090008005000000040'
  '100400800040030009009006050050300000000001600000070002004010900700800004020004080'
  '005009700060000020100800006010700004007060030600003200000006040090050100800100002'
  '600000200090001005008030040000002001500600900007090000070003002000400500006070080'
  '100000060000100003005002900009001000700040080030500002500400006008060070070005000'
  '000010004030200000600008090007060005900005080000800400040900100700002040005030007'
  '400060070000000600030002001700008500010400000020950000000000705009100030003040080'
  '005300000800000020070010500400005300010070006003200080060500009004000030000009700'
);
 array test[11] (0 0 0 0 0 0 0 0 0 0 0 0);
 do i=1 to dim(args);
  rc=parseProblem(args[i]);
  array problem[9,9] /nosymbols;
  rc=read_array('sudoku',problem);
  put 'Problem= ' args[i];
  x=writeMatrix(problem);
  _time=time();
  if solveProblem(test[i],problem)=0 then put 'No Unique Solution Found';
  _diff=time()-_time;
  put 'Time Elapsed: ' _diff best. 'seconds';
  put _page_;
 end;
run;