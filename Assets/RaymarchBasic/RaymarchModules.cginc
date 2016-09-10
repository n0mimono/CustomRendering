
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

// transformations

float3 trRepeat(float3 p, float m) {
    return mod(p, m) - m * 0.5;
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

// operations

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

float opDsp(float d1, float d2) {
  return d1 + d2;
}

float opSmooth(float d, float s) {
  return d - s;
}

// primitives

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

//////////////////////////////////////////////////////////////////////////////////////////////
// 
// Raymarch function examples
// 
//////////////////////////////////////////////////////////////////////////////////////////////

// distance funcsion examples

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

// uv functions

float2 uvFuncBasic(float3 p) {
  return float2(p.x + p.y, p.z - p.x);
}

float2 uvFuncSphere(float3 p) {
  float3 q = p / length(p);
  float u = acos(q.z);
  float v = acos(q.x);

  float pi = 3.1415926;
  return float2(u, v) / pi;
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

//////////////////////////////////////////////////////////////////////////////////////////////
#endif // RAYMARCH_MODULES
//////////////////////////////////////////////////////////////////////////////////////////////
