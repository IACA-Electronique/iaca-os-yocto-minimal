SUMMARY = "Deploy custom assets"
LICENSE = "CLOSED"

SRC_URI = " \
    file://16GB.json \
    file://16GB_a_b.json \
"

inherit deploy

do_deploy() {
    install -d ${DEPLOYDIR}

    install -m 0644 ${WORKDIR}/16GB.json ${DEPLOYDIR}/16GB.json
    install -m 0644 ${WORKDIR}/16GB_a_b.json ${DEPLOYDIR}/16GB_a_b.json
}

addtask deploy after do_install before do_build