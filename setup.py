from setuptools import find_packages, setup

install_requires = open("requirements.txt").read().strip().split("\n")

setup(
    name='flaskr',
    version='1.0.0',
    packages=find_packages(),
    include_package_data=True,
    zip_safe=False,
    install_requires=install_requires,
)