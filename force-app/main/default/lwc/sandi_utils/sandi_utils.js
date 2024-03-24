import { LightningElement } from 'lwc';

(function(){
    // 즉시실행함수

    // 샌드박스 or 운영 여부 확인 후 운영일 경우 console 안보임
    const hostname = location.hostname;
    const regex = /sandbox/g;
    const isSandbox = hostname.match(regex);
    if(!isSandbox){
        let console = (window.console = window.console || {});
        [   "assert", "clear", "count", "debug", "dir", "dirxml",
            "error", "exception", "group", "groupCollapsed", "groupEnd",
            "info", "log", "markTimeline", "profile", "profileEnd", "table",
            "time", "timeEnd", "timeStamp", "trace", "warn"
        ].forEach(method => {
            console[method] = () => {};
        });
    }

})();

// customStyle
export function setCustomStyle(style, id) {
    let styleElement = document.createElement("style");
    styleElement.setAttribute("id", id);
    styleElement.innerText = style;
    document.body.appendChild(styleElement);
}

// customStyle remove
export function removeCustomStyle(id) {
    const target = document.querySelector("style#" + id);
    if(target) target.remove();
}

export function pad(n) { // 한자리 숫자 일때 앞에 0 붙이는 기능
    n = n + '';
    return n.length >= 2 ? n : new Array(2 - n.length + 1).join('0') + n;
}