# PAM
Pathfinding Action Manager, a pathfinding api for minecraft cc:tweaked. The api uses fuel level and action id storage to ensure reboot security, and can function in both gps and local mode.

When downloading, only the PAM.lua file and the directory structure is necessary, all the text files inside PAM/data/ can be created by running the init() function. 
If for whatever reason you wish to download the api inside another directory, such as fx inside a directory called "api", then all you need to edit is the local dataVault at the top of the PAM.lua script.

## REQUIREMENTS
The api only works on turtles that use fuel. It has mainly been tested on minecraft 1.21.1 and cc:tweaked 1.120.0, but would be expected to work with older and younger versions as well.

Important: when using this API, you must not use any of the original movement related functions, since that would invalidate the API's internal state (coordinates would no longer match), neither the original refuel function, which would also invalidate the state. Always use the functions of this API to move and refuel the turtle. while in local mode (not gps mode) if it is moved by any means other than the api movement functions, its coordinate system will get de-synced.

## STATE
* `PAM.getX() -> x`  
    If on gps mode, then it will send a request to the gps system, otherwise it will read its internal x coordiate from a set local zero.

* `PAM.getY() -> y`  
    If in gps mode, then it will send a request to the gps system, otherwise it will read its internal y coordiate from a set local zero.

* `PAM.getZ() -> z`  
    If in gps mode, then it will send a request to the gps system, otherwise it will read its internal z coordiate from a set local zero.

* `  PAM.getFacing() -> f`  
    If in gps mode, then it will send a request to the gps system, otherwise it will read its internal z coordiate from a set local zero.

* `PAM.setX(x) -> true`  
    sets the x coordinate of the turtle.  
    *Arguments:*  
    x: (optional if in gps mode) a number to set the x coordinate as.

* `PAM.setY(y) -> true`  
    sets the y coordinate of the turtle.  
    *Arguments:*  
    y: (optional if in gps mode) a number to set the y coordinate as.

* `PAM.setZ(z) -> true`    
    sets the z coordinate of the turtle.    
    *Arguments:*    
    z: (optional if in gps mode) a number to set the z coordinate as.  

* `PAM.setFacing(f) -> true`  
    sets the facing of the turtle.  
    *Arguments:*  
    f: (optional if in gps mode) a number to set the facing as.

* `PAM.orientSelf(target) -> boolean`  
    turns the turtle to face a target direction.  
    *Arguments:*  
    target: the number of the direction to face. 0=north, 1=east, 2=south, 3=west.  

## UTILITY
* `PAM.init() -> nil`    
    ensures all files exist and are formatted correctly. It also lets the user input the turtle's coordinates, mainly for setting up local mode.    
    This function can be skipped after initial setup of the api, but it won't ruin anything if used afterwards.    

* `PAM.checkActInterrupt() -> boolean, reason`  
    checks if the turtle experienced a force reboot or otherwise was interrupted mid execution of an action or route.
    If interrupted, it will pick up where it left off.
    returns a true on success, or a false and reason why on fail.

* `PAM.setZeroPos() -> true`
    sets a new local zero position, including facing.
    To ensure facing data doesn't get corrupted, it will turn to face north which is f=0.

* `PAM.userMkRoute() -> nil`
    a rudimentary ui to let the user create route files.

* `PAM.mkRoute(name, data, gpsCompat) -> boolean, reason`  
    creates route files.  
    *Arguments:*  
    name: a string with the name of the route file.  
    data: a table containing all coordinate and action data of the route. every waypoint in a route MUST CONTAIN IN THIS ORDER: y,x,z,f,action.  
    gpsCompat: a boolean that defines if the route is for gps mode or local mode.

* `PAM.delRoute(name) -> boolean, reason`  
    deletes a route file.  
    *Arguments:*  
    name: a string with the name of the route file to delete.  

* `PAM.addAction(key, act) -> error`  
    adds a function to the action handler, so it can be called by the route.  
    *Arguments:*  
    key: the string used to find the right function by the action handler.  
    act: the function associated with the key. DO NOT CALL THE FUNCTION HERE, SO NO BRACKETS.

* `PAM.runRoute(name, tries, aggressive, startAt) -> error`  
    executes a route file.  
    *Arguments:*  
    name: a string with the name of the route file.  
    tries: a number of times to try to move before returning an error.  
    aggressive: a boolean for if to attack when blocked or not.  
    startAt: a number (optional and mostly used by checkActInterrupt()) that defines what step of the route to start at.

## TURTLE API REPLACEMENTS
* `PAM.down(steps, tries, aggressive) -> boolean, reason`    
    replaces turtle.down().    
    *Arguments:*    
    steps: a number of times to move down.    
    tries: the amount of times to try going down before failing    
    aggressive: a boolean for if to attack when blocked or not.

* `PAM.up(steps, tries, aggressive) -> boolean, reason`    
    replaces turtle.up().    
    *Arguments:*    
    steps: a number of times to move up.    
    tries: the amount of times to try going up before failing    
    aggressive: a boolean for if to attack when blocked or not.

* `PAM.turnLeft(times) -> boolean, reason`    
    replaces turtle.turnLeft().    
    *Arguments:*    
    times: a number of times to turn left.

* `PAM.turnRight(times) -> boolean, reason`    
    replaces turtle.turnRight().    
    *Arguments:*    
    times: a number of times to turn right.

* `PAM.back(steps, tries) -> boolean, reason`    
    replaces turtle.back().    
    *Arguments:*    
    steps: a number of times to move back.    
    tries: the amount of times to try going back before failing

* `PAM.forward(steps, tries, aggressive) -> boolean, reason`    
    replaces turtle.forward().    
    *Arguments:*    
    steps: a number of times to move forwards.    
    tries: the amount of times to try going forward before failing    
    aggressive: a boolean for if to attack when blocked or not.    

* `PAM.refuel(amount) -> boolean, reason/amount refueled`    
    replaces turtle.refule().    
    *Arguments:*    
    amount: the amount of items to consume.    
