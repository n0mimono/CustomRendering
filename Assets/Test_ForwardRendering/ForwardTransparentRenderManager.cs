using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

public class ForwardTransparentRenderManager : MonoBehaviour {
  public int materialPassCount;
  public GameObject[] objects;

  private Dictionary<Camera, CommandBuffer> buffers = new Dictionary<Camera, CommandBuffer> ();
  private Dictionary<SkinnedMeshRenderer, Material[]> matMap = new Dictionary<SkinnedMeshRenderer, Material[]> ();

  void Start() {
    
    foreach (GameObject go in objects) {
      SkinnedMeshRenderer[] renderers = go.GetComponentsInChildren<SkinnedMeshRenderer> ();
      foreach (SkinnedMeshRenderer rend in renderers) {
        matMap [rend] = rend.sharedMaterials;
        rend.materials = new Material[0];
      }
    }

  }

  private void Cleanup() {
    foreach (var buf in buffers.Where(b => b.Key != null)) {
      buf.Key.RemoveCommandBuffer (CameraEvent.AfterSkybox, buf.Value);
    }
    buffers.Clear ();
  }

  void OnEnable() {
    Cleanup();
  }

  void OnDisable() {
    Cleanup();
  }

  void Update() {
    Camera current = Camera.current;
    if (current == null) return;

    CommandBuffer buffer = null;
    if (buffers.ContainsKey (current)) {
      buffer = buffers [current];
      buffer.Clear ();
    } else {
      buffer = new CommandBuffer ();
      buffers [current] = buffer;
      current.AddCommandBuffer(CameraEvent.AfterSkybox, buffer);
    }

    foreach (GameObject go in objects.
      OrderBy (g => -1f * Vector3.Distance (g.transform.position, current.transform.position))
    ) {
      
      SkinnedMeshRenderer[] renderers = go.GetComponentsInChildren<SkinnedMeshRenderer> ();
      for (int k = 0; k < materialPassCount; k++) {
        foreach (SkinnedMeshRenderer rend in renderers) {
          Material[] mats = matMap[rend];
          for (int i = 0; i < mats.Length; i++) {
            buffer.DrawRenderer (rend, mats [i], i, k);
          }
        }
      }

    }

  }
}
