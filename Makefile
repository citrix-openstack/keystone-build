USE_BRANDING := yes
IMPORT_BRANDING := yes
ifdef B_BASE
include $(B_BASE)/common.mk
include $(B_BASE)/rpmbuild.mk
REPO := /repos/keystone-build
KEYSTONE_UPSTREAM := /repos/keystone
KEYSTONECLIENT_UPSTREAM := /repos/python-keystoneclient
KEYSTONECLIENT_BUILD := /repos/python-keystoneclient-build
else
COMPONENT := keystone
include ../../mk/easy-config.mk
REPO := .
KEYSTONE_UPSTREAM := ../keystone
KEYSTONECLIENT_UPSTREAM := ../python-keystoneclient
KEYSTONECLIENT_BUILD := ../python-keystoneclient-build
endif


KEYSTONE_VERSION := $(shell python $(KEYSTONE_UPSTREAM)/setup.py --version)
KEYSTONE_FULLNAME := openstack-keystone-$(KEYSTONE_VERSION)-$(BUILD_NUMBER)
KEYSTONE_SPEC := $(MY_OBJ_DIR)/openstack-keystone.spec
KEYSTONE_RPM_TMP_DIR := $(MY_OBJ_DIR)/RPM_BUILD_DIRECTORY/tmp/openstack-keystone
KEYSTONE_RPM_TMP := $(MY_OBJ_DIR)/RPMS/noarch/$(KEYSTONE_FULLNAME).noarch.rpm
KEYSTONE_TARBALL := $(MY_OBJ_DIR)/SOURCES/$(KEYSTONE_FULLNAME).tar.gz
KEYSTONE_RPM := $(MY_OUTPUT_DIR)/RPMS/noarch/$(KEYSTONE_FULLNAME).noarch.rpm
KEYSTONE_SRPM := $(MY_OUTPUT_DIR)/SRPMS/$(KEYSTONE_FULLNAME).src.rpm

KEYSTONECLIENT_VERSION := $(shell python $(KEYSTONECLIENT_UPSTREAM)/setup.py --version)
KEYSTONECLIENT_FULLNAME := python-keystoneclient-$(KEYSTONECLIENT_VERSION)-$(BUILD_NUMBER)
KEYSTONECLIENT_SPEC := $(MY_OBJ_DIR)/python-keystoneclient.spec
KEYSTONECLIENT_TARBALL := $(MY_OBJ_DIR)/SOURCES/$(KEYSTONECLIENT_FULLNAME).tar.gz
KEYSTONECLIENT_RPM := $(MY_OUTPUT_DIR)/RPMS/noarch/$(KEYSTONECLIENT_FULLNAME).noarch.rpm
KEYSTONECLIENT_SRPM := $(MY_OUTPUT_DIR)/SRPMS/$(KEYSTONECLIENT_FULLNAME).src.rpm

DEB_KEYSTONE_VERSION := $(shell head -1 $(REPO)/upstream/debian/changelog | \
                          sed -ne 's,^.*(\(.*\)).*$$,\1,p')
KEYSTONE_DEB := $(MY_OUTPUT_DIR)/keystone_$(DEB_KEYSTONE_VERSION)_all.deb
KEYSTONE_DOC_DEB := $(MY_OUTPUT_DIR)/keystone-doc_$(DEB_KEYSTONE_VERSION)_all.deb
PYTHON_KEYSTONE_DEB := $(MY_OUTPUT_DIR)/python-keystone_$(DEB_KEYSTONE_VERSION)_all.deb

EPEL_RPM_DIR := $(CARBON_DISTFILES)/epel5
EPEL_YUM_DIR := $(MY_OBJ_DIR)/epel5

EPEL_REPOMD_XML := $(EPEL_YUM_DIR)/repodata/repomd.xml
REPOMD_XML := $(MY_OUTPUT_DIR)/repodata/repomd.xml

DEBS := $(KEYSTONE_DEB) $(KEYSTONE_DOC_DEB) $(PYTHON_KEYSTONE_DEB)
RPMS := $(KEYSTONE_RPM) $(KEYSTONE_SRPM) \
        $(KEYSTONECLIENT_RPM) $(KEYSTONECLIENT_SRPM)
OUTPUT := $(RPMS) $(REPOMD_XML)

