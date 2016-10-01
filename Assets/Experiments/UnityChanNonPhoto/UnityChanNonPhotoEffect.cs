using UnityEngine;
using System.Collections;

public class UnityChanNonPhotoEffect : MonoBehaviour {
  public Material mat;

  void OnRenderImage(RenderTexture src, RenderTexture dst) {
    if (mat == null) {
      Graphics.Blit (src, dst);
      return;
    }

    // edge detection
    RenderTexture edge = RenderTexture.GetTemporary(src.width, src.height, 0, RenderTextureFormat.ARGB32);
    Graphics.Blit (src, edge, mat, 0);

    // composite
    mat.SetTexture("_EdgeTex", edge);
    Graphics.Blit (src, dst, mat, 1);

    // release
    mat.SetTexture("_EdgeTex", null);
    RenderTexture.ReleaseTemporary(edge);
  }


}
