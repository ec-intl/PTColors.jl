# API Reference

This page documents the public constants, functions, and macros exported by `PTColors`.

```@meta
CurrentModule = PTColors
```

## Module

```@docs
PTColors
```

## Index

```@index
Modules = [PTColors]
```

## Color constants

These constants contain the ANSI escape sequences used to apply and reset terminal colors.

```@docs
HEADER
INFO
OKGREEN
WARNING
FAIL
ENDC
```

## Timestamp and message formatting

```@docs
timestamp
defaultmsg
```

## Message functions

```@docs
headermsg
infomsg
okmsg
warnmsg
failmsg
```

## Callback handling

```@docs
messages
```

## Convenience macros

```@autodocs
Modules = [PTColors]
Order = [:macro]
```
