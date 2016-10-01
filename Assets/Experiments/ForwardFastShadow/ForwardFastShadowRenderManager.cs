using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

public class ForwardFastShadowRenderManager : MonoBehaviour {
  public GameObject[] objects;

  private Material matZWrite;

  private Dictionary<Camera, CommandBuffer> buffers = new Dictionary<Camera, CommandBuffer> ();

  void Start() {
    Shader shader = Shader.Find ("Forward/ForwardFastShadow");
    matZWrite = new Material (shader);
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

    if (buffers.ContainsKey (current)) return;

    CommandBuffer buffer = new CommandBuffer ();
    buffers [current] = buffer;
    current.AddCommandBuffer(CameraEvent.AfterSkybox, buffer);

    foreach (GameObject go in objects) {
      Renderer[] renderers = go.GetComponentsInChildren<Renderer> ();

      foreach (Renderer rend in renderers) {
        Material[] mats = rend.sharedMaterials;
        for (int i = 0; i < mats.Length; i++) {
          buffer.DrawRenderer (rend, matZWrite, i, 0);
        }
      }
    }

  }
}
