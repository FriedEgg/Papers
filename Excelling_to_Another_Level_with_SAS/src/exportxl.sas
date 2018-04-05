/** The %exportxl macro
  *
  * This macro exports SAS datasets to Excel. It only requires base SAS and
  * provides the abilities to:
  *
  *   * create new workbooks, worksheets, and modify existing worksheets
  *   * include or not include a row containing variable names or labels
  *   * output to a range that isn't pre-defined
  *   * use Excel templates or workbooks as templates
  *   * output formatted or unformatted values
  *   * export a file to your system's clipboard so that it can be pasted
        into another program (e.g., Word or Powerpoint)
  *   * avoid 32/64 bit incompatibility issues
  *   * create pivot tables
  *
  * The macro was designed so that it can be called directly or included
  * as a SAS abbreviation
  *
  * AUTHORS: Arthur Tabachneck, Tom Abernathy and Matt Kastin
  * CREATED: August 6, 2013
  * MOST RECENT VERSION: November 10, 2017

  * Named Parameter Descriptions:

  * data: the parameter to which you would assign the name of the file that
    you want to export.  Like with PROC EXPORT, you can use either a one or
    two-level filename, and dataset options can be included.  If you assign
    a one-level filename, the libname work will be used.  When the macro is
    called as an action from a SAS Explorer window, this parameter should be
    set to equal: data=%8b.%32b which the macro will interpret as
    libname.filename of the file that was selected

  * outfile: the parameter to which you would assign the path and filename of
    the workbook that you want the macro to either create or modify.  The
    file’s path must exist before the macro is run. Any one of the following
    values can be used:
    
    Any valid filename (including path) for which you have write access
      Null The output file will be created using the selected data file’s
            pathname, a back slash, the selected data file’s filename, and
            the xlsx extension
      W    Provide window for user input during run
          
  * sheet: the parameter to which you would assign the name of the worksheet
    that you want to either create or modify. Any one of the following
    values can be used:

      Any valid worksheet name
      Null The filename of the data parameter
      W    Provide window for user input during run

  * type: the parameter you would use to indicate the type of process that
    you want to run. The default value of this parameter is: N.  Any one of
    the following values can be used:

      N Create a new workbook
      A Add a new worksheet to an existing workbook
      M Modify an existing worksheet
      C Copy the dataset to your system’s clipboard

  * usenames: the parameter you would use to indicate whether you want the
    first row of the range to contain the first data record, the variable
    names, or the variable labels. The default value of this parameter is: Y.
    Any one of the following values can be used:

      N Don’t include a variable name row
      Y You want the top most row to contain variable names
      L You want the top most row to contain variable labels if they exist,
        otherwise use variable names
      W Provide window for user input during run

  * range: the parameter you would use to indicate the upper left cell where
    you want the table to begin.  The default value is: A1. Any one of The
    following values can be used:
    
      Any valid Excel cell name
      W Provide window for user input during run

  * template: the parameter you would use if you have a preformatted Excel
    template (or Excel workbook) that you want to apply to the data you are
    exporting. In such a case, use this parameter to specify the template’s
    path and filename (e.g., template=c:\temp\template.xltx ). Any one of the
    following values can be used:

    Any valid workbook or template filename (including path)
      Null No template is to be used
      W    Provide window for user input during run

  * templatesheet: If you include the template parameter you must use this
    parameter to specify the template's Worksheet that contains the template
    you want to apply (e.g.,  templatesheet=template ).  Either of the
    following values can be used:
    
      Any existing worksheet name
      W Provide window for user input during run
    
  * useformats: the parameter you would use to indicate whether you want a
    dataset’s formats to be applied when you exporting its data.  The default
    value of this parameter is: N. Any one of the following values can be
    used:

      Y If you want a dataset’s formats to be applied
      N If you don’t want a dataset’s formats to be applied
      W Provide window for user input during run

  * usenotepad: If you're running this macro on a server, or on an operating
    system that doesn’t provide direct access to your computer’s clipboard,
    or have an Excel configuration that clears the clipboard upon opening,
    set this parameter to equal 'Y'. You should only use this parameter if
    you meet one of the above conditions, as it is less efficient than the
    method used for this parameter's default value (i.e., N). Any one of the
    following values can be used:
    
      N Don't use Notepad
      Y Use your system's or server's version of Notepad
    
  * pivot: the parameter you would use to indicate whether you want a
    pivot table created at the same time as you're exporting data.  The
    default value of this parameter is a NULL value.
    
    If you want the macro to create a pivot table, this parameter should
    contain a space separated list of all of the character variables you
    want the Pivot Table to use as class variables, followed by another
    space, and the name of the variable you want the Pivot Table to use
    as its analytical variable. Any one of the following values can be used:
    
      Space separated list of variable names
      W Provide window for user input during run
    

*/

