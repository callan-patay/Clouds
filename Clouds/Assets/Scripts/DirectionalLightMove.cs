using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
public class DirectionalLightMove : MonoBehaviour {

    public Light directional;
	// Use this for initialization
	void Start () {
		
	}
	
    public void setIntensity(Slider slider)
    {
        directional.intensity = slider.value;
    }



    public void setDirectionalX(Slider slider)
    {
        directional.transform.eulerAngles = new Vector3(slider.value, directional.transform.eulerAngles.y, directional.transform.eulerAngles.z);
    }

    public void setDirectionalY(Slider slider)
    {
        directional.transform.eulerAngles = new Vector3(directional.transform.eulerAngles.x, slider.value, directional.transform.eulerAngles.z);
    }

	// Update is called once per frame
	void Update () {
		
	}
}
