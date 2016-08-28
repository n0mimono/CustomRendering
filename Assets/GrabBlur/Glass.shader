Shader "GrabBlur/Glass" {
  Properties {
    _BumpAmt  ("Distortion", range (0,64)) = 10
    _TintAmt ("Tint Amount", Range(0,1)) = 0.1
    _MainTex ("Tint Color (RGB)", 2D) = "white" {}
    _BumpMap ("Normalmap", 2D) = "bump" {}
  }

  SubShader {
    Tags { "Queue"="Transparent" "RenderType"="Opaque" }

    Pass {
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #pragma multi_compile_fog
      #include "UnityCG.cginc"

      struct appdata_t {
        float4 vertex : POSITION;
        float2 texcoord: TEXCOORD0;
      };

      struct v2f {
        float4 vertex : POSITION;
        float4 uvgrab : TEXCOORD0;
        float2 uvbump : TEXCOORD1;
        float2 uvmain : TEXCOORD2;
        UNITY_FOG_COORDS(3)
      };

      float _BumpAmt;
      half _TintAmt;
      float4 _BumpMap_ST;
      float4 _MainTex_ST;

      v2f vert (appdata_t v) {
        v2f o;
        o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
        o.uvgrab = ComputeScreenPos(o.vertex);

        o.uvbump = TRANSFORM_TEX( v.texcoord, _BumpMap );
        o.uvmain = TRANSFORM_TEX( v.texcoord, _MainTex );
        UNITY_TRANSFER_FOG(o,o.vertex);
        return o;
      }

      sampler2D _GrabBlurTexture;
      float4 _GrabBlurTexture_TexelSize;
      sampler2D _BumpMap;
      sampler2D _MainTex;

      half4 frag (v2f i) : SV_Target {
        half2 bump = UnpackNormal(tex2D( _BumpMap, i.uvbump )).rg;
        float2 offset = bump * _BumpAmt * _GrabBlurTexture_TexelSize.xy;
        i.uvgrab.xy = offset * i.uvgrab.z + i.uvgrab.xy;
        half4 col = tex2Dproj (_GrabBlurTexture, UNITY_PROJ_COORD(i.uvgrab));
        return col;

        half4 tint = tex2D(_MainTex, i.uvmain);
        col = lerp (col, tint, _TintAmt);

        UNITY_APPLY_FOG(i.fogCoord, col);
        return col;
      }
      ENDCG
    }
  }
}
