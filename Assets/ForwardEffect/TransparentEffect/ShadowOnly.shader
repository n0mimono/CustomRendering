﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Forward/ShadowOnly" {
  SubShader {
    Tags { "RenderType"="Transparent" "Queue"="Transparent" }

    Pass {
      ColorMask 0
      Zwrite Off

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #include "UnityCG.cginc"

      struct appdata {
        float4 vertex : POSITION;
      };

      struct v2f {
        float4 vertex : SV_POSITION;
      };

      v2f vert (appdata v) {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        return o;
      }
      
      fixed4 frag (v2f i) : SV_Target {
        return fixed4(0,0,0,0);
      }
      ENDCG
    }

  }
  Fallback "Diffuse"
}
