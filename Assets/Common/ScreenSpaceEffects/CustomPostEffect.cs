using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class CustomPostEffect : MonoBehaviour {
  public Material mat;
  public bool     useIvp;

  void OnEnable() {
    GetComponent<Camera> ().depthTextureMode = DepthTextureMode.DepthNormals;
  }

  void OnRenderImage(RenderTexture src, RenderTexture dst) {
    if (mat != null) {
      if (useIvp) {
        Camera    camera = GetComponent<Camera> ();
        Matrix4x4 view   = camera.worldToCameraMatrix;
        Matrix4x4 proj   = GL.GetGPUProjectionMatrix (camera.projectionMatrix, false);
        Matrix4x4 vp     = proj * view;
        Matrix4x4 ivp    = vp.inverse;

        mat.SetMatrix ("_View", view);
        mat.SetMatrix ("_ViewProj", proj);
        mat.SetMatrix ("_ViewProj", vp);
        mat.SetMatrix ("_InvViewProj", ivp);
      }

      Graphics.Blit (src, dst, mat);
    } else {
      Graphics.Blit (src, dst);
    }
  }

}
