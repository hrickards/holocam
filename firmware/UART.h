#include "Global.h"
#include "stdbool.h"

#define LINE_END 0x0D

void UARTInit(void);
void UARTWriteByte(byte data);
byte UARTReadByte(void);
bool UARTByteAvailable(void);
bool UARTLineAvailable(void);
