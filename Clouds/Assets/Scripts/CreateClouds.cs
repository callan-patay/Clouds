using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;



public class CreateClouds : MonoBehaviour {


   public enum cloudType
    {
        CUMULUS,
        STRATOCUMULUS,
        CIRRUS
    };


    private Texture3D _texture;
    private Renderer shader;
    private float scatter;
    private float absorb;

    public GameObject DirectionalLight;
    public cloudType cloudSelection = cloudType.CUMULUS;
    public float PerlinNoisescale = 20f;
    public int textureScale = 256;

    // Use this for initialization
    void Start ()
    {
        shader = GetComponent<Renderer>();

        switch(cloudSelection)
        {
            case cloudType.CUMULUS:
                scatter = 0.0814896f;
                absorb = 0.000000110804f;
                break;
            case cloudType.STRATOCUMULUS:
                scatter = 0.1222340f;
                absorb = 0.00000008446714f;
                break;
            case cloudType.CIRRUS:
                scatter = 0.1661800f;
                absorb = 0.000000001f;
                break;
            default:
                break;
        }

        shader.material.SetFloat("_Max", scatter + absorb);
        _texture = generatePerlinClouds(textureScale);
        shader.material.SetTexture("_Volume", _texture);

    }


    void Update () {
        shader.material.SetFloat("_LightIntensity", DirectionalLight.GetComponent<Light>().intensity);
    }
    Texture3D generatePerlinClouds(int size)
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

                    float p = Perlin3D((float)x * r, (float)y * r, (float)z * r, PerlinNoisescale);
                    Color c;

                    //populates cloud with absorption and scattering coefficient in perlin noise
                    if (p > 0.5)
                    {
                        c = new Color(absorb, scatter, 0.0f, 1.0f);
                    }
                    else
                    {
                        c = new Color(0, 0, 0, 0);
                    }

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
