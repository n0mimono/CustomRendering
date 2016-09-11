
//////////////////////////////////////////////////////////////////////////////////////////////
#ifndef RAYMARCH_BASIC
#define RAYMARCH_BASIC
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

#ifndef CLIP_THRESHOLD
#define CLIP_THRESHOLD 0.01
#endif

#ifndef DIST_FUNC
#define DIST_FUNC distFuncTrial
#endif

#ifndef UV_FUNC
#define UV_FUNC uvFuncBox
#endif

#ifndef USE_UNSCALE
#define USE_UNSCALE 1
#endif

#ifndef NORMAL_PRECISION
#define NORMAL_PRECISION 0.001
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
  return normalize(float3(
    DIST_FUNC(p + float3(  d, 0.0, 0.0)) - DIST_FUNC(p + float3( -d, 0.0, 0.0)),
    DIST_FUNC(p + float3(0.0,   d, 0.0)) - DIST_FUNC(p + float3(0.0,  -d, 0.0)),
    DIST_FUNC(p + float3(0.0, 0.0,   d)) - DIST_FUNC(p + float3(0.0, 0.0,  -d))
  ));
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
  float3 q = mul(unity_WorldToObject, float4(p,1)).xyz;
  return q * scaler() + _LocalOffset.xyz;
}

float3 toWorldNormal(float3 n) {
  float3 u = n * unscaler();
  float3 v = mul(unity_ObjectToWorld, float4(u,0)).xyz;
  return normalize(v);
}

float3x3 normToOrth(float3 n) {
  float3 localTangent = normalize(_LocalTangent.xyz + float3(0,0.1,0));
  float3 worldTangent = toWorldNormal(localTangent);

  float3 n2 = n;
  float3 n1 = normalize(worldTangent - n2.y * n2);
  float3 n0 = cross(n2, n1);
  return float3x3(n0, n1, n2);
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

v2f_raymarch vert_raymarch (appdata_full v) {
  v2f_raymarch o;
  o.pos      = mul(UNITY_MATRIX_MVP, v.vertex);
  o.vertex   = v.vertex;
  o.worldPos = mul(unity_ObjectToWorld, v.vertex);
  return o;
}

//////////////////////////////////////////////////////////////////////////////////////////////
// 
// Fragment functions
// 
//////////////////////////////////////////////////////////////////////////////////////////////

void frag_raymarch (v2f_raymarch i,
  out float4 outAlbedo   : SV_Target0,
  out float4 outSpecular : SV_Target1,
  out float4 outNormal   : SV_Target2,
  out float4 outEmission : SV_Target3
) {
  float3 localCameraPos = toLocal(_WorldSpaceCameraPos.xyz);
  float3 localPos       = toLocal(i.worldPos.xyz);
  float3 viewDir        = normalize(localCameraPos - localPos);

  float3 ray    = -viewDir;
  float3 rayPos = localPos;

  float dist = 0;
  for (int i = 0; i < RAY_ITERATION; i++) {
    dist = DIST_FUNC(rayPos);
    rayPos += ray * dist * _RayDamp;
  }
  clip(CLIP_THRESHOLD - dist);
  if (isnan(dist)) discard;

  float d = dist;
  if (_ModelClip == 1) {
    d = sdSphere(rayPos, scaler() * 0.5);
  } else if (_ModelClip == 2) {
    d = sdBox(rayPos, scaler() * 0.5);
  }
  clip(CLIP_THRESHOLD - d);

  float3 localNormal = pointToNormal(rayPos);
  float3 worldNormal = toWorldNormal(localNormal);

  float2 uv = UV_FUNC(rayPos);

  float3 localBump = UnpackNormal(tex2D(_BumpTex, TRANSFORM_TEX(uv, _BumpTex)));
  float3 worldBump = mul(localBump, normToOrth(worldNormal));

  outAlbedo   = tex2D(_MainTex, TRANSFORM_TEX(uv, _MainTex));
  outSpecular = _SpecularGloss;
  outNormal   = float4(worldBump * 0.5 + 0.5,1);
  outEmission = _Emission;
}

//////////////////////////////////////////////////////////////////////////////////////////////
#endif // RAYMARCH_BASIC
//////////////////////////////////////////////////////////////////////////////////////////////
