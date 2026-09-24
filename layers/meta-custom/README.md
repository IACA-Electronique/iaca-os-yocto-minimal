# Custom IACA layer

This layer provides custom image types for IACA OS builds.

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

## Notes

- The `dir` image type is required because the IACA image classes use the generated root filesystem directory as input.
- Use `iaca` for a single-rootfs image.
- Use `iaca_a_b` when building an image with redundant A/B rootfs partitions (see [Raspberry Pi A/B Redundant Partitioning Guide](../../docs/a_b%20partition/README.md)).