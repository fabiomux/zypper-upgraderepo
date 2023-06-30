# Zypper-Upgraderepo

Zypper-Upgraderepo helps to check and upgrade the repositories used in your system for the
current, next or a custom valid version, reporting the errors and trying to find a replacement
when possible.

It can be also be installed as Zypper plugin using the [Zypper Upgraderepo Plugin][zypper_upgraderepo_plugin].

[![Ruby](https://github.com/fabiomux/zypper-upgraderepo/actions/workflows/main.yml/badge.svg)][wf_main]
[![Gem Version](https://badge.fury.io/rb/zypper-upgraderepo.svg)][gem_version]

## Installation

There are a couple of options to install this application.

### Rubygem

Install it as a regular Ruby gem with:
```shell
$ gem install zypper-upgraderepo
```

### From the openSUSE Build Service repository

This application has been packaged in my personal OBS repository so you can install It
as a common RPM package:
- Add the repository URL in your list;
- install the package from Yast or Zypper.

Being the repository URL slightly changing from a version to another, I included all the steps
in the related [project page][project_page] at my blog.

## Usage

***Warning!!! The executables name prior the 1.8.0 version is zypper-upgraderepo, unfortunately the
RPM package installation introduces annoying copies of the same executable having a version appended
(zypper-upgraderepo.version, zypper-upgraderepo.rubyversion, zypper-upgraderepo.rubyversion.version)
interpreted by zypper itself as different subcommands. So I considered more convenient to remove the
zypper prefix from the original executable and let the sole zypper-upgraderepo-plugin package install
it as a zypper plugin.***

To check the availability of the current repositories:
```shell
$ upgraderepo
```

To check the availability of the next version repositories:
```shell
$ upgraderepo --check-next
```

To upgrade the repositories to the next version:
```shell
$ sudo upgraderepo --upgrade
```

## Get help

Where to start:
```shell
$ upgraderepo --help
```

## More Help:

More info is available at:
- the [Zypper-Upgraderepo GitHub wiki][zypper_upgraderepo_wiki];
- the article [Upgrading with Zypper][upgrading_with_zypper] on Freeaptitude blog.


[zypper_upgraderepo_plugin]: https://github.com/fabiomux/zypper-upgraderepo-plugin "Zypper-Upgraderepo Plugin GitHub page"
[project_page]: https://freeaptitude.altervista.org/projects/zypper-upgraderepo.html "Zypper-Upgraderepo project page"
[zypper_upgraderepo_wiki]: https://github.com/fabiomux/zypper-upgraderepo/wiki "Zypper-Upgraderepo wiki page on GitHub"
[upgrading_with_zypper]: https://freeaptitude.altervista.org/articles/upgrading-opensuse-with-zypper.html "Upgrading openSUSE with Zypper"
[wf_main]: https://github.com/fabiomux/zypper-upgraderepo/actions/workflows/main.yml
[gem_version]: https://badge.fury.io/rb/zypper-upgraderepo
