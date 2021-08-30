include xen-4.16-dunfell.inc

PACKAGECONFIG_append = " \
    xsm \
"

FILES_${PN}-flask = " \
    /boot/xenpolicy-${XEN_REL}* \
"

RDEPENDS_${PN} += "${PN}-devd"

PACKAGES_append = "\
    ${PN}-libxenhypfs \
    ${PN}-libxenhypfs-dev \
    ${PN}-xenhypfs \
    ${PN}-xen-access \
    "

FILES_${PN}-xenhypfs = "\
    ${sbindir}/xenhypfs \
    "

FILES_${PN}-libxenhypfs = "${libdir}/libxenhypfs.so.*"
FILES_${PN}-libxenhypfs-dev = " \
    ${libdir}/libxenhypfs.so \
    ${libdir}/pkgconfig/xenhypfs.pc \
    "

FILES_${PN}-libxendevicemodel = "${libdir}/libxendevicemodel.so.*"
FILES_${PN}-libxendevicemodel-dev = " \
    ${libdir}/libxendevicemodel.so \
    ${libdir}/pkgconfig/xendevicemodel.pc \
    "

FILES_${PN}-misc_append = "\
    ${libdir}/xen/bin/depriv-fd-checker \
    ${libdir}/xen/bin/test-resource \
    ${libdir}/xen/bin/test-xenstore \
    ${bindir}/vchan-socket-proxy \
    "

FILES_${PN}-xl += "\
    ${sysconfdir}/bash_completion.d \
    "

FILES_${PN}-xl-examples += "\
    ${sysconfdir}/xen/xlexample.pvhlinux \
    "

FILES_${PN}-xen-access += "\
    ${sbindir}/xen-access \
    "

do_install_append() {
    # FIXME: this is to fix QA Issue with pygrub:
    # ... pygrub maximum shebang size exceeded, the maximum size is 128. [shebang-size]
    rm -f ${D}/${bindir}/pygrub
    rm -f ${D}/${libdir}/xen/bin/pygrub

    rm -f ${D}/${systemd_unitdir}/system/xen-qemu-dom0-disk-backend.service
}

FILES_${PN}-xencommons_remove = "\
    ${systemd_unitdir}/system/xen-qemu-dom0-disk-backend.service \
"

SYSTEMD_SERVICE_${PN}-xencommons_remove = " \
    xen-qemu-dom0-disk-backend.service \
"
