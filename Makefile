RELEASE=4.3

# also add entry in changelog.Debian
OVSVER=2.6.0
PKGRELEASE=1

OVSDIR=openvswitch-${OVSVER}
OVSSRC=openvswitch-${OVSVER}.tar.gz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell cat .git/refs/heads/master)

DEBS=								\
	openvswitch-common_${OVSVER}-${PKGRELEASE}_${ARCH}.deb	\
	openvswitch-switch_${OVSVER}-${PKGRELEASE}_${ARCH}.deb

all: ${DEBS}
	echo ${DEBS}

deb ${DEBS}: ${OVSSRC}
	rm -rf ${OVSDIR}
	tar xf ${OVSSRC}
	cd  ${OVSDIR}; ln -s ../pvepatches patches
	cd  ${OVSDIR};	quilt push -a
	mv ${OVSDIR}/debian/changelog ${OVSDIR}/debian/changelog.org
	cat changelog.Debian ${OVSDIR}/debian/changelog.org> ${OVSDIR}/debian/changelog
	echo "git clone git://git.proxmox.com/git/openvswitch.git\\ngit checkout ${GITVERSION}" > ${OVSDIR}/debian/SOURCE
	echo "debian/SOURCE" >> ${OVSDIR}/debian/openvswitch-common.docs
	echo "debian/SOURCE" >> ${OVSDIR}/debian/openvswitch-switch.docs
	cd ${OVSDIR}; dpkg-buildpackage -b -jauto -rfakeroot -us -uc

.PHONY: download
${OVSSRC} download:
	rm -rf ${OVSDIR} ${OVSSRC}
	git clone https://github.com/openvswitch/ovs.git -b v${OVSVER} ${OVSDIR}.git
	cd ${OVSDIR}.git; git archive --format=tar.gz -o ../${OVSSRC}.tmp v${OVSVER} --prefix=${OVSDIR}/
	mv ${OVSSRC}.tmp ${OVSSRC}

.PHONY: upload
upload: ${DEBS}
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o rw
	mkdir -p /pve/${RELEASE}/extra
	rm -f /pve/${RELEASE}/extra/openvswitch-*.deb
	rm -f /pve/${RELEASE}/extra/Packages*
	cp ${DEBS} /pve/${RELEASE}/extra
	cd /pve/${RELEASE}/extra; dpkg-scanpackages . /dev/null > Packages; gzip -9c Packages > Packages.gz
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o ro

.PHONY: distclean
distclean: clean

.PHONY: clean
clean:
	rm -rf *~ ${OVSSRC}.tmp ${OVSDIR} *.deb *.changes ${OVSDIR}.git

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
