Shader "Forward/ForwardTransparentSkin" {
  Properties {
    _MainTex ("Texture", 2D) = "white" {}
    _Alpha ("Alpha", Range(0, 1)) = 1
  }
  SubShader {
    Tags { "RenderType"="Transparent" "Queue"="Transparent" }

    CGINCLUDE
      #include "UnityCG.cginc"

      struct appdata {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
      };

      struct v2f {
        float2 uv : TEXCOORD0;
        UNITY_FOG_COORDS(1)
        float4 vertex : SV_POSITION;
      };

      sampler2D _MainTex;
      float4 _MainTex_ST;
      float _Alpha;
      
      v2f vert (appdata v) {
        v2f o;
        o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        UNITY_TRANSFER_FOG(o,o.vertex);
        return o;
      }
      
      fixed4 frag (v2f i) : SV_Target {
        fixed4 col = tex2D(_MainTex, i.uv);
        UNITY_APPLY_FOG(i.fogCoord, col);

        col.a = _Alpha;
        return col;
      }
    ENDCG

    Pass {
      ColorMask 0
      Zwrite On

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #pragma multi_compile_fog
      ENDCG
    }

    Pass {
      Blend SrcAlpha OneMinusSrcAlpha
      ZTest LEqual
      ZWrite Off

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #pragma multi_compile_fog
      ENDCG
    }
  }
}
