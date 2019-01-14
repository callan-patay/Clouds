// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Effects"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Volume("Texture", 3D) = "" {}
		_steps("Steps", int) = 128
		_stepSize("Step Size", float) = 1
		_mipLevel("mip Level", int) = -1
		_offset("offset", vector) = (1,1,1,0)
		_threshold("threshold", float) = 1
		_volumeScale("Volume Scale", float) = 1
		_SliceMin("Slice min", Vector) = (0.0, 0.0, 0.0, -1.0)
		_SliceMax("Slice max", Vector) = (1.0, 1.0, 1.0, -1.0)
		_Color("Color", Color) = (1, 1, 1, 1)
	}
	SubShader
	{
		// No culling or depth
		//Cull Off ZWrite Off ZTest Always
			Cull Back
			//Blend SrcAlpha OneMinusSrcAlpha
			//ZTest Always	// always draw this geometry no matter if something is in front of it
	


		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ DEBUG_PERFORMANCE
			#pragma target 3.0
			#include "UnityCG.cginc"

			uniform float4x4 _FrustumCornersES;
			uniform sampler2D _MainTex;
			sampler3D _Volume;
			uniform float4 _MainTex_TexelSize;
			uniform float4x4 _CameraInvViewMatrix;
			uniform float3 _LightDir;
			uniform sampler2D _CameraDepthTexture;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 raypos : TEXCOORD2;
				float3 raydir : TEXCOORD1;
				float3 local : TEXCOORD3;
			};

			v2f vert(appdata v)
			{
				v2f o;

				// Index passed via custom blit function in RaymarchGeneric.cs
				//half index = v.vertex.z;
				//v.vertex.z = 0.1;

				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				//#if UNITY_UV_STARTS_AT_TOP
				//if (_MainTex_TexelSize.y < 0)
				//	o.uv.y = 1 - o.uv.y;
				//#endif

				o.raypos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.local = v.vertex.xyz;
				


				return o;
			}
			


			//float3 calcNormal(in float3 pos)
			//{
			//	// epsilon - used to approximate dx when taking the derivative
			//	const float2 eps = float2(0.001, 0.0);

			//	// The idea here is to find the "gradient" of the distance field at pos
			//	// Remember, the distance field is not boolean - even if you are inside an object
			//	// the number is negative, so this calculation still works.
			//	// Essentially you are approximating the derivative of the distance field at this point.
			//	float3 nor = float3(
			//		map(pos + eps.xyy).x - map(pos - eps.xyy).x,
			//		map(pos + eps.yxy).x - map(pos - eps.yxy).x,
			//		map(pos + eps.yyx).x - map(pos - eps.yyx).x);
			//	return normalize(nor);
			//}


			int _steps;
			int _mipLevel;
			int _stepSize;
			float3 _offset;
			float _volumeScale;
			float _threshold;
			float _Intensity;
			half3 _SliceMin;
			half3 _SliceMax;
			float4x4 _AxisRotationMatrix;

			bool intersect(float3 rayPos, float3 rayDir, float3 boxmin, float3 boxmax, out float t0, out float t1)
			{
				float3 invR = 1.0 / rayDir;
				float3 tbot = invR * (boxmin - rayPos);
				float3 ttop = invR * (boxmax - rayPos);
				float3 tmin = min(ttop, tbot);
				float3 tmax = max(ttop, tbot);
				float2 t = max(tmin.xx, tmin.yz);
				t0 = max(t.x, t.y);
				t = min(tmax.xx, tmax.yz);
				t1 = min(t.x, t.y);
				return t0 <= t1;
			}
			
			float3 localize(float3 p) {
				return mul(unity_WorldToObject, float4(p, 1)).xyz;
			}

			float3 get_uv(float3 p) {
				// float3 local = localize(p);
				return (p + 0.5);
			}

			float sample_volume(float3 uv, float3 p)
			{
				//_Intensity = 1.5f;
				float v = tex3D(_Volume, uv).r * _volumeScale;

				float3 axis = mul(_AxisRotationMatrix, float4(p, 0)).xyz;
				axis = get_uv(axis);
				float min = step(_SliceMin.x, axis.x) * step(_SliceMin.y, axis.y) * step(_SliceMin.z, axis.z);
				float max = step(axis.x, _SliceMax.x) * step(axis.y, _SliceMax.y) * step(axis.z, _SliceMax.z);

				return v * min * max;
			}
			//https://github.com/mattatz/unity-volume-rendering/blob/master/Assets/VolumeRendering/Shaders/VolumeRendering.cginc

			bool sphereHit(float3 p) {
				return distance(p, 0.0f) < 1.0f;
			}
#define ITERATIONS 100
			float4 _Color;
			float4 raymarch(float3 rayPos, float3 rayDir, float3 origin) {
				//float4 ret = fixed4(0, 0, 0, 1);
				
				//
				//	_stepSize = _stepSize / _steps;
				//float t = 0; // current distance traveled along ray

				
				float3 Dir = normalize(mul(unity_WorldToObject, rayDir));
				//float stepDist = _rayDir * _stepSize;

				float3 boxmin = (-1.0, -1.0, -1.0);
				float3 boxmax = (1, 1,1);
				float tnear;
				float tfar;
				//_Color = (1, 1, 1, 0);
				intersect(rayPos, Dir, boxmin, boxmax, tnear, tfar);

				tnear = max(0.0, tnear);

				float3 start = origin;
				float3 end = origin + Dir * tfar;
				float dist = abs(tfar - tfar);
				_stepSize = dist / (float)ITERATIONS;
				float3 ds = normalize(end - start) * _stepSize;
				float4 dst = float4(0, 0, 0, 0);
				float3 p = start;

				[unroll]
				for (int i = 0; i < ITERATIONS; ++i) 
				{
					float3 uv = get_uv(p);
					float v = sample_volume(uv, p);
					float4 src = float4(v, v, v, v);
					src.a *= 0.5;
					src.rgb *= src.a;

					dst = (1.0 - dst.a) * src + dst;

					//if (sphereHit(p))
					//{
					//	return(1, 0, 0, 1);
					//}



					p += ds;

					if (dst.a > _threshold) {
						break;
					}

					/*p += _rayDir * _stepSize;
					ret = tex3Dlod(_Volume, float4((p.xzy / _volumeScale) + _offset, _mipLevel)).rgba;

					if (ret.r + ret.g > _threshold)
					{
						break;
					}*/

				}
			return saturate(dst) * _Color;
				//return dst + dst;
			
			}




			float4 frag (v2f i) : SV_Target
			{
				i.raydir = (i.raypos - _WorldSpaceCameraPos);
				float4 add = raymarch(i.raypos, i.raydir, i.local);
				//if (add.a < 0.3) 
				//{
				//	discard;
				//}


				return add;



			}
			ENDCG
		}
	}
}
