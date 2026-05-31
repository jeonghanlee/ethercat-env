# -*- mode: makefile-gmake; -*-
#
# Patch registry (M7): declared mapping of patch class to file list.
#
# Each class owns a subdirectory under $(TOP)/patch and a PATCH_FILES_<CLASS>
# variable listing the .patch files applied for that class, in order. A class
# with an empty list is a declared anchor with no patches yet; this is the
# expected pristine state on a fresh clone.
#
# Classes:
#   site           local site adjustments
#   compatibility  upstream/kernel compatibility shims
#   hardware       device/NIC-specific patches
#   archive        retained-but-inactive patches (never auto-applied)
#
# Conventions:
#   - Paths are absolute, rooted at $(TOP)/patch/<class>/.
#   - PATCH_CLASSES is the canonical ordered class list consumed by
#     class-aware macros in configure/RULES_FUNC and targets in RULES_PATCH.
#   - The archive class is declared for completeness but excluded from the
#     default apply set (PATCH_CLASSES_ACTIVE); it is never applied implicitly.
#

PATCH_DIR ?= $(TOP)/patch

PATCH_CLASSES        := site compatibility hardware archive
PATCH_CLASSES_ACTIVE := site compatibility hardware

# Per-class file lists. Empty by default (pristine anchors).
PATCH_FILES_site          :=
PATCH_FILES_compatibility :=
PATCH_FILES_hardware      :=
PATCH_FILES_archive       :=
