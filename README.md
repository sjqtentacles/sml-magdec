# sml-magdec

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
