nDrawExts2
==========

nDrawExts is a module for Monkey which extends the built-in Mojo's functionality.  This is the second generation of the module, now utilizing gles11 instead of native code blocks, increasing compatibility to all of the major OpenGL targets.

The functions closely resemble existing functions and adds the following features:

* Extra blend modes
* Access to the stencil buffer
* Grabbing ARGB data directly from an image


Be sure to read the known issues in nDrawExts2.monkey for usage and more information.
The included example demonstrates all current features.