Shader "Forward/ForwardFastShadow" {
  SubShader {
    Tags { "RenderType"="Transparent" "Queue"="Transparent" }
    LOD 100

    Pass {
      ZWrite Off
      Blend SrcAlpha OneMinusSrcAlpha
      Offset -1,0

      Stencil {
        Ref 1
        Comp NotEqual
        Pass Replace
      }

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #pragma multi_compile_fog
      #include "UnityCG.cginc"

      struct v2f {
        float4 vertex : SV_POSITION;
      };
      
      v2f vert (appdata_full v) {

        // ground-projection
        half4 worldPos = mul(unity_ObjectToWorld, v.vertex);
        half3 ray      = normalize(_WorldSpaceLightPos0.xyz);
        half  t        = -worldPos.y / ray.y;
        half3 p        = worldPos.xyz + ray * t;
        half4 z        = mul(unity_WorldToObject, half4(p, worldPos.w));
        v.vertex = z;

        v2f o;
        o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
        return o;
      }
      
      fixed4 frag (v2f i) : SV_Target {
        return half4(half3(0,0,0), 0.5);
      }
      ENDCG
    }
  }
}
