import {once} from "../utils/common";

/**
 * Makes elements like flash disappear after a certain amount of time.
 * 
 * <div data-disappear-after="5000">This will disappear after 5 seconds</div>
 */

export default function (container, selector) {
    container.querySelectorAll(selector).forEach(function (match) {
        once(match, 'disappear', init);
    });
}

function init(el) {    
    let timeout =  parseInt(el.dataset.disappearAfter);
    if (timeout > 0) {
        setTimeout(() => {el.style = "transition: opacity 1s ease-out; opacity: 0.0";}, timeout);
        setTimeout(() => {el.remove()}, timeout + 1000);
    }
}


