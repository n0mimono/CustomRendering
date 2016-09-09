Shader "Test/DeferredComposite" {
  Properties {
    _MainTex ("Texture", 2D) = "white" {}
    [Enum(Main,0,Depth,1,Albedo,2,Specular,3,Normal,4,Emission,5)] _Target ("Target", Float) = 1
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

      sampler2D _CameraDepthTexture;
      sampler2D _CameraGBufferTexture0;
      sampler2D _CameraGBufferTexture1;
      sampler2D _CameraGBufferTexture2;
      sampler2D _CameraGBufferTexture3;

      sampler2D _MainTex;

      fixed4 frag (v2f_img i) : SV_Target {

        float  depth    = Linear01Depth(tex2D(_CameraDepthTexture, i.uv.xy).r);
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
