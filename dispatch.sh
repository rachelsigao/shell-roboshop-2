#!/bin/bash

source ./common.sh
app_name="dispatch"

check_root
app_setup
golang_setup
systemd_setup
print_time
