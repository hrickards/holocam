#include "stdbool.h"

void MotorInit(void);
void MotorStart(void);
void MotorStop(void);
void MotorXStep(bool dir);
void MotorYStep(bool dir);
void MotorThetaStep(bool dir);
void MotorPhiStep(bool dir);
