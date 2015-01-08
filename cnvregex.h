#ifndef cnvregex_h
#define cnvregex_h

#include <Windows.h>

#define CNVREGEX_DLL "cnvregex.dll"

void InitCnvRegEx();
void DoneCnvRegEx();

char* RegExpr_Create(void ** _this);
char* RegExpr_Free(void* _this);
char* RegExpr_SetInputString(void* _this, char* AInputString);
char* RegExpr_SetExpression(void* _this, char* AExpression);
char* RegExpr_Exec(void* _this, BOOL* AMatch);
char* RegExpr_ExecNext(void* _this, BOOL* AMore);

typedef void* (__cdecl *GetMem_t)(int Size);
typedef int (__cdecl *FreeMem_t)(void* P);
typedef void* (__cdecl *ReallocMem_t)(void* P, int Size);

void OverrideMemAllocator(GetMem_t pGetMem, ReallocMem_t pReallocMem, FreeMem_t pFreeMem);
void ResetMemAllocator();

#endif