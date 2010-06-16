DOCTOR_DIR=/source/webos_doctors
ROOT=${DOCTOR_DIR}/root-1.4.1
PWD=$(shell pwd)
PATCH_FILE=${PWD}/add-onscreen-keyboard.patch

.PHONY: all
all: stock apply

.PHONY: stock
stock: ${ROOT}

.PHONY: apply
apply: build/.patch-applied
build/.patch-applied:
	@mkdir -p build
	@patch --no-backup-if-mismatch -p1 -d ${ROOT}/ -i ${PATCH_FILE}
	@cp -a additional_files/* ${ROOT}/
	@touch $@

.PHONY: generate
generate:
	@mkdir -p build
	@touch build/.patch-applied
	@rm -f ${PATCH_FILE}
	@rm -rf additional_files
	@rm -f files
	@cd ${ROOT} && git ls-files -mo --exclude-standard > ${PWD}/files
	@cd ${ROOT} && git add -u && git diff --cached > ${PATCH_FILE} && git reset
	@cd ${ROOT} && \
		for i in `git ls-files -o --exclude-standard`; do \
			mkdir -p `dirname ${PWD}/additional_files/$$i`; \
			cp $$i ${PWD}/additional_files/$$i; \
		done

${DOCTOR_DIR}/root-1.4.1: ${DOCTOR_DIR}/webosdoctor-1.4.1.jar
	@mkdir -p $@
	@if [ -e $< ]; then \
		unzip -p $< resources/webOS.tar | \
		tar -O -x -f - ./nova-cust-image-castle.rootfs.tar.gz | \
		tar -C $@ -m -z -x -f - ./usr; \
	fi
	@rm -f `find $@ -type l`
	@cd $@ && git init && git add . && git commit -a -m"Initial Commit" && git tag stock

.PRECIOUS: ${DOCTOR_DIR}/webosdoctor-1.4.1.jar
${DOCTOR_DIR}/webosdoctor-1.4.1.jar:
	mkdir -p ${DOCTOR_DIR}
	curl -L -o $@ http://palm.cdnetworks.net/rom/pre/p1411r0d03312010/sr1ntp1411rod/webosdoctorp100ewwsprint.jar

clobber:
	@rm -rf build files
	@cd ${ROOT} && git reset --hard && git clean -d -f
