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

These constants contain ANSI Select Graphic Rendition (SGR) escape sequences
that instruct compatible terminals to select bright foreground color
categories or reset formatting. They do not define fixed RGB values, so the
exact rendered shades depend on the terminal emulator and its active color
theme.

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
