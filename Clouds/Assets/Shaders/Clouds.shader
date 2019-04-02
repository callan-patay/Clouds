Shader "Custom/Clouds" {
	Properties {
		_Volume("Texture", 3D) = "" {}
		_LightIntensity("LightIntensity", Float) = 100
		_Max("Max", Float) = 0.0
		_Colour("Colour", Color) = (1.0, 1.0, 1.0, 0.0)
	}
		SubShader{
			Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }
			LOD 100

			//AlphaTest Greater 0.5
			ZWrite Off
			Blend OneMinusDstColor One
				Pass
				{
					CGPROGRAM
					#pragma vertex vert
					#pragma fragment frag

					#include "UnityCG.cginc"				


					struct appdata {
						float4 vertex : POSITION;
					};

					struct v2f {
						float4 vertex : SV_POSITION;
						float3 wPos : TEXCOORD1;
					};

					struct Ray {
						float3 origin;
						float3 dir;
					};

					sampler3D _Volume;
					float _LightIntensity;
					float _Max;
					float3 sunLight;

					float4 _Colour;

					v2f vert(appdata v) {
						v2f o;
						o.vertex = UnityObjectToClipPos(v.vertex);
						o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
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

					//checks if ray position has left the cloud texture
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
						return tex3D(_Volume, texCoordsFromPosition(wpos)).rg;
					}

					//woodcock tracking
					float sampleDistance(Ray r, inout float randValue)
					{
						float s = 0;

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

						return 0.0f;
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

			
						v3 = cross(v1, v2);
						float3x3 OMatrix =
						{
							v2.x, v2.y, v2.z,
							v3.x, v3.y, v3.z,
							v1.x, v1.y, v1.z
						};

						return OMatrix;
					}

					float _g = 0.8;
					float M_PI = 3.14159;

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

					//checks if light bounced outside of the cloud, or stayed inside of the cloud
					float computeAttenuation(float3 pos, float3 dirtosun, inout float randValue)
					{
						float s = 0;

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

					//calculates average attenuation of directional lighting
					float3 computeDirectLighting(float3 pos, float3 dirtosun, inout float randValue)
					{
						float att = 0;

						[loop]
						for (int i = 0; i < 10; i++)
						{
							att += computeAttenuation(pos, dirtosun, randValue);
						}
						att /= 10.0f;
						return (sunLight * att);
					}

					//attempt at raymarching towards directional light
					//failed
					float3 raymarchOut(float3 pos, float3 dirtosun, inout float randValue)
					{
						int STEPS = 10;
						float stepSize = 30.0f;
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

					//main trace algorithm
					float4 trace(Ray r, float3 lightDir)
					{
						float randValue = random(frac(r.origin.x + r.origin.y + r.origin.z));
						float3 paththrougput = float3(1.0f, 1.0f, 1.0f);
						float4 colour = float4(0.0f, 0.0f, 0.0f, 0.0f);

						float newRand = random(randValue);

						[loop]
						for (int i = 0; i < 10; i++)
						{
							newRand = random(randValue);
							//woodcock tracking
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
								//calculates colour
								colour += float4((paththrougput * computeDirectLighting(r.origin, lightDir, newRand) * sigma.g * isotropicPF()), 1);
								float3 dir;
								//samples isotropic phase function
								dir = sampleIsotropic(newRand);
								r.dir = dir;
								paththrougput *=  sigma.g;
							}
							randValue = random(newRand);
						}

						//clamps value, and multiply it by desired colour if chosen
						return saturate(colour) * _Colour;
					}

					fixed4 frag(v2f i) : SV_Target
					{
						Ray ray;
						float3 worldPosition = i.wPos;
						float3 viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);
						ray.origin = worldPosition;
						ray.dir = viewDirection;
						sunLight = float3(_LightIntensity, _LightIntensity, _LightIntensity);
						return trace(ray, _WorldSpaceLightPos0);

					}
					ENDCG
				}
		}
}
