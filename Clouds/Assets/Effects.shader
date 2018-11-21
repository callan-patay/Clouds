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
	}
	SubShader
	{
		// No culling or depth
		//Cull Off ZWrite Off ZTest Always
			Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
			LOD 100
			CULL Front		// cull front faces instead of backfaces
			ZTest Always	// always draw this geometry no matter if something is in front of it
			ZWrite Off		// do not write this geometry into the depth buffer


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
			};

			v2f vert(appdata v)
			{
				v2f o;

				// Index passed via custom blit function in RaymarchGeneric.cs
				half index = v.vertex.z;
				//v.vertex.z = 0.1;

				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv.xy;

				#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
					o.uv.y = 1 - o.uv.y;
				#endif

				// Get the eyespace view ray (normalized)
				//o.ray = _FrustumCornersES[(int)index].xyz;
				o.raypos = mul(unity_ObjectToWorld, v.vertex);
				o.raydir = o.raypos - _WorldSpaceCameraPos;

				// Dividing by z "normalizes" it in the z axis
				// Therefore multiplying the ray by some number i gives the viewspace position
				// of the point on the ray with [viewspace z]=i
				//o.ray /= abs(o.ray.z);

				// Transform the ray from eyespace to worldspace
				// Note: _CameraInvViewMatrix was provided by the script
				//o.ray = mul(_CameraInvViewMatrix, o.ray);
				return o;
			}
			
			//box
			float sdBox(float3 p, float3 b)
			{
				/*float3 d = abs(p) - b;
				return length(max(d, 0.0))
					+ min(max(d.x, max(d.y, d.z)), 0.0);*/ // remove this line for an only partially signed sdf 
				float3 uvs = p / b;
			}

			// This is the distance field function.  The distance field represents the closest distance to the surface
			// of any object we put in the scene.  If the given point (point p) is inside of an object, we return a
			// negative answer.
			float map(float3 p) {
				return sdBox(p, float3(3, 3, 3));
			}

			float4 cloudColour(float3 p, float3 b)
			{
				float3 uvs = p;
				return tex3D(_Volume, uvs);
			}

			float3 calcNormal(in float3 pos)
			{
				// epsilon - used to approximate dx when taking the derivative
				const float2 eps = float2(0.001, 0.0);

				// The idea here is to find the "gradient" of the distance field at pos
				// Remember, the distance field is not boolean - even if you are inside an object
				// the number is negative, so this calculation still works.
				// Essentially you are approximating the derivative of the distance field at this point.
				float3 nor = float3(
					map(pos + eps.xyy).x - map(pos - eps.xyy).x,
					map(pos + eps.yxy).x - map(pos - eps.yxy).x,
					map(pos + eps.yyx).x - map(pos - eps.yyx).x);
				return normalize(nor);
			}


			int _steps;
			int _mipLevel;
			int _stepSize;
			float3 _offset;
			float _volumeScale;
			float _threshold;
			



			fixed4 raymarch(float3 ro, float3 rd, float s) {
				fixed4 ret = fixed4(0, 0, 0, 0);

				const int maxstep = 64;
				//float t = 0; // current distance traveled along ray
				float3 p = ro;
				for (int i = 0; i < _steps; ++i) {

					p += rd * _stepSize;
					ret = tex3Dlod(_Volume, float4((p.xzy / _volumeScale) + _offset, _mipLevel)).rgba;

					if (ret.r + ret.g > _threshold)
					{
						break;
					}
					
				



					///*if (t >= s)
					//{
					//	ret = fixed4(0, 0, 0, 0);
					//	break;
					//}*/


					//float3 p = ro + rd * t; // World space position of sample
					///*float d = map(p);       // Sample of distance field (see map())

					//						// If the sample <= 0, we have hit something (see map()).
					//if (d < 0.001) {
					//	// Lambertian Lighting
					//	float3 n = calcNormal(p);
					//	ret = fixed4(dot(-_LightDir.xyz, n).rrr, 1);
					//	break;
					//}*/
					//float4 col = cloudColour(p, float3(1,1,1));
					//ret = ret + (col / (float)maxstep);

					//// If the sample > 0, we haven't hit anything yet so we should march forward
					//// We step forward by distance d, because d is the minimum distance possible to intersect
					//// an object (see map()).
					//t += (1.0f / (float)maxstep);
				}
				return ret;
			}




			fixed4 frag (v2f i) : SV_Target
			{
				// ray direction
				i.raydir = normalize(i.raypos - _WorldSpaceCameraPos);
				// ray origin (camera position)
				//float3 ro = _CameraWS;

				float2 duv = i.uv;
				#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
					duv.y = 1 - duv.y;
				#endif

				// Convert from depth buffer (eye space) to true distance from camera
				// This is done by multiplying the eyespace depth by the length of the "z-normalized"
				// ray (see vert()).  Think of similar triangles: the view-space z-distance between a point
				// and the camera is proportional to the absolute distance.
				//float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, duv).r);
				//depth *= length(i.ray.xyz);

				//fixed3 col = tex2D(_MainTex,i.uv);
				fixed4 add = raymarch(i.raypos, i.raydir, 1.0f);
				//if (add.a < 0.3) 
				//{
				//	discard;
				//}

				// Returns final color using alpha blending
				//return fixed4(col*(1.0 - add.w) + add.xyz * add.w,1.0);

				return add;



			}
			ENDCG
		}
	}
}
