typedef NS_ENUM (int, PWPerformPendingMoment)
{
    PWPerformAtEndOfCycle       = 0,

    // Send -performPendingActionsAtMoment: with PWPerformIntermediate to bring all data structures and states up to
    // date before processing is continued.
    PWPerformIntermediate       = 1
};

// This enum needs to be extendable by sub classes (used by PWSync to add PWSPerformAfterPerformingOperations),
// therefore the type name is mapped to int.
enum {
    PWPerformAtEndOfCycleOnly   = 0,

    // This value should be chosen for actions which are delayed for coalescing or ordering reasons, but do not have a
    // specific need to be as late as possible in the cycle.
    // See also the intention of PWPerformIntermediate described above.
    PWPerformAnyMoment          = 1,

    PWLastMomentRestriction     = 1
};
typedef int PWDelayedPerformMomentRestriction;


