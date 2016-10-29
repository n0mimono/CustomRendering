Shader "Book/Box" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }

		CGINCLUDE
		#include "UnityCG.cginc"

		uniform float4 _Color;
		uniform sampler2D _MainTex; float4 _MainTex_ST;

		struct v2f {
			float2 uv : TEXCOORD0;
			float4 pos : SV_POSITION;
		};

		v2f vert(appdata_full v) {
		  v2f o;
			o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		  return o;
		}

		fixed4 frag(v2f i) : SV_Target {
			fixed4 col = tex2D(_MainTex, i.uv) * _Color;
			return col;
		}
		ENDCG

		Pass {
			Cull Back
			Offset 2,2
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}

	}
}
