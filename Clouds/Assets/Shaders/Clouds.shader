Shader "Custom/Clouds" {
	Properties {
		_Volume("Texture", 3D) = "" {}
		_LightDir("LightDir", Vector) = (0.0, 0.0, 0.0, -1.0)
		_g("g", Float) = 0.8
		_LightIntensity("LightIntensity", Float) = 100
		_Factor("Factor", Range(0, 5)) = 1.0
		_Max("Max", Float) = 0.0
	}
		SubShader{
			Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }
			LOD 100
			//GrabPass { }
			ZWrite Off
			Blend OneMinusDstColor One//OneMinusSrcAlpha
				Pass
				{
					CGPROGRAM
					#pragma vertex vert
					#pragma fragment frag
					// Use shader model 3.0 target, to get nicer looking lighting
					#include "UnityCG.cginc"
					//#pragma target 3.0
					#pragma fragmentoption ARB_precision_hint_fastest


					struct appdata {
						float4 vertex : POSITION;
					};

					struct v2f {
						float4 vertex : SV_POSITION;
						float3 wPos : TEXCOORD1; // World Position
						float4 uv: TEXCOORD0;
					};

					struct Ray {
						float3 origin;
						float3 dir;
					};

					sampler3D _Volume;
					float3 _LightDir;
					float _LightIntensity;
					float _Max;
					float3 sunLight;
					sampler2D _GrabTexture;
					float4 _GrabTexture_TexelSize;
					float _Factor;
					float _g;
					float M_PI = 3.14159;

					v2f vert(appdata v) {
						v2f o;
						o.vertex = UnityObjectToClipPos(v.vertex);
						o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
						o.uv = ComputeGrabScreenPos(o.vertex);
						return o;
					}

					uint hash(uint x) {
						x += (x << 10u);
						x ^= (x >> 6u);
						x += (x << 3u);
						x ^= (x >> 11u);
						x += (x << 15u);
						return x;
					}

					float random(float f) {
						const uint mantissaMask = 0x007FFFFFu;
						const uint one = 0x3F800000u;

						uint h = hash(asuint(f));
						h &= mantissaMask;
						h |= one;

						float  r2 = asfloat(h);
						return r2 - 1.0;
					}

					bool outsideTexture(float3 uv)
					{
						const float EPSILON = 0.01;
						float lower = -EPSILON;
						float upper = 1 + EPSILON;
						return (
							uv.x < lower || uv.y < lower || uv.z < lower ||
							uv.x > upper || uv.y > upper || uv.z > upper
							);
					}

					float3 texCoordsFromPosition(float3 position)
					{
						float3 npos = mul(unity_WorldToObject, float4(position, 1.0)).xyz;
						return npos + float3(0.5, 0.5, 0.5);
					}

					float2 coefficients(float3 wpos)
					{
						//float3 npos = mul(unity_WorldToObject, float4(wpos, 1.0)).xyz + float3(0.5, 0.5, 0.5);
						return tex3D(_Volume, texCoordsFromPosition(wpos)).rg;
					}

					//woodcock tracking
					float sampleDistance(Ray r, inout float randValue)
					{
						float s = 0;

						//float cumulusScatter = 0.0814896f;
						//float cumulusAbsorb = 0.000000110804f;
						//float max = cumulusScatter + cumulusAbsorb;

						randValue = random(randValue);

						float newRand = random(randValue);
						int intersected = 0;
						for (int i = 0; i < 10; i++)
						{
							s += -log(1 - randValue) / _Max;
							newRand = random(randValue);
							float2 sigma;
							sigma = coefficients(r.origin + (s * r.dir));
							if (newRand < ((sigma.r + sigma.g) / _Max))
							{
								return s;
							}
							randValue = random(newRand);
						}

						return 1000000000.0f;
					}


			

					float3x3 createOrthonormalbasis(float3 v1)
					{
						float3 v2;
						float3 v3;
						if (abs(v1.x) > abs(v1.y))
						{
							float invlength = 1.0f / sqrt(v1.x*v1.x + v1.z*v1.z);
							v2 = float3(-v1.z * invlength, 0.0f, v1.x * invlength);
						}
						else
						{
							float invLength = 1.0f / sqrt(v1.y*v1.y + v1.z*v1.z);
							v2 = float3(0.0f, v1.z*invLength, -v1.y * invLength);
						}

						//v1 = normalize(v1);
						//v2 = normalize(v2);
						v3 = cross(v1, v2);
						//v3 = normalize(v3);

						float3x3 OMatrix =
						{
							v2.x, v2.y, v2.z,
							v3.x, v3.y, v3.z,
							v1.x, v1.y, v1.z
						};

						return OMatrix;
					}

					float eval(const float3 wo, const float3 wi)
					{
						const float k = 1.0f + (_g * _g) - (2.0f * _g * dot(normalize(wi), normalize(wo)));
						float u =  (1.0f / (4.0f * M_PI)) *((1.0f - (_g * _g)) / (k * sqrt(k)));
						return u;
					}

					float3 HG(Ray r, float randValue)
					{
						float M_TWO_PI = M_PI * 2;
						float s1 = random(randValue);
						float s2 = random(s1);
						float costheta;
						costheta = (1.0f - (_g * _g)) / (1.0f - _g + (2.0f * _g * s1));
						costheta = (1.0f + (_g * _g) - (costheta * costheta)) / (2.0f * _g);
						float sintheta;
						sintheta = sqrt(1.0f - (costheta * costheta));
						float phi;
						phi = s2 * M_TWO_PI;

						float3 wi = float3(sintheta * cos(phi), sintheta * sin(phi), costheta);

						float3x3 Omatrix = createOrthonormalbasis(r.dir);
						Omatrix = transpose(Omatrix);

						float3 wiglobal = mul(Omatrix, wi);

						return wiglobal;
					}

					float isotropicPF()
					{
						return (1.0f / (4.0f * 3.1412654f));
					}

					float3 sampleIsotropic(inout float randValue)
					{
						float s1 = random(randValue);
						randValue = random(s1);
						float theta;
						float phi;
						theta = s1 * M_PI;
						phi = acos(1.0 - 2.0 * randValue);
						return float3(cos(phi) * sin(theta), sin(theta) * sin(phi), cos(theta));
					}

					float computeAttenuation(float3 pos, float3 dirtosun, inout float randValue)
					{
						float s = 0;

						//float cumulusScatter = 0.0814896f;
						//float cumulusAbsorb = 0.000000110804f;
						//float max = cumulusScatter + cumulusAbsorb;

						randValue = random(randValue);

						float newRand = random(randValue);

						[loop]
						for (int i = 0; i < 10; i++)
						{ 
							randValue = random(newRand);
							s += -log(1 - randValue) / _Max;
							float3 newPos;
							newPos = pos + (dirtosun * s);
							if (outsideTexture(texCoordsFromPosition(newPos)))
							{
								return 1;
							}
							float2 sigma;
							sigma = coefficients(newPos);
							if (newRand > ((sigma.r + sigma.g) / _Max))
							{
								return 0;
							}
						 
						}
						return 1.0f;
					}

					float3 computeDirectLighting(float3 pos, float3 dirtosun, inout float randValue)
					{
						float att = 0;
						//float3 sunLight = float3(10000, 10000, 10000);
						[loop]
						for (int i = 0; i < 10; i++)
						{
							att = att + computeAttenuation(pos, dirtosun, randValue);
						}
						att = att / 10.0f;
						return (sunLight * att);
					}

					float3 raymarchOut(float3 pos, float3 dirtosun, inout float randValue)
					{
						int STEPS = 10;
						float stepSize = 30.0f;
						//float3 sunLight = float3(10000, 10000, 10000);
						float density = 0;
						
						float3 marchingPos = pos;

						[loop]
						for (int i = 0; i < STEPS; i++)
						{
							float2 sigma;
							sigma = coefficients(marchingPos);

							density += (sigma.r + sigma.g) * stepSize;
							marchingPos += dirtosun * stepSize;

							if (outsideTexture(marchingPos))
							{
								break;
							}
						}
						float trans = exp(-density);
						return (sunLight * trans);
					}


					float4 trace(Ray r, float3 lightDir)
					{
						float randValue = random(frac(r.origin.x + r.origin.y + r.origin.z) /*+ _Time*/);
						float3 paththrougput = float3(1.0f, 1.0f, 1.0f);
						float4 colour = float4(0.0f, 0.0f, 0.0f, 0.0f);

						float newRand = random(randValue);

						[loop]
						for (int i = 0; i < 10; i++)
						{
							newRand = random(randValue);
							float distance = sampleDistance(r, randValue);
							r.origin += r.dir * distance;
							if (outsideTexture(texCoordsFromPosition(r.origin)))
							{
								break;
							}
							else
							{
								float2 sigma;
								sigma = coefficients(r.origin);
								colour = colour + float4((paththrougput * computeDirectLighting(r.origin, -lightDir, newRand) * sigma.g * isotropicPF()), 1);// eval(-r.dir, -lightDir)), 1);
								float3 dir;
								dir = sampleIsotropic(newRand);// HG(r, newRand);
								paththrougput = paththrougput * sigma.g;
								if (paththrougput.r > 1)
								{
									return float4(1, 0, 0, 1);
								}
								r.dir = dir;
							}
							randValue = random(newRand);
						}
						return colour;
					}

					fixed4 frag(v2f i) : SV_Target
					{
						Ray ray;
						float3 worldPosition = i.wPos;
						float3 viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);
						ray.origin = worldPosition;
						ray.dir = viewDirection;
						sunLight = float3(_LightIntensity, _LightIntensity, _LightIntensity);
						_LightDir = normalize(_LightDir);
						return trace(ray, _WorldSpaceLightPos0);

						//half4 pixelCol = trace(ray, _WorldSpaceLightPos0);
					}
				
					ENDCG
				}

			//GrabPass{ "_GrabTexture" }

			//Pass
			//{
			//	CGPROGRAM
			//	#pragma vertex vert
			//	#pragma fragment frag

			//	#include "UnityCG.cginc"
			//	struct appdata
			//	{
			//		float4 vertex : POSITION;
			//		float2 uv : TEXCOORD0;
			//	};

			//	struct v2f
			//	{
			//		float4 pos: SV_POSITION;
			//		float4 uv : TEXCOORD0;
			//	};

			//	v2f vert(appdata v)
			//	{
			//		v2f o;
			//		o.pos = UnityObjectToClipPos(v.vertex);
			//		o.uv = ComputeGrabScreenPos(o.pos);
			//		return o;
			//	}

			//	sampler2D _GrabTexture;
			//	float4 _GrabTexture_TexelSize;
			//	float _Factor;

			//	fixed4 frag(v2f i) : SV_Target
			//	{

			//		fixed4 pixelCol = fixed4(0, 0, 0, 0.0);

			//		#define ADDPIXELX(weight,kernelX) tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(float4(i.uv.x + _GrabTexture_TexelSize.x * kernelX * _Factor, i.uv.y, i.uv.z, i.uv.w))) * weight

			//		pixelCol += ADDPIXELX(0.05, 4.0);
			//		pixelCol += ADDPIXELX(0.09, 3.0);
			//		pixelCol += ADDPIXELX(0.12, 2.0);
			//		pixelCol += ADDPIXELX(0.15, 1.0);
			//		pixelCol += ADDPIXELX(0.18, 0.0);
			//		pixelCol += ADDPIXELX(0.15, -1.0);
			//		pixelCol += ADDPIXELX(0.12, -2.0);
			//		pixelCol += ADDPIXELX(0.09, -3.0);
			//		pixelCol += ADDPIXELX(0.05, -4.0);

			//		/*#define ADDPIXELY(weight,kernelY) tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(float4(i.uv.x, i.uv.y + _GrabTexture_TexelSize.y * kernelY * _Factor, i.uv.z, i.uv.w))) * weight

			//		pixelCol += ADDPIXELY(0.05, 4.0);
			//		pixelCol += ADDPIXELY(0.09, 3.0);
			//		pixelCol += ADDPIXELY(0.12, 2.0);
			//		pixelCol += ADDPIXELY(0.15, 1.0);
			//		pixelCol += ADDPIXELY(0.18, 0.0);
			//		pixelCol += ADDPIXELY(0.15, -1.0);
			//		pixelCol += ADDPIXELY(0.12, -2.0);
			//		pixelCol += ADDPIXELY(0.09, -3.0);
			//		pixelCol += ADDPIXELY(0.05, -4.0);
			//		pixelCol = pixelCol * 0.5f;*/
			//		return pixelCol;
			//	}
			//	ENDCG
			//}
		}
}
