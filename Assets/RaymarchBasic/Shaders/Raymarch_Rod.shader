Shader "Raymarch/Rod" {
  Properties {
    _Twist ("Twist", Float) = 0.4
    _Height ("Height", Float) = 2
    _Blank ("Blank", Float) = 0.1
    _Thickness ("Thickness", Float) = 0.5

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
      float _Twist;
      float _Height;
      float _Blank;
      float _Thickness;

      #include "RaymarchModules.cginc"
      float distFunc(float3 p) {
        p = trTwist(p, _Twist * sin(_Time.x));

        float xt = _Thickness+0.1;

        float d2 = sdBox(p, float3(_Thickness, _Height, _Thickness));
        float d2x = sdBox(p, float3(xt, _Height, xt));

        float d3 = sdBox(trRepeat(p, 0.3), 0.1);
        d3 = opInt(d3, d2x);

        float d4 = sdBox(trRepeat1(p, 0.8), float3(xt, _Blank, xt));

        return opSub(d4, opUni(d2, d3));
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