.PHONY: build
build: $(OUTPUT)

.PHONY: debs
debs: $(DEBS)

$(KEYSTONE_DOC_DEB): $(KEYSTONE_DEB)
$(PYTHON_KEYSTONE_DEB): $(KEYSTONE_DEB)
$(KEYSTONE_DEB): $(shell find $(REPO)/upstream -type f)
	@if ls $(REPO)/*.deb >/dev/null 2>&1; \
	then \
	  echo "Refusing to run with .debs in $(REPO)." >&2; \
	  exit 1; \
	fi
	cd $(REPO)/upstream; \
	  DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -us -uc -d -b
	mv $(REPO)/*.deb $(@D)
	rm $(REPO)/*.changes
	# The log files end up newer than the .debs, so we never reach a
	# fixed point given this rule's dependency unless we remove them.
	rm $(REPO)/upstream/debian/*.debhelper.log

$(KEYSTONE_SRPM): $(KEYSTONE_RPM)
$(KEYSTONE_RPM): $(KEYSTONE_SPEC) $(KEYSTONE_TARBALL) $(EPEL_REPOMD_XML) \
	     $(shell find $(REPO)/openstack-keystone -type f)
	cp -f $(REPO)/openstack-keystone/* $(MY_OBJ_DIR)/SOURCES
	sh build-keystone.sh $@ $< $(MY_OBJ_DIR)/SOURCES

$(MY_OBJ_DIR)/%.spec: $(REPO)/openstack-keystone/%.spec.in
	mkdir -p $(dir $@)
	$(call brand,$^) >$@
	sed -e 's,@KEYSTONE_VERSION@,$(KEYSTONE_VERSION),g' -i $@

$(KEYSTONE_TARBALL): $(shell find $(KEYSTONE_UPSTREAM) -type f)
	rm -rf $@ $(MY_OBJ_DIR)/openstack-keystone-$(KEYSTONE_VERSION)
	mkdir -p $(@D)
	cp -a $(KEYSTONE_UPSTREAM) $(MY_OBJ_DIR)/openstack-keystone-$(KEYSTONE_VERSION)
	tar -C $(MY_OBJ_DIR) -czf $@ openstack-keystone-$(KEYSTONE_VERSION)

$(KEYSTONECLIENT_SRPM): $(KEYSTONECLIENT_RPM)
$(KEYSTONECLIENT_RPM): $(KEYSTONECLIENT_SPEC) $(KEYSTONECLIENT_TARBALL) \
		       $(shell find $(KEYSTONECLIENT_BUILD) -type f)
	cp -f $(KEYSTONECLIENT_BUILD)/* $(MY_OBJ_DIR)/SOURCES
	sh build-keystone.sh $@ $< $(MY_OBJ_DIR)/SOURCES

$(MY_OBJ_DIR)/%.spec: $(KEYSTONECLIENT_BUILD)/%.spec.in
	mkdir -p $(dir $@)
	$(call brand,$^) >$@
	sed -e 's,@KEYSTONECLIENT_VERSION@,$(KEYSTONECLIENT_VERSION),g' -i $@

$(KEYSTONECLIENT_TARBALL): $(shell find $(KEYSTONECLIENT_UPSTREAM) -type f)
	rm -rf $@ $(MY_OBJ_DIR)/python-keystoneclient-$(KEYSTONECLIENT_VERSION)
	mkdir -p $(@D)
	cp -a $(KEYSTONECLIENT_UPSTREAM)/ \
              $(MY_OBJ_DIR)/python-keystoneclient-$(KEYSTONECLIENT_VERSION)
	tar -C $(MY_OBJ_DIR) -czf $@ \
	       python-keystoneclient-$(KEYSTONECLIENT_VERSION)

$(REPOMD_XML): $(RPMS)
	createrepo $(MY_OUTPUT_DIR)

$(EPEL_REPOMD_XML): $(wildcard $(EPEL_RPM_DIR)/%)
	$(call mkdir_clean,$(EPEL_YUM_DIR))
	cp -s $(EPEL_RPM_DIR)/* $(EPEL_YUM_DIR)
	createrepo $(EPEL_YUM_DIR)

.PHONY: clean
clean:
	rm -f $(OUTPUT)
	rm -rf $(MY_OBJ_DIR)/*
