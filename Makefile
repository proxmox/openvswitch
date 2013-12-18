RELEASE=3.1

OVSVER=2.0.90
PKGRELEASE=1

OVSDIR=openvswitch-${OVSVER}
OVSSRC=openvswitch-${OVSVER}.tar.gz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)

DEBS=								\
	openvswitch-common_${OVSVER}-${PKGRELEASE}_${ARCH}.deb	\
	openvswitch-switch_${OVSVER}-${PKGRELEASE}_${ARCH}.deb

all: ${DEBS}
	echo ${DEBS}


${DEBS}: ${OVSSRC}
	rm -rf ${OVSDIR}
	tar xf ${OVSSRC}
	cd  ${OVSDIR}; patch -p1 <../remove-unneeded-from-control.patch
	cd ${OVSDIR}; dpkg-buildpackage -b -rfakeroot -us -uc	

.PHONY: download
${OVSSRC} download:
	rm -rf ${OVSDIR} ${OVSSRC}
	git clone git://git.openvswitch.org/openvswitch ${OVSDIR}
	rm -rf ${OVSDIR}/.git
	tar czf ${OVSSRC}.tmp ${OVSDIR}
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
	rm -rf *~ ${OVSSRC}.tmp ${OVSDIR} *.deb *.changes

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
