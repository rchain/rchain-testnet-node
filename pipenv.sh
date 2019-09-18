#!/bin/bash -ue

env PYENV_VERSION=3.6.8 ~/.pyenv/shims/python -m pipenv "$@"
