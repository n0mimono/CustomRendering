using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;

public class CustomLightRenderer : MonoBehaviour {
  public Material material;
  public Mesh sphereMesh;

  private struct CommandBufferEntry {
    public CommandBuffer afterLighting;
    public CommandBuffer beforeAlpha;
  }

  private Dictionary<Camera, CommandBufferEntry> buffers = new Dictionary<Camera, CommandBufferEntry>();

  // temp solution
  public static HashSet<CustomLight> lights = new HashSet<CustomLight>();

  private void CleanUp() {
    foreach (var buf in buffers.Where(b => b.Key)) {
      buf.Key.RemoveCommandBuffer (CameraEvent.AfterLighting, buf.Value.afterLighting);
      buf.Key.RemoveCommandBuffer (CameraEvent.BeforeForwardAlpha, buf.Value.beforeAlpha);
    }
  }

  void OnDisable() {
    CleanUp ();
  }

  public void OnWillRenderObject() {

    // clean up if object is inactive.
    if (!gameObject.activeInHierarchy || !enabled) {
      CleanUp ();
      return;
    }

    // noop if we don't have any cameras.
    Camera current = Camera.current;
    if (current == null) return;

    // setup entry
    CommandBufferEntry entry = new CommandBufferEntry ();
    if (buffers.ContainsKey (current)) {
      entry = buffers [current];
      entry.afterLighting.Clear ();
      entry.beforeAlpha.Clear ();
    } else {
      entry.afterLighting = new CommandBuffer ();
      entry.afterLighting.name = "Deferred custom lights";
      entry.beforeAlpha = new CommandBuffer ();
      entry.beforeAlpha.name = "Draw light shapes";
      buffers [current] = entry;

      current.AddCommandBuffer (CameraEvent.AfterLighting, entry.afterLighting);
      current.AddCommandBuffer (CameraEvent.BeforeForwardAlpha, entry.beforeAlpha);
    }

    var propParams = Shader.PropertyToID("_CustomLightParams");
    var propColor = Shader.PropertyToID("_CustomLightColor");
    Vector4 param = Vector4.zero;
    Matrix4x4 trs = Matrix4x4.identity;

    // construct command buffer to draw lights and compute illumination on the scene
    foreach (var o in lights) {

      param.x = o.tubeLength;
      param.y = o.size;
      param.z = 1.0f / (o.range * o.range);
      entry.afterLighting.SetGlobalVector (propParams, param);
      entry.afterLighting.SetGlobalColor (propColor, o.linear);

      trs = Matrix4x4.TRS(o.transform.position, o.transform.rotation, new Vector3(o.range*2,o.range*2,o.range*2));
      entry.afterLighting.DrawMesh (sphereMesh, trs, material, 0, 0);
    }

  }

}
