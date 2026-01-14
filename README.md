# BolusBuddy

Cross-platform Flutter app + FastAPI backend that estimates meal nutrition from photos with depth sensors when available. Built for Type 1 diabetes decision support (no medical claims).

## Repository Structure

- `bolusbuddy_app/` Flutter client
- `backend/` FastAPI server + Docker + Cloud Run config
- `docs/` Architecture, portion estimation, setup

## Highlights

- Depth capture via ARKit (iOS) and ARCore (Android)
- USDA FoodData Central lookup with aggressive caching
- SHA-256 image hash caching
- Net carbs and uncertainty ranges
- Local SQLite meal history
- No model training required (recognition stub + database lookup)

## Documentation

- `docs/architecture.md`
- `docs/portion_estimation.md`
- `docs/setup.md`

## GitHub Setup

```bash
git add .
git commit -m "Initial BolusBuddy scaffold"
git branch -M main
git remote add origin https://github.com/YOUR_USER/bolusbuddy.git
git push -u origin main
```
