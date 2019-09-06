# SWI-Prolog port

This  directory  contains  the  SWI-Prolog    port.  Testing  Pharos  on
SWI-Prolog has been made possible by Theresa Swift and Edward Schartz.

## Port work

  - Renamed all .pl to .P to exploit SWI-Prolog's XSB compatibility mode
  - Replaced GPP based include by ISO Prolog :- include
  - Replaced soft-cut emulation by the real thing
  - Fixed several singletons
  - Use macro emulation for iso_dif/2 (see demo.P)
  - Use macro binding for not/1 to avoid meta-calling (see demo.P)
  - Added demo.P to run the basic example

I think the ported code  should  still   work  on  XSB,  but it doesn't.
Solve/1 is undefined. Does the file name matter for XSB as well?

## Running:

  - Get latest GIT version of SWI-Prolog from
    https://github.com/SWI-Prolog/swipl-devel

  - Add to your `~/.swiplrc` the following line to load .P files in
    XSB compatibility mode.

	:- use_module(library(dialect/xsb/source)).

  - Run

        swipl demo.P
	?- time(run).

## Inspecting tables

  - Install my utilities from https://github.com/JanWielemaker/my-prolog-lib
    according to the README.md
  - Find useful stuff in library(tstat) and library(tdump).

## Profiling

  - Use

	?- profile(run).
