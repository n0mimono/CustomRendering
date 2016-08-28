using UnityEngine;
using System.Collections;

public class PaintBallSpawner : MonoBehaviour {
  public PaintBall prefab;

  public float maxForce;
  public float minForce;

  public float interval;
  public Transform targetLeft;
  public Transform targetRight;
  public Transform targetForward;

  IEnumerator Start() {
    while (true) {
      yield return StartCoroutine (Spawn ());
      yield return null;

      yield return new WaitForSeconds (interval);
      yield return null;
    }
  }

  IEnumerator Spawn() {
    Vector3 center = Vector3.Lerp (targetLeft.position, targetRight.position, Random.value);
    Vector3 target = Vector3.Lerp (center, targetForward.position, Random.value);
    transform.LookAt (target);

    yield return null;
    PaintBall ball = Instantiate (prefab);
    ball.transform.position = transform.position;
    ball.gameObject.SetActive (true);

    yield return null;
    float force = Random.value * (maxForce - minForce) + minForce;
    ball.AddForce (transform.forward * force);
  }

}
