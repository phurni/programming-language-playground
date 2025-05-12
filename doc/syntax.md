# Syntax

In each of the syntax description below, [xxx] indicates that `xxx` may be filled respecting its own syntax description.

Example:

```
if ([expression]) {
  [statements]
}
```

`[expression]` may be filled by any element described in the chapter **expression**.
`[statements]` may be filled by any element described in the chapter **statements**.
So this is a valid content:

```
if (age == 42) {
  print(1)
}
```

A source file contains [definitions].
Code indentation is 2 spaces.
Source file extension is `.src`.

## definitions

Multiple definitions of the following:

### function definition

```
fun without_args() {
  [statements]
}
```

```
fun name(arg1, arg2) {
  [statements]
}
```

The last executed statement in the function is its return value.

## expression

One expression of the following:

### literal

`42`

### variable reference

`name`

### function call

`name()`

`name([expression], [expression])`

### infix operations

```
[expression] + [expression]
[expression] - [expression]
[expression] * [expression]
[expression] / [expression]
[expression] % [expression]

[expression] == [expression]
[expression] != [expression]
[expression] <  [expression]
[expression] <= [expression]
[expression] >  [expression]
[expression] >= [expression]
```

## control structures

One control structure of the following:

### if

```
if ([expression]) {
  [statements]
}
```

### if-else

```
if ([expression]) {
  [statements]
}
else {
  [statements]
}
```

## statements

Multiple statements of the following:

### variable declaration

`var name`

### variable assignment

`name = [expression]`

### [control structures]

### [function call]
