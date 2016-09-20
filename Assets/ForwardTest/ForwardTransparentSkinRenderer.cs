using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

public class ForwardTransparentSkinRenderer : MonoBehaviour {
  private SkinnedMeshRenderer[] renderers;
  private CommandBuffer         buffer;
  private Material              mat;

  private Dictionary<Camera, CommandBuffer> buffers = new Dictionary<Camera, CommandBuffer>();

  void Start() {
    renderers = GetComponentsInChildren<SkinnedMeshRenderer> ();
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

    CommandBuffer buffer = CreateBuffer ();
    buffers [current] = buffer;

    current.AddCommandBuffer(CameraEvent.AfterSkybox, buffer);
  }

  private CommandBuffer CreateBuffer() {
    CommandBuffer buffer = new CommandBuffer ();
    buffer.name = name;

    Shader shader = Shader.Find ("Forward/ForwardTransparentZWrite");
    mat = new Material (shader);

    foreach (SkinnedMeshRenderer rend in renderers) {
      buffer.DrawRenderer (rend, mat);
    }

    return buffer;
  }

}
