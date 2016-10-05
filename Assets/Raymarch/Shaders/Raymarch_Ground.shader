Shader "Raymarch/Ground" {
  Properties {
    _Height ("Height", Float) = 1
    _Noise ("Noise", Float) = 0.5

    //_Size ("Size", Vector) = (1,1,1,1)
    //_Bailout ("Bailout", Float) = 1
    //_Power ("Power", Float) = 1

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
      float _Height;
      float _Noise;

      //float4 _Size;
      //float _Bailout;
      //float _Power;

      #define FRAC_ITERATION 3
      #include "RaymarchModules.cginc"
      float distFunc(float3 p) {
        float d2 = sdBox(p, float3(0.5, _Height, 0.5));
        float3 q = trTrans(trRepeat2n(p, 0.5, _Noise), float3(0,_Noise,0));
        float d3 = sdBox(q, float3(0.2, _Height, 0.2));
        float dx = opUni(d2, d3);
        return dx;

        //float3 r = trScale(p, _Size.xyz / _Size.w);
        //r = trTrans(r, float3(-0.7,0,-1));
        //float d7 = sdFractalMandelbulb(r, _Bailout, _Power);
        //return opUni(dx, d7, 30);
      }

      float2 uvFunc(float3 p) {
        return uvFuncBasic(p);
      }

      #define DIST_FUNC distFunc
      #define UV_FUNC uvFunc
      #define RAY_ITERATION 128
      #define NORMAL_PRECISION 0.05
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
