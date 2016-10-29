using UnityEngine;
using System.Collections;

[RequireComponent(typeof(Book))]
public class AutoPager : MonoBehaviour {
  
	private float curPageNumber {
		set {
			GetComponent<Book> ().curPageNumber = value;
		}
		get {
			return GetComponent<Book> ().curPageNumber;
		}
	}

	IEnumerator Start() {

		curPageNumber = 0f;

		while (true) {
			yield return null;

      // adhoc customize...
      int p = (int)(Mathf.Floor (curPageNumber));
      if (p % 2 == 0) {
        yield return new WaitForSeconds (0.5f);
      } else {
        yield return new WaitForSeconds (8f);
      }

			yield return StartCoroutine (TurnPage());

		}
	}

	private IEnumerator TurnPage() {
		float time = 0;
		while (true) {
			float dt = Time.deltaTime;

			time += dt;
			if (time > 1f) break;
			yield return null;

			curPageNumber += dt;
		}

		curPageNumber = Mathf.Ceil (curPageNumber);
	}

}
