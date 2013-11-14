{$DEFINE debug}
unit HashTrie;

{
  Delphi implementation of HashTrie dynamic hashing method
  Full description available on www.softlab.od.ua

  Delphi 2,3,4,5
  Freware with source.

  Copyright (c) 2000, Andre N Belokon, SoftLab
  Web     http://softlab.od.ua/
  Email   support@softlab.od.ua

  THIS SOFTWARE AND THE ACCOMPANYING FILES ARE DISTRIBUTED
  "AS IS" AND WITHOUT WARRANTIES AS TO PERFORMANCE OF MERCHANTABILITY OR
  ANY OTHER WARRANTIES WHETHER EXPRESSED OR IMPLIED.
  NO WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE IS OFFERED.
  THE USER MUST ASSUME THE ENTIRE RISK OF USING THE ACCOMPANYING CODE.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented, you must
     not claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation
     would be appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. Original copyright may not be removed or altered from any source
     distribution.
  4. All copyright of HashTrie dynamic hashing method belongs to Andre N Belokon,
     SoftLab MIL-TEC Ltd.
}

interface

{UnDef Enterprise}

uses Windows, SysUtils, uAllocators, uCnvPChar;

const
  // DON'T CHANGE LeafSize VALUE !!! MUST BE EQ 256
  // because some code optimization used
  LeafSize = 256;
  // determines max length of the list
  // very big|small values decrease performance
  // optimum value in range 4..16
  BucketSize = 8;
  PCharAllocatorPageSize = 1024;

type
  TLinkedItem = class
    procedure FreeInstance; override;
    class function NewInstance: TObject; override;
  private
    Value: DWORD;
    Data: DWORD;
    Next: TLinkedItem;
    procedure _Create(FValue, FData: DWORD; FNext: TLinkedItem);
  public
    class function Instantiate(Ptr : Pointer; FValue, FData: DWORD; FNext: TLinkedItem): TLinkedItem;
    destructor Destroy; override;
  end;

  THashTrie = class; // forward
  TTraverseProc = procedure(UserData, UserProc: Pointer;
    Value, Data: DWORD; var Done: Boolean) of object;

  TAddDownResult = record
    Added : Boolean;
    OldData : DWORD;
  end;

  TTreeItem = class
    procedure FreeInstance; override;
    class function NewInstance: TObject; override;
  private
    Owner: THashTrie;
    Level: integer;
    Filled: integer;
    Items: array[0..LeafSize - 1] of TObject;
    procedure _Create(AOwner: THashTrie);
  public
    class function Instantiate(Ptr : pointer; AOwner : THashTrie): TTreeItem;
    destructor Destroy; override;
    function ROR(Value: DWORD): DWORD;
    function RORN(Value: DWORD; Level: integer): DWORD;
    function AddDown(Value, Data, Hash: DWORD): TAddDownResult;
    procedure Delete(Value, Hash: DWORD);
    function Find(Value, Hash: DWORD; var Data: DWORD): Boolean;
    function Traverse(UserData, UserProc: Pointer; TraverseProc: TTraverseProc): Boolean;
  end;

  THashTrie = class
  private
    FAutoFreeObjects: Boolean;
    Root: TTreeItem;
    LinkedItemAllocator : TFixedBlockHeap;
    TreeItemAllocator : TFixedBlockHeap;
    function GetRootInitialized: Boolean;
  protected
    function HashValue(Value: DWORD): DWORD; virtual; abstract;
    procedure DestroyItem(var Value, Data: DWORD); virtual;
    function CompareValue(Value1, Value2: DWORD): Boolean; virtual; abstract;
    function AddDown(Value, Data, Hash: DWORD): TAddDownResult;
    procedure Delete(Value, Hash: DWORD);
    function Find(Value, Hash: DWORD; var Data: DWORD): Boolean;
    procedure Traverse(UserData, UserProc: Pointer; TraverseProc: TTraverseProc);
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Clear;
    property AutoFreeObjects: Boolean read FAutoFreeObjects write FAutoFreeObjects default False;
    property RootInitialized: Boolean read GetRootInitialized;
  end;

  TStrHashTraverseProc = procedure(UserData: Pointer; Value: PChar;
    Data: TObject; var Done: Boolean);
  TStrHashTraverseMeth = procedure(UserData: Pointer; Value: PChar;
    Data: TObject; var Done: Boolean) of object;

  TStringHashTrie = class(THashTrie)
  private
    FCaseSensitive: Boolean;
    Allocator : TPCharHeap;
  protected
    function HashValue(Value: DWORD): DWORD; override;
    procedure DestroyItem(var Value, Data: DWORD); override;
    function CompareValue(Value1, Value2: DWORD): Boolean; override;
    function HashStr(S: PChar; Len: Integer): DWORD;
    procedure TraverseProc(UserData, UserProc: Pointer;
      Value, Data: DWORD; var Done: Boolean);
    procedure TraverseMeth(UserData, UserProc: Pointer;
      Value, Data: DWORD; var Done: Boolean);
  public
    constructor Create; override;
    function Add(const S: string; Data: TObject): Boolean; overload;
    procedure Delete(const S: string);
    function Find(const S: string; var Data: TObject): Boolean; overload;
    procedure Traverse(UserData: Pointer; UserProc: TStrHashTraverseProc); overload;
    procedure Traverse(UserData: Pointer; UserProc: TStrHashTraverseMeth); overload;
    function Find(const s : string): Boolean; overload;
    function Add(const s : string): Boolean; overload;
    destructor Destroy; override;
    property CaseSensitive: Boolean read FCaseSensitive write FCaseSensitive default False;
  end;

  TIntHashTraverseProc = procedure(UserData: Pointer; Value: integer;
    Data: TObject; var Done: Boolean);
  TIntHashTraverseMeth = procedure(UserData: Pointer; Value: integer;
    Data: TObject; var Done: Boolean) of object;

  TIntegerHashTrie = class(THashTrie)
  protected
    function HashValue(Value: DWORD): DWORD; override;
    procedure DestroyItem(var Value, Data: DWORD); override;
    function CompareValue(Value1, Value2: DWORD): Boolean; override;
    function HashInt(n: integer): DWORD;
    procedure TraverseProc(UserData, UserProc: Pointer;
      Value, Data: DWORD; var Done: Boolean);
    procedure TraverseMeth(UserData, UserProc: Pointer;
      Value, Data: DWORD; var Done: Boolean);
  public
    constructor Create; override;
    function Add(const n: integer; Data: TObject): Boolean; overload;
    procedure Delete(n: integer);
    function Find(n: integer; var Data: TObject): Boolean; overload;
    procedure Traverse(UserData: Pointer; UserProc: TIntHashTraverseProc); overload;
    procedure Traverse(UserData: Pointer; UserProc: TIntHashTraverseMeth); overload;
    function Find(n : integer): Boolean; overload;
    function Add(n : integer): Boolean; overload;
  end;

