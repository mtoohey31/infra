if (document.getElementsByTagName("video").length > 0) {
  for (let element of document.getElementsByTagName("video")) {
    originalStyle = element.getAttribute("style");
    stylePairs = [];
    originalStyle
      .trim()
      .replace(/;$/, "")
      .trim()
      .split(";")
      .forEach((pair) => {
        stylePairs.push(pair.split(":").map((s) => s.trim()));
      });
    let scaleFound = false;
    for (let pair of stylePairs) {
      if (pair[0] == "transform" && pair[1].indexOf("scale") !== -1) {
        let currScale = parseFloat(
          pair[1].replace(/^.*scale\(/, "", 1).replace(/^\).*$/, "", 1)
        );
        let newScale = currScale + 0.1;
        newScale;
        pair[1] = pair[1].replace(/(?<=scale\()[\d.]+(?=)/, newScale, 1);
        scaleFound = true;
        break;
      }
    }
    if (!scaleFound) {
      stylePairs.push(["transform", "scale(1.1)"]);
    }
    element.setAttribute(
      "style",
      stylePairs.map((pair) => pair.join(":")).join(";")
    );
  }
}
