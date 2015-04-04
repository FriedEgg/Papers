/**
  * Hebrew and Islamic Calendars
  *
  * This program adds a number of functions to be used in the 
  * conversion of SAS dates to and from Hebrew and Islamic dates.  
  * There is also a expansion of the SAS HOLDIAY Function to 
  * include Jewish and Islamic Holidays and an example of how 
  * to use the functions along with the INTERVALDS option to 
  * create an automated Hanukkah email application with an ascii 
  * graphic menorah.
  *
  * If ascii art is desired for other email use,a nice collection
  * is available at: http://www.ascii-art.de/ascii/index.shtml
  *
  * AUTHORS: Matthew Kastin and Arthur Tabachneck
  * DATE: February 14, 2012
  *
  */

proc fcmp outlib=work.func.dates;

  /**
    * Hebrew Calendar Functions
    * 
    * hebrew_leap
    *  Check whether Hebrew year is a leap year
    *
    * hebrew_year_months
    *  Get number of months in Hebrew year (12=normal, 13=leap)
    *
    * hebrew_delay_1
    *  Test for delay of start of new year and to avoid Sunday,
    *  Wednesday and Friday as start of the new year
    * 
    * hebrew_delay_2
    *  Check for delay of start of new year due to length of
    *  adjacent years
    *
    * hebrew_year_days
    *  Get number of days in a given Hebrew year
    *
    * hebrew_month_days
    *  Get number of days in a month of a given Hebrew month
    *
    * hebrew_to_jd
    *  Convert a given Hebrew date to Julian date
    *
    * hebrew_to_sd
    *  Convert a given Hebrew date to SAS date
    *
    * jd_to_hebrew
    *  Given a Julian date, convert it to a Hebrew date,
    *  returning text in format %Y-%b-%d.  This works by
    *  making multiple calls to the inverse function
    *
    * sd_to_hebrew
    *  Given a SAS date, convert it to a Hebrew date,
    *  returning text in format %Y-%b-%d.  This works by
    *  making multiple calls to the inverse function
    *
    */
		
  function hebrew_leap(year);
    return(mod(((year*7)+1),19)<7);
  endsub;

  function hebrew_year_months(year);
    return(ifn(hebrew_leap(year),13,12));
  endsub;

  function hebrew_delay_1(year);
    months=floor(((235*year)-234)/19);
    parts=12084+(13753*months);
    day=(months*29)+floor(parts/25920);
    if mod((3*(day+1)),7)<3 then day+1;
    return(day);
  endsub;

  function hebrew_delay_2(year);
    last=hebrew_delay_1(year-1);
    present=hebrew_delay_1(year);
    next=hebrew_delay_1(year+1);
    a=ifn(next-present=356,2,ifn(present-last=382,1,0));
    return(a);
  endsub;

  function hebrew_year_days(year);
    a=hebrew_to_jd(year+1,7,1)-hebrew_to_jd(year,7,1);
    return(a);
  endsub;

  function hebrew_month_days(year,month);
    /*The followign are always 29 day months*/
    if month in (2,4,6,10,13) then return(29);

    /*If not a leap year, Adar has 29 days*/
    else if month=12 and not(hebrew_leap(year))
     then return(29);

    /*Heshvan's days depend on length of year*/
    else if month=8 and
     not(mod(hebrew_year_days(year),10)=5)
     then return(29);

    /*Kislev also varies with length of year*/
    else if month=9 and
     mod(hebrew_year_days(year),10)=3 then return(29);

    /*All other months have 30 days*/
    else return(30);
  endsub;

  function hebrew_to_jd(year,month,day);
    hebrew_epoch=347995.5;
    months=hebrew_year_months(year);
    jd=hebrew_epoch+hebrew_delay_1(year)+
     hebrew_delay_2(year)+day+1;
    if month<7 then do;
      do mon=7 to months;
        jd+hebrew_month_days(year,mon);
      end;
      do mon=1 to month-1;
        jd+hebrew_month_days(year,mon);
      end;
    end;
    else do mon=7 to month-1;
      jd+hebrew_month_days(year,mon);
    end;
    return(jd);
  endsub;

  function hebrew_to_sd(year,month,day);
    return(hebrew_to_jd(year,month,day)-2436934.5);
  endsub;
 
  function jd_to_hebrew(jd) $10;
    _jd=floor(jd)+0.5;
    count=floor(((_jd-347995.5)*98496)/35975351);
    year=count-1;
    do while(_jd>=hebrew_to_jd(count,7,1));
      count+1; 
      year+1;
    end;
    first=ifn(_jd<hebrew_to_jd(year,1,1),7,1);
    month=first-1;
    do while(_jd>hebrew_to_jd(year,first,1));
      first+1; 
      month+1;
    end;
    day=(_jd-hebrew_to_jd(year,month,1))+1;
    return(catx('-',of year month day));
  endsub;
 
  function sd_to_hebrew(sd) $10;
    return(jd_to_hebrew(sd+2436934.5));
  endsub;
 
  /**
    * Islamic Calendar Functions
    * 
    * islamic_yeap
    *  Check whether Islamic year is a leap year
    *
    * islamic_to_jd
    *  Convert a given Islamic date to a Julian date
    *
    * islamic_to_sd
    *  Convert a given Islamic date to a SAS date
    *
    * jd_to_islamic
    *  Convert a given Julian date to an Islamic date
    *
    * sd_to_islamic
    *  Convert a given SAS date to an Islamic date
    *
    */ 

  function islamic_leap(year);
    return(mod((year*11)+14,30)<11);
  endsub;
 
  function islamic_to_jd(year,month,day);
    return((day+ceil(29.5*(month-1))+(year-1)*354+
     floor((3+(11*year))/30)+1948439.5)-1);
  endsub;
 
  function islamic_to_sd(year,month,day);
    return(islamic_to_jd(year,month,day)-2436934.5);
  endsub;

  function jd_to_islamic(jd) $10;
    _jd=floor(jd)+0.5;
    year=floor(((30*(_jd-1948439.5))+10646)/10631);
    month=min(12,ceil((_jd-(29+islamic_to_jd(year,1,1)))
     /29.5)+1);
    day=(_jd-islamic_to_jd(year,month,1))+1;
    return(catx('-',of year month day));
  endsub;
 
  function sd_to_islamic(sd) $10;
    return(jd_to_islamic(sd+2436934.5));
  endsub;
 
  /**
    * HOLIDAY function expansion
    * 
    * holiday_x
    *  Return the SAS date for a given holiday in a given
    *  year.  Multiple spelling variations are accepted
    *  for Jewish and Islamic holidays.  This function
    *  combines the Jewish and Islamic holidays together
    *  with the holidays captured by the holiday function
    *  and adds some spelling variations to the holidays
    *  contained in the holiday function
    *
    */
 
  function holiday_x(h $,y);
    select(upcase(h));
      when ('ROSH HASHANA') return(hebrew_to_sd(y+3761,7,1));
      when ('YOM KIPPUR') return(hebrew_to_sd(y+3761,7,10));
      when ('SUKKOT') return(hebrew_to_sd(y+3761,7,15));
      when ('SHMINI ATZERET') return(hebrew_to_sd(y+3761,7,22));
      when ('SIMCHAT TORAH','SIMHATH TORAH','SIMKHES TOREH')
       return(hebrew_to_sd(y+3761,7,23));
      when ('HANUKKAH','CHANUKAH','CHANUKKAH','CHANUKA')
       return(hebrew_to_sd(y+3761,9,25));
      when ('TU BISHVAT') return(hebrew_to_sd(y+3760,11,15));
      when ('PURIM') return(ifn(hebrew_leap(y+3760),
       hebrew_to_sd(y+3760,13,14),hebrew_to_sd(y+3760,12,14)));
      when ('PESACH','PASSOVER','PESAH','PESAKH','PEYSEKH',
       'PAYSOKH') return(hebrew_to_sd(y+3760,1,15));
      when ('SEFIRAH',"SEFIRAT HA'OMER")
       return(hebrew_to_sd(y+3760,1,16));
      when ('YOM HASHOAH','HOLOCAUST REMEMBRANCE DAY')
       return(hebrew_to_sd(y+3760,1,27));
      when ('YOM HAZIKARON','ISRAEL MEMORIAL DAY')
       return(hebrew_to_sd(y+3760,2,4));
      when ("YOM HA'ATZMAUT",'YOM HAATZMAUT','YOM HA ATZMAUT',
       'ISRAEL INDEPENDENCE DAY')
       return(hebrew_to_sd(y+3760,2,5));
      when ("LAG BA'OMER","LAG LA'OMER",'LAG BAOMER',
       'LAG LAOMER') return(hebrew_to_sd(y+3760,2,18));
      when ('YOM YERUSHALAYIM','JERUSALEM DAY')
       return(hebrew_to_sd(y+3760,2,28));
      when ('SHAVUOT','SHAVUOS',"SHABHU'OTH")
       return(hebrew_to_sd(y+3760,3,6));
      when ("TISHA B'AV",'TISHA BAV','TISHA B AV')
       return(hebrew_to_sd(y+3760,5,9));
      when ("TU B'AV",'TU BAV','TU B AV')
       return(hebrew_to_sd(y+3760,5,15));
      when ('ISLAMIC NEW YEAR','HIJRI NEW YEAR',
       'RAS AS-SANAH AL-HIJRIYAH') 
       return(islamic_to_sd(y-579,1,1));
      when ('DAY OF ASHURA','ASHURA','ASHOURA')
       return(islamic_to_sd(y-579,1,10));
      when ('MAWLID','MAWLIDU N-NABIYYI','MAWLID AN-NABI',
       'MEVLID','MEVLIT','MULUD')
       return(islamic_to_sd(y-579,3,12));
      when ('LAYLAT AL-MIRAJ','LAILAT AL MIRAJ','SHAB-E-MIRAJ',
       'MIRAC KANDILI') return(islamic_to_sd(y-579,7,27));
      when ("MID-SHA'BAN",'MID-SHABAN','MID-SHA BAN',
       'LAYLATUL BARAAH',"LAYLATUL BARA'AH",'LAYLATUL BARA AH',
       'SHAB-E-BARAT') return(islamic_to_sd(y-579,8,15));
      when ('RAMADAN','RAMAZAN') return(islamic_to_sd(y-579,9,1));
      when ('LAYLAT AL-QADR',"LAILATUL QADR'",'LAILATUL QADR',
       'SHAB-E-QADR') return(islamic_to_sd(y-579,9,27));
      when ('EID-UL-FITR','EID AL-FITR','ID-UL-FITR','ID AL-FITR',
       'IDU I-FITR','EID')
       return(islamic_to_sd(y-579,9,ifn(islamic_leap(y-579),30,29)));
      when ('EID AL-ADHA',"EID AL-ADHA'",'FESTIVAL OF SACRIFICE',
       'GREATER EID') return(islamic_to_sd(y-579,12,10));
      when ('BOXING','BOXING DAY') return(holiday('BOXING',y));
      when ('CANADA','CANADA DAY') return(holiday('CANADA',y));
      when ('CANADAOBSERVED') return(holiday('CANADAOBSERVED',y));
      when ('CHRISTMAS') return(holiday('CHRISTMAS',y));
      when ('COLUMBUS','COLUMBUS DAY')
       return(holiday('COLUMBUS',y));
      when ('EASTER') return(holiday('EASTER',y));
      when ('FATHERS','FATHERS DAY')
       return(holiday('FATHERS',y));
      when ('HALLOWEEN') return(holiday('HALLOWEEN',y));
      when ('LABOR') return(holiday('LABOR',y));
      when ('MLK','MARTIN LUTHER','MARTIN LUTHER KING')
       return(holiday('MLK',y));
      when ('MEMORIAL','MEMORIAL DAY')
       return(holiday('MEMORIAL',y));
      when ('MOTHERS','MOTHERS DAY') return(holiday('MOTHERS',y));
      when ('NEWYEAR','NEW YEAR','NEW YEARS','NEW YEARS DAY')
       return(holiday('NEWYEAR',y));
      when ('THANKSGIVING','THANSGIVING DAY')
       return(holiday('THANKSGIVING',y));
      when ('THANKSGIVINGCANADA')
       return(holiday('THANKSGIVINGCANADA',y));
      when ('USINDEPENDENCE','INDEPENDENCE DAY','JULY 4TH')
       return(holiday('USINDEPENDENCE',y));
      when ('USPRESIDENTS','PRESIDENTS DAY')
       return(holiday('USPRESIDENTS',y));
      when ('VALENTINES','VALENTINES DAY')
       return(holiday('VALENTINES',y));
      when ('VETERANS','VETERANS DAY','REMEMBRANCE',
       'REMEMBRANCE DAY','REMEMBERANCE','REMEMBERANCE DAY')
       return(holiday('VETERANS',y));
      when ('VETERANSUSG') return(holiday('VETERANSUSG',y));
      when ('VETERANSUSPS') return(holiday('VETERANSUSPS',y));
      when ('VICTORIA','VICTORIA DAY') return(holiday('VICTORIA',y));
      otherwise return(.);
    end;
  endsub;
