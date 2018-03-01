// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


//////////////////////////////////////////////////////////////////////////////////////////////
#ifndef RAYMARCH_CORE
#define RAYMARCH_CORE
//////////////////////////////////////////////////////////////////////////////////////////////

#include "UnityCG.cginc"

//////////////////////////////////////////////////////////////////////////////////////////////
// 
// Uniform variables and config
// 
//////////////////////////////////////////////////////////////////////////////////////////////

#ifndef RAY_ITERATION
#define RAY_ITERATION 64
#endif

#ifndef USE_CLIP_THRESHOLD
#define USE_CLIP_THRESHOLD 1
#endif

#ifndef CLIP_THRESHOLD
#define CLIP_THRESHOLD 0.01
#endif

#ifndef CHECK_CONV_BY_CLIP_THRESHOLD
#define CHECK_CONV_BY_CLIP_THRESHOLD 0
#endif

#ifndef DIST_FUNC
#define DIST_FUNC distFuncTrial
#endif

#ifndef ALBEDO_FUNC
#define ALBEDO_FUNC albedoFuncBase
#endif

#ifndef SPECULAR_FUNC
#define SPECULAR_FUNC specularFuncBase
#endif

#ifndef EMISSION_FUNC
#define EMISSION_FUNC emissionFuncBase
#endif

#ifndef NORMAL_FUNC
#define NORMAL_FUNC normalFuncBase
#endif

#ifndef UV_FUNC
#define UV_FUNC uvFuncBox
#endif

#ifndef USE_OBJECTSPACE
#define USE_OBJECTSPACE 1
#endif

#ifndef USE_UNSCALE
#define USE_UNSCALE 1
#endif

#ifndef NORMAL_PRECISION
#define NORMAL_PRECISION 0.001
#endif

#ifndef OUT_DEPTH
#define OUT_DEPTH 1
#endif

float  _ModelClip;
float  _RayDamp;
float4 _LocalOffset;
float4 _LocalTangent;

sampler2D _MainTex; float4 _MainTex_ST;
sampler2D _BumpTex; float4 _BumpTex_ST;
float4    _SpecularGloss;
float4    _Emission;

/* // Property example
  Properties {
    [Header(GBuffer)]
    _MainTex ("Albedo Map", 2D) = "white" {}
    _BumpTex ("Normal Map", 2D) = "bump" {}
    _SpecularGloss ("Specular/Gloss", Color) = (0,0,0,0)
    _Emission ("Emission", Color) = (1,1,1,1)

    [Header(Framework)]
    _RayDamp ("Ray Damp", Float) = 1
    _LocalOffset ("Local Offset", Vector) = (0,0,0,0)
    _LocalTangent ("Local Tangent", Vector) = (0.15,1.24,0.89,0)
    [Enum(Sphere,1,Box,2)] _ModelClip ("Model Clip", Float) = 1
  }
*/

//////////////////////////////////////////////////////////////////////////////////////////////
// 
// Object space raymarch scheme
// 
//////////////////////////////////////////////////////////////////////////////////////////////

float3 pointToNormal(float3 p){
  float d = NORMAL_PRECISION;
  float3 n = float3(
    DIST_FUNC(p + float3(  d, 0.0, 0.0)) - DIST_FUNC(p + float3( -d, 0.0, 0.0)),
    DIST_FUNC(p + float3(0.0,   d, 0.0)) - DIST_FUNC(p + float3(0.0,  -d, 0.0)),
    DIST_FUNC(p + float3(0.0, 0.0,   d)) - DIST_FUNC(p + float3(0.0, 0.0,  -d))
  );
  return normalize(n);
}

float3 unscaler() {
  #if USE_UNSCALE
  return float3(
    length(unity_WorldToObject[0].xyz),
    length(unity_WorldToObject[1].xyz),
    length(unity_WorldToObject[2].xyz)
    );
  #else
  return float3(1,1,1);
  #endif
}

float3 scaler() {
  return 1 / unscaler();
}

float3 toLocal(float3 p) {
#if USE_OBJECTSPACE
  float3 q = mul(unity_WorldToObject, float4(p,1)).xyz;
  return q * scaler() + _LocalOffset.xyz;
#else
  return p + _LocalOffset.xyz;;
#endif
}

