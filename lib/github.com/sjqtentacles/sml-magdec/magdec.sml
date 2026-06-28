structure Magdec :> MAGDEC =
struct
  type coeff = int * int * real * real

  val earthA = 6371.2
  val pi     = Math.pi

  fun deg2rad d = d * pi / 180.0

  (* Index into flat triangular array: row n, column m (0 <= m <= n) *)
  fun idx n m = n * (n + 1) div 2 + m

  (* Build Schmidt quasi-normal associated Legendre polynomials P(n,m) and
     their theta-derivatives dP/dtheta, for n = 0..nMax.
     cosT = cos(colatitude), sinT = sin(colatitude).

     Recurrences used (Schmidt semi-normalized):
       P(0,0) = 1
       P(1,0) = cosT                   dP(1,0)/dT = -sinT
       P(1,1) = sinT                   dP(1,1)/dT =  cosT
       P(n,n) = f_nn * sinT * P(n-1,n-1)
       P(n,m) = a_nm * cosT * P(n-1,m) - b_nm * P(n-2,m)   for 0 <= m <= n-1
     where
       f_nn  = sqrt((2n-1)/(2n))
       a_nm  = sqrt((4n^2-1) / (n^2-m^2))             [= (2n-1)/sqrt((n-m)(n+m))]
       b_nm  = sqrt((2n+1)(n-1+m)(n-1-m) / ((2n-3)(n-m)(n+m)))
  *)
  fun schmidtP nMax (cosT : real) (sinT : real) =
    let
      val sz = (nMax + 2) * (nMax + 3) div 2
      val p  = Array.array (sz, 0.0)
      val dp = Array.array (sz, 0.0)
      fun gp n m    = Array.sub  (p,  idx n m)
      fun gdp n m   = Array.sub  (dp, idx n m)
      fun sp n m v  = Array.update (p,  idx n m, v)
      fun sdp n m v = Array.update (dp, idx n m, v)

      val () = sp  0 0 1.0
      val () = sdp 0 0 0.0

      fun buildN n =
        if n > nMax then ()
        else (
          if n = 1 then (
            sp  1 0 cosT;   sdp 1 0 (~sinT);
            sp  1 1 sinT;   sdp 1 1 cosT
          ) else (
            (* diagonal term P(n,n) *)
            let
              val fnn  = Math.sqrt (Real.fromInt (2*n - 1) / Real.fromInt (2*n))
              val pnn1 = gp  (n-1) (n-1)
              val dpnn1 = gdp (n-1) (n-1)
            in
              sp  n n (fnn * sinT * pnn1);
              sdp n n (fnn * (cosT * pnn1 + sinT * dpnn1))
            end;
            (* off-diagonal terms P(n,m) for m = 0..n-1 *)
            let
              fun buildM m =
                if m > n - 1 then ()
                else (
                  let
                    val nm2  = Real.fromInt ((n-m) * (n+m))   (* (n-m)(n+m) = n^2-m^2 *)
                    val a    = Real.fromInt (2*n - 1) / Math.sqrt nm2
                    val pnm1m = gp  (n-1) m
                    val dpnm1m = gdp (n-1) m
                    val pnm =
                      if n >= 2 then
                        let
                          val nm2_prev = Real.fromInt ((n-1-m) * (n-1+m))
                          val b = Math.sqrt (Real.fromInt (2*n+1) * nm2_prev /
                                             (Real.fromInt (2*n-3) * nm2))
                        in
                          a * cosT * pnm1m - b * gp (n-2) m
                        end
                      else
                        (* n=1, m=0 is handled above; n=1, m=1 is diagonal *)
                        raise Fail "unreachable"
                    val dpnm =
                      let
                        val nm2_prev = Real.fromInt ((n-1-m) * (n-1+m))
                        val b = Math.sqrt (Real.fromInt (2*n+1) * nm2_prev /
                                           (Real.fromInt (2*n-3) * nm2))
                      in
                        a * (cosT * dpnm1m - sinT * pnm1m) - b * gdp (n-2) m
                      end
                  in
                    sp  n m pnm;
                    sdp n m dpnm;
                    buildM (m + 1)
                  end
                )
            in buildM 0 end
          );
          buildN (n + 1)
        )

      val () = buildN 1
    in
      (p, dp)
    end

  fun field {latDeg, lonDeg, altKm, coeffs} =
    let
      val colat = deg2rad (90.0 - latDeg)
      val lon   = deg2rad lonDeg
      val cosT  = Math.cos colat
      val sinT  = Math.sin colat
      val r     = earthA + altKm

      val nMax  = List.foldl (fn ((n, _, _, _), mx) => if n > mx then n else mx) 1 coeffs
      val (pArr, dpArr) = schmidtP nMax cosT sinT

      fun gp  n m = Array.sub (pArr,  idx n m)
      fun gdp n m = Array.sub (dpArr, idx n m)

      (* Accumulate field components in spherical (r, theta, phi) NED convention:
           B_r     = sum (n+1) * (a/r)^{n+2} * (g cos(ml) + h sin(ml)) * P(n,m)
           B_theta = sum        (a/r)^{n+2} * (g cos(ml) + h sin(ml)) * dP(n,m)/dtheta
           B_phi   = sum (1/sinT) * (a/r)^{n+2} * m * (g sin(ml) - h cos(ml)) * P(n,m)
         North = -B_theta, East = B_phi, Down = B_r *)
      val sumBr     = ref 0.0
      val sumBtheta = ref 0.0
      val sumBphi   = ref 0.0

      val () = List.app (fn (n, m, gnm, hnm) =>
        let
          val ratio  = Math.pow (earthA / r, Real.fromInt (n + 2))
          val mReal  = Real.fromInt m
          val mLon   = mReal * lon
          val cosMl  = Math.cos mLon
          val sinMl  = Math.sin mLon
          val ghCos  = gnm * cosMl + hnm * sinMl  (* g*cos(ml) + h*sin(ml) *)
          val ghSin  = gnm * sinMl - hnm * cosMl  (* g*sin(ml) - h*cos(ml) *)
          val pnm    = gp  n m
          val dpnm   = gdp n m
        in
          sumBr     := !sumBr     + Real.fromInt (n + 1) * ratio * ghCos * pnm;
          sumBtheta := !sumBtheta + ratio * ghCos * dpnm;
          sumBphi   := !sumBphi   + ratio * mReal * ghSin * pnm
        end) coeffs

      (* North = (1/r)*dV/dtheta = sumBtheta
         East  = B_phi = sumBphi / sinT
         Down  = dV/dr = -sumBr  (outward B_r negated gives downward Z) *)
      val north = !sumBtheta
      val east  = if Real.abs sinT < 1.0e~10 then 0.0
                  else !sumBphi / sinT
      val down  = ~ (!sumBr)
    in
      {north = north, east = east, down = down}
    end

  fun declination {north, east, down = _} =
    Math.atan2 (east, north) * 180.0 / pi

  fun inclination {north, east, down} =
    let val h = Math.sqrt (north * north + east * east)
    in Math.atan2 (down, h) * 180.0 / pi end

  fun horizontalIntensity {north, east, down = _} =
    Math.sqrt (north * north + east * east)

  fun totalIntensity {north, east, down} =
    Math.sqrt (north * north + east * east + down * down)

  (* Axial dipole only: g10 = -29404.5 nT (WMM2020 approximation) *)
  val sampleCoeffs : coeff list = [(1, 0, ~29404.5, 0.0)]
end
