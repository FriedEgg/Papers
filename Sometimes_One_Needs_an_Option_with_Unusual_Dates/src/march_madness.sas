/**
  *This program is designed to create an interval dataset
  *that will allow one to use interval functions on dates
  *from the NCAA March Madness Basketball tournament.
  *
  *The program relies on and accesses the tournament start
  *dates that are posted on the tournament's Wikipedia page
  *
  *The code creates an interval dataset for all tournament
  *rounds between 1985 and 2012.
  *
  *AUTHOR: Arthur Tabachneck
  *DATE: December 12, 2011
  *
  */
proc delete data=dates;
run;

/**
  *The following macro downloads the pages from Wikipedia
  *which contain the start dates for all NCAA March Madness
  *tournaments between 1985 and 2012.
  *
  */
%macro getmdates;
  %do i=1985 %to %sysfunc(year(%sysfunc(today())));
    filename ncaa http
     "http://en.wikipedia.org/wiki/&i._NCAA_Men%27s_Division_I_Basketball_Tournament";
    data temp (keep=startdate enddate);
      format startdate enddate date9.;
      informat sdate $21.;
      infile ncaa lrecl=32000;
      input @ "began on " sdate &;
      if sdate ne "" then do;
        x=findc(sdate,',',2,'b');
        startdate=input(substr(sdate,1,x),anydtdte21.);
        if &i. ge 2011 then do;
          startdate=startdate+2;
          enddate=startdate+20;
        end;
        else if &i. ge 2001 then do;
          startdate=startdate+1;
          enddate=startdate+19;
        end;
        else enddate=startdate+18;
        output;
        stop;
      end;
    run;
    proc append
      base=dates data=temp;
    run;
  %end;
%mend getmdates;
%getmdates

/**
  * Create an Interval Dataset that captures the dates of
  * each Tournament round
  *
  */
data roundds (keep=begin season);
  set dates end=lastrec;
  round=0;
  i=0;
  do begin= mdy(1,1,year(startdate)) to
            mdy(12,31,year(startdate));
    if startdate<=begin<=enddate then do;
      i+1;
      if i in (1,3,8,10,17,19) then round+1;
      if i in (1:4,8:11,17,19) then season=round;
      else season=0;
    end;
    else season=0;
    output;
  end;
  if lastrec then do;
    season=0;
    year+1;
    output;
    end;
  format begin date.;
run;

/**
  * Set intervalds option
  *
  *  The following line is all that is needed in order to
  *  establish Rounds as a valid interval using the
  *  roundDS dataset
  *
  */
options intervalds=(Rounds=roundDS);

data test (keep=date round);
  format date date9.;
  do date='1jan2011'd to '31dec2012'd;
    round=INTINDEX( 'Rounds', date );
    if round then output;
  end;
run;
