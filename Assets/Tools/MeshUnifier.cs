using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

public class MeshUnifier : MonoBehaviour {
  public bool collectMeshFromChildren;
  public MeshRenderer[] renderers;

  void Start() {
    if (collectMeshFromChildren) {
      CollectRenderers ();
    }

    Combine ();
  }

  public void CollectRenderers() {
    renderers = GetComponentsInChildren<MeshRenderer> ()
      .Where (r => r.enabled)
      .ToArray ();
  }

  public void Combine() {
    CombineInstance[] combine = new CombineInstance[renderers.Length];
    for (int i = 0; i < renderers.Length; i++) {
      MeshFilter filter = renderers [i].GetComponent<MeshFilter> ();
      combine [i].mesh = filter.sharedMesh;
      combine [i].transform = filter.transform.localToWorldMatrix;
      renderers [i].enabled = false;
    }

    Mesh mesh = new Mesh ();
    mesh.name = "Mesh_" + name;
    mesh.CombineMeshes (combine);

    GetComponent<MeshRenderer> ().enabled = true;
    GetComponent<MeshFilter> ().mesh = mesh;
  }

}
