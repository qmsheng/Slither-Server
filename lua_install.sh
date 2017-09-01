#!/bin/bash

# install lpack,lbase64 via luarocks lua-websockets lua-ev xxtea
./bin/openresty/luajit/bin/luarocks install lua-cjson
./bin/openresty/luajit/bin/luarocks install luasocket
./bin/openresty/luajit/bin/luarocks install process --from=http://mah0x211.github.io/rocks/

./bin/openresty/luajit/bin/luarocks install lpack
./bin/openresty/luajit/bin/luarocks install lbase64
./bin/openresty/luajit/bin/luarocks install lua-websockets
./bin/openresty/luajit/bin/luarocks install lua-ev
./bin/openresty/luajit/bin/luarocks install xxtea
./bin/openresty/luajit/bin/luarocks install utf8
./bin/openresty/luajit/bin/luarocks install lapis

echo "DONE!"
echo ""
