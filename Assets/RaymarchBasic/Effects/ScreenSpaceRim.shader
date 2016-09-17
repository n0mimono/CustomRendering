Shader "Hiden/ScreenSpaceRim" {
  Properties {
    _MainTex ("Texture", 2D) = "white" {}
    _Power ("Power", Float) = 1
    _Amplitude ("Amplitude", Float) = 1
    _Damp ("Damp", Float) = 1
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
      sampler2D _CameraGBufferTexture0;
      sampler2D _CameraGBufferTexture1;
      sampler2D _CameraGBufferTexture2;
      sampler2D _CameraGBufferTexture3;

      sampler2D _MainTex;
      float4x4 _InvViewProj;

      float _Power;
      float _Amplitude;
      float _Damp;

      float3 calcView(float2 uv, float d) {
        float2 spos = uv * 2 - 1;
        float4 wpos = mul(_InvViewProj, float4(spos, d, 1));
        wpos /= wpos.w;
        return normalize(_WorldSpaceCameraPos - wpos);
      }

      fixed4 frag (v2f_img i) : SV_Target {
        // depth
        float depth   = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv.xy);
        float depth01 = Linear01Depth(depth);

        // gbuffer
        float4 albedo   = tex2D(_CameraGBufferTexture0, i.uv.xy);
        float4 specular = tex2D(_CameraGBufferTexture1, i.uv.xy);
        float4 normal   = tex2D(_CameraGBufferTexture2, i.uv.xy);
        float4 emission = tex2D(_CameraGBufferTexture3, i.uv.xy);

        // vector reconstruction
        float3 normalDir = normal * 2 - 1;
        float3 viewDir   = calcView(i.uv.xy, depth);

        // main color
        float4 col = tex2D(_MainTex, i.uv.xy);

        // rim
        float NNdotV = 1 - max(0,dot(normalDir,viewDir));
        if (depth01 > 0.999) return col;

        float rim = pow(NNdotV, _Power) * _Amplitude;
        return _Damp * col + _Amplitude * rim;
      }
      ENDCG
    }
  }
}