function CalcStrCRC32(S: PChar): DWORD;
function CalcStrCRC32Upper(S: PChar): DWORD;
function SuperFastHash(data: PChar; Len: Cardinal; AUpper: Boolean): DWORD;

{$IFDEF debug}
type
  TLenStat = array[1..BucketSize] of integer;

procedure Stat(ht: THashTrie; var MaxLevel, PeakCnt, FillCnt, EmptyCnt: integer;
  var LenStat: TLenStat);

{$ENDIF}

implementation

uses
  Math, CnvStrUtils;

resourcestring
  SObjectsMustBeCreatedCallingClass = 'Objects must be created calling class method Instantiate';

type
  PCardinal = ^Cardinal;

const
  MinUppperBufferSize = 128;

{$IFDEF debug}
procedure Stat(ht: THashTrie; var MaxLevel, PeakCnt, FillCnt, EmptyCnt: integer;
  var LenStat: TLenStat);

  procedure TreeStat(ht: TTreeItem);
  var
    j, i: integer;
    LinkedItem: TLinkedItem;
  begin
    Inc(PeakCnt);
    if ht.Level + 1 > MaxLevel
      then MaxLevel := ht.Level + 1;
    for j := 0 to LeafSize - 1 do
      if ht.Items[j] <> nil
        then
        begin
          Inc(FillCnt);
          if ht.Items[j] is TTreeItem
            then TreeStat(TTreeItem(ht.Items[j]))
            else
            begin
              i := 0;
              LinkedItem := TLinkedItem(ht.Items[j]);
              while LinkedItem <> nil do
                begin
                  Inc(i);
                  LinkedItem := LinkedItem.Next;
                end;
              LenStat[i] := LenStat[i] + 1;
            end;
        end
        else Inc(EmptyCnt);
  end;
