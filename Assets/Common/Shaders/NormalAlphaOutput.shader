Shader "Test/NormalAlphaOutput" {
  Properties {
    _MainTex ("Texture", 2D) = "white" {}
  }
  SubShader {
    Cull Off ZWrite Off ZTest Always

    Pass {
      CGPROGRAM
      #include "UnityCG.cginc"
      #pragma vertex vert_img
      #pragma fragment frag
      #pragma target 3.0

      sampler2D_float _CameraDepthTexture;
      sampler2D _CameraGBufferTexture2;
      sampler2D _MainTex;

      fixed4 frag (v2f_img i) : SV_Target {
        float  d        = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv.xy);
        float4 normal   = tex2D(_CameraGBufferTexture2, i.uv.xy);

        if (d >= 1) return float4(0,0,1,1);
        return float4(float3(1,1,1) * normal.a, 1);
      }
      ENDCG
    }
  }
}