%macro exportxl(data=,
                outfile=,
                sheet=,
                type=N,
                usenames=Y,
                range=A1,
                template=,
                templatesheet=,
                useformats=N,
                usenotepad=N,
                pivot=);

/*Check whether the data parameter contains a one or two-level filename*/
/*and, if needed, separate libname and data from data set options */
  %let lp=%sysfunc(findc(%superq(data),%str(%()));
  %if &lp. %then %do;
   %let rp=%sysfunc(findc(%superq(data),%str(%)),b));

/*for SAS*/
   %let dsoptions=%qsysfunc(substrn(%nrstr(%superq(data)),&lp+1,&rp-&lp-1));
   %let data=%sysfunc(substrn(%nrstr(%superq(data)),1,%eval(&lp-1)));
/*for WPS*/
/*     %let dsoptions=%qsysfunc(substrn(%nrquote(%superq(data)),&lp+1,&rp-&lp-1)); */
/*     %let data=%sysfunc(substrn(%nrquote(%superq(data)),1,%eval(&lp-1))); */

  %end;
  %else %let dsoptions=;
  %if %sysfunc(countw(&data.)) eq 2 %then %do;
    %let libnm=%scan(&data.,1);
    %let filenm=%scan(&data.,2);
  %end;
  %else %do;
    %let libnm=work;
    %let filenm=&data.;
  %end;

  %if %upcase(&outfile.) eq W %then %do;
    data _null_;
      window outfile rows=8 columns=80
      irow=1 icolumn=2 color=black
      #2 @3 'Enter path and filename of desired outfile: '
      color=gray outfile $70. required=yes
      attr=underline color=yellow;
      DISPLAY outfile blank;
      call symputx('outfile',outfile);
      stop;
    run;
  %end;
  %if %length(&outfile.) lt 1 %then
    %let outfile=%sysfunc(pathname(&libnm.))\&filenm..xlsx;;

  %if %upcase(&sheet.) eq W %then %do;
    data _null_;
      window sheet rows=8 columns=80
      irow=1 icolumn=2 color=black
      #2 @3 'Enter valid worksheet name: '
      color=gray sheet $40. required=yes
      attr=underline color=yellow;
      DISPLAY sheet blank;
      call symputx('sheet',sheet);
      stop;
    run;
  %end;
  %if %length(&sheet.) lt 1 %then
    %let sheet=&filenm.;;

  /*Left for compatibility with previous version*/
  %if %upcase(&type.) eq P %then %do;
    proc export
      data=&libnm..&filenm.
          %if %length(%unquote(&dsoptions.)) gt 2 %then (%unquote(&dsoptions.));
      outfile= "&outfile."
      dbms=xlsx
      replace
      ;
      %if &sheet. ne "" %then sheet="&sheet.";;
    run;
  %end;
  /*end of compatibility code - Note: above is not documented in paper*/
  %else %do;
    %if %upcase(&range.) eq W %then %do;
      data _null_;
        window range rows=8 columns=80
        irow=1 icolumn=2 color=black
        #2 @3 'Enter the upper left cell where range should begin (e.g. D5): '
        color=gray range $41. required=yes
        attr=underline color=yellow;
        DISPLAY range blank;
        call symputx('range',range);
        stop;
      run;
    %end;
    %else %if %length(&range.) lt 2 %then %do;
      %let range=A1;
    %end;

    %if %upcase(template) eq W %then %do;
      data _null_;
        window template rows=8 columns=80
        irow=1 icolumn=2 color=black
        #2 @3 'Enter the template path and name: '
        color=gray template $41. required=yes
        attr=underline color=yellow;
        DISPLAY template blank;
        call symputx('template',template);
        stop;
      run;
    %end;
    %else %if %length(&template.) lt 2 %then %do;
      %let template=;
    %end;

    %if %upcase(&templatesheet.) eq W %then %do;
      data _null_;
        window templatesheet rows=8 columns=80
        irow=1 icolumn=2 color=black
        #2 @3 "Enter the template sheet's name: "
        color=gray templatesheet $41. required=yes
        attr=underline color=yellow;
        DISPLAY templatesheet blank;
        call symputx('templatesheet',templatesheet);
        stop;
      run;
    %end;
    %else %if %length(&templatesheet.) lt 2 %then %do;
      %let templatesheet=;
    %end;

    %if %upcase(&pivot) eq W %then %do;
      data _null_;
        window pivot rows=8 columns=80
        irow=1 icolumn=2 color=black
        #2 @3 'Enter the space separated class and analysis variable list: '
        color=gray pivot $41. required=yes
        attr=underline color=yellow;
        DISPLAY pivot blank;
        call symputx('pivot',pivot);
        stop;
      run;
    %end;
    %else %if %length(&pivot.) lt 2 %then %do;
      %let pivot=;
    %end;

    %if %upcase(&useformats) eq W %then %do;
      data _null_;
        window useformats rows=8 columns=80
        irow=1 icolumn=2 color=black
        #2 @3 'Enter whether to use formats (Y/N): '
        color=gray useformats $1. required=yes
        attr=underline color=yellow;
        DISPLAY useformats blank;
        call symputx('useformats',useformats);
        stop;
      run;
    %end;

    data _null_;
      dsid=open(catx('.',"&libnm.","&filenm."));
      if dsid eq 0 then do;
        rc=close(dsid);
        link err;
      end;
      rc=close(dsid);
      err: 
      do;
        m = sysmsg();
        put m;
        stop;
      end;
    run;

    data t_e_m_p;
      set &libnm..&filenm. (%unquote(&dsoptions.) obs=1);
    run;

    proc sql noprint;
      select name,length,type,format,strip(coalescec(label,name))
        into :vnames separated by "~",
             :vlengths separated by "~",
             :vtypes separated by "~",
             :vformats separated by "~",
             :vlabels separated by "~"
          from dictionary.columns
            where libname="WORK" and
                  memname="T_E_M_P"
      ;
    quit;
    %let nvar=&sqlobs.;

    filename code2inc temp;
    data _null_;
      file code2inc;
      length script $80;
      length fmt $32;
      do i=1 to &nvar;
        if i gt 1 then put 'rc=fput(fid,"09"x);';
        %if %upcase(&useformats.) eq Y %then %do;
          fmt=scan("&vformats.",i,"~","M");
        %end;
        %else call missing(fmt);;
        if scan("&vtypes.",i,"~") eq 'char' then do;
          if missing(fmt) then
           fmt=catt('$',scan("&vlengths.",i,"~","M"),'.');
          script=catt('rc=fput(fid,putc(put(',
           scan("&vnames.",i,"~","M"),',',fmt,"),'$char",
           scan("&vlengths.",i,"~","M"),".'));");
          put script;
        end;
        else do;
          if missing(fmt) then fmt='best32.';
          script=catt('rc=fput(fid,putc(put(',
           scan("&vnames.",i,"~","M"),',',fmt,"),'$char32.'));");
          put script;
        end;
      end;
      put 'rc=fwrite(fid);';
    run;

    data _null_;
      dsid=open("work.t_e_m_p");
      rc=attrn(dsid,'any');
      if rc ne 1 then do;
        rc=close(dsid);
        link err;
      end;
      rc=close(dsid);
      err: 
      do;
        m = sysmsg();
        put m;
        stop;
      end;
    run;

    data _null_;
      %if %upcase(&usenotepad) eq Y %then %do;
        %let server_path=%sysfunc(pathname(work));
        rc=filename('clippy',"&server_path.\clip.txt",'DISK');
      %end;
      %else %do;
        rc=filename('clippy',' ','clipbrd');
      %end;
      if rc ne 0 then link err;
