import setuptools

setuptools.setup(
    name='rh-ocp-build-data-validator',
    version='0.0.1',
    packages=['validator'],
    entry_points={'console_scripts': ['validate = validator.__main__:main']},
    include_package_data=True,
    install_requires=['pyyaml', 'schema', 'pygithub'])
