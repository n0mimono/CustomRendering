Shader "Forward/ForwardFastShadow" {
  SubShader {
    Tags { "RenderType"="Transparent" "Queue"="Transparent" }
    LOD 100

    CGINCLUDE
      #include "UnityCG.cginc"

      struct v2f {
        float4 vertex : SV_POSITION;
      };
      
      v2f vert (appdata_full v) {

        // ground-projection
        float4 vertex = v.vertex;
        float4 worldPos = mul(unity_ObjectToWorld, vertex);
        worldPos.y = max(0, worldPos.y); // fixed for negative height

        float3 ray      = normalize(_WorldSpaceLightPos0.xyz);
        float  t        = -worldPos.y / ray.y;
        float3 p        = worldPos.xyz + ray * t;
        float4 z        = mul(unity_WorldToObject, float4(p, worldPos.w));
        v.vertex = z;

        v2f o;
        o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
        return o;
      }
    ENDCG

    Pass {
      ZWrite Off
      Offset -1,0
      Blend SrcAlpha OneMinusSrcAlpha

      Stencil {
        Ref 1
        Comp NotEqual
        Pass Replace
      }

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      
      fixed4 frag (v2f i) : SV_Target {
        return half4(0,0,0,0.5);
      }
      ENDCG
    }

  }
}
