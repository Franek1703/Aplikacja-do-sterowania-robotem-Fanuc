"""
Setup file for fanuc_package to enable editable pip install.

This allows the fanuc_firebase_gateway to import the package without
needing to install it globally.

Usage:
    pip install -e .
"""

from setuptools import setup, find_packages

setup(
    name="fanuc_package",
    version="0.1.14",
    description="Python package for FANUC industrial robots",
    author="Agajan Torayev",
    license="Apache License 2.0",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    python_requires=">=3.8",
    install_requires=[
        "scipy>=1.10.0",
        "numpy>=1.24.0",
    ],
)

