Shader "Raymarch/World_Kaleido" {
  Properties {
    _Size ("Size", Vector) = (1,1,1,1)

    [Header(GBuffer)]
    _MainTex ("Albedo Map", 2D) = "white" {}
    _BumpTex ("Normal Map", 2D) = "bump" {}
    _SpecularGloss ("Specular/Gloss", Color) = (0,0,0,0)
    _Emission ("Emission", Color) = (1,1,1,1)

     [Header(Framework)]
    _RayDamp ("Ray Damp", Float) = 1
    _LocalOffset ("Local Offset", Vector) = (0,0,0,0)
    _LocalTangent ("Local Tangent", Vector) = (0.15,1.24,0.89,0)
  }
 	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 100

    CGINCLUDE
      float4 _Size;

      #include "RaymarchModules.cginc"
      #include "noiseSimplex.cginc"

      float distFunc(float3 p) {
        p = trScale(p, _Size.xyz / _Size.w);

        float height = -2;
        //float height = -4 + snoise(p * 0.2) * 2;

        float db = sdBox(p - float3(0,height,0), float3(10,2,10));
        return db;
      }

      float2 uvFunc(float3 p) {
        float2 uv = uvFuncQuartz(p);
        uv.y *= -1;
        return uv;
      }

      #define DIST_FUNC distFunc
      #define UV_FUNC uvFunc
      #define USE_OBJECTSPACE 0
      #define NORMAL_PRECISION 0.01
      #define CHECK_CONV_BY_CLIP_THRESHOLD 1
      #define USE_CLIP_THRESHOLD 1
      #define CLIP_THRESHOLD 0.01
      #define RAY_ITERATION 64 //64 // 128
      #include "RaymarchCore.cginc"
    ENDCG

		Pass {
      Tags { "LightMode" = "Deferred" }
			CGPROGRAM
			#pragma vertex vert_raymarch
			#pragma fragment frag_raymarch
     	ENDCG
		}

  }
}
