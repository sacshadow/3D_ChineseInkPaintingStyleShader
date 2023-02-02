// Upgrade NOTE: replaced '_Projector' with 'unity_Projector'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Projector/Caustics" {
Properties {
	_Color ("Color", Color) = (1,1,1,0)
	_ShadowTex ("Cookie", 2D) = "black" { }
	_Size ("Grid Size", Float) = 1
}

Subshader {
	Tags { "RenderType"="Transparent" "Queue"="Transparent+100" }
	Pass {
		ZWrite Off
		Offset -1, -1
		// Fog { Mode Off }
		ColorMask RGB
		// Blend SrcAlpha OneMinusSrcAlpha
		// Blend DstColor One
		Blend DstColor Zero
	
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma fragmentoption ARB_fog_exp2
		#pragma fragmentoption ARB_precision_hint_fastest
		#include "UnityCG.cginc"
	
		struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		};
	
		uniform sampler2D _ShadowTex;
		float4 _ShadowTex_ST;
		float4 _Color;
		float4x4 unity_Projector;
		fixed _Size;
	
		v2f vert (appdata_tan v) {
			v2f o;
			o.pos = UnityObjectToClipPos (v.vertex);
			o.uv = TRANSFORM_TEX (mul (unity_Projector, v.vertex).xy, _ShadowTex);
			return o;
		}
	
		fixed4 frag (v2f i) : COLOR {
			// if (i.uv.x < 1 && i.uv.y < 1)
				return tex2D (_ShadowTex, fmod (i.uv, 1 / _Size) * _Size) * _Color;
			// else
				// return fixed4 (0,0,0,0);
		}
	
		ENDCG
	}
 }
 }
 