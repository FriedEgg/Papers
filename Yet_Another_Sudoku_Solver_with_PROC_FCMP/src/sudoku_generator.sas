proc fcmp outlib=work.func.sudoku;
 
/**
  * Yet Another Sudoku Solver/Generator
  * Author: Matthew Kastin aka FriedEgg
  * March 24, 2012
  * Version: 1.1
  *
  * Need to DRY code
  *
  */

 subroutine genSudoku(nblanks, show_solution);
  array z[81]  ( 1 2 3 4 5 6 7 8 9
                 4 5 6 7 8 9 1 2 3
                 7 8 9 1 2 3 4 5 6
                 2 3 4 5 6 7 8 9 1
                 5 6 7 8 9 1 2 3 4
                 8 9 1 2 3 4 5 6 7
                 3 4 5 6 7 8 9 1 2
                 6 7 8 9 1 2 3 4 5
                 9 1 2 3 4 5 6 7 8 )           ;
  array x[9]   ( 1 2 3 4 5 6 7 8 9 )           ;
  array a[3]   ( 1 2 3             )           ;
  array c[3]   ( 0 3 6             )           ;
  array b[3,3]                       /nosymbols;
  array d[3,3]                       /nosymbols;
  array e[9,9]                       /nosymbols;
  array r[9,9]                       /nosymbols;

  try=0;
  do until(solvePath(1,r,0));
   try+1;
   seed = 0;
   call ranperm(seed,of x1-x9);
   do i=1 to dim(z);
    z[i]=x[z[i]];
   end;

   do j=1 to 3;
    call ranperm(seed,of a1-a3);
	do i=1 to 3;
	 b[i,j]=a[i];
	end;
   end;
   call ranperm(seed,of c1-c3);
   do i=1 to 3; do j=1 to 3;
    b[i,j]=b[i,j]+c[j];
   end; end;

   do j=1 to 3;
    call ranperm(seed,of a1-a3);
	do i=1 to 3;
	 d[i,j]=a[i];
    end;
   end;
   call ranperm(seed,of c1-c3);
   do i=1 to 3; do j=1 to 3;
    d[i,j]=d[i,j]+c[j];
   end; end;

   k=1;
   do i=1 to 9; do j=1 to 9;
    e[i,j]=z[k];
	k+1;
   end; end;

   i=1; j=1;
   do k=1 to 3; do l=1 to 3;
    if j>9 then j=1;
	do m=1 to 3; do n=1 to 3;
	 r[i,j]=e[b[l,k],d[n,m]];
	 j+1;
	end; end;
	i+1;
   end; end;

   blank=0;
   iseed=input(cats(of x1-x5),5.);
   jseed=input(cats(of x5-x9),5.);
   do until(nblanks=blank);
	i=int(9*ranuni(iseed))+1;
	j=int(9*ranuni(jseed))+1;
    if r[i,j] ^= 0 then do;
	 r[i,j]=0;
	 blank+1;
	end;
   end;
  end;

  call writeSudoku(r);
  if show_solution then do;
   array s[9,9] /nosymbols;
   rc=read_array('sudoku_f',s);
   call writeSudoku(s);
  end; 
 endsub;
 
 function solvePath(u,puzzle[*,*],show_solution);
  /* Unique Solution Path */
  if u then do;
   if solveForward(1,1,puzzle) and solveReverse(9,9,puzzle) then do;
    array f[9,9] /nosymbols; rc+read_array('sudoku_f',f);
    array r[9,9] /nosymbols; rc+read_array('sudoku_r',r);
    m=0;
    if rc=0 then do i=1 to 9; do j=1 to 9;
     m+(f[i,j]=r[i,j]);
    end; end;
   end;
  end;
  /* Optimized Solution Path */
  else do;
   do i=1 to 9;
    r1+(puzzle[i,1]=0); r9+(puzzle[i,9]=0);
   end;
   if r1<r9 then do;
    if solveForward(1,1,puzzle) then do;
     array f[9,9] /nosymbols; m=81+read_array('sudoku_f',f);
    end;
   end;
   else do;
    if solveReverse(9,9,puzzle) then do;
     array f[9,9] /nosymbols; m=81+read_array('sudoku_r',f);
    end;
   end;
  end;
  if show_solution then do;
   if m=81 then call writeSudoku(f);
   else put 'No Unique Solution Found';
  end;
  return(ifn(m=81,1,0));
 endsub;
 
 subroutine solveSudoku(u, _p $);
  /* parse problem */
  length p $82;
  p=_p || ' ';
  put _p;
  array puzzle[9,9] /nosymbols;
  k=1;
  do i=1 to 9; do j=1 to 9;
   puzzle[i,j]=input(substr(p,k,1),1.);
   k+1;
  end; end;
  rc=write_array('sudoku',puzzle);
  call writeSudoku(puzzle);
  rc=solvePath(u,puzzle,1);
  return;
 endsub;
 
 function solveForward(_i,_j,c[*,*]);
  array cells[9,9] /nosymbols;
  do i=1 to 9; do j=1 to 9;
    cells[i,j]=c[i,j];
  end; end;
  i=_i; j=_j;
  /* puzzle is solved */
  if i>9 then do;
   i=1; j+1;
   if(j>9) then do;
    rc=write_array('sudoku_f',cells);
    return(1);
   end;
  end;
  /* cell contains given number, skip */
  if cells[i,j] ne 0 then
   return(solveForward(i+1,j,cells));
  /* iterative guess loop, check, continue */
  do val=1 to 9;
   if checkGuess(i,j,val,cells) then do;
    cells[i,j]=val;
    if solveForward(i+1,j,cells) then return(1);
   end;
  end;
  /* solve failure */
  cells[i,j]=0;
  return(0);
 endsub;
 
 /* solveReverse is basically a duplicate of solveForward with the path movement through the puzzle array in subtractive order instead of additive */
 function solveReverse(_i,_j,c[*,*]);
  array cells[9,9] /nosymbols;
  do i=1 to 9; do j=1 to 9;
    cells[i,j]=c[i,j];
  end; end;
  i=_i; j=_j;
  if i<1 then do;
   i=9; j=j-1;
   /* puzzle is solved */
   if(j<1) then do;
    rc=write_array('sudoku_r',cells);
    return(1);
   end;
  end;
  /* cell contains given number, skip */
  if cells[i,j] ne 0 then
   return(solveReverse(i-1,j,cells));
  /* iterative guess loop, check, continue */
  do val=1 to 9;
   if checkGuess(i,j,val,cells) then do;
    cells[i,j]=val;
    if solveReverse(i-1,j,cells) then return(1);
   end;
  end;
  /* solve failure */
  cells[i,j]=0;
  return(0);
 endsub;
 
 function checkGuess(i,j,val,cells[*,*]);
  /* check row */
  do k=1 to 9;
   if val=cells[k,j] then return(0);
  end;
  /* check column */
  do k=1 to 9;
   if val=cells[i,k] then return(0);
  end;
  /* check box */
  roffset=i-mod(i-1,3);
  coffset=j-mod(j-1,3);
  do k=0 to 2; do m=0 to 2;
   if val=cells[roffset+k,coffset+m] then return(0);
  end; end;
  /* guess is okay */
  return(1);
 endsub;
 
 subroutine writeSudoku(solution[*,*]);
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
  return;
 endsub;
 
