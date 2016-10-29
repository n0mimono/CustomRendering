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

			yield return StartCoroutine (TurnPage());

			yield return new WaitForSeconds (2f);
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
