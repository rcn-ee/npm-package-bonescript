#!/bin/bash -e

DIR=$PWD

distro=$(lsb_release -cs)

git config --global user.name "Robert Nelson"
git config --global user.email robertcnelson@gmail.com

export NODE_PATH=/usr/local/lib/node_modules

rm -rf /usr/bin/npm || true
rm -rf /usr/lib/node_modules/npm/ || true

apt install nodejs --reinstall

echo "npm: [npm i -g npm@4.6.1]"
npm i -g npm@4.6.1

npm_options="--unsafe-perm=true --progress=false --loglevel=error --prefix /usr/local"

echo "Resetting: /usr/local/lib/node_modules/"
rm -rf /usr/local/lib/node_modules/* || true

npm_git_install () {
	if [ -d /usr/local/lib/node_modules/${npm_project}/ ] ; then
		echo "Resetting: /usr/local/lib/node_modules/${npm_project}/"
		rm -rf /usr/local/lib/node_modules/${npm_project}/ || true
	fi

	if [ -d /tmp/${git_project}/ ] ; then
		echo "Resetting: /tmp/${git_project}/"
		rm -rf /tmp/${git_project}/ || true
	fi

	git clone -b ${git_branch} ${git_user}/${git_project} /tmp/${git_project}
	if [ -d /tmp/${git_project}/ ] ; then
		echo "Cloning: ${git_user}/${git_project}"
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
		v6.*)
			patch -p1 < ${DIR}/node-serialport-v6.diff
			;;
		v8.*)
			patch -p1 < ${DIR}/node-serialport-v8.diff
			;;
		esac

		TERM=dumb ${node_bin} ${npm_bin} install -g ${npm_options}
		cd ${DIR}/
	fi

	echo "Packaging: ${npm_project}"
	wfile="${npm_project}-${package_version}-${git_version}-${node_version}"
	cd /usr/local/lib/node_modules/
	if [ -f ${wfile}.tar.xz ] ; then
		rm -rf ${wfile}.tar.xz || true
	fi
	tar -cJf ${wfile}.tar.xz ${npm_project}/
	cd ${DIR}/

	if [ ! -f ./deploy/${distro}/${wfile}.tar.xz ] ; then
		cp -v /usr/local/lib/node_modules/${wfile}.tar.xz ./deploy/${distro}/
		echo "New Build: ${wfile}.tar.xz"
	fi

	if [ -d /tmp/${git_project}/ ] ; then
		rm -rf /tmp/${git_project}/
	fi
}

npm_pkg_install () {
	if [ -d /usr/local/lib/node_modules/${npm_project}/ ] ; then
		rm -rf /usr/local/lib/node_modules/${npm_project}/ || true
	fi

	TERM=dumb ${node_bin} ${npm_bin} install -g ${npm_options} ${npm_project}@${package_version}

	wfile="${npm_project}-${package_version}-${node_version}"
	cd /usr/local/lib/node_modules/
	if [ -f ${wfile}.tar.xz ] ; then
		rm -rf ${wfile}.tar.xz || true
	fi
	tar -cJf ${wfile}.tar.xz ${npm_project}/
	cd ${DIR}/

	if [ ! -f ./deploy/${distro}/${wfile}.tar.xz ] ; then
		cp -v /usr/local/lib/node_modules/${wfile}.tar.xz ./deploy/${distro}/
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
	node_version=$(${node_bin} --version || true)

	unset npm_version
	npm_version=$(${node_bin} ${npm_bin} --version || true)


	echo "npm: [`${node_bin} ${npm_bin} --version`]"
	echo "node: [`${node_bin} --version`]"

	npm_project="bonescript"
	git_project="bonescript"
	git_branch="master"
	git_user="https://github.com/jadonk"
	npm_git_install

	npm_project="winston"
	package_version="2.1.1"
	npm_pkg_install
}

npm_install
