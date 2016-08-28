using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;

public class Painter : MonoBehaviour {
  public Material mat;
  public Mesh mesh;

  public bool IsActive {
    get {
      return gameObject.activeInHierarchy && enabled;
    }
  }

  public Matrix4x4 matrix {
    get {
      return transform.localToWorldMatrix;
    }
  }

  void Start() {
    PaintRenderManager.Instance.Add (this);
  }

}

public static class PainterUtility {

  public static void DrawMesh(this CommandBuffer buf, Painter paint) {
    buf.DrawMesh (paint.mesh, paint.matrix, paint.mat);
  }

}

