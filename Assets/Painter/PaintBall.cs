using UnityEngine;
using System.Collections;

public class PaintBall : MonoBehaviour {
  public Rigidbody rigid;
  public Painter paint;

  public void AddForce(Vector3 force) {
    rigid.AddForce (force);
  }

  public void OnCollisionEnter(Collision col) {
    ContactPoint contact = col.contacts[0];

    paint.transform.SetParent (transform.parent);
    paint.transform.position = contact.point;
    paint.gameObject.SetActive (true);

    gameObject.SetActive (false);
  }

}
