from resume_matching_system.matcher import ResumeMatcher


def test_resume_matcher_scores_relevant_job_higher():
    resume = 'flutter android python fastapi machine learning notifications'
    matcher = ResumeMatcher(resume)

    relevant = 'Build Flutter Android apps and integrate Python APIs'
    unrelated = 'Account management and B2B sales operations'

    assert matcher.score_job(relevant).score > matcher.score_job(unrelated).score
