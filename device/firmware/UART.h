#include "stdbool.h"
#include "Global.h"
#include "Move.h"

#define LINE_END 0x0D

void UARTInit(void);
void UARTWriteByte(byte data);
void UARTWritePosition(position pos);
byte UARTReadByte(void);
position UARTReadPosition(void);
bool UARTByteAvailable(void);
bool UARTLineAvailable(void);
