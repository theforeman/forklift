Name:      katello-rhsm-consumer
Version:   1.0
Release:   1
Group:     Applications/System
License:   GPL
BuildArch: noarch
Source:    %{name}-%{version}.tar.gz
Summary:   Subscription-manager consumer certificate for Katello instance pipeline-katello-3-4-centos7.example.com
Packager:  None
Vendor:    None
Requires:  subscription-manager

%description
Consumer certificate and post installation script that configures rhsm.

%prep

%setup -c

%build

%install
rm -rf $RPM_BUILD_ROOT
install -d $RPM_BUILD_ROOT
install --verbose -d $RPM_BUILD_ROOT/usr/bin
install --verbose katello-rhsm-consumer $RPM_BUILD_ROOT/usr/bin/katello-rhsm-consumer

%clean
rm -rf $RPM_BUILD_ROOT

%files
%attr(755,-,-) /usr/bin/katello-rhsm-consumer
