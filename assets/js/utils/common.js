export function once(el, label, fn) {
  const attr = "data-" + label + "-initialized";
  if (!el.hasAttribute(attr)) {
    el.setAttribute(attr, "true");
    fn(el);
  }
}