float3 toWorld(float3 p) {
#if USE_OBJECTSPACE
  float3 q = (p - _LocalOffset.xyz) * unscaler();
  return mul(unity_ObjectToWorld, float4(q,1)).xyz;
#else
  return p - _LocalOffset.xyz;;
#endif
}

float3 toWorldNormal(float3 n) {
#if USE_OBJECTSPACE
  float3 u = n * unscaler();
  float3 v = mul(unity_ObjectToWorld, float4(u,0)).xyz;
  return normalize(v);
#else
  return normalize(n);
#endif
}

float3x3 normToOrth(float3 n) {
  float3 localTangent = normalize(_LocalTangent.xyz + float3(0,0.1,0));
  float3 worldTangent = toWorldNormal(localTangent);

  float3 n2 = n;
  float3 n1 = normalize(worldTangent - n2.y * n2);
  float3 n0 = cross(n2, n1);
  return float3x3(n0, n1, n2);
}

float worldToDepth(float3 p) {
  float4 vp = mul(UNITY_MATRIX_VP, float4(p, 1));
  return vp.z / vp.w * 0.5 + 0.5;
  //float z = length(p - _WorldSpaceCameraPos.xyz);
  //return (1.0 - z * _ZBufferParams.w) / (z * _ZBufferParams.z);
}

//////////////////////////////////////////////////////////////////////////////////////////////
// 
// Vertex functions
// 
//////////////////////////////////////////////////////////////////////////////////////////////

struct v2f_raymarch {
  float4 pos      : SV_POSITION;
  float4 vertex   : TEXCOORD0;
  float4 worldPos : TEXCOORD1;
};

v2f_raymarch vert_raymarch (appdata_base v) {
  v2f_raymarch o;
  o.pos      = UnityObjectToClipPos(v.vertex);
  o.vertex   = v.vertex;
  o.worldPos = mul(unity_ObjectToWorld, v.vertex);
  return o;
}

//////////////////////////////////////////////////////////////////////////////////////////////
// 
// Fragment functions
// 
//////////////////////////////////////////////////////////////////////////////////////////////

struct gbuffer_out {
  float4 albedo   : SV_Target0;
  float4 specular : SV_Target1;
  float4 normal   : SV_Target2;
  float4 emission : SV_Target3;
  #if OUT_DEPTH
  float  depth    : SV_Depth;
  #endif
};

float raymarch(float3 localPos, float3 viewDir, out float3 localRayPos, out float localDist) {
  float3 ray    = -viewDir;
  float3 rayPos = localPos;

  float dist = 0;
  int i;
  for (i = 0; i < RAY_ITERATION; i++) {
    dist = DIST_FUNC(rayPos);
    rayPos += ray * dist * _RayDamp;
    #if CHECK_CONV_BY_CLIP_THRESHOLD
    if (dist <= 0) break;
    #endif
  }

  localRayPos = rayPos;
  localDist   = dist;

  return (float)i/(float)RAY_ITERATION;
}

gbuffer_out frag_raymarch (v2f_raymarch i) {
  float3 localCameraPos = toLocal(_WorldSpaceCameraPos.xyz);
  float3 localPos       = toLocal(i.worldPos);
  float3 viewDir        = normalize(localCameraPos - localPos);

  float3 rayPos;
  float dist;
  float conv = raymarch(localPos, viewDir, rayPos, dist);

  #if USE_CLIP_THRESHOLD
  clip(CLIP_THRESHOLD - dist);
  #endif
  if (isnan(dist)) discard;

  #if USE_OBJECTSPACE
  float d = dist;
  if (_ModelClip == 1) {
    d = sdSphere(rayPos, scaler() * 0.5);
  } else if (_ModelClip == 2) {
    d = sdBox(rayPos, scaler() * 0.5);
  }
  clip(CLIP_THRESHOLD - d);
  #endif

  float3 localNormal = pointToNormal(rayPos);
  float3 worldNormal = toWorldNormal(localNormal);

  float2 uv = UV_FUNC(rayPos);
  float3 localBump = UnpackNormal(tex2D(_BumpTex, TRANSFORM_TEX(uv, _BumpTex)));
  float3 worldBump = mul(localBump, normToOrth(worldNormal));

  gbuffer_out g;
  g.albedo   = ALBEDO_FUNC(tex2D(_MainTex, TRANSFORM_TEX(uv, _MainTex)), rayPos, dist, conv);
  g.specular = SPECULAR_FUNC(_SpecularGloss, rayPos, dist, conv);
  g.normal   = NORMAL_FUNC(float4(worldBump * 0.5 + 0.5,1), rayPos, dist, conv);
  g.emission = EMISSION_FUNC(_Emission, rayPos, dist, conv);

  #if OUT_DEPTH
  g.depth = worldToDepth(toWorld(rayPos));
  #endif

  return g;
}

