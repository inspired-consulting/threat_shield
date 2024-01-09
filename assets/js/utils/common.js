export function once(el, label, fn) {
  const attr = "data-" + label + "-initialized";
  if (!el.hasAttribute(attr)) {
    el.setAttribute(attr, "true");
    fn(el);
  }
}

export function queryOne(selector) {
  if (!selector) {
    return null;
  }
  let elementById = document.getElementById(selector);
  if (elementById) {
    return elementById;
  } else {
    return document.querySelector(selector);
  }
}

export function queryAll(selector) {
  if (selector && selector.querySelectorAll) {
    document.querySelectorAll(selector);
  } else {
    return [];
  }
}

export function queryEach(selectors) {
  if (selectors && selectors.split) {
    return selectors
      .split(",")
      .map((s) => queryOne(s.trim()))
      .filter((el) => el);
  } else {
    console.log("Invalid selectors:", selectors);
    return [];
  }
}

export function setValue(field, value) {
  if (field) {
    field.value = value;
  }
}

export function markValid(el) {
  el.classList.remove("input-invalid");
  el.classList.add("input-valid");
}

export function markInvalid(el) {
  el.classList.remove("input-valid");
  el.classList.add("input-invalid");
}

export function markNeutral(el) {
  el.classList.remove("input-valid", "input-invalid");
}
