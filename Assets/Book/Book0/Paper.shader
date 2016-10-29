Shader "Book/Paper" {
	Properties {
		_MainTex ("Texture", 2D) = "white" {}
		_BackTex ("Sub Texture", 2D) = "black" {}
		_MaskTex ("Mask Texture", 2D) = "white" {}
		_FrameTex ("Frame Texture", 2D) = "black" {}
		_Angle ("Angle", Range(0, 1)) = 0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }

		CGINCLUDE
		#include "UnityCG.cginc"
		#define Pi 3.14159265359

		uniform sampler2D _MainTex; float4 _MainTex_ST;
		uniform sampler2D _BackTex; float4 _BackTex_ST;
		uniform sampler2D _MaskTex; float4 _Mask_ST;
		uniform sampler2D _FrameTex; float4 _Frame_ST;

		uniform float _Angle;

		struct v2f {
			float2 uv : TEXCOORD0;
			float4 pos : SV_POSITION;
		};

		float4 turn_page(float4 v) {
			float x = v.x;       // 0 to 1
			float z = v.z;       // -1 to 1
			float t = _Angle;    // 0 to 1
			float p = 2 * t -1;  // -1 to 1
			float4 u = v;

			float turn_power = 0.3 * exp(-0.1 * pow(x - 0.5, 2));
			float turn_angle = sqrt(1 - p * p);
			float turn_z = -0.002* z*z*z + z*0.03;

		    float dtheta = (turn_power + turn_z) * turn_angle;
		    float theta = t * Pi + dtheta;
		    theta = max(0, min(Pi, theta));
			float r = x;

			u.x = r * cos(theta);
			u.y = r * sin(theta);

			v = u; // -1 to 1
			return v;
		}

		v2f vert_paper(appdata_full v, bool is_front) {
			v2f o;

			o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
			o.uv.xy = 1 - o.uv.xy;

			float4 vertex = o.uv.x <= 0.5 ? v.vertex : turn_page(v.vertex);
			o.pos = mul(UNITY_MATRIX_MVP, vertex);

			return o;
		}

		v2f vert_raw(appdata_full v) {
		    v2f o;

		    o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
		    o.uv.y = 1 - o.uv.y;

			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

		    return o;
		}

		fixed4 frag_paper(v2f i, bool is_front) : SV_Target {
			fixed4 col; 

			if (is_front) {
			    col = tex2D(_MainTex, i.uv);
			} else {
			    i.uv.x = 1 - i.uv.x;
			    col = tex2D(_BackTex, i.uv);
			}

			fixed4 mask = tex2D(_MaskTex, i.uv);
			fixed4 frame = tex2D(_FrameTex, i.uv);
			col = lerp(frame, col, mask);

			return col;
		}
		ENDCG

		Pass {
			Cull Back
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			v2f vert(appdata_full v) {
				return vert_paper(v, true);
			}
			fixed4 frag(v2f i) : SV_Target {
				return frag_paper(i, true);
			}
			ENDCG
		}

		Pass {
			Cull Front
			Offset -1,-1
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			v2f vert(appdata_full v) {
				return vert_paper(v, false);
			}
			fixed4 frag(v2f i) : SV_Target {
				return frag_paper(i, false);
			}
			ENDCG
		}

		Pass {
		    Cull Back
		    Offset 1,1
			CGPROGRAM
			#pragma vertex vert_raw
			#pragma fragment frag
			fixed4 frag(v2f i) : SV_Target {
				return frag_paper(i, false);
			}
			ENDCG
		}

	}
}
