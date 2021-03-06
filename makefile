@help:
	echo try the 'run_server_with_watch' target

tests_on_running_server:
	node_modules/mocha/bin/mocha --compilers coffee:coffee-script test/testAdmin.coffee

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
                  server/userview.js \
                  server/fileserve.js \
                  shared/identifiers.js \
                  server/access.js  \
                  shared/points.js

import_game_data_to_mongo:
	mongoimport --host $(or $(GAMETAG_MONGODB),localhost) --db gametag --collection games --drop --jsonArray --file startup/games.json

install_python_deps_for_scanner:
	sudo apt-get install python-requests python-opencv python-numpy python-pyglet python-zbar

fix_intel_gfx:
	sudo apt-get purge nvidia*
	sudo apt-get install --reinstall xserver-xorg-video-intel libgl1-mesa-glx libgl1-mesa-dri xserver-xorg-core
	sudo dpkg-reconfigure xserver-xorg
	sudo update-alternatives --remove gl_conf /usr/lib/nvidia-current/ld.so.conf

# system packages:
# mongodb-clients
# ppa:chris-lea/node.js package nodejs
