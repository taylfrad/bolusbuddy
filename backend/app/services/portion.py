from __future__ import annotations

import json
from dataclasses import dataclass

import numpy as np


@dataclass
class CameraIntrinsics:
    fx: float
    fy: float
    cx: float
    cy: float


DENSITY_PRIORS = {
    "white rice": 0.85,
    "salad": 0.3,
    "chicken breast": 1.05,
    "steamed broccoli": 0.35,
    "apple slices": 0.8,
    "pasta": 0.9,
    "salmon": 1.05,
    "potatoes": 0.75,
}


def parse_intrinsics(intrinsics_json: str | None) -> CameraIntrinsics | None:
    if not intrinsics_json:
        return None
    data = json.loads(intrinsics_json)
    return CameraIntrinsics(
        fx=float(data["fx"]),
        fy=float(data["fy"]),
        cx=float(data["cx"]),
        cy=float(data["cy"]),
    )


def estimate_portions_with_depth(
    depth_map_m: np.ndarray,
    intrinsics: CameraIntrinsics,
    items: list[dict],
) -> list[dict]:
    if depth_map_m.size == 0:
        return estimate_without_depth(items)

    plane_depth = _estimate_plane_depth(depth_map_m)
    masks = _build_equal_masks(depth_map_m.shape, len(items))
    output = []
    for item, mask in zip(items, masks):
        volume_m3 = _volume_from_depth(depth_map_m, plane_depth, intrinsics, mask)
        density = DENSITY_PRIORS.get(item["name"].lower(), 1.0)
        grams = volume_m3 * 1_000_000 * density
        output.append({**item, "grams": max(30.0, grams)})
    return output


def estimate_without_depth(items: list[dict]) -> list[dict]:
    fallback = []
    for item in items:
        fallback.append({**item, "grams": 150.0})
    return fallback


def _estimate_plane_depth(depth_map_m: np.ndarray) -> float:
    border = np.concatenate(
        [
            depth_map_m[0, :],
            depth_map_m[-1, :],
            depth_map_m[:, 0],
            depth_map_m[:, -1],
        ]
    )
    return float(np.nanmedian(border))


def _build_equal_masks(shape: tuple[int, int], count: int) -> list[np.ndarray]:
    height, width = shape
    masks = []
    slice_width = max(1, width // count)
    for i in range(count):
        mask = np.zeros((height, width), dtype=bool)
        start = i * slice_width
        end = width if i == count - 1 else (i + 1) * slice_width
        mask[:, start:end] = True
        masks.append(mask)
    return masks


def _volume_from_depth(
    depth_map_m: np.ndarray,
    plane_depth: float,
    intrinsics: CameraIntrinsics,
    mask: np.ndarray,
) -> float:
    depth = np.where(mask, depth_map_m, np.nan)
    height_map = np.clip(plane_depth - depth, 0, None)
    valid = np.isfinite(height_map) & (height_map > 0)
    if not np.any(valid):
        return 0.0001
    depth_valid = depth[valid]
    pixel_area = (depth_valid ** 2) / (intrinsics.fx * intrinsics.fy)
    volume = np.sum(height_map[valid] * pixel_area)
    return float(volume)
