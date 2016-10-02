using UnityEngine;
using System.Collections;

public class CustomLight : MonoBehaviour {

  public Color color;
  public float intensity;
  public float range;
  public float size;
  public float tubeLength;

  public Color linear {
    get {
      return new Color (
        Mathf.GammaToLinearSpace(color.r * intensity),
        Mathf.GammaToLinearSpace(color.g * intensity),
        Mathf.GammaToLinearSpace(color.b * intensity),
        1f
      );
    }
  }

  void OnEnable() {
    CustomLightRenderer.lights.Remove (this);
    CustomLightRenderer.lights.Add (this);
  }

  void Start() {
    CustomLightRenderer.lights.Remove (this);
    CustomLightRenderer.lights.Add (this);
  }

  void OnDisable() {
    CustomLightRenderer.lights.Remove (this);
  }

}
