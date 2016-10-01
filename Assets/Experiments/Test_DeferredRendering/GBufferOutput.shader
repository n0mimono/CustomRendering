Shader "Test/GBufferOutput" {
  Properties {
    _MainTex ("Texture", 2D) = "white" {}
    [Enum(Main,0,Depth,1,Albedo,2,Specular,3,Normal,4,Emission,5)] _Target ("Target", Float) = 1
    _DepthScale ("Depth Eye Scale", Float) = 0.05
  }
  SubShader {
    Cull Off ZWrite Off ZTest Always

    Pass {
      CGPROGRAM
      #include "UnityCG.cginc"
      #pragma vertex vert_img
      #pragma fragment frag
      #pragma target 3.0

      float _Target;

      sampler2D_float _CameraDepthTexture;
      float _DepthScale;

      sampler2D _CameraGBufferTexture0;
      sampler2D _CameraGBufferTexture1;
      sampler2D _CameraGBufferTexture2;
      sampler2D _CameraGBufferTexture3;

      sampler2D _MainTex;

      fixed4 frag (v2f_img i) : SV_Target {

        float  d        = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv.xy);
        float  depth    = LinearEyeDepth(d) * _DepthScale;

        float4 albedo   = tex2D(_CameraGBufferTexture0, i.uv.xy);
        float4 specular = tex2D(_CameraGBufferTexture1, i.uv.xy);
        float4 normal   = tex2D(_CameraGBufferTexture2, i.uv.xy);
        float4 emission = tex2D(_CameraGBufferTexture3, i.uv.xy);

        if (_Target == 1) {
          return float4(1,1,1,1) * depth;
        } else if (_Target == 2) {
          return albedo;
        } else if (_Target == 3) {
          return specular;
        } else if (_Target == 4) {
          return normal;
        } else if (_Target == 5) {
          return emission;
        } 

        return tex2D(_MainTex, i.uv);
      }
      ENDCG
    }
  }
}
