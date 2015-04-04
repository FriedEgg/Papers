/**
  *This program is designed to create interval datasets
  *that will allow one to use interval functions on dates
  *from the Chinese Agricultural calendar.
  *
  *The program relies on and accesses a lunar calendar that
  *is freely available from the Hong Kong Obervatory
  *
  *The code creates interval datasets for year, month,
  *and most Festivals, between January 1st, 1901 and
  *December 31st, 2100.
  *
  *AUTHORS: Xia Ke Shan and Arthur Tabachneck
  *DATE: February 13, 2012
  *
  */

proc delete data=dates;
run;

/**
  *The following macro downloads the pages from the Hong Kong
  *Observatory which contain the lunar dates for all dates
  *between January 1st, 1901 and December 31st, 2100.
  *
  */
%macro getcdates;
  %do i=1901 %to 2100;
    filename lunar http
     "http://www.hko.gov.hk/gts/time/calendar/text/T&i.e.txt";
    data temp;
      format Gregorian_date yymmdd10.;
      infile lunar dlm=' ' firstobs=3 truncover expandtabs ;
      input Gregorian_date : ?? yymmdd12.
            lunar_date & $40.
            day_of_week : $20.
            solar_term &  $40.;
      if not missing(Gregorian_date) then output;
    run;

    proc append base=dates data=temp;
    run;
  %end;


  /*The pages from the Hong Kong Observatory are missing*/
  /*some 31DEC entries.  The following datasteps correct*/
  /*that deficiency.                                    */
  data all;
    do Gregorian_date='01jan1901'd to '31dec2100'd;
      output;
    end;
  run;

  data dates;
    merge dates all;
    by Gregorian_date;
  run;
%mend getcdates;

%getcdates

data dates;
  set dates;
  /**
    *Chinese_month is initialized at 11 since the files
    *from the Hong Kong Observatory begin at 01JAN1901
    *which is in Chinese November 1900.
  *
  */
  retain chinese_month 11;
  if find(upcase(lunar_date),'MONTH') then chinese_month=
   input(compress(lunar_date, ,'kd'),?? best8.);
run;

data dates;
  set dates;
  if chinese_month ne lag(chinese_month) then chinese_day=0;
  chinese_day+1;
  if _n_ eq 1 then chinese_day=11;*start from 01JAN1901;
run;

data Chinese_Calendar;
  set dates;
  if _n_ eq 1 then chinese_year=1900;
  select;
    when(chinese_month=1 and chinese_day=1) do;
      season=1;
      chinese_year+1;
    end;
    when(chinese_month=1 and chinese_day=15) do;
      season=2;
    end;
    when(find(lowcase(solar_term),'bright') and
         find(lowcase(solar_term),'clear' ) ) do;
      season=3;
    end;
    when(chinese_month=5 and chinese_day=5) do;
      season=4;
    end;
    when(chinese_month=7 and chinese_day=7) do;
      season=5;
    end;
    when(chinese_month=7 and chinese_day=15) do;
      season=6;
    end;
    when(chinese_month=8 and chinese_day=15) do;
      season=7;
    end;
    when(chinese_month=9 and chinese_day=9)  do;
      season=8;
    end;
    when(chinese_month=10 and chinese_day=15) do;
      season=9;
    end;
    when(find(lowcase(solar_term),'winter') and
         find(lowcase(solar_term),'solstice') ) do;
      season=10;
    end;
    when(chinese_month=12 and chinese_day=23) do;
      season=11;
    end;
    otherwise season=0;
  end;
run;

/* Create Interval Dataset Chinese_Month */
data Chinese_Month;
  set Chinese_Calendar(keep=Gregorian_date chinese_month
    rename=(Gregorian_date=begin chinese_month=season));
  by season notsorted;
  if first.season;
  format begin date9.;
run;

