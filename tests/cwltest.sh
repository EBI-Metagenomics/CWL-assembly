#!/bin/bash

cwltest --test tests.yml "$@" --tool cwltool -- --singularity --leave-container
