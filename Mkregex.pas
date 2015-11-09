//CE_Desc_Begin(mkregex.pas)
{
This unit contains the TmkreExpr component for Regular expressions.

Author: M.C. van der Kooij (MLWKooij@hetnet.nl)
Translated to Delphi in may 1998

Last modification: 15 - june - 1998

Original regexpr.c

Author: Tatu Ylonen <ylo@ngs.fi>

Copyright (c) 1991 Tatu Ylonen, Espoo, Finland

Permission to use, copy, modify, distribute, and sell this software \
and its documentation for any purpose is hereby granted without \
fee, provided that the above copyright notice appear in all copies. \
This software is provided "as is" without express or implied \
warranty.

Created: Thu Sep 26 17:14:05 1991 ylo
Last modified: Mon Nov  4 17:06:48 1991 ylo
Ported to Think C: 19 Jan 1992 guido@cwi.nl

This code draws many ideas from the regular expression packages by \
Henry Spencer of the University of Toronto and Richard Stallman of \
the Free Software Foundation.

Emacs-specific code and syntax table code is almost directly borrowed \
from GNU regexp.

Bugs fixed and lots of reorganization by Jeffrey C. Ollie, April \
1997 Thanks for bug reports and ideas from Andrew Kuchling, Tim \
Peters, Guido van Rossum, Ka-Ping Yee, Sjoerd Mullender, and \
probably one or two others that I'm forgetting.

$Id: regexpr.c,v 1.28 1998/04/10 22:27:39 guido Exp $ }
//CE_Desc_End
unit mkregex;

interface

uses Windows, Classes, SysUtils;

// MK:
// Assertions are not translated here, they should never be shown to users, and
// they only occurs when the program is corrupted / buggie

{$ifdef ver90}
const
{$else}
resourcestring
{$endif}
  SreAbnormal  = 'Abnormal error, contact author!!';
  SreAssertion = 'Assertion: ';
  SreBadMregN  = 'Bad match register number.';
  SreBadlyPPar = 'Badly placed parenthesis.';
  SreBadlyPSpe = 'Badly placed special character.';
  SreEndPrem   = 'Regular expression ends prematurel!';
  SreSyntax    = 'Regular expression syntax error.';
  SreToComplex = 'Regular expression too complex.';
  SreOptimize  = 'Optimization error.';
  SreUnknowRE  = 'Unknown regex opcode: memory corrupted?';


const
  RE_NREGS = 100;

  //* bit definitions for syntax */
  RE_NO_BK_PARENS      =   1;    //* no quoting for parentheses */
  RE_NO_BK_VBAR        =   2;    //* no quoting for vertical bar */
  RE_BK_PLUS_QM        =   4;    //* quoting needed for + and ? */
  RE_TIGHT_VBAR        =   8;    //* | binds tighter than ^ and $ */
  RE_NEWLINE_OR        =  16;    //* treat newline (in expression) as or */
  RE_CONTEXT_INDEP_OPS =  32;    //* ^$?*+ are special in all contexts */
  RE_ANSI_HEX          =  64;    //* ansi sequences (\n etc) and \xhh */
  RE_NO_GNU_EXTENSIONS = 128;    //* no gnu extensions */

  //* definitions for some common regexp styles */
  RE_SYNTAX_AWK   = (RE_NO_BK_PARENS or RE_NO_BK_VBAR or RE_CONTEXT_INDEP_OPS);
  RE_SYNTAX_EGREP = (RE_SYNTAX_AWK or RE_NEWLINE_OR);
  RE_SYNTAX_GREP  = (RE_BK_PLUS_QM or RE_NEWLINE_OR);
  RE_SYNTAX_EMACS = 0;

  Sword       = 1;
  Swhitespace = 2;
  Sdigit      = 4;
  Soctaldigit = 8;
  Shexdigit   = 16;

type

  Tmkre_registers = record
    _start: array [0..RE_NREGS - 1] of integer;
    _end: array [0..RE_NREGS - 1] of integer;
  end;
  TOnMatchEvent    = procedure (Sender: TObject; str: string; pos, ret: integer; re_registers: Tmkre_registers) of Object;
  TOnSearchEvent   = procedure (Sender: TObject; str: string; pos: integer; re_registers: Tmkre_registers) of Object;
  TmkreSyntaxStyle = (mkre_No_Bk_Parens, mkre_No_Bk_Vbar, mkre_Bk_Plus_Qm,
                      mkre_Tight_Vbar, mkre_Newline_Or, mkre_Context_Indep_Ops,
                      mkre_Ansi_Hex, mkre_No_Gnu_Extensions);
  TmkreSyntaxStyles = set of TmkreSyntaxStyle;

  regexp_syntax_op = { syntax codes for plain and quoted characters }
  (
    Rend,          // special code for end of regexp */
    Rnormal,       // normal character */
    Ranychar,      //* any character except newline */
    Rquote,        //* the quote character */
    Rbol,          //* match beginning of line */
    Reol,          //* match end of line */
    Roptional,     //* match preceding expression optionally */
    Rstar,         //* match preceding expr zero or more times */
    Rplus,         //* match preceding expr one or more times */
    Ror,           //* match either of alternatives */
    Ropenpar,      //* opening parenthesis */
    Rclosepar,     //* closing parenthesis */
    Rmemory,       //* match memory register */
    Rextended_memory, //* \vnn to match registers 10-99 */
    Ropenset,      //* open set.  Internal syntax hard-coded below. */
                   //* the following are gnu extensions to "normal" regexp syntax */
    Rbegbuf,       //* beginning of buffer */
    Rendbuf,       //* end of buffer */
    Rwordchar,     //* word character */
    Rnotwordchar,  //* not word character */
    Rwordbeg,      //* beginning of word */
    Rwordend,      //* end of word */
    Rwordbound,    //* word bound */
    Rnotwordbound, //* not word bound */
    Rnum_ops
  );

  regexp_compiled_ops = //* opcodes for compiled regexp */
  (
    Cend,                  //* end of pattern reached */
    Cbol,                  //* beginning of line */
    Ceol,                  //* end of line */
    Cset,                  //* character set.  Followed by 32 bytes of set. */
    Cexact,                //* followed by a byte to match */
    Canychar,              //* matches any character except newline */
    Cstart_memory,         //* set register start addr (followed by reg number) */
    Cend_memory,           //* set register end addr (followed by reg number) */
    Cmatch_memory,         //* match a duplicate of reg contents (regnum follows)*/
    Cjump,                 //* followed by two bytes (lsb,msb) of displacement. */
    Cstar_jump,            //* will change to jump/update_failure_jump at runtime */
    Cfailure_jump,         //* jump to addr on failure */
    Cupdate_failure_jump,  //* update topmost failure point and jump */
    Cdummy_failure_jump,   //* push a dummy failure point and jump */
    Cbegbuf,               //* match at beginning of buffer */
    Cendbuf,               //* match at end of buffer */
    Cwordbeg,              //* match at beginning of word */
    Cwordend,              //* match at end of word */
    Cwordbound,            //* match if at word boundary */
    Cnotwordbound,         //* match if not at word boundary */
    Csyntaxspec,           //* matches syntax code (1 byte follows) */
    Cnotsyntaxspec,        //* matches if syntax code does not match (1 byte follows) */
    Crepeat1
  );

type
//CE_Desc_Begin(ERegularExpression)
{
This Exception is used in <%LINK TmkreExpr%>}
//CE_Desc_End
  ERegularExpression = class(Exception);

  Pregexp_t = ^Tregexp_t;
  Tregexp_t = record
    buffer:           string;  {compiled pattern}
    fastmap:          string;  {fastmap[ch] is true if ch can start pattern}
    translate:        string;  {translation to apply during compilation/matching}
    fastmap_accurate: boolean; {true if fastmap is valid}
    can_be_null:      char;    {true if can match empty string}
    uses_registers:   boolean; {registers are used and need to be initialized}
    num_registers:    integer; {number of registers used}
    anchor:           byte;    {anchor: 0=none 1=begline 2=begbuf}
  end;

  Pre_registers = ^Tre_registers;
  Tre_registers = record
    _start: array [0..RE_NREGS - 1] of integer;
    _end: array [0..RE_NREGS - 1] of integer;
  end;

  TThreadedSearch = class;
  TThreadedMatch = class;
