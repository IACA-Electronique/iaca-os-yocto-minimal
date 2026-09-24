# Custom IACA layer

This layer provides custom image types and example recipes for IACA OS builds.

## IACA image format

To generate a standard IACA image, add the following configuration to `local.conf`:

```
IMAGE_CLASSES += "image_types_iaca_a_b image_types_dir"
IMAGE_FSTYPES = "dir iaca"
```

## IACA image format with A/B partitions

To generate an IACA image using A/B partitions, add the following configuration to `local.conf`:

```
IMAGE_CLASSES += "image_types_iaca_a_b image_types_dir"
IMAGE_FSTYPES = "dir iaca_a_b"
```

## Example recipes

This layer includes example recipes located in `recipes-example/`:

### Hello World (`hello`)

A simple "Hello, World!" application.

To include it in your image, add the following configuration to `local.conf`:

```
IMAGE_INSTALL:append = " hello"
```

Or build it individually:

```
bitbake hello
```

### Framebuffer Colors (`colors`)

A test application that writes random colors to the framebuffer device (`/dev/fb0`) every 2 seconds.

To include it in your image, add the following configuration to `local.conf`:

```
IMAGE_INSTALL:append = " colors"
```

Or build it individually:

```
bitbake colors
```

### Example Banner (`example`)

A sample recipe demonstrating a custom BitBake Python task (`do_display_banner`) that displays a banner during the build.

To build and execute the recipe:

```
bitbake example
```

## Notes

- The `dir` image type is required because the IACA image classes use the generated root filesystem directory as input.
- Use `iaca` for a single-rootfs image.
- Use `iaca_a_b` when building an image with redundant A/B rootfs partitions (see [Raspberry Pi A/B Redundant Partitioning Guide](../../docs/a_b%20partition/README.md)).