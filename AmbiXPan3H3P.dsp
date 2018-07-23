//
// SuperCollider AmbiX Ambisonics panner
//
// ACN/SN3D, cartesian coordinates
// for acn in `seq 0 35` ; do python3 symbolic_spherical_harmonics.py --seminormalized --four_pi -t faust --acn $acn ; done

declare name "AmbiXPan3H3P";

pg = (
  1,
  y,
  z,
  x,
  sqrt(3)*x*y,
  sqrt(3)*y*z,
  (1/2)*(3*pow(z, 2) - 1),
  sqrt(3)*x*z,
  (1/2)*sqrt(3)*(pow(x, 2) - pow(y, 2)),
  (1/4)*sqrt(10)*(3*pow(x, 2)*y - pow(y, 3)),
  sqrt(15)*x*y*z,
  (1/4)*sqrt(6)*y*(5*pow(z, 2) - 1),
  (1/2)*z*(5*pow(z, 2) - 3),
  (1/4)*sqrt(6)*x*(5*pow(z, 2) - 1),
  (1/2)*sqrt(15)*z*(pow(x, 2) - pow(y, 2)),
  (1/4)*sqrt(10)*(pow(x, 3) - 3*x*pow(y, 2))
  );

declare version	"1.0";
declare author "AmbisonicDecoderToolkit";
declare license "GPL";
declare copyright "(c) Aaron J. Heller 2015, Fernando Lopez-Lezcano 2017";

math = library("math.lib");    // for PI
music = library("music.lib");  // for "noise"

process =  _ * level <: gain(pg);

  // azimuth and elevation panners
  azi = hslider("azi", 0, 0, 2 * pi, 0.1);
  elev = hslider("elev", 0,  -pi/2,  pi/2, 0.1);
  level = hslider("level", 0, 0, 1, 0.01);
  // spherical to cartesian
  r = 1;
  x = r * cos(azi)*cos(elev);
  y = r * sin(azi)*cos(elev);
  z = r * sin(elev);

pi = math.PI;

// gain bus
gain(c) = R(c) with {
  R((c,cl)) = R(c),R(cl);
  R(1)      = _;
  R(0)      = !;
  R(float(0)) = R(0);
  R(float(1)) = R(1);
  R(c)      = *(c);
};

