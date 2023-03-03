Binary turtle
=============
In computer graphics, turtle graphics are vector graphics using a relative cursor (the "turtle")
upon a Cartesian plane. The turtle has three attributes: a location, an orientation (or direction),
and a pen. The pen, too, has attributes: color, on/off (or up/down) state.
The turtle moves with commands that are relative to its own position, such as "move
forward 10 spaces" and "turn left 90 degrees". The pen carried by the turtle can also be
controlled, by enabling it or setting its color. Program translates binary encoded turtle commands to a raster image in a BMP file.

Turtle commands
---------------
The length of all turtle commands is 16 or 32 bits. The first two bits define one of four
commands (set position, set direction, move, set state). Unused bits in all commands are
marked by the – character. They should not be taken into account when the command is
decoded.


## Set position command

The set position command sets the new coordinates of the turtle. It consists of two words.The first word defines the command (bits 15-14). The point (0,0) is located in the bottom left corner of the image. The second word contains the X (bits x9-x0) and Y (bits y5-y0)
coordinates of the new position.

first word:

| bit 15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 |  6 |  5 |  4 |  3 |  2 | 1 | 0 |
|:------:|:--:|:--:|:--:|:--:|:--:|:-:|:-:|:-:|:--:|:--:|:--:|:--:|:--:|:-:|:-:|
|    0   |  0 |  - |  - |  - |  - | - | - |-  |  - |  - |  - |  - |  - | - | - |

second word:

| bit 15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 |7   |  6 |  5 |  4 |  3 |  2 | 1 | 0 |
|:------:|:--:|:--:|:--:|:--:|:--:|:-:|:-:|:-:|:--:|:--:|:--:|:--:|:--:|:-:|:-:|
|   y5   | y4 | y3 | y2 | y1 | y0 | x9|x8 | x7| x6 | x5 | x4 | x3 | x2 |x1 |x0 |


## Set direction command
The set direction command sets the direction in which the turtle will move, when a move
command is issued. The direction is defined by the d1, d0 bits.

| bit 15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 |7  |  6 |  5 |  4 |  3 |  2 | 1 | 0 |
|:------:|:--:|:--:|:--:|:--:|:--:|:-:|:-:|:-:|:--:|:--:|:--:|:--:|:--:|:-:|:-:|
|    0   |  1 |  - |  - |  - |  - | - | - |-  |  - |  - |  - |  - |  - | d1|d0 |

Meaning of d1, d0 bits:

| d1 | d0 | direction |
|:--:|:--:|:---------:|
| 0  | 0  | right     |
| 0  | 1  | up        |
| 1  | 0  | left      |
| 1  | 1  | down      |


## Move command

Direction, positon and state of the pen are required to be defined before move command. If the destination point is located beyond the drawing area the turtle should stop at the edge. The turtle leaves a visible trail when the pen is lowered. Distance is defined by the m9-m0 bits.


| bit 15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 |7  |  6 |  5 |  4 |  3 |  2 | 1 | 0 |
|:------:|:--:|:--:|:--:|:--:|:--:|:-:|:-:|:-:|:--:|:--:|:--:|:--:|:--:|:-:|:-:|
|    1   |  0 |  - |  - |  - |  - |m9 |m8 | m7| m6 | m5 | m4 | m3 | m2 | m1|m0 |

## Set pen state command

The pen state command defines whether the pen is raised or lowered (bit ud) and the color of the trail. Bits r3-r0 are the most significant bits of the 8-bits red component of the color (remaining bits are set to zero). Bits g3-g0 are the most significant bits of the 8-bits green component of the color (remaining bits are set to zero). Bits b3-b0 are the most significant bits of the 8-bits blue component of the color (remaining bits are set to zero).

| bit 15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 |  6 |  5 |  4 |  3 |  2 | 1 | 0 |
|:------:|:--:|:--:|:--:|:--:|:--:|:-:|:-:|:-:|:--:|:--:|:--:|:--:|:--:|:-:|:-:|
|    1   |  1 | ud |  - | b3 | b2 |b1 |b0 | g3| g2 | g1 | g0 | r3 | r2 | r1|r0 |

ud bit:
0 - pen raised;
1 - pen lowered