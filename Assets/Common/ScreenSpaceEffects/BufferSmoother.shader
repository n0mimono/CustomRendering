Shader "Hidden/BufferSmoother" {
	Properties {
		_MainTex ("Texture", 2D) = "white" {}
    _SampleScale ("Sample Scale", Float) = 0
    _CenterAmp ("Center Amplitude", Range(0,1)) = 0.5
	}
	SubShader {
		Cull Off ZWrite Off ZTest Always

		Pass {
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag
			#include "UnityCG.cginc"
			
			sampler2D _MainTex;
      float4 _MainTex_TexelSize;

      float _SampleScale;
      float _CenterAmp;

			fixed4 frag (v2f_img i) : SV_Target {
        float2 uv = i.uv;
        float2 d  = _MainTex_TexelSize.xy * _SampleScale;

        float c = _CenterAmp;
        float r = (1 - c) / 8;

				float4 col =
            tex2D(_MainTex, uv) * c +
            tex2D(_MainTex, uv + float2( d.x,   0)) * r +
            tex2D(_MainTex, uv + float2( d.x, d.y)) * r +
            tex2D(_MainTex, uv + float2(   0, d.y)) * r +
            tex2D(_MainTex, uv + float2(-d.x, d.y)) * r +
            tex2D(_MainTex, uv + float2(-d.x,   0)) * r +
            tex2D(_MainTex, uv + float2(-d.x,-d.y)) * r +
            tex2D(_MainTex, uv + float2(   0,-d.y)) * r +
            tex2D(_MainTex, uv + float2( d.x,-d.y)) * r ;

				return col;
			}
			ENDCG
		}
	}
}
