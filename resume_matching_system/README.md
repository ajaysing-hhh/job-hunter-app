# Resume Matching System (`resume_matching_system`)

Contains AI-inspired matching logic used by the backend scanner.

## Current algorithm
- TF-IDF vectorization of resume + job description text
- Cosine similarity scoring in range `0.0 - 1.0`

The backend uses this score to rank jobs and filter by threshold.
