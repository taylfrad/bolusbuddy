# Portion Estimation (Depth)

## Math Overview

1. **Plane depth (table/plate)** is estimated from the median of border pixels.
2. **Height map** per pixel:
   - `h(x,y) = max(plane_depth - depth(x,y), 0)`
3. **Pixel area** in camera space:
   - `A(x,y) = depth(x,y)^2 / (fx * fy)`
4. **Volume** per item:
   - `V = sum(h(x,y) * A(x,y))` over the item mask.
5. **Mass (grams)**:
   - `grams = V * 1e6 * density`
   - Density priors are food-specific and conservative.

## Implementation

See `backend/app/services/portion.py` for:
- Plane estimation
- Volume integration
- Density priors
- Depth and intrinsics parsing

Fallback when depth is missing:
- Fixed 150g per item, with higher uncertainty.
