Shader "Test/DeferredTest" {
  Properties {
    _Albedo ("Albedo", Color) = (1,1,1,1)
    _Specular ("Specular", Color) = (1,1,1,1)
    _Emission ("Emission", Color) = (1,1,1,1)
  }
  SubShader {
    Tags { "RenderType"="Opaque" }
    LOD 100

    Pass {
      Tags { "LightMode" = "Deferred" }
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #pragma target 3.0
      #include "UnityCG.cginc"

      float4 _Albedo;
      float4 _Specular;
      float4 _Emission;

      struct v2f {
        float4 pos    : SV_POSITION;
        float2 uv     : TEXCOORD0;
        float3 normal : TEXCOORD1;
      };
      
      v2f vert(appdata_full v) {
        v2f o;
        o.pos    = mul(UNITY_MATRIX_MVP, v.vertex);
        o.uv     = v.texcoord;
        o.normal = v.normal;
        return o;
      }
      
      void frag (v2f i,
        out float4 outAlbedo   : SV_Target0,
        out float4 outSpecular : SV_Target1,
        out float4 outNormal   : SV_Target2,
        out float4 outEmission : SV_Target3
      ) {
        outAlbedo   = _Albedo;
        outSpecular = _Specular;
        outNormal   = float4(i.normal * 0.5 + 0.5, 1);
        outEmission = _Emission;
      }
      ENDCG
    }
  }
}
