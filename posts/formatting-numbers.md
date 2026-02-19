# Formatting Numbers of Unknown Order of Magnitude

Sometimes, I write programs that need to display numbers where I don't know how big or small they will be. The most common approaches of printing numbers won't be very helpful in such a case.

```python
# Default print: more decimal places than useful
>>> print(1324325425.3254435363463)
1324325425.3254435

# Fixed amount of decimal places: better, but ...
>>> print("{:.0f}".format(1324325425.3254435363463))
1324325425
# ...useless results for small numbers
>>> print("{:.0f}".format(0.3254435363463))
0
```

A good way to deal with this problem is to use the [scientific notation](https://en.wikipedia.org/wiki/Scientific_notation), which displays the mantissa and exponent separately.

```python
>>> print("{:e}".format(1324325425.3254435363463))
1.324325e+09
>>> print("{:e}".format(0.3254435363463))
3.254435e-01
```

However, not everyone is used to reading the scientific notation and many programs don't accept it as input. What I often want to have is a format that:

* does not irritate humans
* is understood by all programs
* is not unnecessarily verbose

One way to reach this is to round to a fixed number of [significant figures](https://en.wikipedia.org/wiki/Significant_figures).

```python
>>> def fmt_sig(x, sig_figures=3):
...     show_dec = -floor(log10(abs(x)) + 1) + sig_figures
...     return round(x, show_dec)
...
>>> print(fmt_sig(1324325425.3254435363463))
1320000000.0
>>> print(fmt_sig(0.3254435363463))
0.325
```

But rounding the big number can be confusing because it only has an accuracy of three digits while showing eleven digits. My suggested solution is to format numbers with a *minimum* number of significant figures and to print all places before the decimal point for big numbers.

```python
>>> def fmt_min_sig(x, min_sig_figures=3):
...     show_dec = max(-floor(log10(abs(x)) + 1) + min_sig_figures, 0)
...     return ("{:." + str(show_dec) + "f}").format(x)
... 
>>> print(fmt_min_sig(1324325425.3254435363463))
1324325425
>>> print(fmt_min_sig(0.3254435363463))
0.325
>>> print(fmt_min_sig(12.3254435363463))
12.3
```

This approach has worked well for me, but I have not seen it any other code bases. That makes me wonder: Did I miss any downsides? Are others doing the same and I just didn't notice? Or is there a better way to do the same? If you have the answer to one of these questions, please [let me know](mailto:karl@karl.berlin)!

## Update (2026)

It turns out that JavaScript's `Intl.NumberFormat` supports this formatting
strategy since the [V3 proposal](https://github.com/tc39/proposal-intl-numberformat-v3)
shipped in browsers. The ICU library that powers it calls the underlying concept
"relaxed precision". You can get the same behavior as `fmt_min_sig` with:

```js
const fmt = new Intl.NumberFormat("en", {
  minimumSignificantDigits: 3,
  maximumSignificantDigits: 3,
  maximumFractionDigits: 0,
  roundingPriority: "morePrecision"
});
fmt.format(0.0123456)  // '0.0123'
fmt.format(123456.78)  // '123,457'
```

The `morePrecision` mode resolves conflicts between the two rounding strategies
by picking whichever produces more digits. For large numbers,
`maximumFractionDigits: 0` wins (keeping all integer digits). For small numbers,
`minimumSignificantDigits: 3` wins (keeping three significant figures). That is
exactly the `max()` in `fmt_min_sig`.
