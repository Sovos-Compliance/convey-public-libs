unit uCnvPChar;

interface

uses
  uAllocators;

type
  TPCharHeap = class(TVariableBlockHeap)
  public
    function AllocPChar(const s: String): PChar;
  end;

procedure DeAllocPChar(Ptr: PChar);

{ The following two functions are borrowed from FastCode project. They assume memory for
  the PChars passed is 32 bits aligned and PChars contain the length on the offset -4 bytes like
  regular Delphi AnsiStrings. PChars allocated with TPCharHeap.AllocPChar have this characteristics }
function CnvStrIComp(const S1, S2: PChar): Integer;
function CnvStrComp(const S1, S2: PChar): Integer;

implementation

procedure DeAllocPChar(Ptr: PChar);
begin
  DeAlloc (Pointer (integer (Ptr) - sizeof (Cardinal)));
end;

function CnvStrIComp(const S1, S2: PChar): Integer;
asm
  cmp     eax, edx
  je      @@Same             {S1 = S2}
  test    eax, edx
  jnz     @@Compare
  test    eax, eax
  jz      @FirstNil          {S1 = NIL}
  test    edx, edx
  jnz     @@Compare          {S1 <> NIL and S2 <> NIL}
  mov     eax, [eax-4]       {S2 = NIL, Result = Length(S1)}
  ret
@@Same:
  xor     eax, eax
  ret
@FirstNil:
  sub     eax, [edx-4]       {S1 = NIL, Result = -Length(S2)}
  ret
@@Compare:
  push    ebx
  push    ebp
  push    edi
  push    esi
  mov     ebx, [eax-4]       {Length(S1)}
  sub     ebx, [edx-4]       {Default Result if All Compared Characters Match}
  push    ebx                {Save Default Result}
  sbb     ebp, ebp
  and     ebp, ebx
  add     ebp, [edx-4]       {Compare Length = Min(Length(S1),Length(S2))}
  add     eax, ebp           {End of S1}
  add     edx, ebp           {End of S2}
  neg     ebp                {Negate Compare Length}
@@MainLoop:                  {Compare 4 Characters per Loop}
  mov     ebx, [eax+ebp]
  mov     ecx, [edx+ebp]
  cmp     ebx, ecx
  je      @@Next
  mov     esi, ebx           {Convert 4 Chars in EBX into Uppercase}
  or      ebx, $80808080
  mov     edi, ebx
  sub     ebx, $7B7B7B7B
  xor     edi, esi
  or      ebx, $80808080
  sub     ebx, $66666666
  and     ebx, edi
  shr     ebx, 2
  xor     ebx, esi
  mov     esi, ecx           {Convert 4 Chars in ECX into Uppercase}
  or      ecx, $80808080
  mov     edi, ecx
  sub     ecx, $7B7B7B7B
  xor     edi, esi
  or      ecx, $80808080
  sub     ecx, $66666666
  and     ecx, edi
  shr     ecx, 2
  xor     ecx, esi
  cmp     ebx, ecx
  jne     @@CheckDiff
@@Next:
  add     ebp, 4
  jl      @@MainLoop         {Loop until all required Characters Compared}
  pop     eax                {Default Result}
  jmp     @@Done
@@CheckDiff:
  pop     eax                {Default Result}
@@DiffLoop:
  cmp     cl, bl
  jne     @@SetResult
  add     ebp, 1
  jz      @@Done             {Difference after Compare Length}
  shr     ecx, 8
  shr     ebx, 8
  jmp     @@DiffLoop
@@SetResult:
  movzx   eax, bl            {Set Result from Character Difference}
  and     ecx, $ff
  sub     eax, ecx
@@Done:
  pop     esi
  pop     edi
  pop     ebp
  pop     ebx
end;

function CnvStrComp(const S1, S2: PChar): Integer;
asm
  {On entry:
    eax = S1,
    edx = S2}
  cmp eax, edx
  je @SameString
  {Is either of the strings perhaps nil?}
  test eax, edx
  jz @PossibleNilString
  {Compare the first four characters (there has to be a trailing #0). In random
   string compares this can save a lot of CPU time.}
@BothNonNil:
  {Compare the first character}
  mov ecx, [edx]
  cmp cl, [eax]
  je @FirstCharacterSame
  {First character differs}
  movzx eax, byte ptr [eax]
  movzx ecx, cl
  sub eax, ecx
  ret
@FirstCharacterSame:
  {save ebx}
  push ebx
  {Get first four characters}
  mov ebx, [eax]
  cmp ebx, ecx
  je @FirstFourSame
  {Get the string lengths in eax and edx}
  mov eax, [eax - 4]
  mov edx, [edx - 4]
  {Is the second character the same?}
  cmp ch, bh
  je @FirstTwoCharactersMatch
  {Second character differs: Are any of the strings non-nil but zero length?}
  test eax, eax
  jz @ReturnLengthDifference
  test edx, edx
  jz @ReturnLengthDifference
  movzx eax, bh
  movzx edx, ch
@ReturnLengthDifference:
  sub eax, edx
  pop ebx
  ret
@FirstTwoCharactersMatch:
  cmp eax, 2
  jna @ReturnLengthDifference
  cmp edx, 2
  jna @ReturnLengthDifference
  {Swap the bytes into the correct order}
  mov eax, ebx
  bswap eax
  bswap ecx
  sub eax, ecx
  pop ebx
  ret
  {It is the same string}
@SameString:
  xor eax, eax
  ret
  {Good possibility that at least one of the strings are nil}
@PossibleNilString:
  test eax, eax
  jz @FirstStringNil
  test edx, edx
  jnz @BothNonNil
  {Return first string length: second string is nil}
  mov eax, [eax - 4]
  ret
@FirstStringNil:
  {Return 0 - length(S2): first string is nil}
  sub eax, [edx - 4]
  ret
  {The first four characters are identical}
@FirstFourSame:
  {set ebx = length(S1)}
  mov ebx, [eax - 4]
  xor ecx, ecx
  {set ebx = length(S1) - length(S2)}
  sub ebx, [edx - 4]
  {Save the length difference on the stack}
  push ebx
  {set esi = 0 if length(S1) < length(S2), $ffffffff otherwise}
  adc ecx, -1
  {set esi = - min(length(s1), length(s2))}
  and ecx, ebx
  sub ecx, [eax - 4]
  {Adjust the pointers to be negative based}
  sub eax, ecx
  sub edx, ecx
@CompareLoop:
  add ecx, 4
  jns @MatchUpToLength
  mov ebx, [eax + ecx]
  xor ebx, [edx + ecx]
  jz @CompareLoop
@Mismatch:
  bsf ebx, ebx
  shr ebx, 3
  add ecx, ebx
  jns @MatchUpToLength
  movzx eax, byte ptr [eax + ecx]
  movzx edx, byte ptr [edx + ecx]
  sub eax, edx
  pop ebx
  pop ebx
  ret
  {All characters match - return the difference in length}
@MatchUpToLength:
  pop eax
  pop ebx
end;

{ TPCharHeap }

function TPCharHeap.AllocPChar(const s: String): PChar;
type
  PCardinal = ^Cardinal;
var
  Len : Cardinal;
begin
  Len := Length (s);
  Result := Alloc (Len + sizeof (Cardinal) + 1);
  PCardinal (Result)^ := Len; // Store the length on first DWORD
  inc (PCardinal (Result));
  PCardinal (Cardinal (Result) + sizeof (integer) * (Len div sizeof (integer)))^ := 0;
  if Len > 0
    then move (PChar (s)^, Result^, Len);
end;

end.
