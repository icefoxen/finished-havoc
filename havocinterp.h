#ifndef _HAVOCINTERP_H
#define _HAVOCINTERP_H

#include <stdlib.h>
#include <stdio.h>
#include "havocvm.h"


void readInstruction( hv_vm*, instruction* );
void doInstruction( hv_vm*, instruction* );

void run( hv_vm* );

#endif
