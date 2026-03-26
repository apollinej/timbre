#!/bin/bash
# Double-click in Finder or run from Terminal to open this package in Xcode.
cd "$(dirname "$0")" || exit 1
open -a Xcode Package.swift
