# An Easier and Faster Way to Untranspose a Wide File

## Abstract
Although the TRANSPOSE procedure is an extremely powerful tool for making long
files wide and wide files less wide or long, getting it to do what you need
often involves a lot of time, effort, and a substantial knowledge of SAS®
functions and DATA step processing. This is especially true when you have to
untranspose a wide file that contains both character and numeric variables. And,
while the procedure usually seamlessly handles variable types, lengths, and
formats, it doesn’t always do that and just creates a system variable (that is,
\_label\_) to capture variable labels. This paper introduces a macro that
simplifies the process, significantly reduces the amount of coding and
programming skills needed (thus reducing the likelihood of producing the wrong
result), runs up to 50 or more times faster than the multiple PROC TRANSPOSE and
DATA steps that would otherwise be needed, and creates untransposed variables
that inherit all of the original variables’ characteristics.

## Presentations
```
Toronto Area SAS Society
Friday, September 14, 2018 10:50am-11:20am
Classic TASS Agenda
```

```
SAS Global Forum
Monday, April 10, 2018 10:00am-10:30am
2419
Breakout20Sess
Colorado Convention Center
Room: Meeting Room 502
```

## Topics
* Programming: Applications Development

## Primary Products
* SAS base

## Industry
* Cross-Industry

## Job Role
* Analyst

## Skill Level
* Appropriate for all levels
