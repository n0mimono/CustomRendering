Shader "Raymarch/Raymarch_05_Primitive" {
  Properties {
    [Enum(Sphere,0,Box,1)] _Model ("Model", Float) = 0

    [Header(Spehre Option)]
    _SphereSize ("Sphere Size", Float) = 0.5
    [Header(Box Option)]
    _BoxSize ("Box Size", Float) = 0.5
  }

  CGINCLUDE
    float funcSphere(float3 p, float r) {
      return length(p) - r;
    }

    float funcBox(float3 p, float b) {
      float3 d = abs(p) - b;
      return max(d.x, max(d.y, d.z));
    }

    float _SphereSize;
    float _BoxSize;

    float distFuncSphere(float3 p) {
      return funcSphere(p, _SphereSize);
    }

    float distFuncBox(float3 p) {
      return funcBox(p, _BoxSize);
    }

    float _Model;

    float distFunc(float3 p) {
      if      (_Model == 0) return distFuncSphere(p);
      else if (_Model == 1) return distFuncBox(p);

      return 1;
    }
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

      float3 toLocal(float3 p) {
        return mul(unity_WorldToObject, float4(p,1)).xyz;
      }

      float3 toWorldNormal(float3 n) {
        return normalize(mul(unity_ObjectToWorld, float4(n,0)).xyz);
      }

			struct v2f {
        float4 pos    : SV_POSITION;
        float4 vertex : TEXCOORD0;
			};
			
			v2f vert (appdata_full v) {
				v2f o;
				o.pos    = mul(UNITY_MATRIX_MVP, v.vertex);
        o.vertex = v.vertex;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {
        float3 localCameraPos = toLocal(_WorldSpaceCameraPos.xyz);
        float3 viewDir        = normalize(localCameraPos - i.vertex);

        float3 ray    = -viewDir;
        float3 rayPos = i.vertex;

        float dist = 0;
        for (int i = 0; i < 32; i++) {
          dist = DIST_FUNC(rayPos);
          rayPos += ray * dist;
        }
        clip(0.01 - abs(dist));

        float3 localNormal = normalFunc(rayPos);
        float3 worldNormal = toWorldNormal(localNormal);
        return fixed4(worldNormal * 0.5 + 0.5,1);
			}
			ENDCG
		}
	}
}
