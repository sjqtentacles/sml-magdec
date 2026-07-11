(* demo.sml - geomagnetic field vector and derived quantities (declination,
   inclination, horizontal/total intensity) from a spherical-harmonic axial
   dipole model, evaluated at a few literal geographic points using the
   library's sampleCoeffs. Deterministic: identical output on every run and
   both compilers. *)

structure M = Magdec

fun clean x = if Real.== (x, 0.0) then 0.0 else x
fun fmt n x = Real.fmt (StringCvt.FIX (SOME n)) (clean x)

val () = print "sml-magdec demo\n"
val () = print "===============\n\n"

val () = print ("sampleCoeffs: " ^ Int.toString (List.length M.sampleCoeffs)
                ^ " coefficient(s) (axial dipole g10)\n\n")

fun report label {latDeg, lonDeg, altKm} =
  let
    val v = M.field {latDeg = latDeg, lonDeg = lonDeg, altKm = altKm,
                      coeffs = M.sampleCoeffs}
    val n = #north v
    val e = #east v
    val d = #down v
  in
    print (label ^ " (lat=" ^ fmt 1 latDeg ^ ", lon=" ^ fmt 1 lonDeg
           ^ ", alt=" ^ fmt 1 altKm ^ "km):\n");
    print ("  field       = {north=" ^ fmt 2 n ^ ", east=" ^ fmt 2 e
           ^ ", down=" ^ fmt 2 d ^ "} nT\n");
    print ("  declination = " ^ fmt 2 (M.declination v) ^ " deg\n");
    print ("  inclination = " ^ fmt 2 (M.inclination v) ^ " deg\n");
    print ("  horizontalIntensity = " ^ fmt 2 (M.horizontalIntensity v) ^ " nT\n");
    print ("  totalIntensity      = " ^ fmt 2 (M.totalIntensity v) ^ " nT\n\n")
  end

val () = report "Equator"      {latDeg = 0.0,  lonDeg = 0.0,  altKm = 0.0}
val () = report "Mid-latitude" {latDeg = 45.0, lonDeg = 90.0, altKm = 100.0}
val () = report "Near pole"    {latDeg = 89.0, lonDeg = 0.0,  altKm = 0.0}
