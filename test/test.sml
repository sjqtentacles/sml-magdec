structure Tests =
struct
  open Harness
  fun close name e a eps = check name (Real.abs (e - a) <= eps)

  fun run () =
    let
      val g10   = ~29404.5
      val axial = [(1, 0, g10, 0.0)]

      val () = section "axial dipole declination"
      (* Axial dipole: no east component anywhere -> declination = 0 *)
      val fv  = Magdec.field {latDeg = 45.0, lonDeg = 0.0, altKm = 0.0, coeffs = axial}
      val dec = Magdec.declination fv
      val () = close "axial dipole declination = 0" 0.0 dec 0.01

      val () = section "axial dipole inclination"
      (* For an axial dipole: tan(I) = 2 * sin(lat) / cos(lat) = 2 * tan(lat)
         At lat=45: tan(I) = 2 -> I = atan(2) ~ 63.43 degrees
         With g10 < 0 the inclination is negative in northern hemisphere by our convention
         (down component negative), so we test the absolute value. *)
      val incl    = Magdec.inclination fv
      val expectI = Math.atan2 (2.0, 1.0) * 180.0 / Math.pi
      val () = close "axial inclination |I| at lat=45" expectI (Real.abs incl) 2.0

      val () = section "total intensity identity"
      val {north = n, east = e, down = d} = fv
      val total    = Magdec.totalIntensity fv
      val computed = Math.sqrt (n*n + e*e + d*d)
      val () = close "total intensity = sqrt(N^2+E^2+Z^2)" total computed 1.0e~9

      val () = section "inclination non-zero at lat=60"
      val fv2 = Magdec.field {latDeg = 60.0, lonDeg = 0.0, altKm = 0.0, coeffs = axial}
      val i2  = Magdec.inclination fv2
      val () = check "inclination finite"        (Real.isFinite i2)
      val () = check "inclination non-zero"      (Real.abs i2 > 10.0)

      val () = section "sample coeffs"
      val () = checkInt "sample coeffs length" (1, List.length Magdec.sampleCoeffs)
    in
      Harness.run ()
    end
end