begin
  if ht.Root <> nil
    then TreeStat(ht.Root);
end;
{$ENDIF}

{ TTreeItem }

function TTreeItem.AddDown(Value, Data, Hash: DWORD): TAddDownResult;
var
  i, j: integer;
  TreeItem: TTreeItem;
  LinkedItem: TLinkedItem;
begin
  Result.OldData := 0;
  i := Hash and $FF;
  if Items[i] = nil
    then
    begin
      Items[i] := TLinkedItem.Instantiate (Owner.LinkedItemAllocator.Alloc, Value, Data, nil);
      Inc(Filled);
      Result.Added := True;
    end
    else if Items[i] is TTreeItem
      then Result := TTreeItem(Items[i]).AddDown(Value, Data, ROR(Hash))
      else
      begin
        j := 0;
        LinkedItem := TLinkedItem(Items[i]);
        while LinkedItem <> nil do
          begin
            if Owner.CompareValue(LinkedItem.Value, Value)
              then
              begin
                // found
                Result.OldData := LinkedItem.Data;
                Result.Added := False;
                LinkedItem.Data := Data;
                Exit;
              end;
            LinkedItem := LinkedItem.Next;
            Inc(j)
          end;
        if j >= BucketSize
          then
          begin
            // full
            TreeItem := TTreeItem.Instantiate(Owner.TreeItemAllocator.Alloc, Owner);
            TreeItem.Level := Level + 1;
            LinkedItem := TLinkedItem(Items[i]);
            while LinkedItem <> nil do
              begin
                TreeItem.AddDown(LinkedItem.Value, LinkedItem.Data,
                  RORN(Owner.HashValue(LinkedItem.Value), Level + 1));
                LinkedItem := LinkedItem.Next;
              end;
            Result := TreeItem.AddDown(Value, Data, ROR(Hash));
            TLinkedItem(Items[i]).Free;
            Items[i] := TreeItem;
          end
          else
          begin
            Items[i] := TLinkedItem.Instantiate (Owner.LinkedItemAllocator.Alloc, Value, Data, TLinkedItem(Items[i]));
            Result.Added := True;
          end;
      end;
end;

procedure TTreeItem._Create(AOwner: THashTrie);
begin
  Owner := AOwner;
  Level := 0;
  Filled := 0;
  FillChar (Items, sizeof (Items), 0);
end;

procedure TTreeItem.Delete(Value, Hash: DWORD);
var
  i: integer;
  PrevLinkedItem, LinkedItem: TLinkedItem;
begin
  i := Hash and $FF;
  if Items[i] = nil
    then Exit
    else if Items[i] is TTreeItem
      then
      begin
        TTreeItem(Items[i]).Delete(Value, ROR(Hash));
        if TTreeItem(Items[i]).Filled = 0
          then
          begin
            TTreeItem(Items[i]).Free;
            Items[i] := nil;
          end;
      end
      else
      begin
        PrevLinkedItem := nil;
        LinkedItem := TLinkedItem(Items[i]);
        while LinkedItem <> nil do
          begin
            if Owner.CompareValue(LinkedItem.Value, Value)
              then
              begin
                // found
                if PrevLinkedItem = nil
                  then
                  begin
                    Items[i] := LinkedItem.Next;
                    if Items[i] = nil
                      then Dec(Filled);
                  end
                  else PrevLinkedItem.Next := LinkedItem.Next;
                LinkedItem.Next := nil;
                Owner.DestroyItem(LinkedItem.Value, LinkedItem.Data);
                LinkedItem.Free;
                Exit;
              end;
            PrevLinkedItem := LinkedItem;
            LinkedItem := LinkedItem.Next;
          end;
      end;
end;

destructor TTreeItem.Destroy;
var
  j: integer;
  LinkedItem: TLinkedItem;
begin
  for j := 0 to LeafSize - 1 do
    if Items[j] <> nil
      then if Items[j] is TTreeItem
        then TTreeItem(Items[j]).Free
        else
        begin
          LinkedItem := TLinkedItem(Items[j]);
          while LinkedItem <> nil do
            begin
              Owner.DestroyItem(LinkedItem.Value, LinkedItem.Data);
              LinkedItem := LinkedItem.Next;
            end;
          TLinkedItem(Items[j]).Free;
        end;
  inherited;
end;

