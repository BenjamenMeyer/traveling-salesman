Things to do on Mac OSX
=======================

Install HomeBrew_.

Configure the PS1 Environment Variable:

.. code-block:: shell

    $ echo "PS1=\"\\u@\\h:\\w > \\$ \"" >> ~/.bash_profile
    $ source ~/.bash_profile

.. code-block:: shell

    $ brew install git
    $ brew install iterm2
    $ brew install bash
    $ brew install bash-completion@2
    $ brew install homebrew/cask/karabiner-elements
    $ brew install coreutils

.. note:: See [1]_ after installing bash, bash-completion@2 and coreutils.

Notes
-----

.. [1] This will require that the `~/.bash_profile` be updated with changes from the output of the `brew install`.

References
----------
.. _HomeBrew: https://brew.sh/
.. _Karabiner: https://pqrs.org/osx/karabiner/index.html
