Shader "Raymarch/Raymarch_03_ObjectSpace" {
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

      float distFunc(float3 p) {
        return length(p) - 0.5;
      }

      float3 normalFunc(float3 p){
        float d = 0.0001;
        return normalize(float3(
          distFunc(p + float3(  d, 0.0, 0.0)) - distFunc(p + float3( -d, 0.0, 0.0)),
          distFunc(p + float3(0.0,   d, 0.0)) - distFunc(p + float3(0.0,  -d, 0.0)),
          distFunc(p + float3(0.0, 0.0,   d)) - distFunc(p + float3(0.0, 0.0,  -d))
        ));
      }

      float3 toLocal(float3 p) {
        return mul(unity_WorldToObject, float4(p,1)).xyz;
      }

      float3 toWorldNormal(float3 n) {
        return mul(unity_ObjectToWorld, float4(n,0)).xyz;
      }

			struct v2f {
        float4 pos      : SV_POSITION;
        float4 vertex   : TEXCOORD0;
			};
			
			v2f vert (appdata_full v) {
				v2f o;
				o.pos      = mul(UNITY_MATRIX_MVP, v.vertex);
        o.vertex   = v.vertex;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {
        float3 localCameraPos = toLocal(_WorldSpaceCameraPos.xyz);
        float3 viewDir        = normalize(localCameraPos - i.vertex);

        float3 ray    = -viewDir;
        float3 rayPos = i.vertex;

        float dist = 0;
        for (int i = 0; i < 16; i++) {
          dist = distFunc(rayPos);
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
