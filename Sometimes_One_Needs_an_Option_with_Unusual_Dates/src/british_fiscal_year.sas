/**
  *This program is designed to create interval datasets
  *that will allow one to use interval functions on dates
  *for a 200 year window around a fiscal year that begins
  *on the date specified in the macro variable &FYStart.
  *
  *
  *AUTHORS: Arthur Tabachneck
  *UPDATED: October 6, 2014
  *
  */

/**
  * Create Interval Datasets for year, quarter and month.
  * Note: Modify the first line, below, to indicate the
  * fiscal year start for the current year
  *
  */

%let FYstart=6APR2014;

%let FYlow=%sysfunc(catt(%sysfunc(day("&FYstart."d)),
       %sysfunc(substr("&FYstart.",%sysfunc(anyalpha("&FYstart.")),3)),
       %sysfunc(year("&FYstart."d))-100));
%let FYhi=%sysfunc(catt(%sysfunc(day("&FYstart."d)),
       %sysfunc(substr("&FYstart.",%sysfunc(anyalpha("&FYstart.")),3)),
       %sysfunc(year("&FYstart."d))+100));

data fyds fqds fmds;
  d=  day("&FYstart."d);
  m=month("&FYstart."d);
  q=  qtr("&FYstart."d);
  do begin="&FYlow."d to "&FYhi."d-1;
    if day(begin) eq d then do;
      season=mod(month(begin) + (12-m), 12)+1;
      end=intnx('month', begin, 1, 's')-1;
      output fmds;
      if mod(month(begin), 3)=mod(m, 3) then do;
        season=floor((season-1)/3)+1;
        end=intnx('month', begin, 3, 's')-1;
        output fqds;
      end;
      if month(begin) eq m then do;
        season=year(begin);
        end=intnx('year', begin, 1, 's')-1;
        output fyds;
      end;
    end;
  end;
  format begin end date9.;
  drop d m q;
run;

/**
  * Set intervalds option
  *
  *  The following line is all that is needed in order to
  *  establish FiscalQuarter, FiscalYear and FiscalMonth
  *  as valid intervals using the FQDS, FYDS and FMDS
  *  interval datasets, respectively
  *
  */

options intervalds=(FiscalQuarter=FQDS
                    FiscalYear=FYDS
                    FiscalMonth=FMDS);

/**
  *Test using sashelp.pricedata and the intindex function
  *
  */

data need (keep=date fiscal: next:);
  set sashelp.pricedata;
  fiscal_year=INTINDEX( 'FiscalYear', date );
  fiscal_qtr=INTINDEX( 'FiscalQuarter', date );
  fiscal_month=INTINDEX( 'FiscalMonth', date );
  next_year_start=intnx('FiscalYear',date,1,'b');
  next_year_middle=intnx('FiscalYear',date,1,'m');
  next_year_end=intnx('FiscalYear',date,1,'e');
  format date next: date9.;
run;