function TTreeItem.Find(Value, Hash: DWORD; var Data: DWORD): Boolean;
var
  i: integer;
  LinkedItem: TLinkedItem;
begin
  Result := False;
  i := Hash and $FF;
  if Items[i] = nil
    then Exit
    else if Items[i] is TTreeItem
      then Result := TTreeItem(Items[i]).Find(Value, ROR(Hash), Data)
      else
      begin
        LinkedItem := TLinkedItem(Items[i]);
        while LinkedItem <> nil do
          begin
            if Owner.CompareValue(LinkedItem.Value, Value)
              then
              begin
                // found
                Data := LinkedItem.Data;
                Result := True;
                Exit;
              end;
            LinkedItem := LinkedItem.Next;
          end;
      end;
end;

procedure TTreeItem.FreeInstance;
asm
  jmp DeAlloc
end;

class function TTreeItem.Instantiate(Ptr : pointer; AOwner : THashTrie):
    TTreeItem;
begin
  Pointer (Ptr^) := Self; // Assign pointer to VMT in first 32 bits
  Result := Ptr;
  Result._Create (AOwner);
end;

class function TTreeItem.NewInstance: TObject;
begin
  raise Exception.Create (SObjectsMustBeCreatedCallingClass);
end;

function TTreeItem.ROR(Value: DWORD): DWORD;
begin
  Result := ((Value and $FF) shl 24) or ((Value shr 8) and $FFFFFF);
end;

function TTreeItem.RORN(Value: DWORD; Level: integer): DWORD;
begin
  Result := Value;
  while Level > 0 do
    begin
      Result := ROR(Result);
      Dec(Level);
    end;
end;

function TTreeItem.Traverse(UserData, UserProc: Pointer;
  TraverseProc: TTraverseProc): Boolean;
var
  j: integer;
  LinkedItem: TLinkedItem;
begin
  Result := False;
  for j := 0 to LeafSize - 1 do
    if Items[j] <> nil
      then
      begin
        if Items[j] is TTreeItem
          then Result := TTreeItem(Items[j]).Traverse(UserData, UserProc, TraverseProc)
          else
          begin
            LinkedItem := TLinkedItem(Items[j]);
            while LinkedItem <> nil do
              begin
                TraverseProc(UserData, UserProc, LinkedItem.Value, LinkedItem.Data, Result);
                LinkedItem := LinkedItem.Next;
              end;
          end;
        if Result
          then Exit;
      end;
end;

{ TLinkedItem }

procedure TLinkedItem._Create(FValue, FData: DWORD; FNext: TLinkedItem);
begin
  Value := FValue;
  Data := FData;
  Next := FNext;
end;

destructor TLinkedItem.Destroy;
begin
  if Next <> nil
    then Next.Free;
end;

procedure TLinkedItem.FreeInstance;
asm
  jmp DeAlloc
end;

class function TLinkedItem.Instantiate(Ptr : Pointer; FValue, FData: DWORD;
    FNext: TLinkedItem): TLinkedItem;
begin
  Pointer (Ptr^) := Self; // Assign pointer to VMT in first 32 bits
  Result := Ptr;
  Result._Create (FValue, FData, FNext);
end;

class function TLinkedItem.NewInstance: TObject;
begin
  raise Exception.Create (SObjectsMustBeCreatedCallingClass);
end;

{ THashTrie }

function THashTrie.AddDown(Value, Data, Hash: DWORD): TAddDownResult;
begin
  if Root = nil
    then Root := TTreeItem.Instantiate(TreeItemAllocator.Alloc, Self);
  Result := Root.AddDown(Value, Data, Hash);
  if AutoFreeObjects and (not Result.Added) and (Result.OldData <> 0) and (Result.OldData <> Data) then
    TObject(Result.OldData).Free;
end;

procedure THashTrie.Delete(Value, Hash: DWORD);
begin
  if Root <> nil
    then Root.Delete(Value, Hash);
end;

function THashTrie.Find(Value, Hash: DWORD; var Data: DWORD): Boolean;
begin
  if Root <> nil
    then Result := Root.Find(Value, Hash, Data)
    else Result := False;
end;

constructor THashTrie.Create;
begin
  inherited;
  Root := nil;
  LinkedItemAllocator := TFixedBlockHeap.Create (TLinkedItem, 32);
  TreeItemAllocator := TFixedBlockHeap.Create (TTreeItem, 32);
end;

