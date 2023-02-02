Shader "WJDR_UI/Transition" {
	Properties {
		_Color ("Color", Color) = (0.5, 0.5, 0.5, 1)
		_Tex0 ("Tex0 (RGB)", 2D) = "white" {}
		_Tex1 ("Tex1 (RGB)", 2D) = "white" {}
		_Mask ("Mask (RGB)", 2D) = "white" {}
		_Range ("Range", Range(0.01,0.5)) = 0.1
		_Offset ("Offset", Range(-1,1)) = 1
	}
	SubShader {
		Tags { "Queue"="Transparent" "RenderType"="Transparent" }
		//Blend SrcAlpha OneMinusSrcAlpha
		//Blend Zero SrcColor
		LOD 200
		
		Lighting Off
		
		CGPROGRAM
		#pragma surface surf Lambert alpha:fade

		sampler2D _Tex0;
		sampler2D _Tex1;
		sampler2D _Mask;
		float4 _Color;
		half _Offset;
		float _Range;
		
		
		struct Input {
			float2 uv_Tex0;
			float2 uv_Tex1;
			float2 uv_Mask;
		};

		void surf (Input IN, inout SurfaceOutput o) {
			half4 t0 = tex2D (_Tex0, IN.uv_Tex0);
			half4 t1 = tex2D (_Tex1, IN.uv_Tex1);
			half4 m = tex2D (_Mask, IN.uv_Mask);
			
			float k = clamp(_Offset+m.r,0,1);
			
			k = lerp(0,1, clamp((k-0.5 + _Range)/_Range/2,0,1));
			
			half4 c = lerp(t0,t1, k);
			
			o.Albedo = c.rgb * _Color.rgb * 2;
			o.Alpha = c.a;
		}
		ENDCG
	} 
	FallBack "Legacy Shaders/Transparent/VertexLit"
}