/*      Use the following line for SAS*/
     fid=fopen('clippy','o', 0,'v');
/*      Use the following line for WPS*/
/*       fid=fopen('clippy','o',4194404,'v'); */
      if fid eq 0 then link err;
      do i = 1 to &nvar.;
        %if %upcase(&usenames.) ne N %then %do;
          if i gt 1 then rc=fput(fid,'09'x);
          %if %upcase(&usenames.) eq Y %then %do;
            rc=fput(fid,scan("&vnames.",i,"~","M"));
          %end;
          %else %do;
            if missing(scan("&vlabels.",i,"~","M")) then
             rc=fput(fid,scan("&vnames.",i,"~"));
            else rc=fput(fid,scan("&vlabels.",i,"~","M"));
          %end;
        %end;
      end;
      %if %upcase(&usenames.) ne N %then %do;
        rc=fwrite(fid);;
      %end;
      do until (lastone);
        set &libnm..&filenm.
          %if %length(%unquote(&dsoptions.)) gt 2 %then (%unquote(&dsoptions.));
          end=lastone;
        %include code2inc;
      end;
      rc=fclose(fid);
      rc=filename('clippy');
      rc=filename('code2inc');
      stop;

      err: 
      do;
        m = sysmsg();
        put m;
        rc=filename('code2inc');
        stop;
      end;
    run;

    %if %upcase(&type.) eq N or %upcase(&type.) eq M
     or %upcase(&type.) eq A %then %do;

      data _null_;
        length script filevar $256;
        script = catx('\',pathname('WORK'),'PasteIt.vbs');
        filevar = script;
        script="'"||'cscript "'||trim(script)||'"'||"'";
        call symput('script',script);
        file dummy1 filevar=filevar recfm=v lrecl=512;
    
        put 'Dim objExcel';
        put 'Dim Newbook';

        %if %length(&template.) gt 1 %then %do;
          %if %upcase(&type.) eq A %then put 'Dim OldBook';;
          put 'Set objExcel = CreateObject("Excel.Application")';
          put 'objExcel.Visible = True';
          %if %upcase(&type.) eq N %then %do;
            script=catt('Set Newbook = objExcel.Workbooks.Add("',
             "&template.",'")');
            put script;
            script=catt('objExcel.Sheets("',"&TemplateSheet.",
             '").Select');
            put script;
            script=catt('objExcel.Sheets("',"&TemplateSheet.",
             '").Name = "',"&sheet.",'"');
            put script;
            put 'objExcel.Visible = True';
            script=catt('objExcel.Sheets("',"&sheet.",
             '").Range("',"&range.",'").Activate');
            put script;
            %if %upcase(&usenotepad) eq Y %then %do;
              %let Return_to = Return_1;
              %goto use_npad;
              %Return_1:
            %end;
            script=catt('objExcel.Sheets("',"&sheet.",'").Paste');
            put script;
            script=catt('objExcel.Sheets("',"&sheet.",
             '").Range("A1").Select');
            put script;
            put 'objExcel.DisplayAlerts = False';
            script=catt('NewBook.SaveAs("',"&outfile.",'")');
            put script;
          %end;
          %else %do;
            script=catt('strFile="',"&outfile.",'"');
            put script;
            script=catt('Set OldBook=objExcel.Workbooks.Open("',
             "&outfile.",'")');
            put script;
            script=catt('Set Newbook = objExcel.Workbooks.Add("',
             "&template.",'")');
            put script;
            script=catt('objExcel.Sheets("',"&TemplateSheet.",
             '").Select');
            put script;
            script=catt('objExcel.Sheets("',"&TemplateSheet",
             '").Name ="',"&sheet.",'"');
            put script;
            put 'objExcel.Visible = True';
            script=catt('objExcel.Sheets("',"&sheet.",
             '").Range("',"&range.",'").Activate');
            put script;
            %if %upcase(&usenotepad) eq Y %then %do;
              %let Return_to = Return_2;
              %goto use_npad;
              %Return_2:
            %end;
            script=catt('objExcel.Sheets("',"&sheet.",'").Paste');
            put script;
            script=catt('objExcel.Sheets("',"&sheet.",
             '").Range("A1").Select');
            put script;
            script=catt('objExcel.Sheets("',"&sheet.",
             '").Move ,OldBook.Sheets( OldBook.Sheets.Count )');
            put script;
            put 'objExcel.DisplayAlerts = False';
            script=catt('OldBook.SaveAs("',"&outfile.",'")');
            put script;
          %end;
        %end;
        %else %do;
          %if %upcase(&type.) eq N or %upcase(&type.) eq A %then %do;
            %if %upcase(&type.) eq N %then put 'Dim NewSheet';;
            put 'Dim inSheetCount';
            %if %upcase(&type.) eq A %then put 'Dim strFile';;
          %end;

          put 'Set objExcel = CreateObject("Excel.Application")';

          %if %upcase(&type.) eq N %then %do;
            put 'Set Newbook = objExcel.Workbooks.Add()';
            put 'objExcel.Visible = True';
            put 'inSheetCount = Newbook.Application.Worksheets.Count';
            script=catt('set NewSheet = Newbook.Sheets.Add',
             '( ,objExcel.WorkSheets(inSheetCount))');
            put script;
            put 'objExcel.DisplayAlerts = False';
            put 'i = inSheetCount';
            put 'Do Until i = 0';
            put ' Newbook.Worksheets(i).Delete';
            put ' i = i - 1';
            put ' Loop';
            script=catt('Newbook.Sheets(1).Name="',
             "&sheet.",'"');
            put script;
            script=catt('Newbook.Sheets("',"&sheet.",'").Select');
            put script;
            script=catt('Newbook.Sheets("',"&sheet.",
             '").Range("',"&range.",'").Activate');
            put script;
            %if %upcase(&usenotepad) eq Y %then %do;
              %let Return_to = Return_3;
              %goto use_npad;
              %Return_3:
            %end;
            script=catt('Newbook.Sheets("',"&sheet.",'").Paste');
            put script;
            script=catt('NewSheet.SaveAs("',"&outfile.",'")');
            put script;
          %end;
          %else %if %upcase(&type.) eq A %then %do;
            script=catt('strFile="',"&outfile.",'"');
            put script;
            put 'objExcel.Visible = True';
            put 'objExcel.Workbooks.Open strFile';
            put 'inSheetCount = objExcel.Application.Worksheets.Count';
            script=catt('set NewBook = objExcel.Sheets.Add( ,objExcel.',
             'WorkSheets(inSheetCount))');
            put script;
            script=catt('objExcel.Sheets(inSheetCount + 1).Name="',
             "&sheet.",'"');
            put script;
            script=catt('objExcel.Sheets("',"&sheet.",
             '").Select');
            put script;
            put 'objExcel.Visible = True';
            script=catt('objExcel.Sheets("',"&sheet.",'").Range("',
             "&range.",'").Activate');
            put script;
            %if %upcase(&usenotepad) eq Y %then %do;
              %let Return_to = Return_4;
              %goto use_npad;
              %Return_4:
            %end;
            script=catt('objExcel.Sheets("',"&sheet.",'").Paste');
            put script;
            put 'objExcel.DisplayAlerts = False';
            script=catt('Newbook.SaveAs("',"&outfile.",'")');
            put script;
          %end;
          %else %do;
            script=catt('Set Newbook = objExcel.Workbooks.Open("',
             "&outfile.",'")');
            put script;
            script=catt('Newbook.Sheets("',"&sheet.",'").Select');
            put script;
            script=catt('Newbook.Sheets("',"&sheet.",
             '").Range("',"&range.",'").Activate');
            put script;

            %if %upcase(&usenotepad) eq Y %then %do;
              %let Return_to = Return_5;
              %goto use_npad;
              %Return_5:
            %end;
            script=catt('Newbook.Sheets("',"&sheet.",'").Paste');
            put script;
            put 'objExcel.DisplayAlerts = False';
            script=catt('Newbook.SaveAs("',"&outfile.",'")');
            put script;
          %end;
        %end;
        put 'objExcel.Workbooks.Close';
        put 'objExcel.DisplayAlerts = True';
        put 'objExcel.Quit';

        %if %length(&pivot.) gt 2 %then %do;
          put 'Set XL = CreateObject("Excel.Application")';
          put 'XL.Visible=True';
          script=catt('XL.Workbooks.Open "',"&outfile.",'"');
          put script;
          put 'Xllastcell= xl.cells.specialcells(11).address';
          put'XL.Sheets.Add.name = "PivotTable"';
          script=catt('xldata="',"&sheet.",'"');
          put script;
          put 'XL.Sheets(xldata).select';
          put 'XL.ActiveSheet.PivotTableWizard SourceType=xlDatabase,
            XL.Range("A1" & ":" & xllastcell),"Pivottable!R1C1",xldata';
          %do i=1 %to %sysfunc(countw(&pivot.));
            %if &i lt %sysfunc(countw(&pivot.)) %then %do;
              script=catt('XL.ActiveSheet.PivotTables(xldata).PivotFields("',
               "%scan(&pivot.,&i.)",'").Orientation = 1');
            %end;
            %else %do;
              script=catt('XL.ActiveSheet.PivotTables(xldata).PivotFields("',
               "%scan(&pivot.,&i.)",'").Orientation = 4');
            %end;
            put script;
          %end;
          put 'XL.ActiveWorkbook.ShowPivotTableFieldList = False';
          put 'XL.DisplayAlerts = False';
          script=catt('XL.ActiveWorkbook.SaveAs("',"&outfile.",'")');
          put script;
          put 'XL.Workbooks.Close';
          put 'XL.DisplayAlerts = True';
          put 'XL.Quit';
        %end;
        %goto lastline;
        
        %use_npad:
          put 'Dim objShell';
          put 'Set objShell = CreateObject("WScript.Shell")';
          script=catt('objShell.Run "notepad.exe',
                      " &server_path.\clip.txt",'"');
          put script;
          put 'Do Until Success = True';
          put 'Success = objShell.AppActivate("Notepad")';
          put 'Wscript.Sleep 1000';
          put 'Loop';
          put %str('objShell.SendKeys "%E"');
          put 'Do Until Success = True';
          put 'Success = objShell.AppActivate("Notepad")';
          put 'Wscript.Sleep 1000';
          put 'Loop';
          put 'objShell.SendKeys "A"';
          put 'Do Until Success = True';
          put 'Success = objShell.AppActivate("Notepad")';
          put 'Wscript.Sleep 1000';
          put 'Loop';
          put %str('objShell.SendKeys "%E"');
          put 'Do Until Success = True';
          put 'Success = objShell.AppActivate("Notepad")';
          put 'Wscript.Sleep 1000';
          put 'Loop';
          put 'objShell.SendKeys "C"';
          put 'Do Until Success = True';
          put 'Success = objShell.AppActivate("Notepad")';
          put 'Wscript.Sleep 1000';
          put 'Loop';
          put %str('objShell.SendKeys "%F"');
          put 'Do Until Success = True';
          put 'Success = objShell.AppActivate("Notepad")';
          put 'Wscript.Sleep 1000';
          put 'Loop';
          put 'objShell.SendKeys "X"';
          put 'Do Until Success = True';
          put 'Success = objShell.AppActivate("Notepad")';
          put 'Wscript.Sleep 1000';
          put 'Loop';
          put 'objShell.SendKeys "{TAB}"';
          put 'WScript.Sleep 500';
          put 'objShell.SendKeys "{ENTER}"';
          put 'Wscript.Sleep 1000';
          %goto &Return_to.;
          
        %lastline:
          %if %upcase(&usenotepad) eq Y %then put 'WScript.Quit';;
      run;

      data _null_;
        call system(&script.);
      run;
    %end;
  %end;

  /*Delete all temporary files*/
  proc delete data=work.t_e_m_p;
  run;
%mend exportxl;

/*Useage Examples. The following examples assume that you have
  write access to a directory named: c:\temp. Having that specific
  directory isn't a requirement for the macro, but you do need to have
  write access to the file that you specify in the outfile parameter

  * Example 1: Create a new workbook (c:\temp\class.xlsx), copying all
    records from sashelp.class, letting the macro automatically name the
    worksheet (i.e., use the data parameter's filename: class), with the
    worksheet's first row containing the dataset's variable names:
               
    %exportxl(data=sashelp.class, outfile=c:\temp\class.xlsx)

  * Example 2: Create the same workbook as in Example 1, but name the
    worksheet 'Students', and don't include a variable name header record:

      %exportxl(data=sashelp.class, outfile=c:\temp\class.xlsx,usenames=N,
        sheet=Students)

  * Example 3: Same as Example 2, but running on a system that doesn't
    provide direct access to your computer's clipboard (e.g., a server),
    or have an Excel configuration that clears the clipboard upon opening:

      %exportxl(data=sashelp.class, outfile=c:\temp\class.xlsx,usenames=N,
        sheet=Students, usenotepad=Y)

  * Example 4: Create a new workbook from sashelp.cars, name the worksheet
    'cars', and have the worksheet's first row contain the dataset's
    variable labels:
               
      %exportxl( data=sashelp.cars, outfile=c:\temp\cars.xlsx,usenames=L)

  * Example 5: Create a new workbook (c:\temp\class.xlsx), copying all
    records for males from sashelp.class, name the worksheet 'Males', and
    have the worksheet's first row contain the dataset's variable names:
               
      %exportxl( data=sashelp.class(where=(sex eq 'M')),sheet=Males,
        outfile=c:\temp\class.xlsx)


  * Example 6: Modify the workbook created in Example 5, adding a new
    worksheet named 'Females', copying all records for females from
    sashelp.class, and have the worksheet's first row contain the
    dataset's variable names:

      %exportxl( data=sashelp.class(where=(sex eq 'F')),sheet=Females,
        outfile=c:\temp\class.xlsx,type=A)

  * Example 7: Create a workbook using an Excel template
  
      %exportxl( data=sashelp.class (keep=name sex age height),
        template=c:\temp\template.xltx, templatesheet=template,
        outfile=c:\temp\class_stats.xlsx, usenames=N,
        range=A2, sheet=Jan_2018)

  * Example 8: Modify workbook created by running Example 7, adding
    the weight variable to column E
    
      %exportxl( data=sashelp.class (keep=weight), type=M, range=E2,
        outfile=c:\temp\class_stats.xlsx, usenames=N, sheet=Jan_2018)

  * Example 9: Create a new workbook including a Pivot Table

      %exportxl( data=sashelp.cars, outfile=c:\temp\cars.xlsx,
        pivot=Origin Type Make MSRP)

*/
