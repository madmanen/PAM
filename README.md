# PAM
Pathfinding Action Manager, a pathfinding api for minecraft cc:tweaked. The api uses fuel level and action id storage to ensure reboot security, and can function in both gps and local mode.

Currently, the PAM folder needs to be downloaded into a custom folder with the name "api", so that the full path to PAM.lua becomes api/PAM/PAM.lua


## REQUIREMENTS
The api only works on turtles that use fuel. It has mainly been tested on minecraft 1.21.1 and cc:tweaked 1.120.0, but would be expected to work with older and younger versions as well.

Important: when using this API, you must not use any of the original movement related functions, since that would invalidate the API's internal state (coordinates would no longer match), neither the original refuel function, which would also invalidate the state. Always use the functions of this API to move and refuel the turtle. while in local mode (not gps mode) if it is moved by any means other than the api movement functions, its coordinate system will get de-synced.

## STATE

- PAM.getX()

If on gps mode, then it will send a request to the gps system, otherwise it will read its internal x coordiate from a set local zero.
#### returns: 
number x: coordinate of the turtle.


- PAM.getY()

If in gps mode, then it will send a request to the gps system, otherwise it will read its internal y coordiate from a set local zero.
#### returns:
number y: coordinate of the turtle.

- PAM.getZ()

If in gps mode, then it will send a request to the gps system, otherwise it will read its internal z coordiate from a set local zero.
#### returns: 
number z: coordinate of the turtle.

- PAM.setX(x)

sets the x coordinate of the turtle.
#### Arguments:
x: (optional) a number to set the x coordinate as, if in local mode
#### Returns:
boolean true: on success.
