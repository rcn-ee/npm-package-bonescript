#!/bin/bash -e

DIR=$PWD

export NODE_PATH=/usr/local/lib/node_modules

npm_options="--unsafe-perm=true --progress=false --loglevel=error --prefix /usr/local"

echo "Resetting: /usr/local/lib/node_modules/"
rm -rf /usr/local/lib/node_modules/* || true

npm_git_install () {
	if [ -d /usr/local/lib/node_modules/${npm_project}/ ] ; then
		rm -rf /usr/local/lib/node_modules/${npm_project}/ || true
	fi

	if [ -d /tmp/${git_project}/ ] ; then
		rm -rf /tmp/${git_project}/ || true
	fi

	git clone -b ${git_branch} ${git_user}/${git_project} /tmp/${git_project}
	if [ -d /tmp/${git_project}/ ] ; then
		cd /tmp/${git_project}/
		package_version=$(cat package.json | grep version | awk -F '"' '{print $4}' || true)
		git_version=$(git rev-parse --short HEAD)

		unset node_version
		node_version=$(/usr/bin/nodejs --version || true)
		case "${node_version}" in
		v0.12.*)
			patch -p1 < ${DIR}/node-i2c-v0.12.diff
			;;
#		v4.*)
#			patch -p1 < ${DIR}/node-i2c-v4-plus.diff
#			;;
#		v6.*)
#			patch -p1 < ${DIR}/node-i2c-v4-plus.diff
#			patch -p1 < ${DIR}/node-serialport-v6.diff
#			patch -p1 < ${DIR}/node-epoll-v6.diff
#			;;
		esac

		TERM=dumb ${node_bin} ${npm_bin} install -g ${npm_options}
		cd -
		rm -rf /tmp/${git_project}/
	fi

	wfile="${npm_project}-${package_version}-${git_version}-${node_version}"
	cd /usr/local/lib/node_modules/
	if [ -f ${wfile}.tar.xz ] ; then
		rm -rf ${wfile}.tar.xz || true
	fi
	tar -cJf ${wfile}.tar.xz ${npm_project}/
	cd -

	if [ ! -f ./deploy/${wfile}.tar.xz ] ; then
		cp -v /usr/local/lib/node_modules/${wfile}.tar.xz ./deploy/
		echo "New Build: ${wfile}.tar.xz"
	fi
}

npm_pkg_install () {
	if [ -d /usr/local/lib/node_modules/${npm_project}/ ] ; then
		rm -rf /usr/local/lib/node_modules/${npm_project}/ || true
	fi

	TERM=dumb ${node_bin} ${npm_bin} install -g ${npm_options} ${npm_project}@${package_version}

	#wfile="${npm_project}-${package_version}-${node_version}"
	wfile="${npm_project}-${package_version}-${node_version}-rcnee1"
	cd /usr/local/lib/node_modules/
	sed -i -e 's:var/lib/cloud9:usr/share/bone101:g' bonescript/src/server.js
	if [ -f ${wfile}.tar.xz ] ; then
		rm -rf ${wfile}.tar.xz || true
	fi
	tar -cJf ${wfile}.tar.xz ${npm_project}/
	cd -

	if [ ! -f ./deploy/${wfile}.tar.xz ] ; then
		cp -v /usr/local/lib/node_modules/${wfile}.tar.xz ./deploy/
		echo "New Build: ${wfile}.tar.xz"
	fi
}

npm_install () {
	if [ ! -f /usr/lib/libroboticscape.so ] ; then
		apt install -y roboticscape
	fi

	node_bin="/usr/bin/nodejs"
	npm_bin="/usr/bin/npm"

	unset node_version
	node_version=$(/usr/bin/nodejs --version || true)

	echo "npm: [`${node_bin} ${npm_bin} --version`]"
	echo "node: [`${node_bin} --version`]"

	npm_project="bonescript"
	git_project="bonescript"
	git_branch="master"
	git_user="https://github.com/jadonk"
	npm_git_install

#	npm_project="bonescript"
#	package_version="0.5.0"
#	npm_pkg_install
}

npm_install
