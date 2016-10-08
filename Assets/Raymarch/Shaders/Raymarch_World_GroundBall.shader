Shader "Raymarch/World_GroundBall" {
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
    [Enum(Sphere,1,Box,2)] _ModelClip ("Model Clip", Float) = 1
  }
 	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 100

    CGINCLUDE
      float4 _Size;

      #define USE_CLIP_THRESHOLD 0
      #define RAY_ITERATION 64 // 128
      #include "RaymarchModules.cginc"

      float distFunc(float3 p) {
        p = trScale(p, _Size.xyz / _Size.w);
        p = trRotate(p, M_PI / 4, float3(0,1,0));
        float d1 = sdBox(p + float3(0,10,0), float3(1,10,1));
        float d2 = sdSphere(p + float3(0,3,0), 2.5);
        p = trRotate(p, M_PI / 4, float3(0,1,0));
        float d3 = sdBox(p + float3(0,25,0), float3(4,20,4));
        float d4 = sdCylinder(p + float3(-1,8,2), float4(0.5,10,0,0));
        float d5 = sdSphere(p + float3(-1.5,0,3), 1);

        return opUni(opUni(opUni(opUni(d1, d2, 10), d3, 2), d4, 8), d5, 10);
      }

      float2 uvFunc(float3 p) {
        return uvFuncQuartz(p);
      }

      #define DIST_FUNC distFunc
      #define UV_FUNC uvFunc
      #define USE_OBJECTSPACE 0
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
