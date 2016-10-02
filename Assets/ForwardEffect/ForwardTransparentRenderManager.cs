using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;

public class ForwardTransparentRenderManager : MonoBehaviour {

  [Serializable]
  public class Target {
    public GameObject go;
    public int        passCount;

    [HideInInspector]
    public Renderer[] renderers;
    [HideInInspector]
    public Dictionary<Renderer, Material[]> map = new Dictionary<Renderer, Material[]> ();
  }
  public Target[] targets;

  private Dictionary<Camera, CommandBuffer> buffers = new Dictionary<Camera, CommandBuffer> ();

  void Start() {
    foreach (Target tgt in targets) {
      tgt.renderers = tgt.go.GetComponentsInChildren<Renderer> ();
      foreach (Renderer rend in tgt.renderers) {
        tgt.map [rend] = rend.sharedMaterials;
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

    foreach (Target tgt in targets.
      OrderBy (t => -1f * Vector3.Distance (t.go.transform.position, current.transform.position))
    ) {
      
      for (int k = 0; k < tgt.passCount; k++) {
        foreach (Renderer rend in tgt.renderers) {
          Material[] mats = tgt.map[rend];
          for (int i = 0; i < mats.Length; i++) {
            buffer.DrawRenderer (rend, mats [i], i, k);
          }
        }
      }

    }

  }
}