/* Create Interval Datasets Chinese_Holidays */
data Chinese_Holidays;
  set Chinese_Calendar(keep=Gregorian_date season
    rename=(Gregorian_date=begin));
  by season notsorted;
  if first.season;
  format begin date9.;
run;
/* Create Interval Datasets Chinese_Years */
data Chinese_Years(drop=chinese_year);
  set Chinese_Calendar(keep=Gregorian_date chinese_year
    rename=(Gregorian_date=begin));
  select (mod(chinese_year,12));
    when (0)  season=1;
    when (1)  season=2;
    when (2)  season=3;
    when (3)  season=4;
    when (4)  season=5;
    when (5)  season=6;
    when (6)  season=7;
    when (7)  season=8;
    when (8)  season=9;
    when (9)  season=10;
    when (10) season=11;
    when (11) season=12;
    otherwise season=0;
  end;
  format begin date9.;
run;

data Chinese_Years;
  set Chinese_Years;
  by season notsorted;
  if first.season;
  format begin date9.;
run;

/*Create formats for Chinese Holidays and Chinese Years */
proc format;
  value ch(default=40)
      1='Chinese New Year -- ChunJie'
      2='Lantern Festival -- YuanXiaoJie'
      3='Qingming Festival -- QingMingJie'
      4='Dragon Boat Festival -- DuanWuJie'
      5='Night of Sevens -- QiXi'
      6='Ghost Festival -- ZhongYuanJie'
      7='Mid-Autumn Festival -- ZhongQiuJie'
      8='Double Ninth Festival -- ChongYangJie'
      9='Xia Yuan Festival -- XiaYuanJie'
      10='Winter Solstice Festival -- DongZhi'
      11='Kitchen God Festival -- XiaoNian';

  value cy(default=20)
      1='the Monkey Year'
      2='the Rooster Year'
      3='the Dog Year'
      4='the Pig Year'
      5='the Rat Year'
      6='the Ox Year'
      7='the Tiger Year'
      8='the Rabbit Year'
      9='the Dragon Year'
      10='the Snake Year'
      11='the Horse Year'
      12='the Goat Year';
run;


/**
  * Set intervalds option
  *
  *  The following line is all that is needed in order to
  *  establish cm, ch and cy as valid intervals using the
  *  Chinese_Month, Chinese_Holidays and Chinese_Years
  *  interval datasets, respectively
  *
  */
options intervalds=(cm=Chinese_Month
                    ch=Chinese_Holidays
                    cy=Chinese_Years);

/*Testing......................*/ 
/*Test Which Chinese Year it should be  */

data test_years;
  do date='1jan2007'd to '31dec2014'd;
    season=INTINDEX( 'cy', date );
    if season then do;
      Chinese_year=put(season,cy.);
      output;
    end;
  end;
  format date date9.;
run;

/*Test Which Chinese Month it should be*/ 
data test_month;
  do date='1jan2007'd to '31dec2014'd;
    Chinese_Month=INTINDEX( 'cm', date );
    output;
  end;
  format date date9.;
run;

/*Test Chinese Holidays  */
data test_holidays;
  do date='1jan2010'd to '31dec2012'd;
    season=INTINDEX( 'ch', date );
    if season then do;
      Chinese_holiday=put(season,ch.);
      output;
    end;
  end;
  format date date9.;
run;


/*Test INTNX Function */
data test_functions;
  informat date date9.;
  format next_year_start
         next_year_middle
         next_year_end
         next_month_start
         next_month_middle
         next_month_end
         date
         date9.;
  input date;
  next_year_start=intnx('cy',date,1,'b');
  next_year_middle=intnx('cy',date,1,'m');
  next_year_end=intnx('cy',date,1,'e');
  next_month_start=intnx('cm',date,1,'b');
  next_month_middle=intnx('cm',date,1,'m');
  next_month_end=intnx('cm',date,1,'e');
  cards;
13feb2010
14feb2010
15feb2010
2feb2011
3feb2011
4feb2011
;
