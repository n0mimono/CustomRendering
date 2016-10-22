Shader "Raymarch/World_Fault" {
  Properties {
    _Size ("Size", Vector) = (1,1,1,1)
    _Mandel ("Mandel", Vector) = (2,14.8,0,1)
    _Box1 ("Box 1", Vector) = (1,1,1,1)
    _Box2 ("Box 2", Vector) = (1,1,1,1)

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
      float4 _Mandel;
      float4 _Box1;
      float4 _Box2;

      #include "RaymarchModules.cginc"

      float sdFunc_Frac(float3 p, float4 c, float4 t1, float4 t2, float d) {
        float3 z = p;
        float dr = 1;
        float r = 0;

        p = z;
        for (int i = 0; i < 1; i++) {
          z = fBoxFold(z, t1.x);
          z = fSphereFoldInverse(z, t1.y, t1.z, dr);
          z = t1.w * z + p;
          dr = dr * abs(t1.w) + 1;
        }

        p = z;
        float power = c.y;
        for (int i = 0; i < 1; i++) {
          z = fOctaFold(z);

          r = length(z);
          if (r > c.x) break;

          float theta = acos(z.z/r);
          float phi = atan2(z.y, z.x);
          dr = pow(r, power-1)*power*dr + 1;

          float zr = pow(r, power);
          theta = theta * power;
          phi = phi * power;

          z = zr*float3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
          z += p;
        }

        p = z;
        for (int i = 0; i < 5; i++) {
          z = fBoxFold(z, t2.x);
          z = fSphereFoldInverse(z, t2.y, t2.z, dr);
          z = t2.w * z + p;
          dr = dr * abs(t2.w) + 1;
        }

        r = length(z);
        //return 0.5*log(r)*r/dr;
        return (length(z))/dr - pow(abs(t2.w), 1 - d);
      }

      float distFunc(float3 p) {
        p = trScale(p, _Size.xyz / _Size.w);

        float d1 = sdFunc_Frac(p, _Mandel, _Box1, _Box2, 5);
        return d1;
      }

      float2 uvFunc(float3 p) {
        p = p / length(p);
        return uvFuncBox(p);
      }

      #define DIST_FUNC distFunc
      #define UV_FUNC uvFunc
      #define USE_OBJECTSPACE 0
      #define NORMAL_PRECISION 0.01
      #define CHECK_CONV_BY_CLIP_THRESHOLD 1
      #define USE_CLIP_THRESHOLD 1
      #define CLIP_THRESHOLD 0.5
      #define RAY_ITERATION 128 // 64 // 128
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
