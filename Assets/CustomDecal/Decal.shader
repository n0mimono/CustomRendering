// Upgrade NOTE: commented out 'float4x4 _CameraToWorld', a built-in variable
// Upgrade NOTE: replaced '_CameraToWorld' with 'unity_CameraToWorld'
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Decal" {
	Properties {
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader {
		Pass {
      ZWrite Off
      Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

      struct v2f {
        float4 pos         : SV_POSITION;
        float4 spos        : TEXCOORD1;
        float3 ray         : TEXCOORD2;
        float3 orientation : TEXCOORD3;
      };
			
			v2f vert (float3 v: POSITION) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, float4(v, 1));
        o.spos = ComputeScreenPos(o.pos);
        o.ray = mul(UNITY_MATRIX_MV, float4(v, 1)).xyz * float3(-1, -1, 1);
        o.orientation = mul((float3x3)unity_ObjectToWorld, float3(0, 1, 0));

				return o;
			}

      CBUFFER_START(UnityPerCamera2)
      // float4x4 _CameraToWorld;
      CBUFFER_END

      sampler2D _MainTex;
      sampler2D_float _CameraDepthTexture;
      sampler2D _NormalsCopy;

			fixed4 frag (v2f i) : SV_Target {

        // reconstruction
        i.ray = i.ray * (_ProjectionParams.z / i.ray.z);
        float2 uv = i.spos.xy / i.spos.w;
        float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
        depth = Linear01Depth(depth);

        float4 vpos = float4(i.ray * depth, 1);
        float3 wpos = mul (unity_CameraToWorld, vpos).xyz;
        float3 opos = mul (unity_WorldToObject, float4(wpos, 1)).xyz;

        clip (float3(0.5, 0.5, 0.5) - abs(opos.xyz));
        float2 uv0 = opos.xz + 0.5;

        half3 normal = tex2D(_NormalsCopy, uv).rgb;
        fixed3 wnormal = normal.rgb * 2.0 - 1.0;

        // clipping
        clip(dot(wnormal, i.orientation) - 0.3);

        fixed4 col = tex2D(_MainTex, uv0);
				return col;
			}
			ENDCG
		}
	}
}
