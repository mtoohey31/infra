if (document.getElementsByTagName("video").length > 0) {
  for (let element of document.getElementsByTagName("video")) {
    element.playbackRate -= 0.25;
  }
} else if (document.getElementsByTagName("audio").length > 0) {
  for (let element of document.getElementsByTagName("audio")) {
    element.playbackRate -= 0.25;
  }
}
