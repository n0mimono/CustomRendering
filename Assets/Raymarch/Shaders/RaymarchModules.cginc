
//////////////////////////////////////////////////////////////////////////////////////////////
#ifndef RAYMARCH_MODULES
#define RAYMARCH_MODULES
//////////////////////////////////////////////////////////////////////////////////////////////

#include "noiseSimplex.cginc"

//////////////////////////////////////////////////////////////////////////////////////////////
// 
// Math functions
// 
//////////////////////////////////////////////////////////////////////////////////////////////

#define M_PI    3.1415926
#define DEG2RAD 0.0174533
#define RAD2DEG 57.2958

float mod(float x, float y) {
  return x - y * floor(x/y);
}

float2 mod(float2 x, float y) {
  return float2(mod(x.r,y), mod(x.g,y));
}

float3 mod(float3 x, float y) {
  return float3(mod(x.r,y), mod(x.g,y), mod(x.b,y));
}

float smin(float a, float b, float r) {
  return -log(exp(-r * a) + exp(-r * b)) / r;
}

float smax(float a, float b, float r) {
  return log(exp(r * a) + exp(r * b)) / r;
}

//////////////////////////////////////////////////////////////////////////////////////////////
// 
// Basic raymarch functions
// ref: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
// 
//////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////
// transformations
////////////////////////////////

float3 trRepeat(float3 p, float m) {
  return mod(p, m) - m * 0.5;
}

float3 trRepeat1(float3 p, float m) {
  float q = mod(p.y, m) - m * 0.5;
  return float3(p.x, q, p.z);
}

float3 trRepeat2(float3 p, float m) {
  float2 q = mod(p.xz, m) - m * 0.5;
  return float3(q.x, p.y, q.y);
}

float3 trScale(float3 p, float3 a) {
  return p * a;
}

float3 trTrans(float3 p, float3 t) {
  return p + t;
}

float3 trRotate(float3 p, float angle, float3 axis){
  float3 a = normalize(axis);
  float s = sin(angle);
  float c = cos(angle);
  float r = 1.0 - c;
  float3x3 m = float3x3(
    a.x * a.x * r + c,
    a.y * a.x * r + a.z * s,
    a.z * a.x * r - a.y * s,
    a.x * a.y * r - a.z * s,
    a.y * a.y * r + c,
    a.z * a.y * r + a.x * s,
    a.x * a.z * r + a.y * s,
    a.y * a.z * r - a.x * s,
    a.z * a.z * r + c
  );
  return mul(m, p);
}

float3 trRotate(float3 p, float4 r) {
  return trRotate(p, r.w, r.xyz);
}

float3 trTwist(float3 p, float power){
  float s = sin(power * p.y);
  float c = cos(power * p.y);
  float3x3 m = float3x3(
      c, 0, -s,
      0, 1,  0,
      s, 0,  c
   );
  return mul(m, p);
}

////////////////////////////////
// operations
////////////////////////////////

float opUni(float d1, float d2) {
  return min(d1, d2);
}

float opUni(float d1, float d2, float r) {
  return smin(d1, d2, r);
}

float opSub(float d1, float d2) {
  return max(-d1, d2);
}

float opSub(float d1, float d2, float r) {
  return smax(-d1, d2, r);
}

float opInt(float d1, float d2) {
  return max(d1, d2);
}

float opInt(float d1, float d2, float r) {
  return smax(d1, d2, r);
}

float opDisp(float d1, float d2) {
  return d1 + d2;
}

float opSmooth(float d, float s) {
  return d - s;
}

////////////////////////////////
// primitives
////////////////////////////////

float sdSphere(float3 p, float3 r) {
  return length(p/r) - 1;
}

float sdSphere(float3 p, float r) {
  return sdSphere(p, float3(r,r,r));
}

float sdBox(float3 p, float3 b) {
  float3 d = abs(p) - b;
  return min(max(d.x, max(d.y, d.z)),0) + length(max(d,0));
}

float sdBox(float3 p, float b) {
  return sdBox(p, float3(b,b,b));
}

float sdTorus(float3 p, float4 t) {
  return length(float2(length(p.xy) - t.x, p.z)) - t.y;
}

float sdHex(float3 p, float4 h) {
  float3 q = abs(p.xyz);
  return max(max(q.x + q.z*0.577, q.z*1.154) - h.x, q.y - h.y);
}

float sdCylinder(float3 p, float4 h) {
  float2 d = abs(float2(length(p.xz), p.y)) - h.xy;
  return min(max(d.x, d.y), 0) + length(max(d, 0));
}

float sdTriangle(float3 p, float4 h) {
  float3 q = abs(p);
  return max(q.y-h.y, max(q.x*0.866+p.z*0.5, -p.z) - h.x*0.5);
}



//////////////////////////////////////////////////////////////////////////////////////////////
// 
// Raymarch function examples
// 
//////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////
// distance funcsion examples
////////////////////////////////

float distFuncSphere(float3 p) {
  return sdSphere(p, 0.5);
}

float distFuncBox(float3 p) {
  return sdBox(p, 0.5);
}

float distFuncTorus(float3 p) {
  return sdTorus(p, float4(0.75, 0.25, 0, 0));
}

float distFuncHex(float3 p) {
  return sdHex(p, float4(1, 5, 0, 0));
}

float distFuncTrial(float3 p) {
  p = trRotate(trTwist(p, 0.48), 0.62, normalize(float3(1,1,1)));
  float d1 = sdTorus(p, float4(0.81, 0.61, 0, 0));
  float d2 = sdBox(p, float3(1,1.78,1));
  return opSub(d1, d2, 7.11);
}

