# sml-magdec

[![CI](https://github.com/sjqtentacles/sml-magdec/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-magdec/actions/workflows/ci.yml)

Zero-dependency Standard ML library for spherical-harmonic geomagnetic field
computation (IGRF-style).

## Overview

`sml-magdec` computes the geomagnetic field vector in NED (North-East-Down)
coordinates using Schmidt quasi-normal associated Legendre polynomials and a
user-supplied list of Gauss coefficients. Derived quantities (declination,
inclination, horizontal intensity, total intensity) are also provided.

## API

```sml
(* Gauss coefficient: (n, m, g_nm, h_nm) in nanotesla *)
type coeff = int * int * real * real

(* Compute NED field vector at a geographic location *)
val field : {latDeg:real, lonDeg:real, altKm:real, coeffs:coeff list}
         -> {north:real, east:real, down:real}

(* Derived scalar quantities (degrees or nT) *)
val declination         : {north:real, east:real, down:real} -> real
val inclination         : {north:real, east:real, down:real} -> real
val horizontalIntensity : {north:real, east:real, down:real} -> real
val totalIntensity      : {north:real, east:real, down:real} -> real

(* Minimal axial-dipole coefficient set for testing *)
val sampleCoeffs : coeff list
```

## Example

`make example` builds and runs [`examples/demo.sml`](examples/demo.sml), which
evaluates the axial-dipole `sampleCoeffs` field at a few geographic points and
prints the resulting field vector plus declination, inclination, and
intensity (output is byte-identical under MLton and Poly/ML):

```
sml-magdec demo
===============

sampleCoeffs: 1 coefficient(s) (axial dipole g10)

Equator (lat=0.0, lon=0.0, alt=0.0km):
  field       = {north=29404.50, east=0.00, down=0.00} nT
  declination = 0.00 deg
  inclination = 0.00 deg
  horizontalIntensity = 29404.50 nT
  totalIntensity      = 29404.50 nT

Mid-latitude (lat=45.0, lon=90.0, alt=100.0km):
  field       = {north=19843.03, east=0.00, down=39686.07} nT
  declination = 0.00 deg
  inclination = 63.43 deg
  horizontalIntensity = 19843.03 nT
  totalIntensity      = 44370.37 nT

Near pole (lat=89.0, lon=0.0, alt=0.0km):
  field       = {north=513.18, east=0.00, down=58800.04} nT
  declination = 0.00 deg
  inclination = 89.50 deg
  horizontalIntensity = 513.18 nT
  totalIntensity      = 58802.28 nT
```

## Physics

The magnetic scalar potential follows the IGRF convention:

```
V = a Σ_{n=1}^{N} (a/r)^{n+1} Σ_{m=0}^{n}
      (g_nm cos(mλ) + h_nm sin(mλ)) P_nm(cos θ)
```

where `a = 6371.2 km`, `θ` is colatitude, `λ` is longitude.  
The NED components are derived as `B = −∇V`.

## Building

```
make all-tests   # builds and runs under both MLton and Poly/ML
```

## License

MIT
