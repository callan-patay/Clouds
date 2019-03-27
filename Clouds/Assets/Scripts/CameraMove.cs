using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMove : MonoBehaviour {


    public GameObject Cloud;
    public int movementSpeed = 10;
    bool isRotateOn = true;
	// Use this for initialization
	void Start () {
		
	}
	
    public void toggleRotate()
    {
        isRotateOn = !isRotateOn;
    }
	// Update is called once per frame
	void Update () {
        transform.LookAt(Cloud.transform);



        if(isRotateOn)
        {
            transform.Translate(Vector3.right * Time.deltaTime * movementSpeed);
        }
	}
}