////////////////////////////////
// uv functions
////////////////////////////////

float2 uvFuncBasic(float3 p) {
  return float2(p.x + p.y, p.z - p.x);
}

float2 uvFuncQuartz(float3 p) {
  float3 q = p / length(p);
  float u = q.y * acos(q.z) / M_PI + p.x + p.y;
  float v = q.y * acos(q.x) / M_PI + p.z - p.y;
  return float2(u, v);
}

float2 uvFuncSphere(float3 p) {
  float3 q = p / length(p);
  float u = acos(q.z);
  float v = acos(q.x);

  return float2(u, v) / M_PI;
}

float2 uvFuncBox(float3 p) {
  float3 q = abs(p);

  float m = q.x;
  if (q.x > q.y && q.x > q.z) {
    return float2(p.y, p.z);
  } else if (q.y > q.z && q.y > q.x) {
    return float2(p.z, p.x);
  } else {
    return float2(p.x, p.y);
  }
}


////////////////////////////////
// coloring functions
////////////////////////////////

float4 diffuseFuncBase(float3 p, float d, float i) {
  return float4(1,1,1,1);
}

//////////////////////////////////////////////////////////////////////////////////////////////
// 
// Additional raymarch functions
// 
//////////////////////////////////////////////////////////////////////////////////////////////

float3 trRepeat2p(float3 p, float m, float d) {
  if (mod(floor(p.x / m) + floor(p.z / m), d) == 0) return p;
  return trRepeat2(p, m);
}

float3 trRepeat2n(float3 p, float m, float d) {
  float n = snoise(floor(p.xz / m));
  p.y += n * d;
  return trRepeat2(p, m);
}

////////////////////////////////
// fold function examples
// ref: http://blog.hvidtfeldts.net
// ref: http://www.fractalforums.com/ifs-iterated-function-systems/kaleidoscopic-(escape-time-ifs)/
////////////////////////////////


float3 fBoxFold(float3 p, float l) {
  return clamp(p, -l, l) * 2 - p;
}

float3 fSphereFold(float3 p, float l2, float m2) {
  float r2 = dot(p,p);
  if (r2 < m2) return p * (l2/m2);
  else if (r2 < l2) return p * (l2/r2);
  return p;
}

float3 fTetraFold(float3 p) {
  if (p.x + p.y < 0) p.xy = -p.yx;
  if (p.x + p.z < 0) p.xz = -p.zx;
  if (p.y + p.z < 0) p.zy = -p.yz;
  return p;
}

float3 fTetraFoldNegative(float3 p) {
  if (p.x - p.y < 0) p.xy = p.yx;
  if (p.x - p.z < 0) p.xz = p.zx;
  if (p.y - p.z < 0) p.zy = p.yz;
  return p;
}

float3 fCubicFold(float3 p) {
  return abs(p);
}

float3 fOctaFold(float3 p) {
  if (p.x - p.y < 0) p.xy = p.yx;
  if (p.x + p.y < 0) p.xy = -p.yx;
  if (p.x - p.z < 0) p.xz = p.zx;
  if (p.x + p.z < 0) p.xz = -p.zx;
  return p;
}

#ifndef FRAC_ITERATION
#define FRAC_ITERATION 5
#endif

////////////////////////////////
// fractal distance estimation examples
////////////////////////////////

float sdFractalMandelbulb(float3 p, float bailout, float power) {
  float3 z = p;
  float dr = 1;
  float r = 0;
  for (int i = 0; i < FRAC_ITERATION; i++) {
    r = length(z);
    if (r > bailout) break;

    float theta = acos(z.z/r);
    float phi = atan2(z.y, z.x);
    dr = pow(r, power-1)*power*dr + 1;

    float zr = pow(r, power);
    theta = theta * power;
    phi = phi * power;

    z = zr*float3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
    z += p;
  }
  return 0.5*log(r)*r/dr;
}

float sdFractalMandelbox(float3 p, float4 t) {
  float3 z = p;
  float dr = 1;
  for (int i = 0; i < FRAC_ITERATION; i++) {
    z = fBoxFold(z, t.x);
    z = fSphereFold(z, t.y, t.z);
    dr = fSphereFold(float3(dr,0,0), t.y, t.z).x;
    z = t.w * z + p;
    dr = abs(t.w) * dr + 1;
  }
  return length(z)/abs(dr);
}

float sdFractalTetrahedron(float3 p, float a, float b) {
  float r;
  for (int i = 0; i < FRAC_ITERATION; i++) {
    p = fTetraFold(p);
    p = p * a + (1 - a) * b;
  }
  return length(p) * pow(a, -FRAC_ITERATION);
}

float sdFractalKaleido(float3 p, float4 c, float4 r1, float4 r2) {
  float a = c.w;
  float3 b = c.xyz;
  float r;
  for (int i = 0; i < FRAC_ITERATION; i++) {
    p = trRotate(p, r1);
    p = fTetraFoldNegative(abs(p));

    p.z -= 0.5 * b.z * (a - 1) / a;
    p.z = abs(-p.z);
    p.z += 0.5 * b.z * (a - 1) / a;

    p = trRotate(p, r2);
    p.xy = p.xy * a + (1 - a) * b.xy;
    p.z = a * p.z;

  }
  return (length(p)-2) * pow(a, -FRAC_ITERATION);
}

//////////////////////////////////////////////////////////////////////////////////////////////
#endif // RAYMARCH_MODULES
//////////////////////////////////////////////////////////////////////////////////////////////
