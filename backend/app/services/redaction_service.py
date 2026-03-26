import logging
from pathlib import Path

import cv2
import numpy as np

logger = logging.getLogger(__name__)

# Redact the top portion of the image where name/student info typically is
TOP_REDACT_RATIO = 0.12  # Redact top 12% of the image


def redact_pii(image_path: str, output_path: str) -> str:
    """
    Redact PII (name area) from a test page image.
    Blacks out the top portion of the image where student name typically appears.

    Args:
        image_path: Path to the original image.
        output_path: Path to save the redacted image.

    Returns:
        Path to the redacted image.
    """
    img = cv2.imread(image_path)
    if img is None:
        raise ValueError(f"Could not read image: {image_path}")

    height, width = img.shape[:2]
    redact_height = int(height * TOP_REDACT_RATIO)

    # Black out the top area
    img[0:redact_height, 0:width] = 0

    # Ensure output directory exists
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)

    cv2.imwrite(output_path, img)
    logger.info(f"Redacted PII from {image_path} -> {output_path}")
    return output_path
