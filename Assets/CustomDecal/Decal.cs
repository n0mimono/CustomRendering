using UnityEngine;
using System.Collections;

public class Decal : MonoBehaviour {

  public enum Kind {
    DiffuseOnly,
    NormalsOnly,
    Both
  }
  public Kind kind;
  public Material mat;

  void OnEnable() {
    DecalRenderer.Add (this);
  }

  void Start() {
    DecalRenderer.Add (this);
  }

  void OnDisable() {
    DecalRenderer.Remove (this);
  }

}