//////////////////////////////////////////////////////////////////////////////////////////////
// 
// Shadow caster
// 
//////////////////////////////////////////////////////////////////////////////////////////////

// todo: point light support
struct v2f_raymarch_caster {
  V2F_SHADOW_CASTER;
  float4 vertex   : TEXCOORD0;
  float4 worldPos : TEXCOORD1;
};

v2f_raymarch_caster vert_raymarch_caster(appdata_base v) {
  v2f_raymarch o;
  TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
  o.vertex   = v.vertex;
  o.worldPos = mul(unity_ObjectToWorld, v.vertex);
  return o;
}

float4 frag_raymarch_caster_raw(v2f_raymarch_caster i) : SV_Target {
  SHADOW_CASTER_FRAGMENT(i)
}

// todo: wip, fix some bugs
void frag_raymarch_caster (
    v2f_raymarch_caster i,
    out float4 outColor : SV_Target,
    out float  outDepth : SV_Depth
  ) {
  float3 localPos = toLocal(i.worldPos);
  float3 viewDir  = -1 * normalize(UnityWorldSpaceLightDir(i.worldPos));
  float3 rayPos;
  float dist;
  raymarch(localPos, viewDir, rayPos, dist);

  clip(CLIP_THRESHOLD - dist);
  if (isnan(dist)) discard;
  #if USE_OBJECTSPACE
  clip(CLIP_THRESHOLD - sdBox(rayPos, scaler() * 0.5));
  #endif

  outColor = float4(0,0,0,0);
  float4 vp = mul(UNITY_MATRIX_VP, float4(toWorld(rayPos), 1));
  outDepth = (vp.z / vp.w + 1) * 0.5;
}

//////////////////////////////////////////////////////////////////////////////////////////////
// 
// Procedual texture 
// 
//////////////////////////////////////////////////////////////////////////////////////////////

struct texture_out {
  float4 albedo;
  float4 specular;
  float4 normal;
  float4 emission;
};

texture_out texture_raymarch (float4 coord) {
  float3 localCameraPos = float3(0,0,-1 * coord.w);
  float3 localPos       = float3(coord.xy * 2 - 1, coord.z);
  float3 viewDir        = normalize(localCameraPos - localPos);

  float3 rayPos;
  float dist;
  float conv = raymarch(localPos, viewDir, rayPos, dist);

  bool isClip = false;
  #if USE_CLIP_THRESHOLD
  isClip = CLIP_THRESHOLD - dist < 0 ? true : isClip;
  #endif
  isClip = isnan(dist) ? true : isClip;

  float3 localNormal = pointToNormal(rayPos);

  texture_out g;
  if (isClip) {
    g.albedo   = float4(0,0,0,0);
    g.specular = float4(0,0,0,0);
    g.normal   = float4(0.5,0.5,1,1);
    g.emission = float4(0,0,0,0);
  } else {
    g.albedo   = ALBEDO_FUNC(float4(1,1,1,1), rayPos, dist, conv);
    g.specular = SPECULAR_FUNC(float4(1,1,1,1), rayPos, dist, conv);
    g.normal   = NORMAL_FUNC(float4(-1 * localNormal * 0.5 + 0.5,1), rayPos, dist, conv);
    g.emission = EMISSION_FUNC(float4(1,1,1,1), rayPos, dist, conv);
  }

  return g;
}

//////////////////////////////////////////////////////////////////////////////////////////////
#endif // RAYMARCH_CORE
//////////////////////////////////////////////////////////////////////////////////////////////
