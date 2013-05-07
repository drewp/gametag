@help:
	echo try the 'run_server_with_watch' target

install_js_dependencies:
	npm install

%.js: %.coffee
	node_modules/coffee-script/bin/coffee -c $<

run_server: server/server.js
	nodejs server/server.js

run_server_with_watch:
	# this is not discovering other deps as advertised on https://github.com/fgnass/node-dev
	node_modules/node-dev/bin/node-dev server/server.coffee

server/server.js: server/sockets.js \
                  server/events.js \
                  server/print.js \
                  server/users.js \
                  server/fileserve.js \
                  shared/identifiers.js

import_game_data_to_mongo:
	mongoimport --host bang --db gametag --collection games --drop --jsonArray --file startup/games.json

install_python_deps_for_scanner:
	sudo apt-get install python-requests python-opencv python-numpy python-pyglet python-zbar

# system packages:
# mongodb-clients
# ppa:chris-lea/node.js package nodejs