run;
 
options cmplib=work.func;
 
/**
  * Format $JHOL2DAYS
  *
  *  This format provides the relationships between Holiday names
  *  the number of days each holiday lasts.  No spelling variations
  *  are included as the format is only used by the program
  *
  */

proc format;
  value $jhol2days
  'ROSH HASHANA'            =2
  'YOM KIPPUR'              =1
  'SUKKOT'                  =6
  'SHMINI ATZERET'          =1
  'SIMCHAT TORAH'           =1
  'HANUKKAH'                =8
  'TU BISHVAT'              =1
  'PURIM'                   =1
  'PESACH'                  =8
  'SEFIRAH'                 =49
  'YOM HASHOAH'             =1
  'ISRAEL INDEPENDENCE DAY' =1
  'LAG BAOMER'              =1
  'YOM YERUSHALAYIM'        =1
  'SHAVUOT'                 =2
  "TISHA B'AV"              =1
  "TU B'AV"                 =1
  other                     =0
  ;
run;
 
/**
  * Create Interval Dataset JHOLS and a S2JHOL Format
  *
  *  The dataset created in this section provides a custom interval
  *  dataset for the INTERVALDS option. It contains all dates for
  *  Jewish holidays from January 1, 2000 to December 31, 2100
  *
  * Format S2JHOL
  *
  *  This format provides the relationship between the result of
  *  applying the intindex function and the Jewish Holidays that
  *  the numbers represent
  *
  */

