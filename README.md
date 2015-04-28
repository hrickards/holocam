# Movement
 * X: Left/right provided by X stepper axis
 * Y: Up/down provided by Y stepper axis
 * Theta: Pitch/tilt (up/down)
 * Phi: Yaw/pan (left/right)

Don't need roll (in XY plane), or zoom (translation along Z axis).

All distances non-Arduino stored in millimeters, and all angles stored in degrees.

# Protocol
Two (bidirectional) core communication channels:
* User: user-facing interface (after load balancing/etc) to RPi socket
* Control: RPi to/from Arduino

## Buffered
| Slug    | Arguments          | Returns | Channels      | Description                                                   |
|---------|--------------------|---------|---------------|---------------------------------------------------------------|
| moveRel | (x, y, theta, phi) | ()      | control, user | move position relative to current position                    |
| moveAbs | (x, y, theta, phi) | ()      | control, user | move to absolute position specified                           |
| homeX   | ()                 | ()      | control       | move to x=0, and use endstop to ensure that's physically true |
| homeY   | ()                 | ()      | control       | move to y=0, and use endstop to ensure that's physically true |

## Unbuffered
| Slug            | Arguments | Channels      | Returns            | Description                                       |
|-----------------|-----------|---------------|--------------------|---------------------------------------------------|
| start           | ()        | control       | ()                 | powers on all motors and camera                   |
| abort           | ()        | control       | ()                 | cancels any buffered moves                        |
| stop            | ()        | control       | ()                 | aborts then powers off all motors and camera      |
| currentPosition | ()        | control, user | (x, y, theta, phi) | returns current translational/rotational position |

# Hours
## 02/23 to 03/01 20.75h
* Mon 02/23 (08.50h): 3.40-4.30, 6.00-7.30, 9.40-12.40, 1.30-4.45 8.58h
* Fri 02/27 (03.50h): 12.30-4
* Sat 02/28 (08.75h): 11:45-8:30

## 03/02 to 03/08 11.5h
* Wed 03/04 (00.50h): 11:45-12:15
* Thu 03/05 (01.50h): 2:30-4
* Sat 03/07 (07.00h): 4.30-6.00, 7.00-12.30
* Sun 03/08 (02.50h): 4.00-6.30

## 03/09 to 03/15
None

## 03/16 to 03/22
None

## 03/23 to 03/29 24h
* Thu 03/26 (09.75h): 8.30-6.15
* Fri 03/27 (09.25h): 2.45-12.00
* Sat 03/28 (05.00h): 12.45-3.30, 9.45-12.00

## 03/30 to 04/05 7h
* Mon 03/30 (07.00h): 3.30-10.30

## 04/06 to 04/12 4.25h
* Sun 04/12 (04.25h): 1.30-5.45

## 04/13 to 04/19 6.50h
* Mon 04/13 (06.50h): 3.30-4.30, 7.50-1.20

## 04/20 to 04/26 1.75h
* Thu 04/23 (01.75h): 8.00-9.45

## 04/27 to 05/03 6.50h
* Mon 04/27 (06.50): 9.45-4.15
