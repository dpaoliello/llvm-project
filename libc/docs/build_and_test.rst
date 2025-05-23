.. _build_and_test:

=============================
Building and Testing the libc
=============================

Build modes
===========

The libc can be built and tested in two different modes:

#. **The overlay mode** - In this mode, one uses the static archive from LLVM's
   libc along with the system libc. See :ref:`overlay_mode` for more details
   on building and using the libc in this mode. You can only run the libc
   unittests in this mode. To run them, one simply does:

   .. code-block:: sh

     $> ninja check-libc

   Note that, unittests for only those functions which are part of the overlay
   static archive will be run with the above command.

#. **The full build mode** - In this mode, the libc is used as the only libc
   for the user's application. See :ref:`full_host_build` for more details on
   building and using the libc in this mode. Once configured for a full libc
   build, you can run three kinds of tests:

   #. Unit tests - You can run unittests by the command:

      .. code-block:: sh

        $> ninja check-libc

   #. Integration tests - You can run integration tests by the command:

      .. code-block:: sh

        $> ninja libc-integration-tests

Building with VSCode
====================

As a quickstart to using VSCode for development, install the cmake extension
and put the following in your settings.json file:

.. code-block:: javascript

   {
     "cmake.sourceDirectory": "${workspaceFolder}/llvm",
     "cmake.configureSettings": {
         "LLVM_ENABLE_PROJECTS" : "libc",
         "LLVM_LIBC_FULL_BUILD" : true,
         "LLVM_ENABLE_SPHINX" : true,
         "LIBC_INCLUDE_DOCS" : true
     }
   }

Building with Bazel
===================

#. To build with Bazel, use the following command:

  .. code-block:: sh

    $> bazel build --config=generic_clang @llvm-project//libc/...

#. To run the unit tests with bazel, use the following command:

  .. code-block:: sh

    $> bazel test --config=generic_clang @llvm-project//libc/...

#. The bazel target layout of `libc` is located at: `utils/bazel/llvm-project-overlay/libc/BUILD.bazel <https://github.com/llvm/llvm-project/tree/main/utils/bazel/llvm-project-overlay/libc/BUILD.bazel>`_.

Building in a container for a different architecture
====================================================

`Podman <https://podman.io/>`_ can be used together with
`QEMU <https://www.qemu.org/>`_ to run container images built for architectures
other than the host's. This can be used to build and test the libc on other
supported architectures for which you do not have access to hardware. It can
also be used if the hardware is slower than emulation of its architecture on a
more powerful machine under a different architecture.

As an example, to build and test in a container for 32-bit Arm:

#. To install the necessary packages on Arch Linux:

   .. code-block:: sh

     $> pacman -S podman qemu-user-static qemu-user-static-binfmt \
        qemu-system-arm

#. To run Bash interactively in an Ubuntu 22.04 container for 32-bit Arm and
   bind-mount an existing checkout of llvm-project on the host:

   .. code-block:: sh

     $> podman run -it \
        -v </host/path/to/llvm-project>:</container/path/to/llvm-project> \
        --arch arm docker.io/ubuntu:jammy bash

#. Install necessary packages, invoke CMake, build, and run tests.