destructor THashTrie.Destroy;
begin
  if Root <> nil
    then Root.Free;
  TreeItemAllocator.Free;
  LinkedItemAllocator.Free;
  inherited;
end;

procedure THashTrie.Traverse(UserData, UserProc: Pointer;
  TraverseProc: TTraverseProc);
begin
  if Root <> nil
    then Root.Traverse(UserData, UserProc, TraverseProc);
end;

procedure THashTrie.Clear;
begin
  FreeAndNil (Root);
end;

procedure THashTrie.DestroyItem(var Value, Data: DWORD);
begin
  if FAutoFreeObjects         
    then TObject(Data).Free;
end;

function THashTrie.GetRootInitialized: Boolean;
begin
  Result := Root <> nil;
end;

{ TStringHashTrie }

function TStringHashTrie.Add(const S: string; Data: TObject): Boolean;
var
  Str : PChar;
  AddDownResult : TAddDownResult;
begin
  Str := Allocator.AllocPChar (S);
  // I don't care if memory doesn't get freed, it's owned by allocator
  // eventually allocator will be free and memory disposed
  // Try finally block here very tough of peformance
  AddDownResult := AddDown(DWORD(Str), DWORD(Data), HashStr(Str, Length (Str)));
  Result := AddDownResult.Added;
  if not Result
    then DeAllocPChar (Str);
end;

function TStringHashTrie.CompareValue(Value1, Value2: DWORD): Boolean;
begin
  if FCaseSensitive
    then Result := CnvStrComp (PChar (Value1), PChar (Value2)) = 0
    else Result := CnvStrIComp (PChar(Value1), PChar(Value2)) = 0;
end;

constructor TStringHashTrie.Create;
begin
  Allocator := TPCharHeap.Create (PCharAllocatorPageSize);
  inherited;
  FCaseSensitive := False;
  FAutoFreeObjects := False;
end;

procedure TStringHashTrie.Delete(const S: string);
var
  Str : PChar;
begin
  Str := Allocator.AllocPChar (S);
  // We will not use Try..Finally here because it's hard on performance
  // Allocator will free the block allocated when freeing the HashTrie in case
  // an exception happens on inherited Find call
  inherited Delete(DWORD(Str), HashStr(Str, Length (s)));
  DeAllocPChar(Str);
end;

procedure TStringHashTrie.DestroyItem(var Value, Data: DWORD);
begin
  inherited;
  DeAllocPChar (PChar (Value));
  Value := 0;
  Data := 0;
end;

function TStringHashTrie.Find(const S: string; var Data: TObject): Boolean;
var
  Str : PChar;
begin
  Str := Allocator.AllocPChar (S);
  // We will not use Try..Finally here because it's hard on performance
  // Allocator will free the block allocated when freeing the HashTrie in case
  // an exception happens on inherited Find call
  Result := inherited Find(DWORD(Str), HashStr(Str, Length(S)), DWORD(Data));
  DeAllocPChar(Str);
end;

function TStringHashTrie.HashStr(S: PChar; Len: Integer): DWORD;
begin
  if CaseSensitive
    then Result := SuperFastHash (s, Len, False)
    else Result := SuperFastHash (s, Len, True);
end;

function TStringHashTrie.HashValue(Value: DWORD): DWORD;
begin
  Result := HashStr (PChar (Value), PCardinal (integer (Value) - sizeof (Cardinal))^); // Len is zero because we know buffer is large enough for any value in the trie
end;

procedure TStringHashTrie.Traverse(UserData: Pointer;
  UserProc: TStrHashTraverseProc);
begin
  inherited Traverse(UserData, @UserProc, TraverseProc);
end;

procedure TStringHashTrie.TraverseProc(UserData, UserProc: Pointer; Value,
  Data: DWORD; var Done: Boolean);
begin
  TStrHashTraverseProc(UserProc)(UserData, PChar(Value), TObject(Data), Done);
end;

procedure TStringHashTrie.Traverse(UserData: Pointer; UserProc: TStrHashTraverseMeth);
begin
  inherited Traverse(UserData, @TMethod (UserProc), TraverseMeth);
end;

procedure TStringHashTrie.TraverseMeth(UserData, UserProc: Pointer; Value,
  Data: DWORD; var Done: Boolean);
type
  PTStrHashTraverseMeth = ^TStrHashTraverseMeth;
begin
  PTStrHashTraverseMeth(UserProc)^(UserData, PChar(Value), TObject(Data), Done);
