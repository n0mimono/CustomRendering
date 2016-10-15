Shader "Raymarch/World_Kaleido" {
  Properties {
    _Size ("Size", Vector) = (1,1,1,1)
    _Height ("Height", Float) = 0

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
      float _Height;

      #include "RaymarchModules.cginc"
      #include "noiseSimplex.cginc"

      float distFunc(float3 p) {
        p = trScale(p, _Size.xyz / _Size.w);

        float height = _Height;
        float d2 = p.y - height; //+ snoise(p * 0.1);
        float3 p3 = fBoxFold(fBoxFold(fBoxFold(p, 4), 4), 4);

        float d3 = sdBox(p3, float3(3,4,3));
        float d4 = sdSphere(p - float3(0,-2,0), 2);
        return opUni(opSub(d3, d2), d4);
      }

      float4 normalFunc(float4 buf, float3 p, float d, float i) {
        float3 c         = _WorldSpaceCameraPos.xyz;
        float3 ray       = normalize(p - c);
        float  t         = (0 - c.y) / ray.y;
        float3 surPos    = c + ray * t;

        float dist = distFunc(surPos);
        buf.a = exp(-dist);

        return buf;
      }

      float2 uvFunc(float3 p) {
        float2 uv = uvFuncQuartz(p);
        return uv;
      }

      #define NORMAL_FUNC normalFunc
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
