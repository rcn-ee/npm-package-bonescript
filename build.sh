#!/bin/bash -e

DIR=$PWD

distro=$(lsb_release -cs)

git config --global user.name "Robert Nelson"
git config --global user.email robertcnelson@gmail.com

export NODE_PATH=/usr/local/lib/node_modules

echo "Resetting: /usr/bin/npm"
rm -rf /usr/bin/npm || true
rm -rf /usr/lib/node_modules/npm/ || true

apt update
apt upgrade
apt install nodejs --reinstall

echo "Resetting: /usr/local/lib/node_modules/"
rm -rf /usr/local/lib/node_modules/* || true

#echo "npm: [/usr/bin/npm i -g npm@4.6.1]"
#/usr/bin/npm i -g npm@4.6.1

cd ../
#echo "Installing: npm-4.6.1.tgz from source"
#wget -c https://registry.npmjs.org/npm/-/npm-4.6.1.tgz

echo "Installing: npm-6.3.0.tgz from source"
wget -c https://registry.npmjs.org/npm/-/npm-6.3.0.tgz

if [ -d ./package/ ] ; then
	rm -rf ./package/
fi
#tar xf npm-4.6.1.tgz

tar xf npm-6.3.0.tgz

cd ./package/
#make install
make link
cd ../
cd ./npm-package-bb-doc-bone101/

echo "npm-deb: [`${node_bin} /usr/bin/npm --version`]"

if [ -f /usr/lib/node_modules/npm/bin/npm-cli.js ] ; then
	echo "npm4-/usr/lib/: [`${node_bin} /usr/lib/node_modules/npm/bin/npm-cli.js --version`]"
fi
if [ -f /usr/local/lib/node_modules/npm/bin/npm-cli.js ] ; then
	echo "npm4-/usr/local/lib/: [`${node_bin} /usr/local/lib/node_modules/npm/bin/npm-cli.js --version`]"
fi

npm_pre_options="--unsafe-perm=true --loglevel=error --prefix /tmp"
npm_options="--unsafe-perm=true --loglevel=error --prefix /usr/local"


npm_git_install () {
	if [ -d /usr/local/lib/node_modules/${npm_project}/ ] ; then
		echo "Resetting: /usr/local/lib/node_modules/${npm_project}/"
		rm -rf /usr/local/lib/node_modules/${npm_project}/ || true
	fi

	if [ -d /tmp/${git_project}/ ] ; then
		echo "Resetting: /tmp/${git_project}/"
		rm -rf /tmp/${git_project}/ || true
	fi

	echo "Cloning: ${git_user}/${git_project}"
	git clone -b ${git_branch} ${git_user}/${git_project} /tmp/${git_project}
	if [ -d /tmp/${git_project}/ ] ; then
		cd /tmp/${git_project}/
		if [ ! "x${git_sha}" = "x" ] ; then
			git checkout ${git_sha}
			unset git_sha
		fi

		package_version=$(cat package.json | grep version | awk -F '"' '{print $4}' || true)
		git_version=$(git rev-parse --short HEAD)

		unset node_version
		node_version=$(/usr/bin/nodejs --version || true)
#		case "${node_version}" in
#		v6.*)
#			patch -p1 < ${DIR}/node-serialport-v6.diff
#			;;
#		v8.*)
#			patch -p1 < ${DIR}/node-serialport-v8.diff
#			;;
#		esac
		#patch -p1 < ${DIR}/0001-RFC-move-default-port-80-to-8000.patch

		#https://techsparx.com/nodejs/news/2017/npm5-major-error.html
		TERM=dumb ${node_bin} ${npm_bin} pack
		cd ${DIR}/
		TERM=dumb ${node_bin} ${npm_bin} install -g /tmp/${git_project}/*.tgz ${npm_options} --no-save
	fi

	echo "Packaging: ${npm_project}"
	time=$(date +%Y%m%d)
	wfile="${npm_project}-${package_version}-${git_version}-${node_version}-${time}"
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

	if [ -d /tmp/lib/node_modules/${npm_project}/ ] ; then
		rm -rf /tmp/lib/node_modules/${npm_project}/ || true
	fi

	#https://techsparx.com/nodejs/news/2017/npm5-major-error.html
	TERM=dumb ${node_bin} ${npm_bin} install -g ${npm_pre_options} ${npm_project}@${package_version}
	cd /tmp/lib/node_modules/${npm_project}/
	TERM=dumb ${node_bin} ${npm_bin} pack
	cd ${DIR}/
	TERM=dumb ${node_bin} ${npm_bin} install -g /tmp/lib/node_modules/${npm_project}/*.tgz ${npm_options} --no-save

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
	if [ ! -f /usr/lib/librobotcontrol.so ] ; then
		apt install -y librobotcontrol
	fi

	node_bin="/usr/bin/nodejs"
	if [ -f /usr/local/lib/node_modules/npm/bin/npm-cli.js ] ; then
		npm_bin="/usr/local/lib/node_modules/npm/bin/npm-cli.js"
	else
		npm_bin="/usr/lib/node_modules/npm/bin/npm-cli.js"
	fi

	unset node_version
	node_version=$(${node_bin} --version || true)

	unset npm_version
	npm_version=$(${node_bin} ${npm_bin} --version || true)


	echo "npm: [`${node_bin} ${npm_bin} --version`]"
	echo "node: [`${node_bin} --version`]"

	npm_project="bonescript"
	git_project="bonescript"
	git_branch="master"
	git_sha="b968db7a2e051e4c7eae0accf113c13db1ef7ef7"
	git_user="https://github.com/jadonk"
	npm_git_install

	npm_project="winston"
	package_version="2.1.1"
	npm_pkg_install
}

npm_install
