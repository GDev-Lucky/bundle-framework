@{
    TaskArchiveAfterDays = 30
    RetrievalHalfLifeDays = 120
    RetrievalSoftTokenLimit = 6000
    RetrievalHardTokenLimit = 8000
    RetrievalRuntimeTokenLimit = 1500
    RetrievalMinimumScore = 0.05
    RetrievalMinimumExcerptTokens = 80
    RetrievalMaxResultsPerCategory = 2
    RetrievalArchiveFallbackMinimumActiveResults = 1
    RetrievalCategoryTokenCaps = @{
        Project = 800
        Architecture = 1800
        Decisions = 1200
        "Previous Work" = 1200
        Code = 3000
    }
}