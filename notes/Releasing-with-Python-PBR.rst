Notes for releasing projects with Python PBR

- You need to set PBR_VERSION in the environment to get the version correct. Example:

.. code-block:: sh

	$ export PBR_VERSION=0.7.0
	$ python setup.py sdist upload

