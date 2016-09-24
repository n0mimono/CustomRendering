Shader "Effects/UnityChanNonPhotoEffect" {
  Properties {
    _MainTex ("Texture", 2D) = "white" {}

    _SampleDistance ("Sample Distance", Float) = 1
    _EdgeThreshold ("Edge Threshold", Vector) = (1,1,1,1)
    _EdgeAmplitude ("Edge Amplitude", Vector) = (1,1,1,1)

  }
  SubShader {
    Cull Off ZWrite Off ZTest Always

    CGINCLUDE
      #include "UnityCG.cginc"

      sampler2D_float _CameraDepthTexture;
      sampler2D _CameraGBufferTexture0;
      sampler2D _CameraGBufferTexture1;
      sampler2D _CameraGBufferTexture2;
      sampler2D _CameraGBufferTexture3;

      sampler2D _MainTex;
      float4 _MainTex_TexelSize;

      inline float lengthx(float x, float y) {
        return abs(x - y);
      }

      inline float lengthx(float4 x, float4 y, float a) {
        float3 r = pow(abs(x.rgb - y.rgb), a);
        return pow(r.r + r.g + r.b, 1/a);
      }

    ENDCG

    // 0: edge detection
    Pass {
      CGPROGRAM
      #pragma vertex vert_img
      #pragma fragment frag
      #pragma target 3.0

      float _SampleDistance;
      float4 _EdgeThreshold;
      float4 _EdgeAmplitude;

      fixed4 frag (v2f_img i) : SV_Target {
        
        // uv
        float2 uv[3];
        uv[0] = i.uv.xy;
        uv[1] = uv[0] + _MainTex_TexelSize.x * float2(1, 0) * _SampleDistance;
        uv[2] = uv[0] + _MainTex_TexelSize.x * float2(0, 1) * _SampleDistance;
        
        // sampling
        float  depth[3];
        for (int i = 0; i < 3; i++) depth[i] = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv[i]);
        float4 albedo[3];
        for (int i = 0; i < 3; i++) albedo[i] = tex2D(_CameraGBufferTexture0, uv[i]);
        float4 normal[3];
        for (int i = 0; i < 3; i++) normal[i] = tex2D(_CameraGBufferTexture2, uv[i]);

        // edge
        float4 edge = float4(0,0,0,0);
        for (int i = 1; i < 3; i++) {
          if (lengthx(normal[0], normal[i], 1) > _EdgeThreshold.x) edge.r += _EdgeAmplitude.x;
          if (lengthx(depth[0], depth[i]) > _EdgeThreshold.y) edge.g += _EdgeAmplitude.y;
          if (lengthx(albedo[0], albedo[i], 2) > _EdgeThreshold.z) edge.b += _EdgeAmplitude.z;
        }

        return edge;
      }
      ENDCG
    }

    // 0: composie
    Pass {
      CGPROGRAM
      #pragma vertex vert_img
      #pragma fragment frag
      #pragma target 3.0

      sampler2D _EdgeTex;

      fixed4 frag (v2f_img i) : SV_Target {
        float2 uv = i.uv.xy;

        float4 col    = tex2D(_MainTex, uv);
        float4 albedo = tex2D(_CameraGBufferTexture0, uv);
        float4 edge   = tex2D(_EdgeTex, uv);

        edge.a = 1 - saturate(edge.r + edge.g + edge.b);
        albedo.rgb *= edge.a;
        col.rgb = lerp(col.rgb, albedo.rgb, albedo.a);

        return col;
      }
      ENDCG

    }
  }
}
