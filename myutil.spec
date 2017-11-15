%undefine _missing_build_ids_terminate_build
%define debug_package %{nil}

# %commit is intended to be set by tito. The values in this spec file will not be kept up to date.
%{!?commit:
%global commit 4a0e1af82ff19c1390d671eea1fec8f871d22c0d
}

Name:           myutil

# Version and release information will be automatically managed by CD --
# It will be kept in sync with OCP builds.
Version:        0.2
Release:        1%{?dist}
Summary:        Example utility image to demonstrate how RPMs and images are build for OCP.

License:        MIT
URL:            https://github.com/josephspurrier/goversioninfo
Source0:        goversioninfo-0.1.tar.gz

BuildRequires:  bsdtar
BuildRequires:  golang

%description
Example utility image to demonstrate how RPMs and images are build for OCP.

%prep
%autosetup


%build
go build

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/bin
install -m 755 enterprise-images-upstream-example $RPM_BUILD_ROOT%{_bindir}

%files
%{_bindir}/enterprise-images-upstream-example

%changelog
* Wed Nov 15 2017 jupierce <jupierce@redhat.com> 0.2-1
- new package built with tito

* Fri Jul 14 2017 jupierce <jupierce@redhat.com>
-