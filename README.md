# Zypper-Upgraderepo

Zypper-Upgraderepo helps to check and upgrade the repositories used in your system
without have to do it manually.

It can be used stand-alone or installed as _zypper_ plugin.

## Installation

Install it as:

    $ gem install zypper-upgraderepo

If you want to install it as zypper plugin watch the _zypper-upgraderepo-plugin_ project linked below.

## Usage

To check the availability of the current repositories:

    $ zypper-upgraderepo -c

To check the availability of the next version repositories:

    $ zypper-upgraderepo -n

To upgrade the repositories to the next version:

    $ sudo zypper-upgraderepo -u

## Get help

Where to start:

    $ zypper-upgraderepo --help

More Help:

- The wiki page: https://github.com/fabiomux/zypper-upgraderepo
- zypper-upgraderepo-plugin project: https://github.com/fabiomux/zypper-upgraderepo-plugin

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fabiomux/zypper-upgraderepo. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Zypper::Upgraderepo project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/fabiomux/zypper-upgraderepo/blob/master/CODE_OF_CONDUCT.md).
