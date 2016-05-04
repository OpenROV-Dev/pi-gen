#!/bin/bash -e

# Set up hardware peripherals

# I2C
# SPI
# GPIO

# Set up networking

# LAN
# WIFI


# Setup services, if any

on_chroot sh -e - <<EOF
groupadd -f -r admin
adduser ${USER_NAME} admin
EOF
