using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class DeferredComposite : MonoBehaviour {
  public Material mat;

  void OnEnable() {
    GetComponent<Camera> ().depthTextureMode = DepthTextureMode.DepthNormals;
  }

  void OnRenderImage(RenderTexture src, RenderTexture dst) {
    if (mat != null) {
      Graphics.Blit (src, dst, mat);
    } else {
      Graphics.Blit (src, dst);
    }
  }

}
