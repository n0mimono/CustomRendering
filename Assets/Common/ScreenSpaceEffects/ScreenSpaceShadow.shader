Shader "Effects/ScreenSpaceShadow" {
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

      #define SHADOW_ITERATION 20

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

      float pos2Depth(float4 pos) {
        #if defined(SHADER_TARGET_GLSL) || defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)
        return (pos.z / pos.w) * 0.5 + 0.5;
        #else
        return pos.z / pos.w;
        #endif
      }

      float2 pos2Uv(float4 pos) {
        return pos.xy / pos.w * 0.5 + 0.5;
      }

      float3 calcView(float2 uv, float d, out float4 wpos) {
        float2 spos = uv * 2 - 1;
        wpos = mul(_InvViewProj, float4(spos, d, 1));
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
        float4 worldPos;
        float3 normalDir = normal * 2 - 1;
        float3 viewDir   = calcView(i.uv.xy, depth, worldPos);
        float3 lightDir  = normalize(_WorldSpaceLightPos0.xyz);

        // main color
        float4 col = tex2D(_MainTex, i.uv.xy);
        albedo = col;

        // skybox
        if (Linear01Depth(depth01) > 0.99) return albedo;

        // ss-shadow
        float occlusion = 0;
        float sharpness = 1.0 / SHADOW_ITERATION;
        float maxDistance = 50;

        for (int i = 0; i < SHADOW_ITERATION; i++) {
          float3 ray = lightDir * maxDistance / SHADOW_ITERATION;
          float3 rayPos = worldPos.xyz + i * ray;
          float4 vpPos = UnityWorldToClipPos(rayPos);

          float rayDepth = pos2Depth(vpPos);
          float2 rayUv = pos2Uv(vpPos);
          float gDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, rayUv);

          if (abs(LinearEyeDepth(gDepth) - LinearEyeDepth(rayDepth)) < 5) {
            occlusion += sharpness;
          }
        }
        occlusion = 1 - saturate(occlusion);
        //return float4(1,1,1,1) * occlusion;

        // occulusion
        return albedo * occlusion;
      }
      ENDCG
    }
  }
}
