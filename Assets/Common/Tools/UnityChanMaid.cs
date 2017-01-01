using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class UnityChanMaid : MonoBehaviour {
  public Material skin;
  public Material cloth;

  [ContextMenu("Dress")]
  void Dress() {
    foreach (SkinnedMeshRenderer rend in GetComponentsInChildren<SkinnedMeshRenderer>()) {
      Material[] mats = rend.sharedMaterials;

      for (int i = 0; i < mats.Length; i++) {
        mats [i] = skin;
      }
      if (rend.name == "_body_winter") {
        mats [0] = cloth;
        mats [1] = cloth;
      }
      rend.sharedMaterials = mats;
    }
  }

}