data s2jhol(drop=end) jhols;
  declare hash hol();
  hol.definekey('begin');
  hol.definedata('holiday','season');
  hol.definedone();

  array h[16] $30 ('ROSH HASHANA'            'YOM KIPPUR'
                   'SUKKOT'                  'SHMINI ATZERET'
                   'SIMCHAT TORAH'           'HANUKKAH'
                   'TU BISHVAT'              'PURIM'
                   'PESACH'                  'YOM HASHOAH'
                   'ISRAEL INDEPENDENCE DAY' 'LAG BAOMER'
                   'YOM YERUSHALAYIM'        'SHAVUOT'
                   "TISHA B'AV"              "TU B'AV");

  do year=2000 to 2100;
    season=0;
    do i=1 to dim(h);
      holiday=h[i];
      begin=holiday_x(h[i],year);
      season+1;
      hol.add();
      if year=2000 then output s2jhol;
    end;
  end;

  do begin='01JAN2000'd to '31DEC2100'd;
    holiday='';
    end=begin;
    rc=hol.find();
    if (rc = 0) then do;
      end=begin+put(holiday,$jhol2days.)-1;
      output jhols;
    end;
    else do;
      season=0;
      output jhols;
    end;
  end;

  keep begin end season holiday;
  format begin end date11.;