end;

function TStringHashTrie.Find(const s : string): Boolean;
var
  p : TObject;
begin
  Result := Find (s, p);
end;

function TStringHashTrie.Add(const s : string): Boolean;
begin
  Result := Add(s, nil);
end;

destructor TStringHashTrie.Destroy;
begin
  inherited;
  Allocator.Free;
end;

{ dynamic crc32 table }

const
  CRC32_POLYNOMIAL = $EDB88320;
var
  Ccitt32Table: array[0..255] of DWORD;

function CalcStrCRC32Upper(S: PChar): DWORD;
begin
  Result := $FFFFFFFF;
  while s^ <> #0 do
    begin
      Result := (((Result shr 8) and $00FFFFFF) xor (Ccitt32Table[(Result xor byte(UpperArray [S^])) and $FF]));
      inc (S);
    end;
end;

procedure BuildCRCTable;
var
  i, j: longint;
  value: DWORD;
begin
  for i := 0 to 255 do
    begin
      value := i;
      for j := 8 downto 1 do
        if ((value and 1) <> 0) then
          value := (value shr 1) xor CRC32_POLYNOMIAL
        else
          value := value shr 1;
      Ccitt32Table[i] := value;
    end
end;

function CalcStrCRC32(S: PChar): DWORD;
begin
  Result := $FFFFFFFF;
  while s^ <> #0 do
    begin
      Result := (((Result shr 8) and $00FFFFFF) xor (Ccitt32Table[(Result xor byte(S^)) and $FF]));
      inc (s);
    end;
end;

function UpperCardinal (n : Cardinal) : Cardinal;
var
  tmp, tmp2 : Cardinal;
begin
  tmp := n or $80808080;
  tmp2 := tmp - $7B7B7B7B;
  tmp := tmp xor n;
  Result := ((((tmp2 or $80808080) - $66666666) and tmp) shr 2) xor n;
end;

function SuperFastHash(data: PChar; Len: Cardinal; AUpper: Boolean): DWORD;
var
  tmp : Cardinal;
  rem : integer;
  i : integer;
  CurCardinal : Cardinal;
begin
  Result := len;
  if (len <= 0) or (data = nil)
    then
    begin
      Result := 0;
      exit;
    end;
  rem := len and 3;
  len := len shr 2;
  { Main loop }
  for i := len downto 1 do
    begin
      CurCardinal := PCardinal (data)^;
      if AUpper
        then CurCardinal := UpperCardinal (CurCardinal);
      inc (Result, PWord (@CurCardinal)^);
      tmp  := (PWord (@PChar(@CurCardinal) [2])^ shl 11) xor Result;
      Result := (Result shl 16) xor tmp;
      inc (Data, sizeof (Cardinal));
      inc (Result, Result shr 11);
    end;
  { Handle end cases }
  case rem of
    3 :
      begin
        CurCardinal := PWord (data)^ shl 8 + byte (data [sizeof (Word)]);
        if AUpper
          then CurCardinal := UpperCardinal (CurCardinal);
        inc (Result, PWord (@CurCardinal)^);
        Result := Result xor (Result shl 16);
        Result := Result xor (byte (PChar (@CurCardinal) [sizeof (Word)]) shl 18);
        inc (Result, Result shr 11);
      end;
    2 :
      begin
        CurCardinal := PWord (data)^;
        if AUpper
          then CurCardinal := UpperCardinal (CurCardinal);
        inc (Result, PWord (@CurCardinal)^);
        Result := Result xor (Result shl 11);
        inc (Result, Result shr 17);
      end;
    1 :
      begin
        if AUpper
          then inc (Result, byte (UpperArray [data^]))
          else inc (Result, byte (data^));
        Result := Result xor (Result shl 10);
        inc (Result, Result shr 1);
      end;
  end;

  { Force "avalanching" of final 127 bits }
  Result := Result xor (Result shl 3);
  inc (Result, Result shr 5);
  Result := Result xor (Result shl 4);
  inc (Result, Result shr 17);
  Result := Result xor (Result shl 25);
  inc (Result, Result shr 6);
end;

