@help:
	echo 

install_js_dependencies:
	npm install

%.js: %.coffee
	node_modules/nodefront/node_modules/coffee-script/bin/coffee -c $<

run_server: server/server.js
	nodejs server/server.js

server/server.js: server/sockets.js

build_all_continuously:
	#mkdir -p build
	cd server; ../node_modules/nodefront/nodefront.js serve --compile --live
	#--output ../build
