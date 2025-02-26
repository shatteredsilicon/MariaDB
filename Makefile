BUILDDIR	?= /tmp/ssmbuild

ARCH	:= $(shell rpm --eval "%{_arch}")
VERSION	?= $(shell rpmspec -q --queryformat="%{version}" MariaDB.spec)
RELEASE	?= $(shell rpmspec -q --queryformat="%{release}" MariaDB.spec)

EL8_SRPM_FILE	:= $(BUILDDIR)/results/SRPMS/MariaDB-$(VERSION)-$(RELEASE).el8.src.rpm
EL9_SRPM_FILE	:= $(BUILDDIR)/results/SRPMS/MariaDB-$(VERSION)-$(RELEASE).el9.src.rpm
SRPM_FILES		:= $(EL8_SRPM_FILE) $(EL9_SRPM_FILE)
RPM_FILES		:= $(BUILDDIR)/results/RPMS/MariaDB-common-$(VERSION)-$(RELEASE).el8.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-common-$(VERSION)-$(RELEASE).el9.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-server-$(VERSION)-$(RELEASE).el8.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-server-$(VERSION)-$(RELEASE).el9.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-client-$(VERSION)-$(RELEASE).el8.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-client-$(VERSION)-$(RELEASE).el9.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-backup-$(VERSION)-$(RELEASE).el8.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-backup-$(VERSION)-$(RELEASE).el9.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-connect-engine-$(VERSION)-$(RELEASE).el8.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-connect-engine-$(VERSION)-$(RELEASE).el9.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-cracklib-password-check-$(VERSION)-$(RELEASE).el8.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-cracklib-password-check-$(VERSION)-$(RELEASE).el9.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-devel-$(VERSION)-$(RELEASE).el8.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-devel-$(VERSION)-$(RELEASE).el9.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-gssapi-server-$(VERSION)-$(RELEASE).el8.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-gssapi-server-$(VERSION)-$(RELEASE).el9.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-oqgraph-engine-$(VERSION)-$(RELEASE).el8.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-oqgraph-engine-$(VERSION)-$(RELEASE).el9.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-shared-$(VERSION)-$(RELEASE).el8.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-shared-$(VERSION)-$(RELEASE).el9.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-test-$(VERSION)-$(RELEASE).el8.$(ARCH).rpm \
					$(BUILDDIR)/results/RPMS/MariaDB-test-$(VERSION)-$(RELEASE).el9.$(ARCH).rpm

.PHONY: all
all: srpm rpm

.PHONY: srpm
srpm: $(SRPM_FILES)

$(SRPM_FILES):
	mkdir -vp $(BUILDDIR)/rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
	mkdir -vp $(BUILDDIR)/mock
	mkdir -vp $(shell dirname $(EL8_SRPM_FILE))
	mkdir -vp $(shell dirname $(EL9_SRPM_FILE))

	cp MariaDB.spec $(BUILDDIR)/rpmbuild/SPECS/MariaDB.spec
	sed -i -E 's/%\{\??_version\}/$(VERSION)/g' $(BUILDDIR)/rpmbuild/SPECS/MariaDB.spec
	sed -i -E 's/%\{\??_release\}/$(RELEASE)/g' $(BUILDDIR)/rpmbuild/SPECS/MariaDB.spec
	cp *.patch $(BUILDDIR)/rpmbuild/SOURCES/
	spectool -C $(BUILDDIR)/rpmbuild/SOURCES -g $(BUILDDIR)/rpmbuild/SPECS/MariaDB.spec
	mock --buildsrpm -r ssm-8-$(ARCH) --define "debug_package %{nil}" --spec $(BUILDDIR)/rpmbuild/SPECS/MariaDB.spec --sources $(BUILDDIR)/rpmbuild/SOURCES/ --resultdir $(BUILDDIR)/mock
	mv $(BUILDDIR)/mock/$(shell basename $(EL8_SRPM_FILE)) $(EL8_SRPM_FILE)
	mock --buildsrpm -r ssm-9-$(ARCH) --define "debug_package %{nil}" --spec $(BUILDDIR)/rpmbuild/SPECS/MariaDB.spec --sources $(BUILDDIR)/rpmbuild/SOURCES/ --resultdir $(BUILDDIR)/mock
	mv $(BUILDDIR)/mock/$(shell basename $(EL9_SRPM_FILE)) $(EL9_SRPM_FILE)

.PHONY: rpm
rpm: $(RPM_FILES)

$(RPM_FILES): $(SRPM_FILES)
	mkdir -vp $(BUILDDIR)/mock
	mock -r ssm-8-$(ARCH) --resultdir $(BUILDDIR)/mock --rebuild $(EL8_SRPM_FILE)
	mock -r ssm-9-$(ARCH) --resultdir $(BUILDDIR)/mock --rebuild $(EL9_SRPM_FILE)

	for rpm_file in $(RPM_FILES); do \
		mkdir -vp $$(dirname $${rpm_file}); \
		mv $(BUILDDIR)/mock/$$(basename $${rpm_file}) $${rpm_file}; \
	done

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)/{rpmbuild,mock,results}
