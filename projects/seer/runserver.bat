pushd
cd ..\..\
REM *** Start up the redis server first - this will be external on the www server ***
start ..\blog-redis\redis-server.exe --protected-mode no
REM *** Start up our web server ***
./luvit projects/seer/server/server.lua "projects/seer"
popd