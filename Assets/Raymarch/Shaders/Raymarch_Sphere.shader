﻿Shader "Raymarch/Sphere" {
  Properties {
    _Size ("Size", Float) = 0.5

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
      float _Size;

      #include "RaymarchModules.cginc"
      float distFunc(float3 p) {
        float d5 = sdSphere(p, _Size);
        float d2 = sdBox(trRepeat(p, 3), 1);

        return opSub(d2, d5);
      }

      float2 uvFunc(float3 p) {
        return uvFuncBox(p);
      }

      #define DIST_FUNC distFunc
      #define UV_FUNC uvFunc
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
