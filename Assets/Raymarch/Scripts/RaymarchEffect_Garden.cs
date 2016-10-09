using UnityEngine;
using System.Collections;
using System;

public class RaymarchEffect_Garden : MonoBehaviour {

  private Renderer rend;
  private MaterialPropertyBlock prop;

  void Start() {
    prop = new MaterialPropertyBlock ();
    rend = GetComponent<Renderer> ();

    StartCoroutine (ProcEffect ());
  }

  private void SetProp(float val) {
    prop.SetVector ("_Rotate", new Vector4(0, 1, 0, val));
    rend.SetPropertyBlock (prop);
  }

  private IEnumerator ProcEffect() {
    SetProp (-1);
    yield return new WaitForSeconds (4f);

    yield return StartCoroutine(ProcSet(1f, 2f, -1f, -0.9f));
    yield return new WaitForSeconds (2f);

    yield return StartCoroutine(ProcSet(1f, 2f, -0.9f, -0.8f));
    yield return new WaitForSeconds (2f);

    yield return StartCoroutine(ProcSet(1f, 2f, -0.8f, -0.7f));
    yield return new WaitForSeconds (2f);

    yield return StartCoroutine(ProcSet(1f, 2f, -0.7f, 0.8f));
    yield return new WaitForSeconds (2f);

    yield return StartCoroutine(ProcSet(1f, 2f, 0.8f, 0.7f));
    yield return new WaitForSeconds (2f);

    yield return StartCoroutine(ProcSet(1f, 2f, 0.7f, 0.6f));
    yield return new WaitForSeconds (2f);

    yield return StartCoroutine(ProcSet(1f, 2f, 0.6f, 0.5f));
    yield return new WaitForSeconds (2f);

    yield return StartCoroutine(ProcSet(1f, 2f, 0.5f, 0.46f));
    yield return null;
  }

  private IEnumerator ProcSet(float duration, float scale, float start, float end) {
    for (float t = 0f; t < duration; t += Time.deltaTime * scale) {
      SetProp (start + (end - start) * t);
      yield return null;
    }



  }


}
