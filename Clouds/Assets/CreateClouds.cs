using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CreateClouds : MonoBehaviour {


    [SerializeField]
    private Texture3D _texture;
    public Quaternion axis = Quaternion.identity;


    public float scale = 20f;

    // Use this for initialization
    void Start () {
        _texture = generateClouds(256);



        GetComponent<Renderer>().material.SetTexture("_Volume", _texture);
        GetComponent<Renderer>().material.SetMatrix("_AxisRotationMatrix", Matrix4x4.Rotate(axis));

    }


    // https://github.com/fleity/VolumeDemo/blob/master/Assets/Shaders/raymarch_simple.shader

    // Update is called once per frame
    void Update () {
		
	}


    Texture3D generateClouds(int size)
    {
        Color[] colorArray = new Color[size * size * size];
        _texture = new Texture3D(size, size, size, TextureFormat.RGBA32, true);
        float r = 1.0f / (size - 1.0f);


        for (int x = 0; x < size; x++)
        {
            for (int y = 0; y < size; y++)
            {
                for (int z = 0; z < size; z++)
                {
                    float p = Perlin3D((float)x *r, (float)y *r, (float)z *r, 1.0f);

                    Color c; //= new Color(0.0f, 0.0f, 0.0f, 1.0f);

                    //if(p < 0.8)
                   // {

                        c = new Color(p, p, p, p);
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
        float AB = Mathf.PerlinNoise(x, y) * scale;
        float BC = Mathf.PerlinNoise(y, z) * scale;
        float AC = Mathf.PerlinNoise(x, z) * scale;

        float BA = Mathf.PerlinNoise(y, x) * scale;
        float CB = Mathf.PerlinNoise(z, y) * scale;
        float CA = Mathf.PerlinNoise(z, x) * scale;

        float ABC = AB + BC + AC + BA + CB + CA;
        return ABC / 6f;

    }


}
