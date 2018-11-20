using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CreateClouds : MonoBehaviour {


    [SerializeField]
    private Texture3D _texture;

    public float scale = 20f;

    // Use this for initialization
    void Start () {
        _texture = generateClouds(256);


        GetComponent<Renderer>().material.SetTexture("_Volume", _texture);
	}


    // https://github.com/fleity/VolumeDemo/blob/master/Assets/Shaders/raymarch_simple.shader

    // Update is called once per frame
    void Update () {
		
	}


    Texture3D generateClouds(int size)
    {
        Color[] colorArray = new Color[size * size * size];
        _texture = new Texture3D(size, size, size, TextureFormat.RGBA32, true);
        for (int x = 0; x < size; x++)
        {
            for (int y = 0; y < size; y++)
            {
                for (int z = 0; z < size; z++)
                {
                    float p = Perlin3D((float)x / size, (float)y / size, (float)z / size, scale);
                    Color c = new Color(p, p, p, p);
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
        float AB = Mathf.PerlinNoise(x * scale, y * scale);
        float BC = Mathf.PerlinNoise(y * scale, z * scale);
        float AC = Mathf.PerlinNoise(x * scale, z * scale);

        float BA = Mathf.PerlinNoise(y * scale, x * scale);
        float CB = Mathf.PerlinNoise(z * scale, y * scale);
        float CA = Mathf.PerlinNoise(z * scale, x * scale);

        float ABC = AB + BC + AC + BA + CB + CA;
        return ABC / 6f;

    }


}
