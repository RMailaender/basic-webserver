interface Utc
    exposes [
        Utc,
        now,
        toMillisSinceEpoch,
        fromMillisSinceEpoch,
        toNanosSinceEpoch,
        fromNanosSinceEpoch,
        deltaAsMillis,
        deltaAsNanos,
        toIso8601Str,
    ]
    imports [
        Effect,
        InternalTask,
        InternalDateTime,
        Task.{ Task },
    ]

## Stores a timestamp as nanoseconds since UNIX EPOCH
Utc := I128

## Duration since UNIX EPOCH
now : Task Utc *
now =
    Effect.posixTime
    |> Effect.map Num.toI128
    |> Effect.map @Utc
    |> Effect.map Ok
    |> InternalTask.fromEffect

## Convert Utc timestamp to ISO 8601 string
## Example: 2023-11-14T23:39:39Z
toIso8601Str : Utc -> Str
toIso8601Str = \@Utc nanos ->
    nanos
    |> Num.divTrunc nanosPerMilli
    |> InternalDateTime.epochMillisToDateTime
    |> InternalDateTime.toIso8601Str

# Constant number of nanoseconds in a millisecond
nanosPerMilli = 1_000_000

## Convert Utc timestamp to milliseconds
toMillisSinceEpoch : Utc -> I128
toMillisSinceEpoch = \@Utc nanos ->
    nanos // nanosPerMilli

## Convert milliseconds to Utc timestamp
fromMillisSinceEpoch : I128 -> Utc
fromMillisSinceEpoch = \millis ->
    @Utc (millis * nanosPerMilli)

## Convert Utc timestamp to nanoseconds
toNanosSinceEpoch : Utc -> I128
toNanosSinceEpoch = \@Utc nanos ->
    nanos

## Convert nanoseconds to Utc timestamp
fromNanosSinceEpoch : I128 -> Utc
fromNanosSinceEpoch = @Utc

## Calculate milliseconds between two Utc timestamps
deltaAsMillis : Utc, Utc -> U128
deltaAsMillis = \@Utc first, @Utc second ->
    firstCast = Num.bitwiseXor (Num.toU128 first) (Num.shiftLeftBy 1 127)
    secondCast = Num.bitwiseXor (Num.toU128 second) (Num.shiftLeftBy 1 127)
    (Num.absDiff firstCast secondCast) // nanosPerMilli

## Calculate nanoseconds between two Utc timestamps
deltaAsNanos : Utc, Utc -> U128
deltaAsNanos = \@Utc first, @Utc second ->
    firstCast = Num.bitwiseXor (Num.toU128 first) (Num.shiftLeftBy 1 127)
    secondCast = Num.bitwiseXor (Num.toU128 second) (Num.shiftLeftBy 1 127)
    Num.absDiff firstCast secondCast

# TESTS
expect deltaAsNanos (fromNanosSinceEpoch 0) (fromNanosSinceEpoch 0) == 0
expect deltaAsNanos (fromNanosSinceEpoch 1) (fromNanosSinceEpoch 2) == 1
expect deltaAsNanos (fromNanosSinceEpoch -1) (fromNanosSinceEpoch 1) == 2
expect deltaAsNanos (fromNanosSinceEpoch Num.minI128) (fromNanosSinceEpoch Num.maxI128) == Num.maxU128

expect deltaAsMillis (fromMillisSinceEpoch 0) (fromMillisSinceEpoch 0) == 0
expect deltaAsMillis (fromNanosSinceEpoch 1) (fromNanosSinceEpoch 2) == 0
expect deltaAsMillis (fromMillisSinceEpoch 1) (fromMillisSinceEpoch 2) == 1
expect deltaAsMillis (fromMillisSinceEpoch -1) (fromMillisSinceEpoch 1) == 2
expect deltaAsMillis (fromNanosSinceEpoch Num.minI128) (fromNanosSinceEpoch Num.maxI128) == Num.maxU128 // nanosPerMilli