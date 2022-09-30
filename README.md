# Zypper-Upgraderepo

Zypper-Upgraderepo helps to check and upgrade the repositories used in your system for the
current, next or a custom valid version, reporting the errors and trying to find a replacement
when possible.

It can be also be installed as Zypper plugin using the [Zypper Upgraderepo Plugin][zypper_upgraderepo_plugin].

## Installation

There are several options to install the service menus listed in this repository.

## Rubygem

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
in the related [project page][project_page] on my blog.

## Usage

To check the availability of the current repositories:
```shell
$ zypper-upgraderepo
```

To check the availability of the next version repositories:
```shell
$ zypper-upgraderepo --check-next
```

To upgrade the repositories to the next version:
```shell
$ sudo zypper-upgraderepo --upgrade
```

## Get help

Where to start:
```shell
$ zypper-upgraderepo --help
```

## More Help:

More info is available at:
- the [Zypper-Upgraderepo GitHub wiki][zypper_upgraderepo_wiki];
- the article [Upgrading with Zypper][upgrading_with_zypper] on Freeaptitude blog.


[zypper_upgraderepo_plugin]: https://github.com/fabiomux/zypper-upgraderepo-plugin "Zypper-Upgraderepo Plugin GitHub page"
[project_page]: https://freeaptitude.altervista.org/projects/zypper-upgraderepo.html "Zypper-Upgraderepo project page"
[zypper_upgraderepo_wiki]: https://github.com/fabiomux/zypper-upgraderepo/wiki "Zypper-Upgraderepo wiki page on GitHub"
[upgrading_with_zypper]: https://freeaptitude.altervista.org/articles/upgrading-opensuse-with-zypper.html "Upgrading openSUSE with Zypper"
