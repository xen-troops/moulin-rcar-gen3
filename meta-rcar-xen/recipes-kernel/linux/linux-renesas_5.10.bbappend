FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = " \
    file://xen-chosen.dtsi;subdir=git/arch/${ARCH}/boot/dts/renesas \
    file://0001-dma-mapping-handle-vmalloc-addresses-in-dma_common_-.patch \
"

python __anonymous () {
    new_dtbs = []
    d.setVar("OLD_KERNEL_DEVICETREE", d.getVar("KERNEL_DEVICETREE"))
    for dtb in (d.getVar("KERNEL_DEVICETREE") or "").split():
        new_dtbs.append(dtb[:-4] + "-xen.dtb")
    d.setVar("KERNEL_DEVICETREE", " ".join(new_dtbs))
}

# Generate device trees for boot with xen
# This task will generate ${DTS}-xen.dts for every ${KERNEL_DEVICETREE}
# Newly generate dts will include xen-chosen.dtsi
python do_generate_dtses () {
    dts_path = d.expand("${S}/arch/${ARCH}/boot/dts/")
    for dtb in (d.getVar("OLD_KERNEL_DEVICETREE") or "").split():
        dts = dtb[:-3] + "dts"
        new_dts = dts[:-4] + "-xen.dts"
        dts_lines = open(os.path.join(dts_path, dts)).readlines()
        with open(os.path.join(dts_path, new_dts), "wt") as f:
            for l in dts_lines:
                # insert include just before "/ {"
                if l.strip() == "/ {":
                    f.write('#include "xen-chosen.dtsi"\n')
                f.write(l)
}

addtask generate_dtses before do_compile after do_configure