run;

data s2jhol;
  retain fmtname 's2jhol' type 'n';
  set s2jhol (drop=begin rename=(season=start holiday=label));
run;
 
proc format cntlin=s2jhol;
run;
 
/**
  * Set intervalds option
  *
  *  The following line is all that is needed in order to
  *  establish JewishHolidays as a valid interval using the
  *  jhols interval dataset
  *
  */

options intervalds=(JewishHolidays=jhols);

/**
  * Macro SENDIT
  *
  * The following macro uses the interval dataset to send
  * emails on each Jewish holiday.  There is a little artistic
  * touch added for the days during Hanukkah.  On those days
  * the email will include an ASCII graphic menorah with the
  * correct number of candles lit.
  *
  */

%macro sendit(to,subj,from,test=NO);
  %if &test. eq YES %then
    %let today=%sysevalf("12DEC2012"d);
  %else %let today=%sysfunc(today());
  %if %sysfunc(intindex(JewishHolidays,&today.)) %then %do;
    options EMAILSYS=SMTP
            EMAILID="your_email_address"
            EMAILPW="your_email_password"
            EMAILHOST="your_email_smtp_address"
            EMAILAUTHPROTOCOL=LOGIN
            EMAILPORT=587 ;
   /* Note: EMAILPORT may have to set to 25 */

    filename mymail email lrecl=256 TYPE='TEXT/HTML';

    data _null_;
      file mymail to=("&to.") subject="&subj.";
      array candles[17] $40. (17*'&nbsp;');
      put "<BR>";
      put "<B><font face='courier new'>";
      x=intindex('JewishHolidays',&today.);
      msg=cat('Hope you have a Happy ',
       propcase(strip(put(x,s2jhol.))),'!');
      put msg "<BR> <BR>";
      if put(x,s2jhol.) eq 'HANUKKAH' then do;
        ncandles=2*(&today.-intnx('JewishHolidays',
         &today.,0))+1;
        if ncandles gt 7 then ncandles+2;
        candles[9]=")";
        msg=catx(' ',of %quote(candles:));
        put "<font face='courier new' color=red>";
        put msg "<BR>";
        do i=1 to ncandles by 2;
          candles[i]=")";
          if i eq 7 then i=9;
        end;
        put "<font face='courier new' color=red>";
        msg=catx(' ',of %quote(candles1-candles8));
        put msg;
        put "<font face='courier new' color=black>";
        put %quote(candles(9));
        put "<font face='courier new' color=red>";
        msg=catx(' ',of %quote(candles10-candles17));
        put msg "<BR>";
        do i=1 to 17 by 2;
          candles[i]="|";
        end;
        msg=catx(' ',of %quote(candles:));
        put "<font face='courier new' color=black>";
        put msg "<BR>";
        do i=2 to 16 by 2;
          candles[i]="_";
        end;
        msg=catx(' ',of %quote(candles:));
        put msg "<BR>";
        do i=1 to 17;
          if i eq 8 then i=11;
          candles[i]='&nbsp;';
        end;
        msg=catx(' ',of %quote(candles:));
        put msg "<BR>";
      end;
      put "</B></font><BR>";
      put "&from";
      put '</style></body></html>';
    run;
  %end;
%mend;

/* Example usage */
%sendit(EmailAddress,Happy Holidays,YourName,test=YES) /* If only testing */
%sendit(EmailAddress,Happy Holidays,YourName) /* Actual use */

/*or, to send a number of emails*/
data _null_;
  informat email $30.;
  input email &;
  call execute('%sendit('||strip(email)||',Happy Holidays,YourName)');
  cards;
art297@netscape.net
art297@rogers.com
;
