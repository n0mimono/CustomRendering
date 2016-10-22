Shader "Effects/ScreenSpaceWater" {
  Properties {
    _MainTex ("Texture", 2D) = "white" {}
    _Power ("Power", Float) = 1
    _Amplitude ("Amplitude", Float) = 1
    _Damp ("Damp", Float) = 1

    _BumpTex ("Bump", 2D) = "bump" {}
  }
  SubShader {
    Cull Off ZWrite Off ZTest Always

    Pass {
      CGPROGRAM
      #include "UnityCG.cginc"
      #include "Assets/Raymarch/Shaders/noiseSimplex.cginc"
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
      float4x4 _ViewProj;

      float _Power;
      float _Amplitude;
      float _Damp;

      sampler2D _BumpTex;

      // see: https://www.shadertoy.com/view/ltB3zD
      float noise(float2 seed) {
        return frac(sin(dot(seed.xy, float2(12.9898, 78.233))) * 43758.5453);
      }

      float3 calcView(float2 uv, float d, out float4 wpos) {
        float2 spos = uv * 2 - 1;
        wpos = mul(_InvViewProj, float4(spos, d, 1));
        wpos /= wpos.w;
        return normalize(_WorldSpaceCameraPos.xyz - wpos.xyz);
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
        float4 wpos;
        float3 normalDir = normal.xyz * 2 - 1;
        float3 viewDir   = calcView(i.uv.xy, depth, wpos);

        // main color
        float4 col = tex2D(_MainTex, i.uv.xy);

        // up-effect
        float3 hpos = wpos + float3(0,10,0) * noise(i.uv.yx);
        float4 hvp  = mul(_ViewProj, float4(hpos, 1));
        float2 huv  = hvp.xy / hvp.w * 0.5 + 0.5;
        float4 hn   = tex2D(_CameraGBufferTexture2, huv);
        float  hv   = 1.5 * saturate(hn.a + noise(i.uv.yx + 1) * 0.2 - 0.2);
        col += pow(float4(hv,hv,0.95,0),2) * hv * 0.05;

        float h = wpos.y + 5 + (noise(i.uv.yx) * 2 - 1) * 0.2 + snoise(i.uv.xy * 2);
        if (h > -1) return col;

        // distorted color
        float2 bump = UnpackNormal(tex2D(_BumpTex, wpos.xz * 0.5)).xy;
        col = tex2D(_MainTex, i.uv.xy + bump * 0.05);

        float val = 1.5 * saturate(normal.a + noise(i.uv.xy) * 0.2 - 0.2);
        col += pow(float4(val,val,0.95,0), 2) * val * 0.5;
        return col;
      }
      ENDCG
    }
  }
}
