--Welcome to the Pathfinding Action Manager PAM 
local PAM = {};
local dataVault = "PAM/data/";

--optional initializing function to check that all files are there
function PAM.init()
    local currectFiles = {"pos.txt", "config.txt", "currentAction.txt"};
    local files = fs.list(dataVault);
    for i = 1, #currectFiles do
        if not fs.exists(currectFiles[i]) then
            local file = fs.open(fs.combine(dataVault, currectFiles[i]), "w");
            file.close();
        end
    end
    --checks if the routes directory exists
    if not fs.exists(dataVault .. "routes/") or not fs.isDir(dataVault .. "routes/") then
        fs.makeDir(dataVault .. "routes/");
    end
    --setting up the pos.txt file
    local initPosFormat = 
        {"y=", "x=", "z=", "f=", "fuel=", 
        "py=", "px=", "pz=", "pf=", "pfuel="};
    local initPos = {};
    write("init y: ");
    table.insert(initPos, read());
    write("init x: ");
    table.insert(initPos, read());
    write("init z: ");
    table.insert(initPos, read());
    print("facing: 0=north, 1=east, 2=south, 3=west");
    write("initial facing: ");
    table.insert(initPos, read());
    table.insert(initPos, turtle.getFuelLevel());
    file = fs.open(dataVault .. "pos.txt", "w");
    for i = 1, 10 do
        --format line by taking base format, then adding initPos that is being cycled through twice
        local line = initPosFormat[i] .. tostring(initPos[((i - 1) % #initPos) + 1]); 
        file.writeLine(line);
    end
    file.close();
    print("pos.txt setup complete [1/" .. #currectFiles .. "]");
    --setting up config.txt file default settings
    local configDefault = --contains the default api settings
        {"gpsMode=false",
         "gpsDestruFacingCheck=false", 
         "movTries=1",
         "movAggro=false",
         "actContiueTries=1",
         "actContinueAggro=false"}
    file = fs.open(dataVault .. "config.txt", "w");
    for i = 1, #configDefault do
        file.writeLine(configDefault[i]);
    end
    print("config.txt setup complete [2/" .. #currectFiles .. "]");
    --setting up currentAction.txt file
    local currentActionDefault = {"act=nil", "amount=0", "route=nil", "routeMov=nil"};
    file = fs.open(dataVault .. "currentAction.txt", "w");
    for i = 1, #currentActionDefault do
        file.writeLine(currentActionDefault[i]);
    end
    print("currentAction.txt setup complete [3/" .. #currectFiles .. "]");
    
    print("setup complete!");
end

--reads the data of file at the line that contains keyword
local function readData(file, keyword)
    local path = fs.combine(dataVault, file);
    if fs.exists(path) then
        local file = fs.open(path, "r");
        local line = file.readLine();
        while line do
            local match = string.match(line, "^" ..keyword.. "=(.*)");
            if match then
                file.close();
                if match == "true" then
                    return true;
                elseif match == "false" then
                    return false;
                elseif tonumber(match) then
                    return tonumber(match);
                else
                    return match;
                end
            end
            line = file.readLine();
        end
        file.close();
        return nil, "no match found";
    else
        return nil, "file not found";
    end
end

--writes data to a file at the line containing keyword
local function writeData(file, keyword, data)
    local lines = {};
    local path = fs.combine(dataVault, file);
    if fs.exists(path) then
        local file = fs.open(path, "r");
        local line = file.readLine();
        while line do
            local match = string.match(line, "^" .. keyword .. "=(.*)");
            if match then
                table.insert(lines, keyword .. "=" .. data);
            else
                table.insert(lines, line);
            end
            line = file.readLine();
        end
        file.close();
        file = fs.open(path, "w");
        for _, line in ipairs(lines) do
            file.writeLine(line);
        end
        file.close();
    else
        return nil;
    end
end

--checks if the turtle was interrupted mid action execution
--and calls action to finish
--also checks for route execution to continue
function PAM.checkActInterrupt()
    local act = readData("currentAction.txt", "act");
    local route = readData("currentAction.txt", "route");
    local routeMov = readData("currentAction.txt", "routeMov");
    local reason;
    local ok;
    local tries = readData("config.txt", "actContiueTries");
    local aggro = readData("config.txt", "actContinueAggro");
    if act ~= "nil" then
        local fuelDif = math.abs(readData("pos.txt", "pfuel") - turtle.getFuelLevel());
        local amountLeft = readData("currentAction.txt", "amount");
        if fuelDif ~= 0 then
            if act == "forward" then
                amountLeft = math.abs(readData("currentAction.txt", "amount") - fuelDif);
                ok, reason = PAM.forward(amountLeft, tries, aggro);
            elseif act == "back" then
                ok, reason = PAM.back(amountLeft, tries, aggro);
            elseif act == "up" then
                ok, reason = PAM.up(amountLeft, tries, aggro);
            elseif act == "down" then
                ok, reason = PAM.down(amountLeft, tries, aggro);
            end
        elseif act == "turnLeft" then
            ok, reason = PAM.turnLeft(amountLeft);
        elseif act == "turnRight" then
            ok, reason = PAM.turnRight(amountLeft);
        else
            writeData("currentAction.txt", "act", "nil");
        end
        if not ok then 
            return ok, reason;
        end
    end
    if route ~= "nil" then
        PAM.runRoute(route, tries, aggro, routeMov + 1);
    end
    return true;
end

--sets the pos to a new local zero point
--while turning to turtle to face north
function PAM.setZeroPos()
    local cords = {"y", "x", "z", "py", "px", "pz"};
    PAM.orientSelf(0);
    for _, cord in pairs(cords) do
        writeData("pos.txt", cord, 0);
    end
    return true;
end

--returns the x-coordinate of the turtle
function PAM.getX()
    if readData("config.txt", "gpsMode") == true then
        local gpsX, _, _ = gps.locate(2, false);
    else
        return readData("pos.txt", "x");
    end
end

--returns the y-coordinate of the turtle
function PAM.getY()
    if readData("config.txt", "gpsMode") == true then
        local _, gpsY, _ = gps.locate(2, false);
        return gpsY;
    else
        return readData("pos.txt", "y");
    end
end

--returns the z-coordinate of the turtle
function PAM.getZ()
    if readData("config.txt", "gpsMode") == true then
        local _, _, gpsZ = gps.locate(2, false);
        return gpsZ;
    else
        return readData("pos.txt", "z");
    end
end

--returns the compass facing of the turtle
--direction is 0=north, 1=east, 2=south, 3=west
function PAM.getFacing()
    if readData("config.txt", "gpsMode") == true then
        return gpsFacingCheck();
    else
        return readData("pos.txt", "f");
    end
end

--sets the x-coordinate of the turtle
function PAM.setX(x)
    if readData("config.txt", "gpsMode") == true then
        local gpsX, _, _ = gps.locate(2, false);
        writeData("pos.txt","x", gpsX);
        return true;
    else
        writeData("pos.txt", "x", x);
        return true;
    end
end

--sets the y-coordinate of the turtle
function PAM.setY(y)
    if readData("config.txt", "gpsMode") == true then
        local _, gpsY, _ = gps.locate(2, false);
        writeData("pos.txt","y", gpsY);
        return true;
    else
        writeData("pos.txt", "y", y);
        return true;
    end
end

--sets the z-coordinate of the turtle
function PAM.setZ(z)
    if readData("config.txt", "gpsMode") == true then
        local _, _, gpsZ = gps.locate(2, false)
        writeData("pos.txt","z", gpsZ);
        return true;
    else
        writeData("pos.txt", "z", z);
        return true;
    end
end

--sets the compass facing of the turtle
--direction is 0=north, 1=east, 2=south, 3=west
function PAM.setFacing(f)
    local facing = readData("pos.txt", "f");
    writeData("pos.txt", "pf", facing);
    if readData("config.txt", "gpsMode") == true then
        local ok, result = gpsFacingCheck()
        if not ok then
            return ok, result;
        else
            writeData("pos.txt", "f", result);
        end
    else
        writeData("pos.txt", "f", f);
        PAM.orientSelf(f);
    end
    return true;
end

--support function to find facing via gps
--by moving and detecting what axis and direction it moved
local function gpsFacingCheck()
    local px, _, pz = gps.locate(2, false);
    local ok, reason;
    if readData("config.txt", "gpsDestruFacingCheck") then
        local tries = readData("config.txt", "movTries");
        local aggressive = readData("config.txt", "movAggro");
        ok, reason = PAM.forward(1, tries, aggressive);
    else
        ok, reason = PAM.forward(1, 0, false);
    end
    if not ok then
        return ok, reason;
    end
    local x, _, z = gps.locate();
    if px ~= x then
        if px > x then
            return true, 3;
        else
            return true, 1;
        end
    else
        if pz > z then
            return true, 0;
        else
            return true, 2;
        end
    end
end

--refuels the turtle MUST be used for this api to work
--accepts an amount of items to consume
function PAM.refuel(amount)
    local nFuel = readData("pos.txt", "fuel");
    writeData("pos.txt", "pfuel", nFuel);
    local ok, reason = turtle.refuel(amount);
    if not ok then
        return ok, reason;
    else
        writeData("pos.txt", "fuel", turtle.getFuelLevel());
        return ok, math.abs(nFuel - turtle.getFuelLevel());
    end
end

--moves the turtle forward a set amount of steps
--trying to break blocks in front a set amount of times
--and will attack entities if aggressive is true
function PAM.forward(steps, tries, aggressive)
    local forwardNow;
    writeData("currentAction.txt", "act", "forward");
    writeData("currentAction.txt", "amount", steps);
    writeData("pos.txt", "pfuel", turtle.getFuelLevel());
    local facing = readData("pos.txt", "f");
    if facing == 0 or facing == 2 then
        forwardNow = readData("pos.txt", "z");
        writeData("pos.txt", "pz", forwardNow);
    else
        forwardNow = readData("pos.txt", "x");
        writeData("pos.txt", "px", forwardNow);
    end
    for i = 1, steps do
        if turtle.detect()then
            for j = 1, tries do
                turtle.dig();
            end
            if turtle.detect() and aggressive then
                turtle.attack();
                sleep(0.5);
            end
        end
        local ok, reason = turtle.forward();
        if not ok then
            return ok, reason;
        end
    end
    if readData("config.txt", "gpsMode") then
        local pz = readData("pos.txt", "pz");
        local _, _, z = gps.locate(2, false);
        if pz ~= z then
            writeData("pos.txt", "z", z);
        else
            local x, _, _ = gps.locate(2, false);
            writeData("pos.txt", "x", x);
        end
    else
        if facing == 0 then
            local moved = forwardNow - steps;
            writeData("pos.txt", "z", moved);
        elseif facing == 1 then
            local moved = forwardNow + steps;
            writeData("pos.txt", "x", moved);
        elseif facing == 2 then
            local moved = forwardNow + steps;
            writeData("pos.txt", "z", moved);
        else
            local moved = forwardNow - steps;
            writeData("pos.txt", "x", moved);
        end
    end
    writeData("pos.txt", "fuel", turtle.getFuelLevel());
    writeData("currentAction.txt", "act", "nil");
    return true
end

--moves the turtle backwards a set amount of steps
--trying to move back a set amount of times
function PAM.back(steps, tries)
    local backNow;
    writeData("currentAction.txt", "act", "back");
    writeData("currentAction.txt", "amount", steps);
    writeData("pos.txt", "pfuel", turtle.getFuelLevel());
    local facing = readData("pos.txt", "f");
    if facing == 0 or facing == 2 then
        backNow = readData("pos.txt", "z");
        writeData("pos.txt", "pz", backNow);
    else
        backNow = readData("pos.txt", "x");
        writeData("pos.txt", "px", backNow);
    end
    for i = 1, steps do
        local ok, reason = turtle.back();
        if not ok then
            for i = 1, tries do
                sleep(0.5);
                ok, reason = turtle.back();
                if ok then
                    break;
                end
            end
            if not ok then
                return ok, reason;
            end
        end
    end
    if readData("config.txt", "gpsMode") then
        local pz = readData("pos.txt", "pz");
        local _, _, z = gps.locate(2, false);
        if pz ~= z then
            writeData("pos.txt", "z", z);
        else
            local x, _, _ = gps.locate(2, false);
            writeData("pos.txt", "x", x);
        end
    else
        if facing == 0 then
            local moved = backNow + steps;
            writeData("pos.txt", "z", moved);
        elseif facing == 1 then
            local moved = backNow - steps;
            writeData("pos.txt", "x", moved);
        elseif facing == 2 then
            local moved = backNow - steps;
            writeData("pos.txt", "z", moved);
        else
            local moved = backNow + steps;
            writeData("pos.txt", "x", moved);
        end
    end
    writeData("pos.txt", "fuel", turtle.getFuelLevel());
    writeData("currentAction.txt", "act", "nil");
    return true;
end

--turns the turtle to the left a set amount of times
function PAM.turnLeft(times)
    writeData("currentAction.txt", "act", "turnLeft");
    writeData("currentAction.txt", "amount", times);
    local facing = readData("pos.txt", "f");
    writeData("pos.txt", "pf", facing);
    for i = 1, times do
        local ok, reason = turtle.turnLeft();
        if not ok then
            return ok, reason;
        end
        if times - i > -1 then
            writeData("currentAction.txt", "amount", times - i);
        end
    end 
    writeData("pos.txt", "f", ((facing - times) % 4));
    writeData("currentAction.txt", "act", "nil");
end

--turns the turtle to the right a set amount of times
function PAM.turnRight(times)
    writeData("currentAction.txt", "act", "turnRight");
    writeData("currentAction.txt", "amount", times);
    local facing = readData("pos.txt", "f");
    writeData("pos.txt", "pf", facing);
    for i = 1, times do
        local ok, reason = turtle.turnRight();
        if not ok then
            return ok, reason;
        end
        if times - i > -1 then
            writeData("currentAction.txt", "amount", times - i);
        end
    end 
    writeData("pos.txt", "f", (facing + times) % 4);
    writeData("currentAction.txt", "act", "nil");
    return true;
end

--moves the turtle up an amount of steps
--trying to break blocks above a set amount of times
--and will attack entities if aggressive is true 
function PAM.up(steps, tries, aggressive)
    writeData("currentAction.txt", "act", "up");
    writeData("currentAction.txt", "amount", steps);
    writeData("pos.txt", "pfuel", turtle.getFuelLevel());
    local gpsMode = readData("config.txt", "gpsMode");
    local y;
    if gpsMode then
        _, y, _ = gps.locate(2, false);
    else
        y = readData("pos.txt", "y");
    end
    writeData("pos.txt", "py", y);
    for i = 1, steps do
        if turtle.detectUp()then
            for j = 1, tries do
                turtle.digUp();
            end
            if turtle.detectUp() and aggressive then
                turtle.attackUp();
                sleep(0.5);
            end
        end
        local ok, reason = turtle.up();
        if ok ~= true then
            return ok, reason;
        end
    end
    if gpsMode then
        _, y, _ = gps.locate(2, false);
        if not y then
         return false, "y gps timeout"; 
         end
        writeData("pos.txt", "y", y);
    else
        writeData("pos.txt", "y", y + steps);
    end
    writeData("pos.txt", "fuel", turtle.getFuelLevel());
    writeData("currentAction.txt", "act", "nil");
    return true
end

--moves the turtle down an amount of steps
--trying to break blocks above a set amount of times
--and will attack entities if aggressive is true 
function PAM.down(steps, tries, aggressive)
    writeData("currentAction.txt", "act", "down");
    writeData("currentAction.txt", "amount", steps);
    writeData("pos.txt", "pfuel", turtle.getFuelLevel());
    local y = readData("pos.txt", "y");
    writeData("pos.txt", "py", y);
    for i = 1, steps do
        if turtle.detectDown()then
            for j = 1, tries do
                turtle.digDown();
            end
            if turtle.detectDown() and aggressive then
                turtle.attackDown();
                sleep(0.5);
            end
        end
        local ok, reason = turtle.down();
        if not ok then
            return ok, reason;
        end
    end
    if readData("config.txt", "gpsMode") == true then
        _, y, _ = gps.locate(2, false);
        writeData("pos.txt", "y", y);
    else
        writeData("pos.txt", "y", y - steps);
    end
    writeData("pos.txt", "fuel", turtle.getFuelLevel());
    writeData("currentAction.txt", "act", "nil");
    return true
end

--support function to user input of route file name
local function inputName()
    local name = read();
    if not string.find(name, ".txt") then
        name = name .. ".txt";
        print("upsy, you wrote a bad name. I fixed it for you :3");
    end
    return name;
end

--the function to let the user create routes
--via waypoints, and encoding that into a custom route file
function PAM.userMkRoute()
    local userInput;
    local name;
    local data = {};
    local gpsMode;
    print("Welcome to the route maker. Here you can manually create routes");
    print("Start by writing the name of the route.");
    while userInput ~= "y" do
        write("Name of route: ");
        name = inputName();
        if fs.exists(fs.combine(dataVault, "routes/", name)) then
            print("Name already in use");
            goto continue;
        end
        write("Confirm name? [y/n]: ");
        userInput = string.lower(read());
        ::continue::
    end
    print("Is this route for gps mode? [y/n]: ");
    userInput = string.lower(read());
    if userInput == "y" then
        gpsMode = "true";
    else
        gpsMode = "false";
    end
    userInput = nil;
    local waypoints = 0;
    print("Next, the coordinates of the waypoints.");
    print("facing cheatsheet; 0=north, 1=east, 2=south, 3=west");
    while userInput ~= "n" do
        write("y" .. waypoints .. ": ");
        userInput = string.lower(read());
        table.insert(data, userInput);
        write("x" .. waypoints .. ": ");
        userInput = string.lower(read());
        table.insert(data, userInput);
        write("z" .. waypoints .. ": ");
        userInput = string.lower(read());
        table.insert(data, userInput);
        write("facing" .. waypoints .. ": ");
        userInput = string.lower(read());
        table.insert(data, userInput);
        print("add an action to this waypoint? [y/n]: ");
        userInput = string.lower(read());
        if userInput == "y" then
            write("name of function: ")
            userInput = string.lower(read());
            table.insert(data, userInput);
        else
            table.insert(data, "nil");
        end
        write("add another waypoint? [y/n]: ");
        userInput = string.lower(read());
        waypoints = waypoints + 1;
    end
    PAM.mkRoute(name, data, gpsMode);
end

--base function to create a route file and fill it with data
--requires a name and a table of data
function PAM.mkRoute(name, data, gpsCompat)
    local format = {"y", "x", "z", "f", "act"};
    local waypoints = 0;
    if not string.find(name, ".txt") then
        name = name .. ".txt";
        print("upsy, you wrote a bad name. I fixed it for you :3");
    end
    local path = fs.combine(dataVault, "routes/", name);
    if #data % #format ~= 0 then
        return false, "incomplete coordinate data";
    elseif fs.exists(path) then
        return false, "file already exists";
    end
    local file = fs.open(path, "w");
    file.writeLine("gpsCompat=" .. gpsCompat);
    for i = 1, #data do
        if ((i - 1) % #format) + 1 == 1 then
            waypoints = waypoints + 1;
        end
        file.writeLine(format[((i - 1) % #format) + 1] .. waypoints .. "=" .. data[i]);
    end
    return true;
end

--finds and deletes a route file
function PAM.delRoute(name)
    if not string.find(name, ".txt") then
        name = name .. ".txt";
        print("upsy, you wrote a bad name. I fixed it for you :3");
    end
    local path = fs.combine(dataVault, "routes/", name);
    if not fs.exists(path) then
        return false, "file does not exist";
    else
        fs.delete(path);
        return true;
    end
end

--executes a route from its current position
--this is the beginning of the actual pathfinding
--call this as a coroutine.create when you want to follow a route
local doRoute = function (name, tries, aggressive, startAt)
    if not string.find(name, ".txt") then
        name = name .. ".txt";
    end
    local path = fs.combine("routes/", name);
    print(path);
    if not fs.exists(dataVault .. path) then --checks if the file exists'
        return false, "file does not exist";
    end
    writeData("currentAction.txt", "route", name);
    local route = {};
    local format = {"y", "x", "z", "f", "act"};
    local line = "som";
    local reason;
    local waypoints = 0;
    local i = 1;
    while line ~= nil do
        if ((i - 1) % #format) + 1 == 1 then --controls right formatting for keyword
            waypoints = waypoints + 1;
        end
        line, reason = readData(path, format[((i - 1) % #format) + 1] .. waypoints);
        if line ~= nil then
            table.insert(route, line);
        end
        i = i + 1;
    end
    
    --checks if gps is on and should be on, if not then returns errors
    local gpsCompat = readData(path, "gpsCompat");
    local gpsMode = readData("config.txt", "gpsMode");
    local gpsOn = false;
    if gpsCompat and gpsMode then
        gpsOn = true;
    elseif gpsCompat and not gpsMode then
        return false, "gpsMode off for gps route";
    elseif not gpsCompat and gpsMode then
        return false, "gpsMode on for gps incompatible route";
    end
    local f = readData("pos.txt", "f");
    local dir;--direction is 0=north, 1=east, 2=south, 3=west
    local tDir;
    local ok, reason;
    for i = startAt, #route do
        local action = format[((i - 1) % #format) + 1];
        writeData("currentAction.txt", "routeMov", i);
        if action == "act" then
            if route[i] ~= "nil" then
                coroutine.yield("PAM_ACTION", route[i]); --return the name of the action to perform
            end
        elseif action == "y" then
            local y;
            if gpsOn then
                for j = 1, tries do
                    _, y, _ = gps.locate(2, false);
                    if y then break; end
                end
                if not y then
                    return false, "y gps timeout";
                end
            else
                y = readData("pos.txt", "y");
            end
            local yDif = math.abs(y - route[i]);
            if route[i] > y then
                ok, reason = PAM.up(yDif, tries, aggressive);
            else
                 ok, reason = PAM.down(yDif, tries, aggressive);
            end
            if not ok then return ok, reason; end
        elseif action == "x" then
            local x;
            if gpsOn then
                for j = 1, tries do
                    x, _, _ = gps.locate(2, false);
                    if x then
                     break; 
                     end
                end
                if not x then
                    return false, "x gps timeout";
                end
            else
                x = readData("pos.txt", "x");
            end
            local xDif = math.abs(x - route[i]);
            if route[i] > x then
                dir = 1;
            else
                dir = 3;
            end
            PAM.orientSelf(dir);
            ok, reason = PAM.forward(xDif, tries, aggressive);
            if not ok then return ok, reason; end
        elseif action == "z" then
            local z;
            if gpsOn then
                for j = 1, tries do
                    _, _, z = gps.locate(2, false);
                    if z then break; end
                end
                if not z then
                    return false, "z gps timeout";
                end
            else
                z = readData("pos.txt", "z");
            end
            local zDif = math.abs(z - route[i]);
            if route[i] > z then
                dir = 2;
            else
                dir = 0;
            end
            PAM.orientSelf(dir);
            ok, reason = PAM.forward(zDif, tries, aggressive);
            if not ok then return ok, reaon; end
        elseif format[((i - 1) % #format) + 1] == "f" then
            PAM.orientSelf(route[i]);
        else
            return false, "incompatible route format"
        end
    end
    writeData("currentAction.txt", "route", "nil");
    return true;
end

--helper function that 
--turns the turtle to face the target direction
function PAM.orientSelf(target)
    local facing = readData("pos.txt", "f");
    local rightTurns = (target - facing) % 4;
    if rightTurns == 3 then
        PAM.turnLeft(1);
    elseif rightTurns > 0 and rightTurns < 3 then
        PAM.turnRight(rightTurns);
    else
        return false;
    end
    return true;
end

local actionHandlers = {};

--adds action functions to the actionHandlers table
--needs a key to grab the action name later,
--and the action function WITHOUT BRACKETS
function PAM.addAction(key, act)
    if type(act) ~= "function" then
        error("expected function got " .. type(act));
    end
    actionHandlers[key] = act;
end

--driver function for the doRoute function.
--called to initiate the execution of a route
function PAM.runRoute(name, tries, aggressive, startAt)
    if type(startAt) ~= "number" then 
        startAt = 1;
    end
    local route = coroutine.create(doRoute);
    local ok, filter, payload = coroutine.resume(route, name, tries, aggressive, startAt);
    if not ok then error(filter); end
    while coroutine.status(route) ~= "dead" do
        if filter == "PAM_ACTION" then
            local handler = actionHandlers[payload];
            if handler then handler(); end
            ok, filter, payload = coroutine.resume(route);
        else
            local ev = {os.pullEventRaw()};
            if filter == nil or ev[1] == filter then
                ok, filter, payload = coroutine.resume(route, table.unpack(ev));
            end
        end
        if not ok then error(filter); end
    end
end
return PAM;
