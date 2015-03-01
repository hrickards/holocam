#include "Global.h"

typedef int16_t position; // Signed for relative movements
#define POSITION_MAX INT8_MAX
#define POSITION_MIN INT8_MIN

void MoveInit(void);
void MoveSpin(void);
int MoveAddRelative(position x, position y, position theta, position phi);
int MoveAddAbsolute(position x, position y, position theta, position phi);
// Writes current position into passed variables
void MoveGetCurrentPosition(position *x, position *y, position *theta, position *phi);
void MoveGetTargetPosition(position *x, position *y, position *theta, position *phi);
void MoveAbort(void);
void MoveHomeX(void);
void MoveHomeY(void);
