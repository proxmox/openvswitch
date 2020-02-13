# also add entry in changelog.Debian
OVSVER=2.12.0
PKGRELEASE=1

OVSDIR=openvswitch-${OVSVER}
OVSSRC=openvswitch-${OVSVER}.tar.gz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell cat .git/refs/heads/master)

DEB1=openvswitch-common_${OVSVER}-${PKGRELEASE}_${ARCH}.deb
DEB2=openvswitch-switch_${OVSVER}-${PKGRELEASE}_${ARCH}.deb
DEBS=$(DEB1) $(DEB2)

all: ${DEBS}
	echo ${DEBS}

.PHONY: deb
deb: $(DEBS)
$(DEB2): $(DEB1)
$(DEB1): ${OVSSRC}
	rm -rf ${OVSDIR}
	tar xf ${OVSSRC}
	rm -rf ${OVSDIR}/debian
	cp -rf debian ${OVSDIR}
	cd ${OVSDIR}; DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -b -jauto -us -uc

.PHONY: download
${OVSSRC} download:
	rm -rf ${OVSDIR} ${OVSSRC}
	git clone https://github.com/openvswitch/ovs.git -b v${OVSVER} ${OVSDIR}.git
	cd ${OVSDIR}.git; git archive --format=tar.gz -o ../${OVSSRC}.tmp v${OVSVER} --prefix=${OVSDIR}/
	mv ${OVSSRC}.tmp ${OVSSRC}

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS} | ssh -X repoman@repo.proxmox.com -- upload --product pve --dist stretch

.PHONY: distclean
distclean: clean

.PHONY: clean
clean:
	rm -rf *~ ${OVSSRC}.tmp ${OVSDIR} *.deb *.changes *.buildinfo ${OVSDIR}.git

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
