using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CreateClouds : MonoBehaviour {


    [SerializeField]
    private Texture3D _texture;

    public Quaternion axis = Quaternion.identity;
    public GameObject DirectionalLight;

    private float cumulusScatter;
    private float cumulusAbsorb;

    public float scale = 20f;

    // Use this for initialization
    void Start () {
        _texture = generateVolume(256);
    

        cumulusScatter = 0.0814896f;
        cumulusAbsorb = 0.000000110804f;

        /* rgb's
         * 
         * cumulus scattering 0.0814896 red channel
         *         absorbtion 0.110804 * 10^-6 green channel
         *         
         * stratocumulus scattering 0.1222340
         *               absorbtion 0.844671 * 10^-7
         * 
         * cirrus scattering 0.1661800
         *        absorbtion 0.1 * 10^-8
         * 
         * 
         * 
         * 
         * 
         * 
         * */

       


        GetComponent<Renderer>().material.SetTexture("_Volume", _texture);
        //GetComponent<Renderer>().material.SetTexture("_Volume1", _texture1);
        GetComponent<Renderer>().material.SetMatrix("_AxisRotationMatrix", Matrix4x4.Rotate(axis));
        GetComponent<Renderer>().material.SetVector("_LightDir", DirectionalLight.transform.eulerAngles);
       
    }


    // https://github.com/fleity/VolumeDemo/blob/master/Assets/Shaders/raymarch_simple.shader

    // Update is called once per frame
    void Update () {
        //GetComponent<Renderer>().material.SetVector("_Pos", transform.position);

        
	}
    Texture3D generateClouds1(int size)
    {
        Color[] colorArray = new Color[size * size * size];
        Texture3D _texturetempt = new Texture3D(size, size, size, TextureFormat.RGBA32, false);
        float r = 1.0f / (size - 1.0f);

        
        for (int x = 0; x < size; x++)
        {
            for (int y = 0; y < size; y++)
            {
                for (int z = 0; z < size; z++)
                {
                    float p = Perlin3D((float)x * r, (float)y * r, (float)z * r, 8.0f);
                    float p1 = Perlin3D((float)x * r, (float)y * r, (float)z * r, 6.0f);

                    Color c; //= new Color(0.0f, 0.0f, 0.0f, 1.0f);

                    if (p > 0.5)
                    {
                        c = new Color(cumulusScatter, cumulusAbsorb, 0, 1.0f);
                    }
                    else if (p1 > 0.5)
                    {
                        c = new Color(cumulusScatter, cumulusAbsorb, 0, 1.0f);
                    }
                    else
                    {
                        c = new Color(0, 0, 0, 0);
                    }
                    // c = new Color(p, p, p, p);
                    //}
                    colorArray[x + (y * size) + (z * size * size)] = c;
                }
            }
        }

        _texturetempt.SetPixels(colorArray);
        _texturetempt.Apply();
        return _texturetempt;

    }

    Texture3D generateVolume(int size)
    {
        Color[] colorArray = new Color[size * size * size];
       Texture3D _texturetempt = new Texture3D(size, size, size, TextureFormat.RGBA32, false);
        float r = 1.0f / (size - 1.0f);

        Vector3 point1 = new Vector3(size/3, size/3, size/3);
        Vector3 point2 = point1 * 2;
        Vector3 point3 = new Vector3(size / 2, size / 2, size / 2);
        Vector3 point4 = new Vector3(point3.x + 40f, point3.y, point3.z);
        Vector3 point5 = new Vector3(point3.x - 40f, point3.y, point3.z);
        Vector3 point6 = new Vector3(point1.x + 40f, point1.y, point3.z + 40f);

        for (int x = 0; x < size; x++)
        {
            for (int y = 0; y < size; y++)
            {
                for (int z = 0; z < size; z++)
                {
                    Color c; 
                    Vector3 currentPos = new Vector3(x, y, z);


                    if (Vector3.Distance(currentPos, point1) < 80 
                        || Vector3.Distance(currentPos, point2) < 80 
                        || Vector3.Distance(currentPos, point3) < 80 
                        || Vector3.Distance(currentPos, point4) < 80 
                        || Vector3.Distance(currentPos, point5) < 80
                        || Vector3.Distance(currentPos, point6) < 80)
                    {
                        c = new Color(cumulusAbsorb, cumulusScatter, 1.0f, 1.0f);
                    }
                    else
                    {
                        c = new Color(0.0f, 0.0f, 0.0f, 0.0f);
                    }


                    colorArray[x + (y * size) + (z * size * size)] = c;
                }
            }
        }
        
        _texturetempt.SetPixels(colorArray);
        _texturetempt.Apply();
        return _texturetempt;

    }


    Texture3D generateClouds(int size)
    {
        Color[] colorArray = new Color[size * size * size];
        Texture3D _texturetempt = new Texture3D(size, size, size, TextureFormat.RGBA32, false);
        float r = 1.0f / (size - 1.0f);


        for (int x = 0; x < size; x++)
        {
            for (int y = 0; y < size; y++)
            {
                for (int z = 0; z < size; z++)
                {
                    float p = Perlin3D((float)x *r, (float)y *r, (float)z *r, 8.0f);
                    float p1 = Perlin3D((float)x * r, (float)y * r, (float)z * r, 6.0f);
                    Color c; //= new Color(0.0f, 0.0f, 0.0f, 1.0f);

                    if (p > 0.5)
                    {
                        c = new Color (p, p, p, 1.0f);
                    }
                    else if(p1 > 0.5)
                    {
                        c = new Color(p1, p1, p1, 1.0f);
                    }
                    else
                    {
                        c = new Color(0, 0, 0, 0);
                    }
                  // c = new Color(p, p, p, p);
                    //}
                    colorArray[x + (y * size) + (z * size * size)] = c;
                }
            }
        }

        _texturetempt.SetPixels(colorArray);
        _texturetempt.Apply();
        return _texturetempt;

    }


    public static float Perlin3D(float x, float y, float z, float scale)
    {
        float AB = Mathf.PerlinNoise(x * scale, y * scale) ;
        float BC = Mathf.PerlinNoise(y * scale, z * scale) ;
        float AC = Mathf.PerlinNoise(x * scale, z * scale) ;

        float BA = Mathf.PerlinNoise(y * scale, x * scale) ;
        float CB = Mathf.PerlinNoise(z * scale, y * scale) ;
        float CA = Mathf.PerlinNoise(z * scale, x * scale) ;

        float ABC = AB + BC + AC + BA + CB + CA;
        return ABC / 6f;

    }


}
