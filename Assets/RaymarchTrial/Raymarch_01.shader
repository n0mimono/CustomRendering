Shader "Raymarch/Trial/Raymarch_01_Ray" {
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
        float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

        float3 ray    = -viewDir;
        float3 rayPos = _WorldSpaceCameraPos.xyz;

        float dist = 0;
        for (int i = 0; i < 16; i++) {
          dist = distFunc(rayPos);
          rayPos += ray * dist;
        }

        if (abs(dist) < 0.01) {
          return fixed4(1,1,1,1);
        } else {
          return fixed4(0,0,0,1);
        }

			}
			ENDCG
		}
	}
}
