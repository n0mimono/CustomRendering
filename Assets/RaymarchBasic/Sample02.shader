Shader "Raymarch/Sample/Sample02" {
  Properties {
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
      #include "RaymarchModules.cginc"
      float distFunc(float3 p) {
        float d0 = sdSphere(p, 2);
        float d1 = sdBox(p, 2);
        float d2 = sdBox(trRepeat(p, 1 + sin(_Time.x) * 0.5), 0.2);

        return opInt(opSub(d2, d1), d0);
      }

      float2 uvFunc(float3 p) {
        return uvFuncBasic(p);
      }

      #define DIST_FUNC distFunc
      #define UV_FUNC uvFunc
      #include "RaymarchBasic.cginc"
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