{ Original C code for SuperFastHash by Paul Hsieh:

#include "pstdint.h" /* Replace with <stdint.h> if appropriate */
#undef get16bits
#if (defined(__GNUC__) && defined(__i386__)) || defined(__WATCOMC__) \
  || defined(_MSC_VER) || defined (__BORLANDC__) || defined (__TURBOC__)
#define get16bits(d) (*((const uint16_t *) (d)))
#endif

#if !defined (get16bits)
#define get16bits(d) ((((uint32_t)(((const uint8_t *)(d))[1])) << 8)\
                       +(uint32_t)(((const uint8_t *)(d))[0]) )
#endif

}
(*
uint32_t SuperFastHash (const char * data, int len) {
uint32_t hash = len, tmp;
int rem;

    if (len <= 0 || data == NULL) return 0;

    rem = len & 3;
    len >>= 2;

    /* Main loop */
    for (;len > 0; len--) {
        hash  += get16bits (data);
        tmp    = (get16bits (data+2) << 11) ^ hash;
        hash   = (hash << 16) ^ tmp;
        data  += 2*sizeof (uint16_t);
        hash  += hash >> 11;
    }

    /* Handle end cases */
    switch (rem) {
        case 3: hash += get16bits (data);
                hash ^= hash << 16;
                hash ^= data[sizeof (uint16_t)] << 18;
                hash += hash >> 11;
                break;
        case 2: hash += get16bits (data);
                hash ^= hash << 11;
                hash += hash >> 17;
                break;
        case 1: hash += *data;
                hash ^= hash << 10;
                hash += hash >> 1;
    }

    /* Force "avalanching" of final 127 bits */
    hash ^= hash << 3;
    hash += hash >> 5;
    hash ^= hash << 4;
    hash += hash >> 17;
    hash ^= hash << 25;
    hash += hash >> 6;

    return hash;
}
*)

{ TIntegerHashTrie }

constructor TIntegerHashTrie.Create;
begin
  inherited;
  FAutoFreeObjects := False;
end;

function TIntegerHashTrie.Add(const n: integer; Data: TObject): Boolean;
begin
  Result := AddDown(DWORD(n), DWORD(Data), HashInt(n)).Added;
end;

function TIntegerHashTrie.CompareValue(Value1, Value2: DWORD): Boolean;
begin
  Result := Value1 = Value2;
end;

procedure TIntegerHashTrie.Delete(n: integer);
begin
  inherited Delete(DWORD(n), HashInt(n));
end;

procedure TIntegerHashTrie.DestroyItem(var Value, Data: DWORD);
begin
  inherited;
  Value := 0;
  Data := 0;
end;

function TIntegerHashTrie.Find(n: integer; var Data: TObject): Boolean;
begin
  Result := inherited Find(DWORD(n), HashInt(n), DWORD(Data));
end;

function TIntegerHashTrie.HashInt(n: integer): DWORD; assembler;
asm
      MOV     EDX,n
      XOR     EDX,$FFFFFFFF
      MOV     EAX,MaxInt
      IMUL    EDX,EDX,08088405H
      INC     EDX
      MUL     EDX
      MOV     Result,EDX
end;

function TIntegerHashTrie.HashValue(Value: DWORD): DWORD;
begin
  Result := HashInt(Integer(Value));
end;

procedure TIntegerHashTrie.Traverse(UserData: Pointer; UserProc:
  TIntHashTraverseMeth);
begin
  inherited Traverse(UserData, @TMethod(UserProc), TraverseMeth);
end;

procedure TIntegerHashTrie.Traverse(UserData: Pointer; UserProc:
  TIntHashTraverseProc);
begin
  inherited Traverse(UserData, @UserProc, TraverseProc);
end;

procedure TIntegerHashTrie.TraverseMeth(UserData, UserProc: Pointer; Value,
  Data: DWORD; var Done: Boolean);
type
  PTIntHashTraverseMeth = ^TIntHashTraverseMeth;
begin
  PTIntHashTraverseMeth(UserProc)^(UserData, Integer(Value), TObject(Data), Done);
end;

procedure TIntegerHashTrie.TraverseProc(UserData, UserProc: Pointer; Value,
  Data: DWORD; var Done: Boolean);
begin
  TIntHashTraverseProc(UserProc)(UserData, Integer(Value), TObject(Data), Done);
end;

function TIntegerHashTrie.Find(n : integer): Boolean;
var
  p : TObject;
begin
  Result := Find (n, p);
end;

function TIntegerHashTrie.Add(n : integer): Boolean;
begin
  Result := Add (n, nil);
end;

initialization
  BuildCRCTable;
end.

