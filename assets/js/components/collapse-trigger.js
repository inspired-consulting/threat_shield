import {once, queryOne} from "../utils/common";

/**
 * Let an alement collapse or expand based another element.
 * 
 * <a class="collpase-trigger" data-target="some-menu">Collapse/Expand</a>
 */

export default function (container, selector) {
    container.querySelectorAll(selector).forEach(function (match) {
        once(match, 'collapse-trigger', init);
    });
}

function init(el) {    
    let target = queryOne(el.dataset.target);
    if (target) {        
        el.addEventListener("click", function () {
            let opened = !target.classList.toggle("hidden");
            if (opened) {
                console.log("Opened: ", target);
                addCloseListener(target);
            }
        });
    } else {
        console.log("Target for collapse trigger not found:", el.dataset.target);
    }
}

function addCloseListener(target) {
    // Use set timeout to register listener after the click event has been processed.
    setTimeout(function () {        
        window.addEventListener("click", function cl (e) {
            if (!target.contains(e.target)) {
                console.log("Clicked outside. Closing: ", target);
                target.classList.add("hidden");
                window.removeEventListener("click", cl);
            }
        });
    }, 0);
   
}


