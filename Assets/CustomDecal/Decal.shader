// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: commented out 'float4x4 _CameraToWorld', a built-in variable
// Upgrade NOTE: replaced '_CameraToWorld' with 'unity_CameraToWorld'
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Decal" {
	Properties {
		_MainTex ("Texture", 2D) = "white" {}
    _BumpMap ("Normals", 2D) = "bump" {}
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
        float3 orientationX : TEXCOORD4;
        float3 orientationZ : TEXCOORD5;
      };
			
			v2f vert (float3 v: POSITION) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, float4(v, 1));
        o.spos = ComputeScreenPos(o.pos);
        o.ray = mul(UNITY_MATRIX_MV, float4(v, 1)).xyz * float3(-1, -1, 1);
        o.orientation = mul((float3x3)unity_ObjectToWorld, float3(0, 1, 0));
        o.orientationX = mul ((float3x3)unity_ObjectToWorld, float3(1,0,0));
        o.orientationZ = mul ((float3x3)unity_ObjectToWorld, float3(0,0,1));

				return o;
			}

      CBUFFER_START(UnityPerCamera2)
      // float4x4 _CameraToWorld;
      CBUFFER_END

      sampler2D _MainTex;
      sampler2D _BumpMap;
      sampler2D_float _CameraDepthTexture;
      sampler2D _NormalsCopy;

			void frag (v2f i, out half4 outDiffuse : COLOR0, out half4 outNormal : COLOR1) {

        // reconstruction
        i.ray = i.ray * (_ProjectionParams.z / i.ray.z);
        float2 uv = i.spos.xy / i.spos.w;
        float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
        depth = Linear01Depth(depth);

        float4 vpos = float4(i.ray * depth, 1);
        float3 wpos = mul (unity_CameraToWorld, vpos).xyz;
        float3 opos = mul (unity_WorldToObject, float4(wpos, 1)).xyz;

        //clip (0.5 - length(opos.xyz));
        clip (float3(0.5,0.5,0.5) - abs(opos.xyz));

        float2 uv0 = opos.xz + 0.5;

        half3 normal = tex2D(_NormalsCopy, uv).rgb;
        fixed3 wnormal = normal.rgb * 2.0 - 1.0;
        clip (dot(wnormal, i.orientation) - 0.3);

        fixed4 col = tex2D (_MainTex, uv0);
        clip (col.a - 0.2);
        outDiffuse = col;

        fixed3 nor = UnpackNormal(tex2D(_BumpMap, uv0));
        half3x3 norMat = half3x3(i.orientationX, i.orientationZ, i.orientation);
        nor = mul (nor, norMat);
        outNormal = fixed4(nor*0.5+0.5,1);

 			}
			ENDCG
		}
	}
}
