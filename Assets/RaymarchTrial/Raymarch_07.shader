Shader "Raymarch/Raymarch_07_More" {
  Properties {
    [Enum(Sphere,0,Box,1,Torus,2)] _Model ("Model", Float) = 0
    [Toggle] _UseRepeat ("Use Repeat", Float) = 0

    [Enum(None,0,Sphere,1,Box,2)] _ModelClip ("Model Clip", Float) = 0
    _ClipThreshold ("Clip Threshold", Float) = 0.01

    [Header(Spehre Option)]
    _SphereSize ("Sphere Size", Float) = 0.5
    [Header(Box Option)]
    _BoxSize ("Box Size", Float) = 0.5
    [Header(Torus Option)]
    _TorusParams ("Toras Params", Vector) = (1,1,0,0)

    [Header(Extra Option)]
    _RepeatClamp ("Repeat Clamp", Float) = 1
    _SmoothExpansion ("Smooth Expansion", Float) = 0
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

    float _RepeatClamp;

    float3 trans(float3 p) {
      return repeat(p, _RepeatClamp);
    }

    float _SphereSize;
    float _BoxSize;
    float4 _TorusParams;

    float distFuncSphere(float3 p) {
      return funcSphere(p, _SphereSize);
    }

    float distFuncBox(float3 p) {
      return funcBox(p, _BoxSize);
    }

    float distFuncTorus(float3 p) {
      return funcTorus(p, _TorusParams);
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

      dist -= _SmoothExpansion;
      return dist;
    }

    float _ModelClip;
    float _ClipThreshold;
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

      float3 normalFunc(float3 p){
        float d = 0.0001;
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
        return q * scaler();
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
          rayPos += ray * dist;
        }

        float d = abs(dist);
        if (_ModelClip == 1) {
          d = funcSphere(rayPos, scaler() * 0.5);
        } else if (_ModelClip == 2) {
          d = funcBox(rayPos, scaler() * 0.5);
        }
        clip(_ClipThreshold - d);

        float3 localNormal = normalFunc(rayPos);
        float3 worldNormal = toWorldNormal(localNormal);
        return fixed4(worldNormal * 0.5 + 0.5,1);
			}
			ENDCG
		}
	}
}
