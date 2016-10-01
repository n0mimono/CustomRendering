using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;

public class DecalObject : MonoBehaviour {
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

  protected virtual void Start() {
    GetRenderManager().Add (this);
  }

  public virtual DecalObjectRenderManager GetRenderManager() {
    return GameObject.FindObjectOfType<DecalObjectRenderManager>();
  }

}

public static class DecalObjectUtility {

  public static void DrawMesh(this CommandBuffer buf, DecalObject obj) {
    buf.DrawMesh (obj.mesh, obj.matrix, obj.mat);
  }

}
