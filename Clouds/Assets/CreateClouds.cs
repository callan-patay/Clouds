using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CreateClouds : MonoBehaviour {


    [SerializeField]
    private Texture3D _texture;
    private Texture3D _texture1;
    public Quaternion axis = Quaternion.identity;
    public GameObject DirectionalLight;

    private float cumulusScatter;
    private float cumulusAbsorb;

    public float scale = 20f;

    // Use this for initialization
    void Start () {
        _texture = generateClouds(256);
        //_texture1 = generateClouds1(256);

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
        GetComponent<Renderer>().material.SetTexture("_Volume1", _texture1);
        GetComponent<Renderer>().material.SetMatrix("_AxisRotationMatrix", Matrix4x4.Rotate(axis));
        GetComponent<Renderer>().material.SetVector("_LightDir", DirectionalLight.transform.eulerAngles);
       
    }


    // https://github.com/fleity/VolumeDemo/blob/master/Assets/Shaders/raymarch_simple.shader

    // Update is called once per frame
    void Update () {
        GetComponent<Renderer>().material.SetVector("_Pos", transform.position);

        
	}
    Texture3D generateClouds1(int size)
    {
        Color[] colorArray = new Color[size * size * size];
        _texture1 = new Texture3D(size, size, size, TextureFormat.RGBA32, false);
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

        _texture1.SetPixels(colorArray);
        _texture1.Apply();
        return _texture1;

    }


    Texture3D generateClouds(int size)
    {
        Color[] colorArray = new Color[size * size * size];
        _texture = new Texture3D(size, size, size, TextureFormat.RGBA32, false);
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

        _texture.SetPixels(colorArray);
        _texture.Apply();
        return _texture;

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
