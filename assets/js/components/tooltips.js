import { createPopper } from "@popperjs/core";
import { once } from "../utils/common";

/**
 * Converts title-Attributes to popovers.
 *
 * <a title="Edit item"><img src="some_icon.png"/></div>
 */

export default function (container, selector) {
  container.querySelectorAll(selector).forEach(function (match) {
    once(match, "tooltip", init);
  });
}

function init(el) {
  let title = el.getAttribute("title");
  el.removeAttribute("title");

  let tooltip = document.createElement("div");
  tooltip.classList.add("tooltip");
  tooltip.style.visibility = "hidden";
  tooltip.innerHTML = title;
  el.appendChild(tooltip);
  createPopper(el, tooltip, {
    placement: "top",
    modifiers: [
      {
        name: "offset",
        options: {
          offset: [0, 20],
        },
      },
    ],
  });

  el.addEventListener("mouseenter", function () {
    tooltip.style.visibility = "visible";
  });
  el.addEventListener("mouseleave", function () {
    tooltip.style.visibility = "hidden";
  });
}
