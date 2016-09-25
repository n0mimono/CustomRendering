Shader "Melt/Melter" {
	Properties {
    _Color ("Color", Color) = (1,1,1,1)
    _SpecularGloss ("Specular Gloss", Color) = (1,1,1,1)
    _Emission ("Emission", Color) = (0,0,0,0)
	}
	SubShader {
		Pass {
      ZWrite Off

      CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

      struct ap {
        float4 vertex: POSITION;
        float3 normal : NORMAL;
      };

      struct v2f {
        float4 pos    : SV_POSITION;
        float4 spos   : TEXCOORD1;
        float3 ray    : TEXCOORD2;
        float3 normal : TEXCOORD3;
      };
			
			v2f vert (ap v) {
				v2f o;
				o.pos    = mul(UNITY_MATRIX_MVP, v.vertex);
        o.spos   = ComputeScreenPos(o.pos);
        o.ray    = mul(UNITY_MATRIX_MV, v.vertex).xyz * float3(-1, -1, 1);
        o.normal = UnityObjectToWorldNormal(v.normal);
				return o;
			}

      float4 _Color;
      float4 _SpecularGloss;
      float4 _Emission;

      sampler2D_float _CameraDepthTexture;
      sampler2D _CameraGBufferTexture0;
      sampler2D _CameraGBufferTexture1;
      sampler2D _CameraGBufferTexture2;
      sampler2D _CameraGBufferTexture3;

      float _UseSphereMesh;
      float _ClipOrientation;

			void frag (v2f i,
        out half4 outDiffuse  : COLOR0,
        out half4 outSpecular : COLOR1,
        out half4 outNormal   : COLOR2,
        out half4 outEmission : COLOR3
      ) {

        // reconstruction
        i.ray = i.ray * (_ProjectionParams.z / i.ray.z);
        float2 uv = i.spos.xy / i.spos.w;

        float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
        depth = Linear01Depth(depth);

        float4 vpos = float4(i.ray * depth, 1);
        float3 wpos = mul (unity_CameraToWorld, vpos).xyz;
        float3 opos = mul (unity_WorldToObject, float4(wpos, 1)).xyz;

        half4 albedo   = tex2D(_CameraGBufferTexture0, uv);
        half4 specular = tex2D(_CameraGBufferTexture1, uv);
        half4 normal   = tex2D(_CameraGBufferTexture2, uv);
        half4 emission = tex2D(_CameraGBufferTexture3, uv);

        outDiffuse  = albedo;
        outSpecular = specular;
        outNormal   = float4(i.normal*0.5+0.5,1);// normal;
        outEmission = emission;
 			}
			ENDCG
		}
	}
}
