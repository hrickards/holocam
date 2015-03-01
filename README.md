# Movement
X: Left/right provided by X stepper axis
Y: Up/down provided by Y stepper axis
Theta: Pitch/tilt (up/down)
Phi: Yaw/pan (left/right)

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
2/23: 3.40-4.30, 6.00-7.30, 9.40-12.40, 1.30-4.45
2/27: 12.30-4
2/28: 11:45-8:30
