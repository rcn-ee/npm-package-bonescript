#!/bin/bash -e

export NODE_PATH=/usr/local/lib/node_modules

npm_options="--unsafe-perm=true --progress=false --loglevel=error --prefix /usr/local"

npm_git_install () {
	if [ -d /usr/local/lib/node_modules/${npm_project}/ ] ; then
		rm -rf /usr/local/lib/node_modules/${npm_project}/ || true
	fi

	wrepo="bonescript"
	if [ -d /tmp/${wrepo}/ ] ; then
		rm -rf /tmp/${wrepo}/ || true
	fi

	git clone -b 0.5.x https://github.com/jadonk/${wrepo} /tmp/${wrepo}
	if [ -d /tmp/${wrepo}/ ] ; then
		cd /tmp/${wrepo}/
		package_version=$(cat package.json | grep version | awk -F '"' '{print $4}' || true)
		git_version=$(git rev-parse --short HEAD)
		TERM=dumb ${node_bin} ${npm_bin} install -g ${npm_options}
		cd -
		rm -rf /tmp/${wrepo}/
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

npm_install () {
	node_bin="/usr/bin/nodejs"
	npm_bin="/usr/bin/npm"

	unset node_version
	node_version=$(/usr/bin/nodejs --version || true)

	echo "npm: [`${node_bin} ${npm_bin} --version`]"
	echo "node: [`${node_bin} --version`]"

	npm_project="bonescript"
	npm_git_install
}

npm_install
