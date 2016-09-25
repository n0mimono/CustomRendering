Shader "Painter/Skybox" {
  Properties {
    _FrontColor ("Front (+Z)", Color) = (1,1,1,1)
    _BackColor ("Back (-Z)", Color) = (1,1,1,1)
    _LeftColor ("Left (+X)", Color) = (1,1,1,1)
    _RightColor ("Right (-X)", Color) = (1,1,1,1)
    _UpColor ("Up (+Y)", Color) = (1,1,1,1)
    _DownColor ("Down (-Y)", Color) = (1,1,1,1)
  }

SubShader {
	Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
	Cull Off ZWrite Off Fog { Mode Off }

  CGINCLUDE
  #include "UnityCG.cginc"

  struct appdata_t {
    float4 vertex : POSITION;
    float2 texcoord : TEXCOORD0;
  };
  struct v2f {
    float4 vertex : SV_POSITION;
    float2 texcoord : TEXCOORD0;
  };

  v2f vert (appdata_t v) {
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.texcoord = v.texcoord;
    return o;
  }
  ENDCG

	Pass {
    CGPROGRAM
    #pragma vertex vert
    #pragma fragment frag
    half4 _FrontColor;
    half4 frag (v2f i) : SV_Target { return _FrontColor; }
    ENDCG
	}
	Pass {
    CGPROGRAM
    #pragma vertex vert
    #pragma fragment frag
    half4 _BackColor;
    half4 frag (v2f i) : SV_Target { return _BackColor; }
    ENDCG
	}
	Pass {
    CGPROGRAM
    #pragma vertex vert
    #pragma fragment frag
    half4 _LeftColor;
    half4 frag (v2f i) : SV_Target { return _LeftColor; }
    ENDCG
	}
	Pass {
    CGPROGRAM
    #pragma vertex vert
    #pragma fragment frag
    half4 _RightColor;
    half4 frag (v2f i) : SV_Target { return _RightColor; }
    ENDCG
	}
	Pass {
    CGPROGRAM
    #pragma vertex vert
    #pragma fragment frag
    half4 _UpColor;
    half4 frag (v2f i) : SV_Target { return _UpColor; }
    ENDCG
	}
	Pass {
    CGPROGRAM
    #pragma vertex vert
    #pragma fragment frag
    half4 _DownColor;
    half4 frag (v2f i) : SV_Target { return _DownColor; }
    ENDCG
	}
}
}
