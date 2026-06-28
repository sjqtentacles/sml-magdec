signature MAGDEC =
sig
  type coeff = int * int * real * real

  val field : {latDeg: real, lonDeg: real, altKm: real, coeffs: coeff list}
           -> {north: real, east: real, down: real}

  val declination         : {north: real, east: real, down: real} -> real
  val inclination         : {north: real, east: real, down: real} -> real
  val horizontalIntensity : {north: real, east: real, down: real} -> real
  val totalIntensity      : {north: real, east: real, down: real} -> real

  val sampleCoeffs : coeff list
end
