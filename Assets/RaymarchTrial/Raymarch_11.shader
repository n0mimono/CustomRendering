Shader "Raymarch/Raymarch_11_Hex" {
  Properties {
    [Enum(Sphere,0,Box,1,Torus,2,Hex,3,Custom,4)] _Model ("Model", Float) = 0
    [Toggle] _UseRepeat ("Use Repeat", Float) = 0

    [Enum(None,0,Sphere,1,Box,2)] _ModelClip ("Model Clip", Float) = 0
    _ClipThreshold ("Clip Threshold", Float) = 0.01

    [Enum(Basic,0,Sphere,1,Box,2)] _UvType ("UV Type", Float) = 0
    _UvTiling ("UV Tiling Scale", Float) = 1

    [Header(Figure Option)]
    _SphereSize ("Sphere Size", Vector) = (1,1,1,1)
    _BoxSize ("Box Size", Vector) = (1,1,1,1)
    _TorusParams ("Toras Params", Vector) = (1,1,0,0)
    _HexParams ("Hex Params", Vector) = (1,1,0,0)
    _CustomParams ("Custom Params", Vector) = (1,1,0,0)

    [Header(Extra Option)]
    _RepeatClamp ("Repeat Clamp", Float) = 1
    _SmoothExpansion ("Smooth Expansion", Float) = 0
    _RayDamp ("Ray Damp", Float) = 1
    _LocalOffset ("Local Offset", Vector) = (0,0,0,0)

    [Header(Textures)]
    _MainTex ("Texture", 2D) = "white" {}
  }

  CGINCLUDE
    float mod(float x, float y) {
      return x - y * floor(x/y);
    }

    float3 mod(float3 x, float y) {
      return float3(mod(x.r,y), mod(x.g,y), mod(x.b,y));
    }

    float3 repeat(float3 p, float m) {
      return mod(p, m) - m * 0.5;
    }

    float smin(float a, float b, float r) {
      return -log(exp(-r * a) + exp(-r * b)) / r;
    }

    float smax(float a, float b, float r) {
      return log(exp(r * a) + exp(r * b)) / r;
    }

    // https://wgld.org/d/glsl/g017.html
    float3 rotate(float3 p, float angle, float3 axis){
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

    // https://wgld.org/d/glsl/g017.html
    float3 twist(float3 p, float power){
      float s = sin(power * p.y);
      float c = cos(power * p.y);
      float3x3 m = float3x3(
          c, 0, -s,
          0, 1,  0,
          s, 0,  c
       );
      return mul(m, p);
    }

    float funcSphere(float3 p, float3 r) {
      return length(p/r) - 1;
    }

    float funcSphere(float3 p, float r) {
      return funcSphere(p, float3(r,r,r));
    }

    float funcBox(float3 p, float3 b) {
      float3 d = abs(p) - b;
      return min(max(d.x, max(d.y, d.z)),0) + length(max(d,0));
    }

    float funcBox(float3 p, float b) {
      return funcBox(p, float3(b,b,b));
    }

    float funcTorus(float3 p, float4 t) {
      return length(float2(length(p.xy) - t.x, p.z)) - t.y;
    }

    float funcHex(float3 p, float4 h) {
      float3 q = abs(p.xyz);
      return max(max(q.x + q.z*0.577, q.z*1.154) - h.x, q.y - h.y);
    }

    float _RepeatClamp;

    float3 trans(float3 p) {
      return repeat(p, _RepeatClamp);
    }

    float4 _SphereSize;
    float4 _BoxSize;
    float4 _TorusParams;
    float4 _HexParams;
    float4 _CustomParams;

    float distFuncSphere(float3 p) {
      return funcSphere(p, _SphereSize.xyz / _SphereSize.w);
    }

    float distFuncBox(float3 p) {
      return funcBox(p, _BoxSize.xyz / _BoxSize.w);
    }

    float distFuncTorus(float3 p) {
      return funcTorus(p, _TorusParams);
    }

    float distFuncHex(float3 p) {
      return funcHex(p, _HexParams);
    }

    float distFuncCustom(float3 p) {
      p = rotate(twist(p, _CustomParams.x), _CustomParams.y, normalize(float3(1,1,1)));
      return smax(-distFuncTorus(p), distFuncBox(p), _CustomParams.z);
    }

    float _Model;
    float _UseRepeat;
    float _SmoothExpansion;

    float distFunc(float3 p) {
      if (_UseRepeat) p = trans(p);

      float dist = 1;
      if      (_Model == 0) dist = distFuncSphere(p);
      else if (_Model == 1) dist = distFuncBox(p);
      else if (_Model == 2) dist = distFuncTorus(p);
      else if (_Model == 3) dist = distFuncHex(p);
      else if (_Model == 4) dist = distFuncCustom(p);

      dist -= _SmoothExpansion;
      return dist;
    }

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

    float _UvType;
    float _UvTiling;

    float2 uvFunc(float3 p) {
      float2 uv = float2(1,1);

      if      (_UvType == 0) uv = uvFuncBasic(p);
      else if (_UvType == 1) uv = uvFuncSphere(p);
      else if (_UvType == 2) uv = uvFuncBox(p);

      uv *= _UvTiling;
      return uv;
    }

    float _ModelClip;
    float _ClipThreshold;
    float _RayDamp;
    float4 _LocalOffset;

    sampler2D _MainTex;
  ENDCG

	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

      #define DIST_FUNC distFunc
      #define UV_FUNC uvFunc

      float3 normalFunc(float3 p){
        float d = 0.001;
        return normalize(float3(
          DIST_FUNC(p + float3(  d, 0.0, 0.0)) - DIST_FUNC(p + float3( -d, 0.0, 0.0)),
          DIST_FUNC(p + float3(0.0,   d, 0.0)) - DIST_FUNC(p + float3(0.0,  -d, 0.0)),
          DIST_FUNC(p + float3(0.0, 0.0,   d)) - DIST_FUNC(p + float3(0.0, 0.0,  -d))
        ));
      }

      float3 unscaler() {
        return float3(
          length(unity_WorldToObject[0].xyz),
          length(unity_WorldToObject[1].xyz),
          length(unity_WorldToObject[2].xyz)
          );
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

			struct v2f {
        float4 pos      : SV_POSITION;
        float4 vertex   : TEXCOORD0;
        float4 worldPos : TEXCOORD1;
			};
			
			v2f vert (appdata_full v) {
				v2f o;
				o.pos      = mul(UNITY_MATRIX_MVP, v.vertex);
        o.vertex   = v.vertex;
        o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {
        float3 localCameraPos = toLocal(_WorldSpaceCameraPos.xyz);
        float3 localPos       = toLocal(i.worldPos.xyz);
        float3 viewDir        = normalize(localCameraPos - localPos);

        float3 ray    = -viewDir;
        float3 rayPos = localPos;

        float dist = 0;
        for (int i = 0; i < 64; i++) {
          dist = DIST_FUNC(rayPos);
          rayPos += ray * dist * _RayDamp;
        }
        clip(0.01 - dist);
        if (isnan(dist)) discard;

        float d = dist;
        if (_ModelClip == 1) {
          d = funcSphere(rayPos, scaler() * 0.5);
        } else if (_ModelClip == 2) {
          d = funcBox(rayPos, scaler() * 0.5);
        }
        clip(_ClipThreshold - d);

        float3 localNormal = normalFunc(rayPos);
        float3 worldNormal = toWorldNormal(localNormal);

        float2 uv = UV_FUNC(rayPos);

        return fixed4(worldNormal * 0.5 + 0.5,1);
        //return fixed4(uv.x,0,uv.y,1);
        //return tex2D(_MainTex, uv);
			}
			ENDCG
		}
	}
}