//CE_Desc_Begin(TmkreExpr)
{
This component can search in string for Regular expressions.

Set <%LINK TmkreExpr.Str%> with the string and <%LINK TmkreExpr.Pattern%> \
with the Regular Expression.

See <%LINK TmkreExpr.Pattern%> for an description of possible Expressions.}
//CE_Desc_End
  TmkreExpr = class(Tcomponent)
  private
    FStyle: integer;
    FActive,
    FUseFastmap,
    FCanBeEmpty: boolean;
    Fstr: string;
    FNoChange,
    FStyleChange: boolean;
    FSyntaxStyles: TmkreSyntaxStyles;
    FThreadedSearch: TThreadedSearch;
    FThreadedMatch: TThreadedMatch;
    Fpattern: string;                            // uncompiled pattern
    regexp_t: Tregexp_t;
    FMatches: TStringList;
    FOnMatch: TOnMatchEvent;
    FOnStartMatch: TNotifyEvent;
    FOnEndMatch: TNotifyEvent;
    FOnSearch: TOnSearchEvent;
    FOnStartSearch: TNotifyEvent;
    FOnEndSearch: TNotifyEvent;
    re_syntax_table: array[0 .. 255] of char;
    re_compile_initialized: boolean;
    regexp_plain_ops,
    regexp_quoted_ops: array[0 .. 255] of regexp_syntax_op;
    regexp_precedences: array[0 .. ord(Rnum_ops)] of char;
    regexp_context_indep_ops: boolean;
    regexp_ansi_sequences: boolean;
    FCallProcessMessages: Boolean;
    procedure CheckRegExp;
    procedure SetUseFastmap(fstm: boolean);
    procedure SetCanBeEmpty(BeEm: boolean);
    procedure SetStr(str: string);
    procedure SetSyntaxStyles(NewStyles: TmkreSyntaxStyles);
    function GetMatches: TStringList;
    procedure Setpattern(pat: string);

    procedure Inser_Jump(pos: integer; opcode_type: regexp_compiled_ops;
                     addr: integer; var pattern_offset: integer; var pattern: string);
    function Ansi_Translate(ch: char; size: integer; var pos: integer;
                         regex, translate: string): char;
    function hex_char_to_decimal(ch: char): char;
    function re_optimize: boolean;
    function re_optimize_star_jump(var code: PChar): boolean;
    function re_do_compile_fastmap(bufferstr: string; pos: integer;
                               var can_be_null: char;
                               fastmap: PChar): boolean;
    procedure re_compile_fastmap_aux(var code: PChar; pos: integer;
                                visited: PChar;var can_be_null: char;
                                fastmap: PChar);
    procedure re_compile_fastmap;
    procedure re_compile_initialize;
    function re_compile_pattern: string;
    function re_match({str: string; }pos: integer;
                      old_regs: Pre_registers): integer;
    function re_search({str: string; }pos, range: integer;
                       regs: Pre_registers): integer;

    procedure OnMatchTerminate(Sender: TObject);
    procedure OnSearchTerminate(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
{    procedure Match;
    function Search(pos: integer): integer;
    function SearchWithRange(pos, range: integer): integer;     }
    procedure DoMatch;
    function DoSearch(pos: integer): integer;
    function DoSearchWithRange(pos, range: integer): integer;
    procedure DoThreadedSearchWithRange(pos, range: integer);
    procedure Stop;
    procedure Execute;
    property Translate: string read regexp_t.Translate write regexp_t.Translate;
    property Matches: TStringList read GetMatches;
    property RegExp: Tregexp_t read regexp_t write regexp_t; // we can copy this thing
  published
    property Active: boolean read FActive write FActive;
    property UseFastmap: boolean read FUseFastmap write SetUseFastmap;
    property CanBeEmpty: boolean read FCanBeEmpty write SetCanBeEmpty;
    property Pattern: string read FPattern write Setpattern;
    property SyntaxStyles: TmkreSyntaxStyles read FSyntaxStyles write SetSyntaxStyles;
    property Str: string read FStr write SetStr;
    property OnMatch: TOnMatchEvent read FOnMatch write FOnMatch;
    property OnStartMatch: TNotifyEvent read FOnStartMatch write FOnStartMatch;
    property OnEndMatch: TNotifyEvent read FOnEndMatch write FOnEndMatch;
    property OnSearch: TOnSearchEvent read FOnSearch write FOnSearch;
    property OnStartSearch: TNotifyEvent read FOnStartSearch write FOnStartSearch;
    property OnEndSearch: TNotifyEvent read FOnEndSearch write FOnEndSearch;
    property CallProcessMessages: Boolean read FCallProcessMessages write
        FCallProcessMessages;
  end;

  TThreadedSearch = class(TThread)
  private
    Result, pos, range: integer;
    re_registers: Tre_registers;
    FmkreExpr: TmkreExpr;
    procedure DoOnSearchEvent;
  public
    constructor Create(mkreExpr: TmkreExpr);
    procedure Execute; override;
  end;

  TThreadedMatch = class(TThread)
  private
    FmkreExpr: TmkreExpr;
    sFound: string;
    pos: integer;
    re_registers: Tre_registers;
    procedure DoOnMatchEvent;
  public
    constructor Create(mkreExpr: TmkreExpr);
    procedure Execute; override;
  end;


procedure Register;

implementation

uses Forms;

procedure Register;
begin
  RegisterComponents('MK',[TmkreExpr]);
end;

const
  STACK_PAGE_SIZE = 256;
  NUM_REGISTERS   = 256;
  NUM_LEVELS      = 5;
  MAX_NESTING     = 100;

{  The stack implementation is taken from an idea by Andrew Kuchling.
 * It's a doubly linked list of arrays. The advantages of this over a
 * simple linked list are that the number of mallocs required are
 * reduced. It also makes it possible to statically allocate enough
 * space so that small patterns don't ever need to call malloc.
 *
 * The advantages over a single array is that is periodically
 * realloced when more space is needed is that we avoid ever copying
 * the stack. }

{  item_t is the basic stack element.  Defined as a union of
 * structures so that both registers, failure points, and counters can
 * be pushed/popped from the stack.  There's nothing built into the
 * item to keep track of whether a certain stack item is a register, a
 * failure point, or a counter. }

type
  {$IFDEF VER180}
  NativeInt = Integer;
  {$ENDIF}

  Pitem_t = ^Titem_t;
  Titem_t = record
    reg_num: integer;
    reg_level: integer;
    reg_start: PChar;
    reg_end: PChar;
    fail_count: integer;
    fail_level: integer;
    fail_phantom: integer;
    fail_code: PChar;
    fail_text: PChar;

   //MK: union causes error
{  case integer of
    0: (reg_num: integer;
        reg_level: integer;
        reg_start: PChar;
        reg_end: PChar);
    1: (fail_count: integer;
        fail_level: integer;
        fail_phantom: integer;
        fail_code: PChar;
        fail_text: PChar); }
  end;

{ A 'page' of stack items.}
  Pitem_page_t = ^Titem_page_t;
  Titem_page_t = record
    items: array [0 .. NUM_REGISTERS] of Titem_t;
    prev: Pitem_page_t;
    next: Pitem_page_t;
  end;

{ Structure to encapsulate the stack.}
  Tstack = record
    index: integer;
    current: Pitem_page_t;  // Pointer to the current page.
    first: Titem_page_t;    // First page is statically allocated.
  end;

  Tmatch_state = record
{   The number of registers that have been pushed onto the stack
    since the last failure point. }
    count: integer;

{   The number of failure points on the stack.}
    level: integer;

{   The number of failure points on the stack.}
    point: integer;

{   Storage for the registers.  Each register consists of two
    pointers to characters.  So register N is represented as
    start[N] and end[N].  The pointers must be converted to
    offsets from the beginning of the string before returning the
    registers to the calling program. }

    _start: array[0..NUM_REGISTERS] of Pchar;
    _end: array[0..NUM_REGISTERS] of Pchar;

{   Keeps track of whether a register has changed recently.}
    changed: array[0..NUM_REGISTERS] of integer;

{   index into the curent page.  If index == 0 and you need
    to pop an item, move to the previous page and set index
    = STACK_PAGE_SIZE - 1.  Otherwise decrement index to
    push a page. If index == STACK_PAGE_SIZE and you need
    to push a page move to the next page and set index =
    0. If there is no new next page, allocate a new page
    and link it in. Otherwise, increment index to push a
    page.}
    stack: Tstack;
  end;

constructor TmkreExpr.Create(AOwner: TComponent);
begin
  inherited Create(Aowner);
  FMatches := TStringList.Create;
  SetSyntaxStyles([mkre_No_Bk_Parens, mkre_No_Bk_Vbar, mkre_Context_Indep_Ops,
                   mkre_Newline_Or]);
  SetLength(regexp_t.fastmap, 256);
  regexp_t.translate := '';
  regexp_t.fastmap_accurate := False;
  regexp_t.can_be_null := #0;
  regexp_t.uses_registers := True;
  regexp_t.anchor := 0;
  FUseFastmap := True;
  FActive     := False;
  FNoChange   := False;
  FStyleChange := True;
end;

destructor TmkreExpr.Destroy;
begin
  FMatches.Free;
  if Assigned(FThreadedMatch) then FThreadedMatch.Terminate;
  if Assigned(FThreadedSearch) then FThreadedSearch.Terminate;
  inherited;
end;

procedure TmkreExpr.CheckRegExp;
begin
  if regexp_t.buffer = '' then
    raise Exception.Create('No compiled pattern available.');
  if regexp_t.Translate <> '' then
    if Length(regexp_t.Translate) <> 256 then
      raise Exception.Create('Translate table length error.');
  if regexp_t.fastmap <> '' then
    if Length(regexp_t.fastmap) <> 256 then
      raise Exception.Create('Fastmap table length error.');
end;

//CE_Desc_Begin(TmkreExpr.DoMatch)
{
Start matching in a separate thread, while matching, the application will continue working.

Like the search methods, the <%LINK TmkreExpr.OnMatch%> event is called when an match is found.
Use <%LINK TmkreExpr.Stop%> to stop matching.
}
//CE_Desc_End
procedure TmkreExpr.DoMatch;
begin
  while Assigned(FThreadedMatch) do
    if CallProcessMessages
      then Application.ProcessMessages
      else Sleep (0);
  if Assigned(FOnStartMatch)
    then FOnStartMatch(Self);
  FThreadedMatch := TThreadedMatch.Create(Self);
  FThreadedMatch.OnTerminate := OnMatchTerminate;
  {$IFDEF VER180}
  FThreadedMatch.Resume;
  {$ELSE}
  FThreadedMatch.Start;
  {$ENDIF}
end;

//CE_Desc_Begin(TmkreExpr.DoThreadedSearchWithRange)
{
Start searching in a separate thread, while searching, the application will continue working.

Like SearchWithRange, the <%LINK TmkreExpr.OnSearch%> event is called when an match is found.
Use <%LINK TmkreExpr.Stop%> to stop searching.}
//CE_Desc_End
procedure TmkreExpr.DoThreadedSearchWithRange(pos, range: integer);
begin
  while Assigned(FThreadedSearch) do
    if CallProcessMessages
      then Application.ProcessMessages
      else Sleep (0);
  if Assigned(FOnStartSearch) then FOnStartSearch(Self);
  FThreadedSearch := TThreadedSearch.Create(Self);
  FThreadedSearch.OnTerminate := OnSearchTerminate;
  {$IFDEF VER180}
  FThreadedSearch.Resume;
  {$ELSE}
  FThreadedSearch.Start;
  {$ENDIF}
end;

//CE_Desc_Begin(TmkreExpr.DoSearch)
{
Search for <%LINK TmkreExpr.pattern%> in <%LINK TmkreExpr.Str%>.
When a match is found the event <%LINK TmkreExpr.OnSearch%> is triggered.
<%ARGBEGIN%><%ARG pos,integer,Search from here%>
<%SEEALSO TmkreExpr.OnStartSearch, TmkreExpr.OnEndSearch%>}
//CE_Desc_End
function TmkreExpr.DoSearch(pos: integer): integer;
begin
  Result := DoSearchWithRange(pos, Length(FStr) - pos - 1);
end;

//CE_Desc_Begin(TmkreExpr.DoSearchWithRange)
{
Search for <%LINK TmkreExpr.pattern%> in <%LINK TmkreExpr.Str%>.
When a match is found the event <%LINK TmkreExpr.OnSearch%> is triggered.
<%ARGBEGIN%><%ARG pos,integer,Search from here%>
<%ARG range,integer,To here\,when negative the search is backwards%>
<%SEEALSO TmkreExpr.OnStartSearch, TmkreExpr.OnEndSearch%>}
//CE_Desc_End
function TmkreExpr.DoSearchWithRange(pos, range: integer): integer;
var
  re_registers: Tre_registers;
begin
  CheckRegExp;
  Result := re_search(pos, range, @re_registers);
  if Assigned(FOnSearch) and (Result > 0) then FOnSearch(Self, copy(Fstr, re_registers._start[0], re_registers._end[0] - re_registers._start[0] + 1), Result, Tmkre_registers(re_registers));
end;

function TmkreExpr.GetMatches: TStringList;
begin
  Result := nil;
  if csDesigning in ComponentState
    then Exit;
  {if not FNoChange then
  begin
    DoMatch;
    while Assigned(FThreadedSearch) do
      if CallProcessMessages
        then Application.ProcessMessages
        else Sleep (0);
    FNoChange := True;
  end;}
  Result := FMatches;
end;

procedure TmkreExpr.SetUseFastmap(fstm: boolean);
begin
  if fstm <> FUseFastmap then
  begin
    if fstm then
      SetLength(regexp_t.fastmap, 256)
    else
      SetLength(regexp_t.fastmap, 0);
    FStyleChange := True;
    FUseFastmap := fstm;
  end;
end;

procedure TmkreExpr.SetCanBeEmpty(BeEm: boolean);
begin
  if BeEm <> FCanBeEmpty then
  begin
    FStyleChange := True;
    FCanBeEmpty := BeEm;
  end;
end;

procedure TmkreExpr.SetStr(str: string);
begin
  FNoChange := False;
  FStr := str;
  if FActive then DoMatch;
end;

procedure TmkreExpr.Setpattern(pat: string);
begin
  if (pat <> FPattern) or FStyleChange then
  begin
    FNoChange := False;
    if FStyleChange then
      re_compile_initialize;
    FPattern := pat;
    re_compile_pattern;
    FStyleChange := False;
  end;
end;

procedure TmkreExpr.SetSyntaxStyles(NewStyles: TmkreSyntaxStyles);
const
  Syntax: array[low(TmkreSyntaxStyle) .. high(TmkreSyntaxStyle)] of integer =(
    RE_NO_BK_PARENS     ,    //* no quoting for parentheses */
    RE_NO_BK_VBAR       ,    //* no quoting for vertical bar */
    RE_BK_PLUS_QM       ,    //* quoting needed for + and ? */
    RE_TIGHT_VBAR       ,    //* | binds tighter than ^ and $ */
    RE_NEWLINE_OR       ,    //* treat newline as or */
    RE_CONTEXT_INDEP_OPS,    //* ^$?*+ are special in all contexts */
    RE_ANSI_HEX         ,    //* ansi sequences (\n etc) and \xhh */
    RE_NO_GNU_EXTENSIONS);   //* no gnu extensions */
var
  i: TmkreSyntaxStyle;
begin
  if NewStyles <> FSyntaxStyles then
  begin
    FStyle := 0;
    for i := low(TmkreSyntaxStyle) to high(TmkreSyntaxStyle) do
      if i in NewStyles then FStyle := FStyle + Syntax[i];
    FSyntaxStyles := NewStyles;
    FStyleChange := True;
    FNoChange := False;
  end;
end;

// Original code starts here

{$ifdef ver90}
procedure Assert(blnAssertion: boolean; strOnError: string);
begin
  if not blnAssertion then
    raise Exception.Create(SreAssertion + strOnError);
end;
{$endif}

procedure New_state(var state: Tmatch_state; nregs: integer);
var
  i: integer;
begin
  for i := 0 to nregs - 1 do
  begin
    state._start[i] := nil;
    state._end[i] := nil;
    state.changed[i] := 0;
  end;
  state.stack.current := @state.stack.first;
  state.stack.first.prev := nil;
  state.stack.first.next := nil;
  state.stack.index := 0;
  state.level := 0;
  state.count := 0;
  state.point := 0;
end;

// Free any memory that might have been malloc'd
procedure Free_state(var state: Tmatch_state);
begin
  while (state.stack.first.next <> nil) do
  begin
    state.stack.current := state.stack.first.next;
    state.stack.first.next := state.stack.current.next;
    dispose(state.stack.current);
    state.stack.current := nil;
  end;
end;

function short(a: word): integer;
begin
  if (a > $7fff) then Result := a - $10000
                 else Result := a;
end;

{$HINTS OFF}
procedure TmkreExpr.re_compile_fastmap_aux(var code: PChar; pos: integer;
                                visited: PChar;var can_be_null: char;
                                fastmap: PChar);
var
  a,b: integer;
  syntaxcode: char;
begin
  if visited[pos] <> #0 then exit;
  visited[pos] := #1;
  while True do
  begin
    case regexp_compiled_ops(code[pos]) of
      Cend: begin
              inc(pos);
              can_be_null := #1;
              Exit;
            end;
      Cbol,
      Cbegbuf,
      Cendbuf,
      Cwordbeg,
      Cwordend,
      Cwordbound,
      Cnotwordbound:
          begin
            inc(pos);
            for a := 0 to 255 do
              fastmap[a] := #1;
          end;
      Csyntaxspec:
          begin
            inc(pos);
            syntaxcode := code[pos];
            inc(pos);
            for a := 0 to 255 do
              if (integer(re_syntax_table[a]) and integer(syntaxcode)) > 0 then
                fastmap[a] := #1;
            Exit;
          end;
      Cnotsyntaxspec:
          begin
            inc(pos);
            syntaxcode := code[pos];
            inc(pos);
            for a := 0 to 255 do
              if not ((integer(re_syntax_table[a]) and integer(syntaxcode)) > 0) then
                fastmap[a] := #1;
            Exit;
          end;
      Ceol:
          begin
            inc(pos);
            fastmap[10] := #1;                                              // was 13
            //can match null, but only at end of buffer
            if can_be_null = #0 then can_be_null := #2;
            Exit;
          end;
      Cset:
          begin
            inc(pos);
            for a := 0 to 31 do
              if code[pos + a] <> #0 then
                for b := 0 to 7 do
                 if (integer(code[pos + a]) and ( 1 shl b)) > 0 then
                   fastmap[(a shl 3) + b] := #1;
            inc(pos, 32);
            Exit;
          end;
      Cexact:
          begin
            inc(pos);
            fastmap[integer(code[pos])] := #1;
            Exit;
          end;
      Canychar:
          begin
            inc(pos);
            for a := 0 to 255 do
              if a <> 10 then                                   // was 13
                fastmap[a] := #1;
            exit;
          end;
      Cstart_memory,
      Cend_memory:         inc(pos, 2);
      Cmatch_memory:
          begin
            inc(pos);
            for a := 0 to 255 do
              fastmap[a] := #1;
            can_be_null := #1;
            Exit;
          end;
      Cjump,
      Cdummy_failure_jump,
      Cupdate_failure_jump,
      Cstar_jump:
          begin
            inc(pos);
            a := integer(code[pos]) + integer(code[pos + 1]) shl 8;
            inc(pos, 2);         // check a for sign!
            pos := pos + short(a);
            if visited[pos] <> #0 then
            {/* argh... the regexp contains empty loops.  This is not
                good, as this may cause a failure stack overflow when
                matching.  Oh well. */
             /* this path leads nowhere; pursue other paths. */}
              Exit;
            visited[pos] := #1;
          end;
      Cfailure_jump:
          begin
            inc(pos);
            a := integer(code[pos]) + integer(code[pos + 1]) shl 8;
            inc(pos, 2);         // check a for sign!
            a := pos + short(a);
            re_compile_fastmap_aux(code, a, visited, can_be_null, fastmap);
          end;
      Crepeat1: inc(pos, 3);
    else
      begin
        Raise ERegularExpression.Create(SreUnknowRE);
      end;
    end;
  end;
end;
{$HINTS ON}

function TmkreExpr.re_do_compile_fastmap(bufferstr: string; pos: integer;
                               var can_be_null: char;
                               fastmap: PChar): boolean;
var
  small_visited: array [0 .. 511] of char;
  Ext_visited: string;
  visited, buffer: PChar;
begin
  if Length(bufferstr) <= SizeOf(small_visited) then
    visited := small_visited
  else
  begin
    SetLength(Ext_visited, Length(bufferstr));
    visited := @Ext_visited[1];
  end;
  can_be_null := #0;
  FillChar(fastmap^, 256, 0);
  FillChar(visited^, Length(bufferstr), 0);
  buffer := @bufferstr[1];
  re_compile_fastmap_aux(buffer, pos, visited, can_be_null, fastmap);
  Result := true;
end;

//CE_Desc_Begin(TmkreExpr.re_compile_fastmap)
{This computes the fastmap for the regexp.  For this to have any effect, \
the calling program must have initialized the fastmap field to point \
to an array of 256 characters.}
//CE_Desc_End
procedure TmkreExpr.re_compile_fastmap;
begin
  if (regexp_t.fastmap = '') or (regexp_t.fastmap_accurate) then Exit;
  if not (re_do_compile_fastmap(regexp_t.buffer, 0, regexp_t.can_be_null, PChar(regexp_t.fastmap))) then
    Exit;
  if regexp_t.buffer[1] = Char(Cbol) then regexp_t.anchor := 1       //begline
  else
    if regexp_t.buffer[1] = Char(Cbegbuf) then regexp_t.anchor := 2  //begbuf
                                      else regexp_t.anchor := 0; //none
  regexp_t.fastmap_accurate := True;
end;


//CE_Desc_Begin(TmkreExpr.re_optimize_star_jump)
{star is coded as:
1: failure_jump 2
   ... code for operand of star
   star_jump 1
2: ... code after star

We change the star_jump to update_failure_jump if we can determine \
that it is safe to do so; otherwise we change it to an ordinary \
jump.

plus is coded as

    jump 2
1: failure_jump 3
2: ... code for operand of plus
   star_jump 1
3: ... code after plus

For star_jump considerations this is processed identically to star.
*
}
//CE_Desc_End
function TmkreExpr.re_optimize_star_jump(var code: PChar): boolean;
label
  make_normal_jump, loop_p1;
var
  map: array[0 .. 255] of char;
  can_be_null: char;
  p1, p2: PChar;
  ch: char;
  a,b: integer;
  num_instructions: integer;
begin
  Result := False;
  num_instructions := 0;

  a := short(byte(code[0]) + byte(code[1]) * 256);

  inc(code, 2);
  p1 := code + a + 3;   //skip the failure_jump
  //Check that the jump is within the pattern
  if (p1 < @regexp_t.buffer[1]) or
     ((integer(@regexp_t.buffer[1]) + length(regexp_t.buffer)) < integer(p1)) then
    Exit;
  Assert((p1[-3] = char(Cfailure_jump)), 'No Cfailure_jump');
  p2 := code;
  //p1 points inside loop, p2 points to after loop
  if not re_do_compile_fastmap(regexp_t.buffer, p2 - @regexp_t.buffer[1], can_be_null, map) then
    goto make_normal_jump;
{/* If we might introduce a new update point inside the
  * loop, we can't optimize because then update_jump would
  * update a wrong failure point.  Thus we have to be
  * quite careful here.
  */}

  //loop until we find something that consumes a character
loop_p1:
  inc(num_instructions);
  case regexp_compiled_ops(p1[0]) of
    Cbol,
    Ceol,
    Cbegbuf,
    Cendbuf,
    Cwordbeg,
    Cwordend,
    Cwordbound,
    Cnotwordbound:
        begin
          inc(p1);
          goto loop_p1;
        end;
    Cstart_memory,
    Cend_memory:
        begin
          inc(p1, 2);
          goto loop_p1;
        end;
    Cexact:
        begin
          inc(p1);
          ch := p1[0];
          inc(p1);
          if (map[ord(ch)]) <> #0 then
            goto make_normal_jump;
        end;
    Canychar:
        begin
          inc(p1);
          for b := 0 to 255 do
            if (b <> 10) and (map[b] <> #0) then        // was 13
              goto make_normal_jump;
        end;
    Cset:
        begin
          inc(p1);
          for b := 0 to 255 do
            // Check This!!!!
            if ((integer(p1[b div 8]) and (1 shl (b and 7))) <> 0) and
                (map[b] <> #0) then
              goto make_normal_jump;
          inc(p1, 32);
        end;
  else
    goto make_normal_jump;
  end;

  //now we know that we can't backtrack.
  while p1 <> (p2 - 3) do
  begin
    inc(num_instructions);
    case regexp_compiled_ops(p1[0]) of
      Cend: Exit;
      Cbol,
      Ceol,
      Canychar,
      Cbegbuf,
      Cendbuf,
      Cwordbeg,
      Cwordend,
      Cwordbound,
      Cnotwordbound: inc(p1);
      Cset: inc(p1, 33);
      Cexact,
      Cstart_memory,
      Cend_memory,
      Cmatch_memory,
      Csyntaxspec,
      Cnotsyntaxspec: inc(p1, 2);
      Cjump,
      Cstar_jump,
      Cfailure_jump,
      Cupdate_failure_jump,
      Cdummy_failure_jump: goto make_normal_jump;
    else
      Exit;
    end;
  end;
  //make_update_jump:
  dec(code, 3);
  inc(a,3);
  code[0] := char(Cupdate_failure_jump);
  code[1] := char(a and 255);
  code[2] := char(a shr 8);
  if num_instructions > 1 then
  begin
    Result := True;
    Exit;
  end;
  assert(num_instructions = 1, 'No instructions found!');
  {/* if the only instruction matches a single character, we can do
  * better */}
  p1 := code + 3 + a; //start of sole instruction
  if (p1[0] = char(Cset)) or (p1[0] = char(Cexact)) or (p1[0] = char(Canychar)) or
     (p1[0] = char(Csyntaxspec)) or (p1[0] = char(Cnotsyntaxspec)) then
    code[0] := char(Crepeat1);
  Result := True;
  Exit;

make_normal_jump:
  dec(code, 3);
  code[0] := char(Cjump);
  Result := True;
end;

function TmkreExpr.re_optimize: boolean;
var
  code: PChar;
begin
  Result := False;
  code := @regexp_t.buffer[1];
  while True do
  begin
    case regexp_compiled_ops(code[0]) of
      Cend:
          begin
            Result := True;
            Exit;
          end;
      Canychar,
      Cbol,
      Ceol,
      Cbegbuf,
      Cendbuf,
      Cwordbeg,
      Cwordend,
      Cwordbound,
      Cnotwordbound: inc(code);
      Cset: inc(code, 33);
      Cexact,
      Cstart_memory,
      Cend_memory,
      Cmatch_memory,
      Csyntaxspec,
      Cnotsyntaxspec: inc(code, 2);
      Cstar_jump: begin
                    inc(code);
                    if not re_optimize_star_jump(code) then Exit;
                  end;
      Cupdate_failure_jump,
      Cjump,
      Cdummy_failure_jump,
      Cfailure_jump,
      Crepeat1: inc(code, 3);
    else
      Exit;
    end;
  end;
end;

function TmkreExpr.hex_char_to_decimal(ch: char): char;
begin
  Result := #16; // error
  if (ch >= '0') and (ch <= '9') then
    Result := char(ord(ch) - ord('0'));
  if (ch >= 'a') and (ch <= 'f') then
    Result := char(ord(ch) - ord('a') + 10);
  if (ch >= 'A') and (ch <= 'F') then
    Result := char(ord(ch) - ord('A') + 10);
end;

function TmkreExpr.Ansi_Translate(ch: char; size: integer; var pos: integer;
                         regex, translate: string): char;
var
  gethex_ch, gethex_value: char;
begin
  Result := #0;
  case ch of
    'a', 'A': Result := #7;   // audible bell
    'b', 'B': Result := #8;   // backspace
    'f', 'F': Result := #12;  // form feed
    'n', 'N': Result := #10;  // line feed
    'r', 'R': Result := #13;  // carriage return
    't', 'T': Result := #9;   // tab
    'v', 'V': Result := #11;  // vertical tab
    'x', 'X': begin       // hex code
                if Pos > Size then
                  Raise ERegularExpression.Create('Regular expression ends prematurely');
                gethex_ch := regex[pos];
                inc(pos);
                gethex_value := hex_char_to_decimal(gethex_ch);
                if (gethex_value = #16) then
                  Raise ERegularExpression.Create('');
                if Pos > Size then
                  Raise ERegularExpression.Create('Regular expression ends prematurely');
                gethex_ch := regex[pos];
                inc(pos);
                gethex_ch := hex_char_to_decimal(gethex_ch);
                if (gethex_value = #16) then
                  Raise ERegularExpression.Create('');
                Result := char(ord(gethex_value) * 16 + ord(gethex_ch));
              end;
  else
    if translate <> '' then
      Result := translate[ord(ch)];
  end;
end;

procedure TmkreExpr.re_compile_initialize;
var
  a, i: integer;
begin
//  FillChar(bufp.re_syntax_table, 256, 0); // not nessesary
  for a := ord('a') to ord('z') do re_syntax_table[a] := char(Sword);
  for a := ord('A') to ord('Z') do re_syntax_table[a] := char(Sword);
  for a := ord('0') to ord('9') do re_syntax_table[a] := char(Sword or Sdigit or Shexdigit);
  for a := ord('0') to ord('7') do re_syntax_table[a] := char(integer(re_syntax_table[a]) + Soctaldigit);
  for a := ord('a') to ord('f') do re_syntax_table[a] := char(integer(re_syntax_table[a]) + Shexdigit);
  for a := ord('A') to ord('F') do re_syntax_table[a] := char(integer(re_syntax_table[a]) + Shexdigit);
  re_syntax_table[ord('_')] := char(Sword);
  for a := 9 to 13 do re_syntax_table[a] := char(Swhitespace);
  re_syntax_table[ord(' ')] := char(Swhitespace);

  for i := 0 to 255 do
  begin
    regexp_plain_ops[i] := Rnormal;
    regexp_quoted_ops[i] := Rnormal;
  end;
  for a := ord('0') to ord('9') do regexp_quoted_ops[a] := Rmemory;
  regexp_plain_ops[ord('\')] := Rquote;
  if (FStyle and RE_NO_BK_PARENS) = RE_NO_BK_PARENS then
  begin
    regexp_plain_ops[ord('(')] := Ropenpar;
    regexp_plain_ops[ord(')')] := Rclosepar;
  end
  else
    begin
      regexp_quoted_ops[ord('(')] := Ropenpar;
      regexp_quoted_ops[ord(')')] := Rclosepar;
    end;

  if (FStyle and RE_NO_BK_VBAR) = RE_NO_BK_VBAR then
    regexp_plain_ops[ord('|')] := Ror
  else
    regexp_quoted_ops[ord('|')] := Ror;
  regexp_plain_ops[ord('*')] := Rstar;
  if (FStyle and RE_BK_PLUS_QM) = RE_BK_PLUS_QM then
  begin
    regexp_quoted_ops[ord('+')] := Rplus;
    regexp_quoted_ops[ord('?')] := Roptional;
  end
  else
  begin
    regexp_plain_ops[ord('+')] := Rplus;
    regexp_plain_ops[ord('?')] := Roptional;
  end;

  if (FStyle and RE_NEWLINE_OR) = RE_NEWLINE_OR then
    regexp_plain_ops[10] := Ror;                               // was 13
  regexp_plain_ops[ord('[')] := Ropenset;
  regexp_plain_ops[ord('^')] := Rbol;
  regexp_plain_ops[ord('$')] := Reol;
  regexp_plain_ops[ord('.')] := Ranychar;
  if not ((FStyle and RE_NO_GNU_EXTENSIONS) = RE_NO_GNU_EXTENSIONS) then
  begin
    regexp_quoted_ops[ord('w')] := Rwordchar;
    regexp_quoted_ops[ord('W')] := Rnotwordchar;
    regexp_quoted_ops[ord('<')] := Rwordbeg;
    regexp_quoted_ops[ord('>')] := Rwordend;
    regexp_quoted_ops[ord('b')] := Rwordbound;
    regexp_quoted_ops[ord('B')] := Rnotwordbound;
    regexp_quoted_ops[ord('`')] := Rbegbuf;
    regexp_quoted_ops[44] := Rendbuf;    // '
  end;
  if (FStyle and RE_ANSI_HEX) = RE_ANSI_HEX then
    regexp_quoted_ops[ord('v')] := Rextended_memory;
  for a := 0 to ord(Rnum_ops) - 1 do
    regexp_precedences[a] := #4;
  if (FStyle and RE_TIGHT_VBAR) > 0 then
  begin
    regexp_precedences[ord(Ror)] := #3;
    regexp_precedences[ord(Rbol)] := #2;
    regexp_precedences[ord(Reol)] := #2;
  end
  else
  begin
    regexp_precedences[ord(Ror)] := #2;
    regexp_precedences[ord(Rbol)] := #3;
    regexp_precedences[ord(Reol)] := #3;
  end;
  regexp_precedences[ord(Rclosepar)] := #1;
  regexp_precedences[ord(Rend)] := #0;
  regexp_context_indep_ops := (FStyle and RE_CONTEXT_INDEP_OPS) > 0;
  regexp_ansi_sequences := (FStyle and RE_ANSI_HEX) > 0;

  re_compile_initialized := True;
end;

procedure TmkreExpr.Inser_Jump(pos: integer;opcode_type: regexp_compiled_ops;
                     addr: integer; var pattern_offset: integer; var pattern: string);
var
  a, disp: integer;
begin
  for a := pattern_offset - 1 downto pos do
    pattern[a + 3] := pattern[a];
  pattern[pos] := char(opcode_type);
  //PUT_ADDR(offset,addr)
  disp := addr - (pos + 1) - 2;
  pattern[pos + 1] := char(disp and 255);
  pattern[pos + 2] := char((disp shr 8) and 255);
  inc(pattern_offset, 3);
end;

//CE_Desc_Begin(TmkreExpr.re_compile_pattern)
{This compiles the regexp (given in regex and length in regex_size).
This empty string if the regexp compiled successfully, and an error \
message if an error was encountered.
The translate field must be set to point to a valid translation table, \
or empty if it is not used.}
//CE_Desc_End
function TmkreExpr.re_compile_pattern: string;
label
  normal_char, store_opcode_and_arg, store_opcode;
var
  i, pos, current_level, level: integer;
  op: regexp_syntax_op;
  opcode: regexp_compiled_ops;
  pattern_offset: integer;
  starts: array[0 .. NUM_LEVELS * MAX_NESTING] of integer;
  starts_base: integer;
  future_jumps: array[0 .. MAX_NESTING] of integer;
  num_jumps: integer;
  a, ch: char;
  pattern: string;
  translate: string;
  next_register: integer;
  paren_depth: integer;
  num_open_registers: integer;
  open_registers: array[0 .. RE_NREGS] of integer;
  beginning_context: boolean;

  size, disp: integer;

  complement, firstchar, range: boolean;
  prev, offset : integer;
begin
  pattern_offset := 0;
  ch := #0;
  if not re_compile_initialized then
    re_compile_initialize;
  regexp_t.fastmap_accurate := false;
  regexp_t.uses_registers := True;
  regexp_t.num_registers := 1;
  translate := regexp_t.translate;
  pattern := '';
  pattern_offset := 1;
  try
    starts_base := 0;
    num_jumps := 0;
    current_level := 0;
    Starts[starts_base + current_level] := pattern_offset; {SET_LEVEL_START}
    num_open_registers := 0;
    next_register := 1;
    paren_depth := 0;
    beginning_context := True;
    op :=Rnum_ops; // maybe wrong, just give it a try
    {we use Rend dummy to ensure that pending jumps are updated
     (due to low priority of Rend) before exiting the loop.}
    size := Length(FPattern);
    pos := 1;
    while op <> Rend do
    begin
      if pos > size then op := Rend
      else
        begin
          if pos > size then
            Raise ERegularExpression.Create(SreEndPrem);
          ch := FPattern[pos];
          inc(pos);
          if translate <> '' then ch := translate[ord(ch)];
          op := regexp_plain_ops[ord(ch)];
          if op = RQuote then
          begin
            if pos > size then
              Raise ERegularExpression.Create(SreEndPrem);
            ch := FPattern[pos];
            inc(pos);
            op := regexp_quoted_ops[ord(ch)];
            if (op = Rnormal) and regexp_ansi_sequences then
              ch := Ansi_Translate(ch, Size, pos, FPattern, translate);
          end;
        end;
      level := integer(regexp_precedences[ord(op)]);
      if (level > current_level) then
      begin
        inc(current_level); // before or after the while??
        while current_level < level do
        begin
          starts[starts_base + current_level] := pattern_offset;
          inc(current_level);
        end;
        starts[starts_base + current_level] := pattern_offset;
      end
      else
        if level < current_level then
        begin
          current_level := level;
          while (num_jumps > 0) and
                (future_jumps[num_jumps - 1] >= starts[starts_base + current_level]) do
          begin
            //PUT_ADDR(offset,addr)
            //         offset = future_jumps[num_jumps-1]
            //         addr   = pattern_offset
            disp := pattern_offset - future_jumps[num_jumps-1] - 2;
            pattern[future_jumps[num_jumps-1]] := char(disp and 255);
            pattern[future_jumps[num_jumps-1] + 1] := char((disp shr 8) and 255);
            dec(num_jumps);
          end;
        end;

      case op of
        Rend: ;
        Rnormal:
            begin
normal_char:
              opcode := Cexact;
store_opcode_and_arg: //* opcode & ch must be set */
              starts[starts_base + current_level] := pattern_offset;
              pattern := pattern + char(opcode) + ch;
              inc(pattern_offset, 2);
            end;
        Ranychar:
            begin
              opcode := CAnychar;
store_opcode:
              starts[starts_base + current_level] := pattern_offset;
              pattern := pattern + char(opcode);
              inc(pattern_offset);
            end;
        Rquote:
            Raise ERegularExpression.Create(SreAbnormal);
        Rbol:
            begin
              if not beginning_context then
                if regexp_context_indep_ops then
                  Raise ERegularExpression.Create(SreBadlyPSpe)
                else
                  goto normal_char;
              opcode := Cbol;
              goto store_opcode;
            end;
        Reol:
            begin
              if not( (pos > size) or
                      (((FStyle and RE_NO_BK_VBAR) = RE_NO_BK_VBAR) and (FPattern[pos] = #124)) or     // oct 174
                      (((FStyle and RE_NO_BK_VBAR) <> RE_NO_BK_VBAR) and (((pos + 1) < size) and
                         (FPattern[pos] = #92) and (FPattern[pos+1] = #124))) or                                 // oct 92 / 174
                      (((FStyle and RE_NO_BK_PARENS) = RE_NO_BK_PARENS) and (FPattern[pos] = ')')) or
                      (((FStyle and RE_NO_BK_PARENS) <> RE_NO_BK_PARENS) and (((pos + 1) < size) and
                         (FPattern[pos] = #92) and (FPattern[pos+1] = ')')))                                     // oct 92
                    ) then
                if regexp_context_indep_ops then
                  Raise ERegularExpression.Create(SreBadlyPSpe)
                else
                  goto normal_char;
              opcode := Ceol;
              goto store_opcode;
            end;
        Roptional:
            begin
              if beginning_context then
                if regexp_context_indep_ops then
                  Raise ERegularExpression.Create(SreBadlyPSpe)
                else
                  goto normal_char;
              if starts[starts_base + current_level] <> pattern_offset then
              begin
                pattern := pattern + #0#0#0;
                Inser_Jump(starts[starts_base + current_level], Cfailure_jump,
                           pattern_offset + 3, pattern_offset, pattern);
              end;
            end;
        Rstar,
        Rplus:
            begin
              if beginning_context then
                 if regexp_context_indep_ops then
                   Raise ERegularExpression.Create(SreBadlyPSpe)
                 else
                   goto normal_char;

              if starts[starts_base + current_level] <> pattern_offset then
              //* ignore empty patterns for + and * */
              begin
                Pattern := Pattern + #0#0#0#0#0#0;//#0#0#0; //ALLOC(9);
                Inser_Jump(starts[starts_base + current_level], Cfailure_jump,
                           pattern_offset + 6, pattern_offset, pattern);
                Inser_Jump(pattern_offset, Cstar_jump,
                           starts[starts_base + current_level], pattern_offset, pattern);
                if op = Rplus then //* jump over initial failure_jump */
                begin
                  Pattern := Pattern + #0#0#0;
                  Inser_Jump(starts[starts_base + current_level], Cdummy_failure_jump,
                             starts[starts_base + current_level] + 6, pattern_offset, pattern);
                end{
                else
                  SetLength(pattern, Length(pattern) - 3)}; // weer verwijderen van drie codes
              end;
            end;
        Ror:
            begin
              Pattern := Pattern + #0#0#0#0#0#0; //ALLOC(6);
              Inser_Jump(starts[starts_base + current_level], Cfailure_jump,
                         pattern_offset + 6, pattern_offset, pattern);
              if num_jumps >= MAX_NESTING then
                Raise ERegularExpression.Create(SreToComplex);
              pattern[pattern_offset] := char(Cjump);
              inc(pattern_offset);
              future_jumps[num_jumps] := pattern_offset;
              inc(num_jumps);
//              pattern := pattern + #0#0;
              inc(pattern_offset, 2);
              starts[starts_base + current_level] := pattern_offset;
            end;
        Ropenpar:
            begin
              starts[starts_base + current_level] := pattern_offset;
              if next_register < RE_NREGS then
              begin
                regexp_t.uses_registers := True;
                pattern := pattern + char(Cstart_memory) + char(next_register);
                inc(pattern_offset, 2);
                open_registers[num_open_registers] := next_register;
                inc(num_open_registers);
                regexp_t.num_registers := regexp_t.num_registers + 1;
                inc(next_register);
              end;
              inc(paren_depth);
              //PUSH_LEVEL_STARTS;
              if starts_base < ((MAX_NESTING - 1) * NUM_LEVELS) then
                starts_base := starts_base + NUM_LEVELS
              else
                Raise ERegularExpression.Create(SreToComplex);

              current_level := 0;
              starts[starts_base + current_level] := pattern_offset;
            end;
        Rclosepar:
            begin
              if paren_depth <= 0 then
                Raise ERegularExpression.Create(SreBadlyPPar);
              dec(starts_base, NUM_LEVELS);
              current_level := integer(regexp_precedences[ord(Ropenpar)]);
              dec(paren_depth);
              if paren_depth < num_open_registers then
              begin
                regexp_t.uses_registers := True;
                dec(num_open_registers);
                pattern := pattern + char(Cend_memory) + char(open_registers[num_open_registers]);
                inc(pattern_offset, 2);
              end;
            end;
        Rmemory:
            begin
              if ch = '0' then
                Raise ERegularExpression.Create(SreBadMregN);
              regexp_t.uses_registers := True;
              opcode := Cmatch_memory;
              ch := char(ord(ch) - ord('0'));
              goto store_opcode_and_arg;
            end;
        Rextended_memory:
            begin
              if pos > size then
                Raise ERegularExpression.Create(SreEndPrem);
              ch := FPattern[pos];
              inc(pos);
              if (ch < '0') or (ch > '9') then
                Raise ERegularExpression.Create(SreBadMregN);
              if pos > size then
                Raise ERegularExpression.Create(SreEndPrem);
              a := FPattern[pos];
              inc(pos);
              if (a < '0') or (a > '9') then
                Raise ERegularExpression.Create(SreBadMregN);
              ch := char(10 * (ord(a) - ord('0')) + ord(ch) - ord('0'));
              if (ch <= '0') or (ch >= char(RE_NREGS)) then
                Raise ERegularExpression.Create(SreBadMregN);
              regexp_t.uses_registers := True;
              opcode := Cmatch_memory;
              goto store_opcode_and_arg;
            end;
        Ropenset:
            begin
              Starts[starts_base + current_level] := pattern_offset; //   SET_LEVEL_START;
//   ALLOC(1+256/8);
              pattern := pattern + char(Cset);
              inc(pattern_offset);
              offset := pattern_offset;
              pattern := pattern + #0#0#0#0#0#0#0#0 + #0#0#0#0#0#0#0#0 +
                                   #0#0#0#0#0#0#0#0 + #0#0#0#0#0#0#0#0;
              inc(pattern_offset, 32);
              if pos > size then
                Raise ERegularExpression.Create(SreEndPrem);
              ch := FPattern[pos];
              inc(pos);
              if translate <> '' then ch := translate[ord(ch)];
              if ch = #94 then    // was oct
              begin
                complement := True;
                if pos > size then
                  Raise ERegularExpression.Create(SreEndPrem);
                ch := FPattern[pos];
                inc(pos);
                if translate <> '' then ch := translate[ord(ch)];
              end
              else
                complement := False;
              prev := -1;
              range := False;
              firstchar := True;
              while (ch <> #93) or firstchar do    //was oct
              begin
                Firstchar := False;
                if (regexp_ansi_sequences and (ch = #92)) then // was oct
                begin
                  if pos > size then
                    Raise ERegularExpression.Create(SreEndPrem);
                  ch := FPattern[pos];
                  inc(pos);
                  Ansi_Translate(ch, size, pos, FPattern, translate);
                end;
                if range then
                begin
                  for i := prev to ord(ch) do
                    pattern[offset + (i div 8)] := char(integer(pattern[offset + (i div 8)]) or (1 shl (i and 7)));
                  prev := -1;
                  range := False;
                end
                else
                  if (prev <> -1) and (ch = '-') then
                    range := True
                  else
                  begin
                    pattern[offset + (ord(ch) div 8)] := char(integer(pattern[offset + (ord(ch) div 8)]) or (1 shl (ord(ch) and 7)));
                    prev := ord(ch);
                  end;
                if pos > size then
                  Raise ERegularExpression.Create(SreEndPrem);
                ch := FPattern[pos];
                inc(pos);
                Ansi_Translate(ch, size, pos, FPattern, translate);
              end;
              if range then
                pattern[offset + (ord('-') div 8)] := char(integer(pattern[offset + (ord('-') div 8)]) or (1 shl (ord('-') and 7)));
              if (complement) then
              begin
                for i := 0 to 256 div 8 do
                  pattern[offset + i] := char(integer(pattern[offset + i]) xor 255);
              end;
            end;
        Rbegbuf:
            begin
              opcode := Cbegbuf;
              goto store_opcode;
            end;
        Rendbuf:
            begin
              opcode := Cendbuf;
              goto store_opcode;
            end;
        Rwordchar:
            begin
              opcode := Csyntaxspec;
              ch := char(Sword);
              goto store_opcode_and_arg;
            end;
        Rnotwordchar:
            begin
              opcode := Cnotsyntaxspec;
              ch := char(Sword);
              goto store_opcode_and_arg;
            end;
        Rwordbeg:
            begin
              opcode := Cwordbeg;
              goto store_opcode;
            end;
        Rwordend:
            begin
              opcode := Cwordend;
              goto store_opcode;
            end;
        Rwordbound:
            begin
              opcode := Cwordbound;
              goto store_opcode;
            end;
        Rnotwordbound:
            begin
              opcode := Cnotwordbound;
              goto store_opcode;
            end;
      else
        Raise ERegularExpression.Create(SreSyntax);
      end;
      beginning_context := (op = Ropenpar) or (op = Ror);
    end;
    if starts_base <> 0 then
      Raise ERegularExpression.Create(SreBadlyPPar);
    pattern := pattern + char(Cend);
    inc(pattern_offset);
  finally
    regexp_t.buffer := pattern;
  end;
  if not re_optimize then
    Raise ERegularExpression.Create(SreOptimize);
end;

//CE_Desc_Begin(TmkreExpr.re_match)
{This tries to match the regexp against the string. This returns the \
length of the matched portion, or -1 if the pattern could not be \
matched and -2 if an error (such as failure stack overflow) is \
encountered.}
//CE_Desc_End

{$HINTS OFF}
function TmkreExpr.re_match({str: string;}pos: integer;
                  old_regs: Pre_registers): integer;
label
  continue_matching, fail, done_matching, Error;
var
  code, translate, text, textstart, textend: PChar;
  a,b,reg,match_end: integer;
  ch: char;
  regstart, regend: PChar;
  regsize: integer;
  state: Tmatch_state;
  item: Pitem_t;

  failuredest, pinst: PChar;
  item_t: Pitem_t;
  item_t2: Pitem_t;
  index: integer;
  current: Pitem_page_t;
begin
  Result := 0;
  Assert((pos > 0) and (Length(Fstr) >= 0), 'Nothing to do');
  Assert((pos <= length(Fstr)), 'Position not valid');
  text := @Fstr[pos];
  textstart := @Fstr[1];
  textend   := PChar(NativeInt(@Fstr[1]) + Length(Fstr) * SizeOf(Char)); //decrease 1 for null char
  code := @regexp_t.buffer[1];
  if regexp_t.translate <> '' then
  begin
    translate := @regexp_t.translate[1];
    dec(translate);
  end
  else translate := nil;
  New_State(state, regexp_t.num_registers);
continue_matching:
  case regexp_compiled_ops(code[0]) of
    Cend:
        begin
          inc(code);
          match_end := text - textstart;
          if old_regs <> nil then
          begin
            old_regs._start[0] := pos;
            old_regs._end[0] := match_end;
            if not regexp_t.uses_registers then
            begin
              for a := 1 to RE_NREGS - 1 do
              begin
                old_regs._start[a] := -1;
                old_regs._end[a]   := -1;
              end;
            end
            else
            begin
              a := 1;
              while a < regexp_t.num_registers do
              begin
                if ((State._start[a]) = nil) or (State._end[a] = nil) then
                begin
                  Old_Regs._start[a] := -1;
                  Old_Regs._end[a]   := -1;
                  continue;
                end;
                Old_Regs._start[a] := State._Start[a] - textstart;
                Old_Regs._end[a]   := State._End[a] - textstart;
                inc(a);
              end;
              while a < RE_NREGS do
              begin
                Old_regs._start[a] := -1;
                Old_regs._end[a]   := -1;
                inc(a);
              end;
            end;
          end;
          Free_State(state);
          Result := match_end - pos + 1;
          Exit;
        end;
    CBol:
        begin
          inc(code);
          if (text = textstart) or (text[-1] = #10) then      // was #13
            goto continue_matching;
          goto fail;
        end;
    Ceol:
        begin
          inc(code);
          if (text = textend) or (text[0] = #10) then         // was #13
            goto continue_matching;
          goto fail;
        end;
    Cset:
        begin
          inc(code);
          //NEXTCHAR
          if (text = textend) then goto fail;
          ch := text[0];
          inc(text);
          if (translate <> nil) then ch := translate[ord(ch)];
          if (integer(code[ord(ch) div 8]) and
              integer(1 shl (ord(ch) and 7)) > 0) then
          begin
            inc(code, 32);
            goto continue_matching;
          end;
          goto fail;
        end;
    Cexact:
        begin
          inc(code);
          //NEXTCHAR
          if (text = textend) then goto fail;
          ch := text[0];
          inc(text);
          if (translate <> nil) then ch := translate[ord(ch)];
          inc(code);
          if ch <> code[-1] then goto fail;
          goto continue_matching;
        end;
    Canychar:
        begin
          inc(code);
          //NEXTCHAR
          if (text = textend) then goto fail;
          ch := text[0];
          inc(text);
          if (translate <> nil) then ch := translate[ord(ch)];
          if ch = #10 then goto fail; // was #13
          goto continue_matching;
        end;
    Cstart_memory:
        begin
          inc(code);
          reg := ord(code[0]);
          inc(code);
          //Set_Reg_Start(state, reg, text, 'Cstart_memory');
          if state.changed[reg] < state.level then
          begin
            //Stack_Next(state.stack, item_t, msg);
            if state.stack.index = STACK_PAGE_SIZE then
            begin
              if state.stack.current.next = nil then
              begin
                new(state.stack.current.next);
                if state.stack.current.next = nil then
                  //Raise Exception.Create(msg);
                  goto Error;
                state.stack.current.next.prev := state.stack.current;
                state.stack.current.next.next := nil;
              end;
              state.stack.current := state.stack.current.next;
              state.stack.index := 0;
            end;
            item_t := @state.stack.current.items[state.stack.index];
            inc(state.stack.index);
            //Stack_Next
            item_t.reg_num   := reg;
            item_t.reg_start := state._start[reg];
            item_t.reg_end   := state._end[reg];
            item_t.reg_level := state.changed[reg];
            state.changed[reg] := state.level;
            inc(state.count);
          end;
          state._start[reg] := text;
          //Set_Reg_Start
          goto continue_matching;
        end;
    Cend_memory:
        begin
          inc(code);
          reg := ord(code[0]);
          inc(code);
          //Set_Reg_End(state, reg, text, 'Cstart_memory');
          if state.changed[reg] < state.level then
          begin
            //Stack_Next(state.stack, item_t, msg);
            if state.stack.index = STACK_PAGE_SIZE then
            begin
              if state.stack.current.next = nil then
              begin
                new(state.stack.current.next);
                if state.stack.current.next = nil then
                  //Raise Exception.Create(msg);
                  goto error;
                state.stack.current.next.prev := state.stack.current;
                state.stack.current.next.next := nil;
              end;
              state.stack.current := state.stack.current.next;
              state.stack.index := 0;
            end;
            item_t := @state.stack.current.items[state.stack.index];
            inc(state.stack.index);
            //Stack_Next
            item_t.reg_num   := reg;
            item_t.reg_start := state._start[reg];
            item_t.reg_end   := state._end[reg];
            item_t.reg_level := state.changed[reg];
            state.changed[reg] := state.level;
            inc(state.count);
          end;
          state._End[reg] := text;
          //Set_Reg_End
          goto continue_matching;
        end;
    Cmatch_memory:
        begin
          inc(code);
          reg := ord(code[0]);
          inc(code);
          regstart := State._Start[reg];
          regend   := State._End[reg];
          if (regstart = nil) or (regend = nil) then goto fail; // or should we just match nothing?
          regsize := regend - regstart;

          if (regsize > (textend - text)) then goto fail;
          if translate <> nil then
          begin
            while regstart < regend do
            begin
              if translate[ord(regstart[0])] <> translate[ord(text[0])] then
                goto fail;
              inc(regstart);
              inc(text);
            end;
          end
          else
            while regstart < regend do
            begin
              if regstart[0] <> text[0] then
                goto fail;
              inc(regstart);
              inc(text);
            end;
          goto continue_matching;
        end;
    Cupdate_failure_jump,
    Cstar_jump,
    Cjump:
        begin
          inc(code);
          if regexp_compiled_ops(code[-1]) = Cupdate_failure_jump then
            //Update_Failure(state, text, 'Cupdate_failure_jump');
            begin
              //Stack_Back(state.stack, item_t, state.count + 1, msg);
              current := state.stack.current;
              index := state.stack.index - (state.count + 1);
              while index < 0 do
              begin
                if current.prev = nil then
                  //Raise Exception.Create(msg);
                  goto error;
                current := current.prev;
                index := index + STACK_PAGE_SIZE;
              end;
              item_t := @current.items[index];
              //Stack_Back
              if item_t.fail_phantom = 0 then
              begin
                //Stack_Next(state.stack, item_t2, msg);
                if state.stack.index = STACK_PAGE_SIZE then
                begin
                  if state.stack.current.next = nil then
                  begin
                    new(state.stack.current.next);
                    if state.stack.current.next = nil then
                      //Raise Exception.Create(msg);
                      goto error;
                    state.stack.current.next.prev := state.stack.current;
                    state.stack.current.next.next := nil;
                  end;
                  state.stack.current := state.stack.current.next;
                  state.stack.index := 0;
                end;
                item_t2 := @state.stack.current.items[state.stack.index];
                inc(state.stack.index);
                //Stack_Next
                item_t2.fail_code := item_t.fail_code;
                item_t2.fail_text := text;
                item_t2.fail_count := state.count;
                item_t2.fail_level  := state.level;
                item_t2.fail_phantom := 1;
                state.count := 0;
                inc(state.level);
                inc(state.point);
              end
              else
              begin
                //Stack_Discard(state.stack, state.count, msg); // on error
                state.stack.index := state.stack.index - state.count;
                while state.stack.index < 0 do
                begin
                  if state.stack.current.prev = nil then
                    //Raise Exception.Create(msg);
                    goto error;
                  state.stack.current := state.stack.current.prev;
                  state.stack.index := state.stack.index + STACK_PAGE_SIZE;
                end;
                //-Stack_Discard
                //Stack_Top(state.stack, item_t, msg);
                if state.stack.index = 0 then
                begin
                  if state.stack.current.prev = nil then
                    //Raise Exception.Create(msg);
                    goto error;
                  item_t := @state.stack.current.prev.items[STACK_PAGE_SIZE - 1];
                end
                else
                  item_t := @state.stack.current.items[state.stack.index - 1];
                //Stack_Top
                item_t.fail_text := text;
                state.count := 0;
                inc(state.level);
              end;
            end;
            //Update_Failure
          a := short(ord(code[0]) + ord(code[1]) * 256);
          inc(code, 2);
          inc(code, a);
          if (code < PChar(regexp_t.buffer)) or
             (NativeInt(@regexp_t.buffer[1]) + Length(regexp_t.buffer) * SizeOf(Char) < NativeInt(code)) then
          begin
            Free_State(state);
            Result := -2;
            Exit;
          end;
          goto continue_matching;
        end;
    Cdummy_failure_jump:
        begin
          inc(code);
          a := short(ord(code[0]) + ord(code[1]) * 256);
          inc(code, 2);
          Assert(code[0] = char(Cfailure_Jump), 'No Cfailure_Jump');
          b := short(ord(code[1]) + ord(code[2]) * 256);
          failuredest := code + b + 3;
          if (failuredest < PChar(regexp_t.buffer)) or
             (NativeInt(@regexp_t.buffer[1]) + Length(regexp_t.buffer) * SizeOf(Char) < NativeInt(failuredest)) then
          begin
            Free_State(state);
            Result := -2;
            Exit;
          end;
          //Push_Failure(state, failuredest, nil, 'Cdummy_failure_jump');
          //Stack_Next(state.stack, item_t, msg);
          if state.stack.index = STACK_PAGE_SIZE then
          begin
            if state.stack.current.next = nil then
            begin
              new(state.stack.current.next);
              if state.stack.current.next = nil then
                //Raise Exception.Create(msg);
                goto error;
              state.stack.current.next.prev := state.stack.current;
              state.stack.current.next.next := nil;
            end;
            state.stack.current := state.stack.current.next;
            state.stack.index := 0;
          end;
          item_t := @state.stack.current.items[state.stack.index];
          inc(state.stack.index);
          //Stack_Next
          item_t.fail_code := failuredest;
          item_t.fail_text := nil;
          item_t.fail_count := state.count;
          item_t.fail_level  := state.level;
          item_t.fail_phantom := 0;
          state.count := 0;
          inc(state.level);
          inc(state.point);
          //Push_Failure
          inc(code, a);
          if (code < PChar(regexp_t.buffer)) or
             (NativeInt(@regexp_t.buffer[1]) + Length(regexp_t.buffer) * SizeOf(Char) < NativeInt(code)) then
          begin
            Free_State(state);
            Result := -2;
            Exit;
          end;
          goto continue_matching;
        end;
    Cfailure_jump:
        begin
          inc(code);
          a := short(ord(code[0]) + ord(code[1]) * 256);
          inc(code, 2);
          if ((code + a) < PChar(regexp_t.buffer)) or
             (NativeInt(@regexp_t.buffer[1]) + Length(regexp_t.buffer) * SizeOf(Char) < NativeInt(code) + a * SizeOf(Char)) then
          begin
            Free_State(state);
            Result := -2;
            Exit;
          end;
          //Push_Failure(state, code + a, text, 'Cdummy_failure_jump');
          //Stack_Next(state.stack, item_t, msg);
          if state.stack.index = STACK_PAGE_SIZE then
          begin
            if state.stack.current.next = nil then
            begin
              new(state.stack.current.next);
              if state.stack.current.next = nil then
                //Raise Exception.Create(msg);
                goto error;
              state.stack.current.next.prev := state.stack.current;
              state.stack.current.next.next := nil;
            end;
            state.stack.current := state.stack.current.next;
            state.stack.index := 0;
          end;
          item_t := @state.stack.current.items[state.stack.index];
          inc(state.stack.index);
          //Stack_Next
          item_t.fail_code := code + a;
          item_t.fail_text := text;
          item_t.fail_count := state.count;
          item_t.fail_level  := state.level;
          item_t.fail_phantom := 0;
          state.count := 0;
          inc(state.level);
          inc(state.point);
          //Push_Failure
          goto continue_matching;
        end;
    Crepeat1:
        begin
          inc(code);
          a := short(ord(code[0]) + ord(code[1]) * 256);
          inc(code, 2);
          pinst := code + a;
          if (pinst < PChar(regexp_t.buffer)) or
             (NativeInt(@regexp_t.buffer[1]) + Length(regexp_t.buffer) * SizeOf(Char) < NativeInt(pinst)) then
          begin
            Free_State(state);
            Result := -2;
            Exit;
          end;
          // pinst is sole instruction in loop, and it matches a
          //* single character.  Since Crepeat1 was originally a
          //* Cupdate_failure_jump, we also know that backtracking
          //* is useless: so long as the single-character
          //* expression matches, it must be used.  Also, in the
          //* case of +, we've already matched one character, so +
          //* can't fail: nothing here can cause a failure.
          case regexp_compiled_ops(pinst[0]) of
            Cset:
                begin
                  inc(pinst);
                  if (translate <> nil) then
                  begin
                    while (text < textend) do
                    begin
                      ch := translate[ord(text[0])];
                      if (integer(code[ord(ch) div 8]) and
                          integer(1 shl (ord(ch) and 7)) > 0) then
                        inc(text)
                      else
                        Break;
                    end;
                  end
                  else
                    while (text < textend) do
                    begin
                      ch := text[0];
                      if (integer(code[ord(ch) div 8]) and
                          integer(1 shl (ord(ch) and 7)) > 0) then
                        inc(text)
                      else
                        Break;
                    end;
                end;
            Cexact:
                begin
                  inc(pinst);
                  ch := pinst[0];
                  if (translate <> nil) then
                  begin
                    while (text < textend) and
                          (translate[ord(text[0])] = ch) do
                      inc(text);
                  end
                  else
                    while (text < textend) and
                          (text[0] = ch) do
                      inc(text);
                end;
            Canychar:
                begin
                  inc(pinst);
                  while (text < textend) and (text[0] <> #10) do inc(text); // was #13
                  //break;
                end;
            Csyntaxspec:
                begin
                  inc(pinst);
                  a := ord(pinst[0]);
                  if (translate <> nil) then
                  begin
                    while (text < textend) and
                          ((ord(re_syntax_table[ord(translate[ord(text[0])])]) and a) > 0) do
                      inc(text);
                  end
                  else
                    begin
                      while (text < textend) and
                          ((ord(re_syntax_table[ord(text[0])]) and a) > 0) do
                        inc(text);
                    end;
                end;
            Cnotsyntaxspec:
                begin
                  inc(pinst);
                  a := ord(pinst[0]);
                  if (translate <> nil) then
                  begin
                    while (text < textend) and
                          not ((ord(re_syntax_table[ord(translate[ord(text[0])])]) and a) > 0) do
                      inc(text);
                  end
                  else
                    begin
                      while (text < textend) and
                            not ((ord(re_syntax_table[ord(text[0])]) and a) > 0) do
                        inc(text);
                    end;
                end;
            else
            begin
              Free_State(state);
              raise ERegularExpression.Create(SreUnknowRE);
            end;
          end;
          // due to the funky way + and * are compiled, the top
          //* failure- stack entry at this point is actually a
          //* success entry -- update it & pop it
          //Update_Failure(state, text, '');
          begin
            //Stack_Back(state.stack, item_t, state.count + 1, msg);
            current := state.stack.current;
            index := state.stack.index - (state.count + 1);
            while index < 0 do
            begin
              if current.prev = nil then
                //Raise Exception.Create(msg);
                goto error;
              current := current.prev;
              index := index + STACK_PAGE_SIZE;
            end;
            item_t := @current.items[index];
            //Stack_Back
            if item_t.fail_phantom = 0 then
            begin
              //Stack_Next(state.stack, item_t2, msg);
              if state.stack.index = STACK_PAGE_SIZE then
              begin
                if state.stack.current.next = nil then
                begin
                  new(state.stack.current.next);
                  if state.stack.current.next = nil then
                    //Raise Exception.Create(msg);
                    goto error;
                  state.stack.current.next.prev := state.stack.current;
                  state.stack.current.next.next := nil;
                end;
                state.stack.current := state.stack.current.next;
                state.stack.index := 0;
              end;
              item_t2 := @state.stack.current.items[state.stack.index];
              inc(state.stack.index);
              //Stack_Next
              item_t2.fail_code := item_t.fail_code;
              item_t2.fail_text := text;
              item_t2.fail_count := state.count;
              item_t2.fail_level  := state.level;
              item_t2.fail_phantom := 1;
              state.count := 0;
              inc(state.level);
              inc(state.point);
            end
            else
            begin
              //Stack_Discard(state.stack, state.count, msg); // on error
              state.stack.index := state.stack.index - state.count;
              while state.stack.index < 0 do
              begin
                if state.stack.current.prev = nil then
                  //Raise Exception.Create(msg);
                  goto error;
                state.stack.current := state.stack.current.prev;
                state.stack.index := state.stack.index + STACK_PAGE_SIZE;
              end;
              //-Stack_Discard
              //Stack_Top(state.stack, item_t, msg);
              if state.stack.index = 0 then
              begin
                if state.stack.current.prev = nil then
                  //Raise Exception.Create(msg);
                  goto error;
                item_t := @state.stack.current.prev.items[STACK_PAGE_SIZE - 1];
              end
              else
                item_t := @state.stack.current.items[state.stack.index - 1];
              //Stack_Top
              item_t.fail_text := text;
              state.count := 0;
              inc(state.level);
            end;
          end;
          //Update_Failure
          goto fail;
        end;
    Cbegbuf:
        begin
          inc(code);
          if text = textstart then goto continue_matching;
          goto fail;
        end;
    Cendbuf:
        begin
          inc(code);
          if text = textend then goto continue_matching;
          goto fail;
        end;
    Cwordbeg:
        begin
          inc(code);
          if text = textend then goto fail;
          if (not(ord(re_syntax_table[ord(text[0])])) and Sword) > 0 then goto fail;
          if text = textstart then goto continue_matching;
          if (not(ord(re_syntax_table[ord(text[-1])])) and Sword) > 0 then goto continue_matching;
          goto fail;
        end;
    Cwordend:
        begin
          inc(code);
          if text = textstart then goto fail;
          if (not(ord(re_syntax_table[ord(text[-1])])) and Sword) > 0 then goto fail;
          if text = textend then goto continue_matching;
          if (not(ord(re_syntax_table[ord(text[0])])) and Sword) > 0 then goto continue_matching;
          goto fail;
        end;
    Cwordbound:
        begin
          inc(code);
          { Note: as in gnu regexp, this also matches at the
          * beginning and end of buffer.}
          if (text = textstart) or (text = textend) then
            goto continue_matching;
          if ((ord(re_syntax_table[ord(text[-1])]) and Sword) xor
              (ord(re_syntax_table[ord(text[0])]) and Sword)) > 0 then
            goto continue_matching;
          goto fail;
        end;
    Cnotwordbound:
        begin
          inc(code);
          { Note: as in gnu regexp, this never matches at the
          * beginning and end of buffer.}
          if (text = textstart) or (text = textend) then
            goto fail;
          if ((ord(re_syntax_table[ord(text[-1])]) and Sword) xor
              (ord(re_syntax_table[ord(text[0])]) and Sword)) > 0 then
            goto fail;
          goto continue_matching;
        end;
    Csyntaxspec:
        begin
          inc(code);
          if (text = textend) then goto fail;
          ch := text[0];
          inc(text);
          if (translate <> nil) then ch := translate[ord(ch)];
          inc(code);
          if ((not(ord(re_syntax_table[ord(ch)])) and ord(code[-1])) > 0) then goto fail;
          goto continue_matching;
        end;
    Cnotsyntaxspec:
        begin
          inc(code);
          if (text = textend) then goto fail;
          ch := text[0];
          inc(text);
          if (translate <> nil) then ch := translate[ord(ch)];
          inc(code);
          if ((ord(re_syntax_table[ord(ch)]) and ord(code[-1])) > 0) then goto fail;
          goto continue_matching;
        end;
  end;
fail: // POP_FAILURE(state, code, text, goto done_matching, goto error)
  repeat
    while state.count > 0 do
    begin
      //Stack_Prev(state.stack, item, 'POP FAILURE - error');
      if state.stack.index = 0 then
      begin
        if state.stack.current.prev = nil then
          //Raise Exception.Create(msg);
          goto error;
        state.stack.current := state.stack.current.prev;
        state.stack.index := STACK_PAGE_SIZE - 1;
      end
      else
        dec(state.stack.index);
      item := @state.stack.current.items[state.stack.index];
      //Stack_Prev
      state._start[item.reg_num] := item.reg_start;
      state._end[item.reg_num]   := item.reg_end;
      state.changed[item.reg_num] := item.reg_level;
      dec(state.count);
    end;
    //Stack_Prev(state.stack, item, 'POP FAILURE - Empty');
    if state.stack.index = 0 then
    begin
      if state.stack.current.prev = nil then
        //Raise Exception.Create(msg);
        goto done_matching;;
      state.stack.current := state.stack.current.prev;
      state.stack.index := STACK_PAGE_SIZE - 1;
    end
    else
      dec(state.stack.index);
    item := @state.stack.current.items[state.stack.index];
    //Stack_Prev
    code := item.fail_code;
    text := item.fail_text;
    state.count := item.fail_count;
    state.level := item.fail_level;
    dec(state.point);
  until (item.fail_text <> nil);
  goto continue_matching;

done_matching:
  Result := -1;

  Free_State(state);
  Exit;

error:
  Result := -2;
  Free_State(state);
  Exit;

end;
{$HINTS ON}

//CE_Desc_Begin(TmkreExpr.re_search)
{This rearches for a substring matching the regexp. This returns the first \
index at which a match is found.  Range specifies at how many  positions to try \
matching; positive values indicate searching forwards, and negative values \
indicate searching backwards.
regs is used to hold the start and end value of groups (end value - 1)

This returns -1 if no match is found, and -2 if an error (such as failure stack \
overflow) is encountered.}
//CE_Desc_End
function TmkreExpr.re_search({str: string; }pos, range: integer;
                  regs: Pre_registers): integer;
var
  fastmap: PChar;
  translate: PChar;
  text, partstart, partend: PChar;
  dir, ret: integer;
  anchor: byte;

begin
  // Result := -2; no needed
  Assert((pos >= 0) and (Length(Fstr) >= 0), 'Nothing to do');
  Assert((((pos + range) >= 0) and ((pos + range) <= length(Fstr))), 'Position not valid');
  if regexp_t.fastmap <> '' then fastmap := @regexp_t.fastmap[1]
                            else fastmap := nil;
  if regexp_t.translate <> '' then
  begin
    translate := @regexp_t.translate[1];
    dec(translate);
  end
  else translate := nil;
  if (fastmap <> nil) and (not regexp_t.fastmap_accurate) then re_compile_fastmap;
  anchor := regexp_t.anchor;
  if regexp_t.can_be_null = #1 then fastmap := nil; //can_be_null == 2: can match null at eob
  if range < 0 then
  begin
    dir := -1;
    range := -range;
  end
  else
    dir := 1;

  if anchor = 2 then
    if (pos <> 0) then
    begin
      Result := -1;
      Exit;
    end
    else
      Range := 0;

  while range > 0 do
  begin
    if fastmap <> nil then
    begin
      if dir = 1 then
      begin    //searching forwards
        text := @Fstr[pos];
        partend := PChar(NativeInt(@Fstr[1]) + (Length(Fstr) - 1) * SizeOf(Char));
        partstart := text;
        if translate <> nil then
        begin
          while (text <> partend) and not(fastmap[ord(translate[ord(text[0])])] > #0) do
            inc(text);
        end
        else
           while (text <> partend) and not(fastmap[ord(text[0])] > #0) do
            inc(text);
        pos := pos + text - partstart;
        range := range - (integer(text) - integer(partstart));
        if (pos = length(Fstr)) and (regexp_t.can_be_null = #0) then
        begin
          Result := -1;
          Exit;
        end;
      end
      else
      begin  //searching backwards
        text := @Fstr[pos];
        partstart := PChar(integer(@Fstr[1]) + pos - range);
        partend := text;
        if translate <> nil then
        begin
          while (text <> partstart) and not(fastmap[ord(translate[ord(text[0])])] > #0) do
            dec(text);
        end
        else
           while (text <> partstart) and not(fastmap[ord(text[0])] > #0) do
            dec(text);
        pos := pos - (integer(partend) - integer(text));
        range := range - (integer(partend) - integer(text));
      end;
    end;
    if anchor = 1 then if (pos > 2) and (Fstr[pos - 1] <> #10) then  // was #13
    begin
      dec(range);
      inc(pos, dir);
      continue;
    end;
    assert((pos > 0) and (pos <= length(Fstr)), 'search out of bounds');
    ret := re_match({str, }pos, regs);
    if ret >= 0 then
    begin
      result := pos;
      exit;
    end;
    if ret = -2 then
    begin
      result := -2;
      exit;
    end;
    dec(range);
    inc(pos, dir);
  end;
  Result := -1;
end;

//Method_Marker(TmkreExpr.OnMatchTerminate)

procedure TmkreExpr.OnMatchTerminate(Sender: TObject);
begin
  if Assigned(FOnEndMatch) then FOnEndMatch(Self);
  FThreadedMatch.free;
  FThreadedMatch := nil;
end;

procedure TmkreExpr.OnSearchTerminate(Sender: TObject);
begin
  if Assigned(FOnEndSearch) then FOnEndSearch(Self);
  FThreadedSearch.free;
  FThreadedSearch := nil;
end;

//CE_Desc_Begin(TmkreExpr.Stop)
{
Stop DoMatch and DoThreadedSearchWithRange from matching.

<%SEEALSO TmkreExpr.DoMatch,TmkreExpr.DoThreadedSearchWithRange%>}
//CE_Desc_End
procedure TmkreExpr.Stop;
begin
  if Assigned(FThreadedMatch) then
  begin
    FThreadedMatch.Terminate;
//    OnMatchTerminate(Self);
  end;
  if Assigned(FThreadedSearch) then
  begin
    FThreadedSearch.Terminate;
//    OnSearchTerminate(Self);
  end;
end;

procedure TmkreExpr.Execute;
var
  sFound: string;
  pos: integer;
  re_registers: Tre_registers;
begin
  FMatches.Clear;
  FMatches.BeginUpdate;
  CheckRegExp;
  try
    pos := 0;
    repeat
      pos := re_search(pos + 1, Length(FStr) - pos - 1, @re_registers);
      if pos > 0 then
      begin
        sFound := Copy(Fstr, re_registers._start[0], re_registers._end[0] - re_registers._start[0] + 1);
        FMatches.AddObject(sFound, TObject(re_registers._start[0]));
        if Assigned(FOnMatch)
          then FOnMatch (Self, sFound, re_registers._start[0], pos, Tmkre_registers(re_registers));
      end;
    until pos < 1;
  Finally
    FMatches.EndUpdate;
  end;
end;

//****************
// TThreadedSearch
//****************
constructor TThreadedSearch.Create(mkreExpr: TmkreExpr);
begin
  inherited Create(True); // do not start immediately
  FmkreExpr := mkreExpr;
end;

procedure TThreadedSearch.Execute;
begin
  FmkreExpr.CheckRegExp;
  Result := FmkreExpr.re_search(pos, range, @re_registers);
  if Assigned(FmkreExpr.FOnSearch) and (Result > 0) then DoOnSearchEvent;
end;

procedure TThreadedSearch.DoOnSearchEvent;
begin
  FmkreExpr.FOnSearch(Self, copy(FmkreExpr.Fstr, re_registers._start[0], re_registers._end[0] - re_registers._start[0] + 1), Result, Tmkre_registers(re_registers));
end;

//***************
// TThreadedMatch
//***************
constructor TThreadedMatch.Create(mkreExpr: TmkreExpr);
begin
  inherited Create(True); // do not start immediately
  FmkreExpr := mkreExpr;
end;

procedure TThreadedMatch.Execute;
begin
  FmkreExpr.FMatches.Clear;
  FmkreExpr.FMatches.BeginUpdate;
  FmkreExpr.CheckRegExp;
  try
    pos := 0;
    repeat
      if Terminated then Exit;
      pos := FmkreExpr.re_search(pos + 1, Length(FmkreExpr.FStr) - pos - 1, @re_registers);
      if pos > 0 then
      begin
        sFound := copy(FmkreExpr.Fstr, re_registers._start[0], re_registers._end[0] - re_registers._start[0] + 1);
        FmkreExpr.FMatches.AddObject(sFound, TObject(re_registers._start[0]));
        if Assigned(FmkreExpr.FOnMatch) then Synchronize(DoOnMatchEvent);
      end;
    until pos < 1;
  Finally
    FmkreExpr.FMatches.EndUpdate;
  end;
  Terminate;
end;

procedure TThreadedMatch.DoOnMatchEvent;
begin
  FmkreExpr.FOnMatch(Self, sFound, re_registers._start[0], pos, Tmkre_registers(re_registers));
end;


//CE_Desc_Begin(TmkreExpr.Active)
{
When active is set to true, all strings are matched when assigned to \
<%LINK TmkreExpr.Str%>

(This is equal to)
<%CODE%>
  Str := 'string to parse';
  DoMatch;
<%TEXT%>
}
//CE_Desc_End

//CE_Desc_Begin(TmkreExpr.CanBeEmpty)
{
When True, matches can contain empty strings}
//CE_Desc_End

//CE_Desc_Begin(TmkreExpr.Pattern)
{<%TEXT%>
A regular expression (or RE) specifies a set of strings that matches it; the \
functions in this module let you check if a particular string matches a given \
regular expression (or if a given regular expression matches a particular string, \
which comes down to the same thing).

Regular expressions can be concatenated to form new regular expressions; if A \
and B are both regular expressions, then AB is also an regular expression. If a \
string p matches A and another string q matches B, the string pq will match AB. \
Thus, complex expressions can easily be constructed from simpler ones like the \
primitives described here. For details of the theory and implementation of \
regular expressions, consult almost any textbook about compiler construction.

A brief explanation of the format of regular expressions follows.

Regular expressions can contain both special and ordinary characters. Ordinary \
characters, like 'A', 'a', or '0', are the simplest regular expressions; they \
simply match themselves. You can concatenate ordinary characters, so 'last' \
matches the characters 'last'. (In the rest of this section, we'll write RE's \
in this special font, usually without quotes, and strings to be matched 'in \
single quotes'.)

Special characters either stand for classes of ordinary characters, or affect \
how the regular expressions around them are interpreted.

The special characters are:

. (Dot.) Matches any character except a newline.
^ (Caret.) Matches the start of the string.
$ Matches the end of the string. foo matches both 'foo' and 'foobar', \
while the regular expression 'foo$' matches only 'foo'.
* Causes the resulting RE to match 0 or more repetitions of the preceding \
RE. ab* will match 'a', 'ab', or 'a' followed by any number of 'b's.
+ Causes the resulting RE to match 1 or more repetitions of the preceding \
RE. ab+ will match 'a' followed by any non-zero number of 'b's; it will not \
match just 'a'.
? Causes the resulting RE to match 0 or 1 repetitions of the preceding RE. \
ab? will match either 'a' or 'ab'.

\ Either escapes special characters (permitting you to match characters \
like '*?+&$'), or signals a special sequence; special sequences are discussed \
below.

[ ] Used to indicate a set of characters. Characters can be listed \
individually, or a range is indicated by giving two characters and separating \
them by a '-'. Special characters are not active inside sets. For example, \
[akm$] will match any of the characters 'a', 'k', 'm', or '$'; [a-z] will match \
any lowercase letter. If you want to include a ] inside a set, it must be the \
first character of the set; to include a -, place it as the first or last \
character.

Characters not within a range can be matched by including a ^ as the first \
character of the set; ^ elsewhere will simply match the '^' character.

The standard style is EGrep compatible, which means that (, ), and | doesn't \
have to be qouted. If you change the style setting, take in account the \
differences.
<%SEEALSO TmkreExpr.SyntaxStyles%>
The special sequences consist of '\' and a character from the list below. If the \
ordinary character is not on the list, then the resulting RE will match the \
second character. For example, \$ matches the character '$'.

| A|B, where A and B can be arbitrary REs, creates a regular expression \
that will match either A or B. This can be used inside groups (see below) as well.
( ) Indicates the start and end of a group; the contents of a group can be \
matched later in the string with the \[1-9] special sequence, described next. ,
\1 .. \9 Matches the contents of the group of the same number. For \
example, (.+) \1 matches 'the the' or '55 55', but not 'the end' (note the space \
after the group). This special sequence can only be used to match one of the \
first 9 groups; groups with higher numbers can be matched using the \v sequence.
\b Matches the empty string, but only at the beginning or end of a word. A \
word is defined as a sequence of alphanumeric characters, so the end of a word \
is indicated by whitespace or a non-alphanumeric character.
\B Matches the empty string, but when it is not at the beginning or end of \
a word.
\v Must be followed by a two digit decimal number, and matches the contents \
of the group of the same number. The group number must be between 1 and 99, \
inclusive.
\w Matches any alphanumeric character; this is equivalent to the set \
[a-zA-Z0-9].
\W Matches any non-alphanumeric character; this is equivalent to the set \
[^a-zA-Z0-9].
\< Matches the empty string, but only at the beginning of a word. A word is \
defined as a sequence of alphanumeric characters, so the end of a word is \
indicated by whitespace or a non-alphanumeric character.
\> Matches the empty string, but only at the end of a word.

\\ (2 backslashes) Matches a literal backslash.

\` Like ^, this only matches at the start of the string.
\' Like $, this only matches at the end of the string.}
//CE_Desc_End

//CE_Desc_Begin(TmkreExpr.Matches)
{
All matches on Str are stored in this stringlist. When Matches is read Str will \
be matched for pattern. Its behaviour is like calling DoMatch.

<%SEEALSO TmkreExpr.Str,TmkreExpr.Active,TmkreExpr.DoMatch%>}
//CE_Desc_End

//CE_Desc_Begin(TmkreExpr.OnMatch)
{
This event is called everytime when an match is found on a string.
<%ARGBEGIN%><%ARG Sender,TObject,Is the TmkreRegexpr component that caused \
the event%>
<%ARG str,string,The match that was found%>
<%ARG pos,integer,The start position of the match in Str%>
<%ARG ret,integer,The end position of the match in Str%>
<%ARG re_registers,Tmkre_registers,The groups that were found%>

}
//CE_Desc_End

//CE_Desc_Begin(TmkreExpr.OnEndMatch)
{
This event is triggered after the whole string is searched for \
matches,  and before the Thread for matching is destroyed}
//CE_Desc_End
//CE_Desc_Begin(TmkreExpr.OnEndSearch)
{
This event is triggered after a string is searched for the next \
match and before the thread is destroyed.}
//CE_Desc_End
//CE_Desc_Begin(TmkreExpr.OnSearch)
{
This event is called when a match is found for the search pattern.
<%ARGBEGIN%><%ARG Sender,TObject,The TmkRegexpr component that caused the event%>
<%ARG str,string,The match that was found%>
<%ARG pos,integer,The start position of the match in Str%>
<%ARG re_registers,Tmkre_registers,The groups that were found%>
}
//CE_Desc_End
//CE_Desc_Begin(TmkreExpr.OnStartMatch)
{
This event is called before any match is done.}
//CE_Desc_End
//CE_Desc_Begin(TmkreExpr.OnStartSearch)
{
This event is called before any search is done.}
//CE_Desc_End
//CE_Desc_Begin(TmkreExpr.Str)
{
This string will be matched by the pattern.

Matching can be started by:
Reading Matches
calling the DoMatch method
Setting Active to True

When adding a text file to this property, be aware that the Regular expressions \
works on Unix text files, that means that lines are separated by a LF and not by \
Cr / LF. It's because of that that it is nessesary to eliminate the CR from the file.\
For that purpose the function mkConvertDos2Ux is added.

<%SEEALSO TmkreExpr.Pattern,TmkreExpr.Matches,TmkreExpr.DoMatch,TmkreExpr.Active,mkConvertDos2Ux%>}
//CE_Desc_End
//CE_Desc_Begin(TmkreExpr.SyntaxStyles)
{
Following Syntax rules are defined:
- mkre_No_Bk_Parens       no quoting for parentheses  ( )
- mkre_No_Bk_Vbar         no quoting for vertical bar |
- mkre_Bk_Plus_Qm         quoting needed for + and ?
- mkre_Tight_Vbar         | binds tighter than ^ and $
- mkre_Newline_Or         treat newline (in expression) as or
- mkre_Context_Indep_Ops  ^$?*+ are special in all contexts
- mkre_Ansi_Hex           ansi sequences (\n etc) and \xhh
- mkre_No_Gnu_Extensions  no gnu extensions

Common styles:
- AWK     mkre_No_Bk_Parens, mkre_No_Bk_Vbar and mkre_Context_Indep_Ops
- EGREP   mkre_No_Bk_Parens, mkre_No_Bk_Vbar, mkre_Context_Indep_Ops and mkre_Newline_Or
- GREP    mkre_Bk_Plus_Qm and mkre_Newline_Or
- EMACS   none

Default setting when created:
EGREP mkre_No_Bk_Parens, mkre_No_Bk_Vbar, mkre_Context_Indep_Ops and mkre_Newline_Or
}
//CE_Desc_End
//CE_Desc_Begin(TmkreExpr.Translate)
{
This is an string which is:
empty or
256 characters

When the string is 256 characters each character translates the \
corresponding char to another char. In pattern AND Str.
So you have to fill it with char #0 till #255, and after that you can choose to \
map some characters to others.

Example:
<%CODE%>//Ignore case
var
  c: integer;
  translate: string;
begin
  SetLength(translate, 256);
  for c := 0 to 255 do
    translate[c] := char(c);
  for c := ord('a') to ord('z') do
    translate[c] := char(c - 32);
  mkreExpr1.translate := translate;
end;
<%SEEALSO TmkreExpr.Str%>
}
//CE_Desc_End
//CE_Desc_Begin(TmkreExpr.UseFastmap)
{
When True, an map is created which determinate which characters are searched for \
matching the first valid character in the pattern.

(When [a-z]* is the pattern searches can skip all other characters, an match is first tried \
when a..z is found.)

Default fastmap is True

}
//CE_Desc_End
end.