/* unit test solver
array sudoku[11] $ 81 (
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
array u[11] (0 0 0 0 0 0 0 0 0 0 0 0);
do i=1 to dim(sudoku);
  _time=time();
  call solveSudoku(u[i],sudoku[i]);
  _diff=time()-_time;
  put 'Time Elapsed: ' _diff best. 'seconds';
  put _page_;
end; */
 
/* unit test generator

do i=1 to 5;
 _time=time();
 call genSudoku(47+i,1);
 _diff=time()-_time;
 put 'Time Elapsed: ' _diff best. 'seconds';
 put _page_;
end; */

run;
 
/* DATA step test */
%let cmplib=%sysfunc(getoption(cmplib));
options cmplib=work.func;

/* solver 
data _null_;
array sudoku[11] $ 81 (
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
array u[11] (11*0);
do i=1 to dim(sudoku);
  _time=time();
  call solveSudoku(u[i],sudoku[i]);
  _diff=time()-_time;
  put 'Time Elapsed: ' _diff best. 'seconds';
end;
run;
*/

/* generator */ 
data _null_;
 do i=1 to 3;
  _time=time();
  call genSudoku(47+i,1);
  _diff=time()-_time;
  put 'Time Elapsed: ' _diff best. 'seconds';
 end;  
run;

%let cmplib=&cmplib;