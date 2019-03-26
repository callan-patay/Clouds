using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMove : MonoBehaviour {


    public GameObject Cloud;
    public int movementSpeed = 10;

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
        transform.LookAt(Cloud.transform);
        transform.Translate(Vector3.right * Time.deltaTime * movementSpeed);
	}
}
