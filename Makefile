BUILDDIR	?= /tmp/ssmbuild

ARCH	:= $(shell rpm --eval "%{_arch}")
VERSION	?= $(shell rpmspec -q --queryformat="%{version}" MariaDB.spec)
RELEASE	?= $(shell rpmspec -q --queryformat="%{release}" MariaDB.spec)

SRPM_FILE		:= $(BUILDDIR)/results/SRPMS/MariaDB-$(VERSION)-$(RELEASE).src.rpm
RPM_FILES		:= $(BUILDDIR)/results/RPMS/MariaDB-common-$(VERSION)-$(RELEASE).$(ARCH).rpm $(BUILDDIR)/results/RPMS/MariaDB-server-$(VERSION)-$(RELEASE).$(ARCH).rpm $(BUILDDIR)/results/RPMS/MariaDB-client-$(VERSION)-$(RELEASE).$(ARCH).rpm $(BUILDDIR)/results/RPMS/MariaDB-backup-$(VERSION)-$(RELEASE).$(ARCH).rpm $(BUILDDIR)/results/RPMS/MariaDB-connect-engine-$(VERSION)-$(RELEASE).$(ARCH).rpm $(BUILDDIR)/results/RPMS/MariaDB-cracklib-password-check-$(VERSION)-$(RELEASE).$(ARCH).rpm $(BUILDDIR)/results/RPMS/MariaDB-devel-$(VERSION)-$(RELEASE).$(ARCH).rpm $(BUILDDIR)/results/RPMS/MariaDB-gssapi-server-$(VERSION)-$(RELEASE).$(ARCH).rpm $(BUILDDIR)/results/RPMS/MariaDB-oqgraph-engine-$(VERSION)-$(RELEASE).$(ARCH).rpm $(BUILDDIR)/results/RPMS/MariaDB-shared-$(VERSION)-$(RELEASE).$(ARCH).rpm $(BUILDDIR)/results/RPMS/MariaDB-test-$(VERSION)-$(RELEASE).$(ARCH).rpm

.PHONY: all
all: srpm rpm

.PHONY: srpm
srpm: $(SRPM_FILE)

$(SRPM_FILE):
	mkdir -vp $(BUILDDIR)/rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
	mkdir -vp $(shell dirname $(SRPM_FILE))

	cp MariaDB.spec $(BUILDDIR)/rpmbuild/SPECS/MariaDB.spec
	sed -i -E 's/%\{\??_version\}/$(VERSION)/g' $(BUILDDIR)/rpmbuild/SPECS/MariaDB.spec
	sed -i -E 's/%\{\??_release\}/$(RELEASE)/g' $(BUILDDIR)/rpmbuild/SPECS/MariaDB.spec
	cp *.patch $(BUILDDIR)/rpmbuild/SOURCES/
	spectool -C $(BUILDDIR)/rpmbuild/SOURCES -g $(BUILDDIR)/rpmbuild/SPECS/MariaDB.spec
	rpmbuild -bs --define "debug_package %{nil}" --define "_topdir $(BUILDDIR)/rpmbuild" $(BUILDDIR)/rpmbuild/SPECS/MariaDB.spec
	mv $(BUILDDIR)/rpmbuild/SRPMS/$(shell basename $(SRPM_FILE)) $(SRPM_FILE)

.PHONY: rpm
rpm: $(RPM_FILES)

$(RPM_FILES): $(SRPM_FILE)
	mkdir -vp $(BUILDDIR)/mock
	mock -r ssm-9-$(ARCH) --resultdir $(BUILDDIR)/mock --rebuild $(SRPM_FILE)

	for rpm_file in $(RPM_FILES); do \
		mkdir -vp $$(dirname $${rpm_file}); \
		mv $(BUILDDIR)/mock/$$(basename $${rpm_file}) $${rpm_file}; \
	done

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)/{rpmbuild,mock,results}
