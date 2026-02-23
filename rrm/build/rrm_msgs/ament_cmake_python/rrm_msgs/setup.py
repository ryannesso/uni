from setuptools import find_packages
from setuptools import setup

setup(
    name='rrm_msgs',
    version='0.0.0',
    packages=find_packages(
        include=('rrm_msgs', 'rrm_msgs.*')),
)
