@help:
	echo try the 'run_server_with_watch' target

install_js_dependencies:
	npm install

%.js: %.coffee
	node_modules/nodefront/node_modules/coffee-script/bin/coffee -c $<

run_server: server/server.js
	nodejs server/server.js

run_server_with_watch:
	# this is not discovering other deps as advertised on https://github.com/fgnass/node-dev
	node_modules/node-dev/bin/node-dev server/server.coffee

server/server.js: server/sockets.js server/events.js
