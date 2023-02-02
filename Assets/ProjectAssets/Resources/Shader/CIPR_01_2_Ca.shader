Shader "WJDR/CIPR_01_2_Ca"
{
Properties {
	//Color
	_Color ("Base Color", Color) = (0.898,0.8588,0.8235,1)
	_OutlineColor ("Outline Color", Color) = (0.05,0.05,0.05,1)
	_Ran0 ("Ran Close", Range(0,2.5)) = 1
	_Ran1 ("Ran Far", Range(-1,1)) = 0.5
	//Texture
	_ColorRemap ("Color Remap", 2D) = "black" {}
	_MatCap ("MatCap {outline r, inline g}", 2D) = "black" {}
	_Noise ("Noise",2D) = "white" {}
	_Stroke ("Stroke",2D) = "white" {}
	
	//Overall Control
	_RemapCtrl("RC{dis x, noise y, depth z, dry w}", Vector) = (256,128,0.6,0.25)
	_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
	
	//Texture
	_RimRate ("Rim Rate", Range(0,20)) = 2
	_RimRateClose ("Rim Rate Close", Range(0,20)) = 2.5
	_RimRateRange ("Rim Rate Range", Range(0,20)) = 8
	_RimOffset ("Rim Offset", Float) = 0
	_StrokeCtrl("SC{size x, cun y, ca z, ran w}", Vector) = (2,0.6,0.25,1)
	_NoiseCtrl("NC{size x, cun y, ca z, ran w}", Vector) = (2,0.6,1,1)
	
	//Outline_0
	_OutlineWidth0 ("Outline width 0", Range(0, 20)) = 1
	_OutlineCtrl("OC{persp x,rd y,rp z,of x}", Vector) = (1,1,10,10)
	_OutlineTexCtrl ("OTC{close x, far y, size zw}", Vector) = (1,1,10,10)
	_OutlineNoiseCtrl("ONC{size x, range y}",Vector) = (2,0.25,1,1)
	// _OutlineRand ("")
	
	//Outline_1
	_OutlineWidth1 ("Outline width 1", Range(0, 20)) = 1
	//Inline
	_InlineCtrl ("IC{close x, far y, offset zw}", Vector) = (1,1,10,10)
	
	
	
}
SubShader {
	
	//Texture Pass
	Pass {
		Tags { "RenderType"="Opaque" }
		LOD 100
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile_fog
		#include "UnityCG.cginc"

		struct appdata {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float2 uv : TEXCOORD0;
		};

		struct v2f {
			float4 vertex : SV_POSITION;
			float2 uv : TEXCOORD0;
			UNITY_FOG_COORDS(1)
			float3 normal : TEXCOORD2;
			float4 mcrmd : TEXCOORD3;//{xy: Matcap UV, z: Rimlight, w: distance}
			float rim : TEXCOORD4;
		};
		
		float4 _Color;
		float4 _OutlineColor;
		float _Ran0;
		float _Ran1;
		sampler2D _ColorRemap;
		sampler2D _MatCap;
		sampler2D _Noise;
		sampler2D _Stroke;
		float4 _RemapCtrl;
		float4 _InlineCtrl;
		float4 _StrokeCtrl;
		float4 _NoiseCtrl;
		float _RimRate;
		float _RimRateClose;
		float _RimRateRange;
		float _RimOffset;
		
		v2f vert (appdata v) {
			float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			float3 worldNormal = UnityObjectToWorldNormal(v.normal);
			float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
			float dis = length(worldPos - _WorldSpaceCameraPos);
			
			float3 map = cross(worldNormal, worldViewDir);
			map = mul((float3x3)UNITY_MATRIX_V, map);
			float l = length(map);
			map = normalize(map) * pow(l,lerp(_InlineCtrl.x,_InlineCtrl.y,dis/128));
			
			float rim0 = clamp(1 - saturate (dot(worldViewDir, worldNormal)+_RimOffset),0,1);
			float rr = lerp(_RimRateClose, _RimRate, clamp(dis/_RemapCtrl.x*_RimRateRange,0,1));
			rim0 = clamp(pow(rim0, rr) * 2,0,1);
			float rim1 = clamp(1 - saturate (dot(worldViewDir, worldNormal)+0),0,1);
			rim1 = clamp(pow(rim1, 1.5) * 2,0,1);
			
			
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.uv = worldPos.xy + worldPos.yz + worldPos.xz;
			// o.uv = mul(rotate,o.uv); 
			o.normal = worldNormal;
			o.mcrmd.xy = map.xy * _InlineCtrl.zw/10 * 0.5 + 0.5;
			o.mcrmd.z = rim0;
			o.mcrmd.w = dis/_RemapCtrl.x;
			o.rim = rim1;
			UNITY_TRANSFER_FOG(o,o.vertex);
			return o;
		}

		fixed4 frag (v2f i) : SV_Target {
			fixed4 col = _Color;
			fixed remap = tex2D(_ColorRemap, i.mcrmd.ww).r * _OutlineColor * 2;
			fixed4 inLine = tex2D(_MatCap, i.mcrmd.xy).g;
			fixed stroke_Cun_0 = tex2D(_Stroke, i.uv/_StrokeCtrl.x).a;
			fixed noise = tex2D(_Noise,i.uv/_NoiseCtrl.x).b;
			fixed stroke_Ran = tex2D(_Stroke, i.uv/10).r;
			
			fixed stroke_Cun_1 = tex2D(_Stroke, i.uv/_StrokeCtrl.x*2).a;
			
			// sample the texture
			col = lerp(col,remap,
				(i.mcrmd.z - stroke_Cun_0*_StrokeCtrl.y-noise*_NoiseCtrl.y)*2);//stroke
			col = clamp(col,0,1);
			col = lerp(col,remap,(inLine)*i.mcrmd.z);//inline
			col = clamp(col,0,1);
			float k = (i.rim - _StrokeCtrl.z)/(1-_StrokeCtrl.z);
			float z = lerp(_NoiseCtrl.z,-0.06f,clamp(i.mcrmd.w*8 - 1,0,1));
			col = lerp(col, remap, clamp((k-stroke_Cun_1*1.2-noise* z)*1.5,0,1));
			// col = clamp(col,0,1);
			
			//DEBUG
			// col = length(i.mcrmd.xy-0.5)*2;
			// col = length(i.mcrmd.xy-0.5)*2 * i.mcrmd.z;
			// col = i.mcrmd.z;
			// col = _Color;
			// apply fog
			
			// col = min(col,1 - clamp(i.rim*1.5 - stroke_Ran*0.75,0,1)*0.5);
			//float r = lerp(_StrokeCtrl.w, -5,i.mcrmd.w);
			//float n = clamp(lerp(_NoiseCtrl.w,0,i.mcrmd.w),0.5,10);
			//k = (i.rim - r)/(1-r)*lerp(_Ran0,_Ran1,clamp(pow(i.mcrmd.w,0.25),0,1));
			//col = col * (1 - clamp(k*1.5 - stroke_Ran*0.75 - noise*n,0,1)*0.5);
			UNITY_APPLY_FOG(i.fogCoord, col);
			return col;
		}
		ENDCG
	}
	
	//Outline 0
	Pass
	{
		Tags { "RenderType"="Opaque" "IgnoreProjector"="True" }
		Cull Front
		
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile_fog
		#include "UnityCG.cginc"

		struct appdata {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float2 uv : TEXCOORD0;
		};

		struct v2f {
			float4 vertex : SV_POSITION;
			float2 uv : TEXCOORD0;
			UNITY_FOG_COORDS(1)
			float4 mcrmd : TEXCOORD2;//{xy: Matcap UV, z: Rimlight, w: distance}
			float2 wps : TEXCOORD3;
		};
		
		float4 _OutlineColor;
		sampler2D _ColorRemap;
		sampler2D _MatCap;
		sampler2D _Noise;
		float4 _RemapCtrl;
		float4 _OutlineCtrl;
		float4 _OutlineTexCtrl;
		float4 _OutlineNoiseCtrl;
		float _OutlineWidth0;
		float _Cutoff;

		v2f vert (appdata v) {
			float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			float3 worldNormal = UnityObjectToWorldNormal(v.normal);
			float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
			float dis = length(worldPos - _WorldSpaceCameraPos);
			
			float3 map = cross(worldNormal, worldViewDir);
			map = mul((float3x3)UNITY_MATRIX_V, map);
			float l = length(map);
			map = normalize(map) * pow(l,lerp(_OutlineTexCtrl.x, _OutlineTexCtrl.y,dis/128));
			
			float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
			float2 extend = normalize(TransformViewToProjection(normal.xy));
			float rand = (1 + sin(length(worldPos.xyz) * _OutlineCtrl.z))*_OutlineCtrl.y;
			
			float range = clamp(lerp(-_OutlineCtrl.w/10,1,length(map.xy)),0,1);
			
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.vertex.xy += extend * _OutlineWidth0 * 0.01 * pow(o.vertex.w, _OutlineCtrl.x)*rand;
			o.vertex.z -= 0.001;
			o.uv = v.uv;
			// o.mcrmd.xy = map.xy * _OutlineTexCtrl.zw/10 * 0.5 + 0.5;
			o.mcrmd.xy = normalize(normalize(map.xy) + float2(-extend.y,extend.x)) * range * _OutlineTexCtrl.zw/10 * 0.5 + 0.5;
			// o.mcrmd.zw = dis/_RemapCtrl.x;
			o.mcrmd.z = length(worldPos - _WorldSpaceCameraPos)/_RemapCtrl.x;
			o.mcrmd.w = dis;
			o.wps = v.vertex.xz;
			UNITY_TRANSFER_FOG(o,o.vertex);
			return o;
		}

		fixed4 frag (v2f i) : SV_Target {
			
			fixed4 col = tex2D(_ColorRemap, i.mcrmd.z) * _OutlineColor * 2;
			fixed mask = tex2D(_MatCap, i.mcrmd.xy).r;
			// fixed noise0 = tex2D(_Noise, i.vertex.xy/_RemapCtrl.y).b;
			// fixed noise1 = tex2D(_Noise, i.vertex.xy/_OutlineNoiseCtrl.x).r;
			
			fixed noise0 = tex2D(_Noise, i.vertex.xy/_RemapCtrl.y).b;
			fixed noise1 = tex2D(_Noise, i.vertex.xy/_OutlineNoiseCtrl.x).r;
			
			
			// clip(-1);
			clip(mask - _Cutoff);
			clip(noise0 - _RemapCtrl.w/100);
			
			fixed range = _OutlineNoiseCtrl.y/10;
			noise1 = (round(noise1*3)/3)*range - range/4;
			col += noise1;
			
			UNITY_APPLY_FOG(i.fogCoord, col);
			return col;
		}
		ENDCG
	}
	
	//Outline 1
	Pass
	{
		Tags { "RenderType"="Opaque" "IgnoreProjector"="True"}
		Cull Front
	
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile_fog
       
		#include "UnityCG.cginc"
       
		struct appdata
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
		};
       
		struct v2f
		{
			float2 rmUV : TEXCOORD0;
			UNITY_FOG_COORDS(1)
			float4 vertex : SV_POSITION;
			float2 wps : TEXCOORD2;
		};
		
		float4 _OutlineColor;
		sampler2D _ColorRemap;
		sampler2D _Noise;
		float4 _RemapCtrl;
		float4 _OutlineCtrl;
		float4 _OutlineNoiseCtrl;
		float _OutlineWidth1;
		
		v2f vert (appdata v) {
			float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
			float2 extend = normalize(TransformViewToProjection(normal.xy));
			float dis = length(worldPos - _WorldSpaceCameraPos);
			float rand = (1 + sin(length(worldPos.xyz) * 180  * _OutlineCtrl.z))*0.5;
			
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.vertex.xy += extend * _OutlineWidth1 * 0.01 * pow(o.vertex.w, _OutlineCtrl.x)*rand;
			o.vertex.z -= 0.002;
			o.rmUV = length(worldPos - _WorldSpaceCameraPos)/_RemapCtrl.x;
			UNITY_TRANSFER_FOG(o,o.vertex);
			o.wps = v.vertex.xz;
			return o;
		}
       
		fixed4 frag (v2f i) : SV_Target {
			fixed4 col = tex2D(_ColorRemap, i.rmUV) * _OutlineColor * 2;
			// fixed noise0 = tex2D(_Noise, i.vertex.xy/_RemapCtrl.y/2).b;
			// fixed noise1 = tex2D(_Noise, i.vertex.xy/20).b*1.2;
			// fixed noise2 = tex2D(_Noise, i.vertex.xy/_OutlineNoiseCtrl.x).r;
			
			fixed noise0 = tex2D(_Noise, i.vertex.xy/_RemapCtrl.y/2).b;
			// fixed noise1 = tex2D(_Noise, i.vertex.xy/20).b*1.2;
			fixed noise2 = tex2D(_Noise, i.vertex.xy/_OutlineNoiseCtrl.x).r;
			

			clip(noise0 - _RemapCtrl.w/100);
			
			fixed range = _OutlineNoiseCtrl.y/10;
			noise2 = (round(noise2*3)/3)*range - range/4;
			col += noise2;
			// col = noise2;
			UNITY_APPLY_FOG(i.fogCoord, col);
			return col;
		}
		ENDCG
	}
	
	UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
}
}
