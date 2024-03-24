var AUTHNICE = function() {
	this.NPjsVersion = "nicepay-start.1.0";
	this.NPappType;
	this.nicePaymentDomain;
	this.merchantReturnUrl = "";
	this.platform = this.uaMatch(navigator.userAgent);
	this.platform_mobile = this.isMobile(navigator.userAgent);
	this.platform.mobile = false;
	this.platform_mobile.mobile = false;
	this.fnError = function(){};
	this.disableScr = "";
	this.documentUntactBody = parent.document.body || parent.document.documentElement;
	this.newPayIframe;
};

AUTHNICE.prototype = {
	 /*
	 *	js\ub97c \ub2e4\uc6b4\ub85c\ub4dc \ub610\ub294 \ubb34\ub2e8 \uc218\uc815\ud558\uc5ec \uc5f0\ub3d9\ud560 \uacbd\uc6b0
	 *  \uc548\uc815\uc801\uc778 \uacb0\uc81c \uc11c\ube44\uc2a4\ub97c \ubcf4\uc7a5\ud560\uc218 \uc5c6\uc2b5\ub2c8\ub2e4.
	 */
	"test" : function(){
		console.log(' test function ')
	},
	"requestPay" : function(param) {
		try{
			if("undefined" == typeof param) {
				return alert("\uacb0\uc81c\uc694\uccad \ud30c\ub77c\ubbf8\ud130\uac00 \ub204\ub77d\ub418\uc5c8\uc2b5\ub2c8\ub2e4.", false);
			}
			if(param.clientId == "" || param.clientId == undefined) {
				return alert("\uac00\ub9f9\uc810 \uc2dd\ubcc4\ucf54\ub4dc(clientId) \uc124\uc815\uc774 \uc798\ubabb\ub418\uc5c8\uc2b5\ub2c8\ub2e4.", false);
			}

			if(param.clientId.substr(0,3) == "R1_"){
				this.NPappType = "APPR";
				this.nicePaymentDomain = "https://pay.nicepay.co.kr";
			}else if(param.clientId.substr(0,3) == "R2_"){
				this.NPappType = "AUTH";
				this.nicePaymentDomain = "https://pay.nicepay.co.kr";
			}else if(param.clientId.substr(0,3) == "S1_"){
				this.NPappType = "APPR";
				this.nicePaymentDomain = "https://sandbox-pay.nicepay.co.kr";
			}else if(param.clientId.substr(0,3) == "S2_"){
				this.NPappType = "AUTH";
				this.nicePaymentDomain = "https://sandbox-pay.nicepay.co.kr";
			}else{
				return alert("\uac00\ub9f9\uc810 \uc2dd\ubcc4\ucf54\ub4dc(clientId) \uc124\uc815\uc774 \uc798\ubabb\ub418\uc5c8\uc2b5\ub2c8\ub2e4.", false);
			}

			if(param.fnError == undefined || typeof param.fnError != "function") {
				return alert("\ud544\uc218 \ud30c\ub77c\ubbf8\ud130 fnError Funtion \ub204\ub77d\ub418\uc5c8\uc2b5\ub2c8\ub2e4.", false);
			}
			this.fnError = param.fnError;
			param.fnError = "";
			this.clientId = param.clientId;
			this.orderId = param.orderId;
			this.amount = param.amount;
			this.goodsName = param.goodsName;
			this.method = param.method;
			console.log( 'param : ', param);
			console.log( 'AUTHNICE : ', this);
			this.newDivLayer = document.querySelector("#newDivLayer") || this.makeLayer();
			this.merchantReturnUrl = param.returnUrl;
			if(this.platform["msedge"]){
				if(param.disableEdgeChk == "false" || param.disableEdgeChk == undefined || param.disableEdgeChk == ''){
					if(this.platform.version < 17){
						var str_comfirm = "Win10 Edge \ud658\uacbd \uacb0\uc81c \uc548\ub0b4 \n\n Win10 Edge \ud658\uacbd\uc5d0\uc11c\ub294 \uacb0\uc81c\uac00 \uc6d0\ud560 \ud558\uc9c0 \uc54a\uc744 \uc218 \uc788\uc2b5\ub2c8\ub2e4. \n\n"
							+ "\uacb0\uc81c\ub97c \uc774\uc6a9\ud558\uc2dc\ub824\uba74 about:flags \ucc3d\uc744 \ub744\uc6b4 \ud6c4 \n"
							+ "\uac1c\ubc1c\uc790 \uc124\uc815 > Microsoft \ud638\ud658\uc131 \ubaa9\ub85d \uc0ac\uc6a9 \ud56d\ubaa9\uc744 \uccb4\ud06c \ud574\uc81c\ub85c \n"
							+ "\uc124\uc815\ud558\uc2dc\uba74 \uacb0\uc81c\ub97c \uc9c4\ud589\ud558\uc2e4 \uc218 \uc788\uc2b5\ub2c8\ub2e4. \n\n"
							+ "\ud574\uc81c\ub97c \uc124\uc815\ud558\ub7ec \uac00\uc2dc\ub824\uba74 '\ud655\uc778'\uc744 \n"
							+ "\uacb0\uc81c\ub97c \uc9c4\ud589\ud558\uc2dc\ub824\uba74 '\ucde8\uc18c'\ub97c \ub20c\ub7ec\uc8fc\uc2dc\uae30 \ubc14\ub78d\ub2c8\ub2e4. \n\n";
						if(confirm(str_comfirm)){
							window.open("about:flags","optionWindow","width=500 , height=750");
							return;
						}
					}
				}
			}
			this.requestPayment(param);
			this.disableScr = param.disableScroll;
			if(param.disableScroll == 'true' || param.disableScroll == undefined || param.disableScroll == ''){
				if(document.body && document.body.scrollTop){
					document.body.style.overflowX = "";
				}else if(document.documentElement){
					document.documentElement.style.overflowX = "";
				}
				this.documentUntactBody.style.overflow = "hidden";
			}else{
				if(document.body && document.body.scrollTop){
					document.body.style.overflowX = "hidden";
				}else if(document.documentElement){
					document.documentElement.style.overflowX = "hidden";
				}
			}
		}catch(e){
			this.fnError({errorMsg : "\uacb0\uc81c \uc2dc\ub3c4\uc911 \uc5d0\ub7ec\uac00 \ubc1c\uc0dd\ud558\uc600\uc2b5\ub2c8\ub2e4." });
			this.requestError("UT01", "[UntactJS] Request Pay Exception : "+e.message, param);
			console.error("UT01", "[UntactJS] Request Pay Exception message : " ,e.message, param);
			console.error("UT01", "[UntactJS] Request Pay Exception param : " ,param);
			return false;
		}
	},

	"makeLayer" : function() {
		console.log('## makeLayer start');
		var newDiv = document.createElement("div");
		newDiv.setAttribute("id", "newDivLayer");
		newDiv.style.position = "fixed";
		newDiv.style.display = "none";
		newDiv.style.top = "0";
		newDiv.style.left ="0";
		newDiv.style.bottom = "0";
		newDiv.style.right = "0";
		newDiv.style.width = "100%";
		newDiv.style.height = "100%";
		newDiv.style.zIndex = "99999";
		
		document.body.appendChild(newDiv);
		console.log('## makeLayer end');
		return newDiv;
	},

	"makeIframe" : function() {
		this.newPayIframe = document.createElement('iframe');
		this.newPayIframe.setAttribute("id", "newPayIframe");
		this.newPayIframe.setAttribute("name", "newPayIframe");
		this.newPayIframe.setAttribute("src", "about:blank");
		this.newPayIframe.setAttribute("frameborder", "0");
		this.newPayIframe.style.position = "absolute";
		this.newPayIframe.style.left = 0;
		this.newPayIframe.style.right = 0;
		this.newPayIframe.style.top = 0;
		this.newPayIframe.style.bottom = 0;
		this.newPayIframe.style.width = "100%";
		this.newPayIframe.style.height = "100%";
		console.log(' makeIframe end');
	},

	"requestPayment" : function(param) {
		console.log('requestPayment ');
		this.newDivLayer.style.display = "block";
		var newPayForm = document.createElement("form");
		newPayForm.acceptCharset = "UTF-8";
		newPayForm.method="post";
		newPayForm.action = this.nicePaymentDomain + "/v1/pay";
		param.NPjsVersion = this.NPjsVersion;
		param.NPappType = this.NPappType;
		param.NPbrowser = this.platform.name +" , " + this.platform.version;
		param.NPos = this.platform.platform;

		if(this.platform.mobile || this.platform_mobile.mobile){
			param.NPsvcType = "02";
		}else {
			param.NPsvcType = "01";
		}
		for(var key in param) {
			var newInput = document.createElement("input")
			newInput.type = "hidden";
			newInput.name = key;
			newInput.value = param[key];
			console.log('key :' , key);
			console.log('value :' , param[key]);
			console.log('newInput : ', newInput);
			newPayForm.appendChild(newInput);
		}
		if(this.platform.mobile || this.platform_mobile.mobile){
			this.newDivLayer.appendChild(newPayForm);
		}else {
			newPayForm.target = "newPayIframe";
			this.makeIframe();
			this.newPayIframe.appendChild(newPayForm);
			this.newDivLayer.appendChild(this.newPayIframe);
		}
		console.log(' newPayForm: ' , JSON.stringify(newPayForm));
		if(window.addEventListener){
			window.addEventListener("message", this.callbackEvent, false);
		}else {
			if(window.attachEvent) {
				window.attachEvent("onmessage", this.callbackEvent);
			}
		}
		console.log(' requestPayment end');
		newPayForm.submit();
	},

	"removeIframe" : function() {
		this.newPayIframe = document.querySelector("#newPayIframe");
		this.newPayIframe && this.newPayIframe.parentNode.removeChild(this.newPayIframe);
		var newDivLayer = document.querySelector("#newDivLayer");
		if(newDivLayer != null){
			newDivLayer.style.display = "none";
		}
	},

	"callbackEvent" : function(e) {
		try{
			if(this.disableScr == 'true' || this.disableScr == undefined || this.disableScr == ''){
				if(document.body && document.body.style.overflow){
					document.body.style.overflowX = "";
				}else if(document.documentElement && document.documentElement.style.overflow){
					document.documentElement.style.overflowX = "";
				}
				this.documentUntactBody.style.overflow = "auto";
			}else{
				if(document.body && document.body.style.overflow){
					document.body.style.overflowX = "auto";
				}else if(document.documentElement && document.documentElement.style.overflow){
					document.documentElement.style.overflowX = "auto";
				}
			}

			var rsp;
			if (e.data !== null && typeof e.data === "string") {
				try {
					rsp = JSON.parse(e.data);
				} catch (parseError) { // 확장 프로그램 처리 오류 발생 시 예외처리
					console.error("Receivedd data is null or not a string:", parseError, e.data);
					this.requestError("UT02", "[UntactJS] Json Parse Exception : " + parseError.message, e.data);
					return false;
				}

				if(rsp && rsp.type === "callback.submit") {
					this.resultMerchant(rsp.result, rsp.charset);
				}else {
					this.fnError(rsp ? rsp.result : { errorMsg : "Invalid Nicepayments Response Format"});
					this.removeIframe();
				}
			}

		}catch(e){
			this.fnError({ errorMsg : "\uacb0\uc81c \uc2dc\ub3c4\uc911 \uc5d0\ub7ec\uac00 \ubc1c\uc0dd\ud558\uc600\uc2b5\ub2c8\ub2e4." });
			this.requestError("UT02", "[UntactJS] Callback Exception : "+e.message, rsp);
			return false;
		}
	},

	"resultMerchant" : function(result, charset) {
		try{
			if(this.platform_mobile.mobile == false){
				document.charset=charset;
			}
		}catch(e){
			this.fnError({ errorMsg : "\uacb0\uc81c \uc2dc\ub3c4\uc911 \uc5d0\ub7ec\uac00 \ubc1c\uc0dd\ud558\uc600\uc2b5\ub2c8\ub2e4." });
			this.requestError("UT02", "[UntactJS] Exception (charsetError) : "+e.message, rsp);
		}
		var newResultForm = document.createElement("form");
		newResultForm.method="post";
		newResultForm.acceptCharset=charset;
		newResultForm.target = "_self";
		newResultForm.action = this.merchantReturnUrl;
		for(var key in result) {
			var formEl = document.createElement("input");
			formEl.type = "hidden";
			formEl.name = key
			if(key == "mallReserved"){
				formEl.value = JSON.stringify(result[key]).replace(/\"/gi,"").replace(/&#034;/g,"\"").replace(/&#039;/g,"\'").replace(/&lt;/g,"<").replace(/&gt;/g,">");
			}else{
				formEl.value = result[key];
			}
			newResultForm.appendChild(formEl);
		}
		document.body.appendChild(newResultForm);
		newResultForm.submit();
	},
	"uaMatch" : function(ua) {

		if (ua === undefined) {
			ua = window.navigator.userAgent;
		}
		ua = ua.toLowerCase();
		var match = /(edge)\/([\w.]+)/.exec(ua)
				|| /(opr)[\/]([\w.]+)/.exec(ua)
				|| /(chrome)[ \/]([\w.]+)/.exec(ua)
				|| /(iemobile)[\/]([\w.]+)/.exec(ua)
				|| /(version)(applewebkit)[ \/]([\w.]+).*(safari)[ \/]([\w.]+)/.exec(ua)
				|| /(webkit)[ \/]([\w.]+).*(version)[ \/]([\w.]+).*(safari)[ \/]([\w.]+)/.exec(ua)
				|| /(webkit)[ \/]([\w.]+)/.exec(ua)
				|| /(opera)(?:.*version|)[ \/]([\w.]+)/.exec(ua)
				|| /(msie) ([\w.]+)/.exec(ua)
				|| ua.indexOf("trident") >= 0 && /(rv)(?::| )([\w.]+)/.exec(ua)
				|| ua.indexOf("compatible") < 0 && /(mozilla)(?:.*? rv:([\w.]+)|)/.exec(ua)
				|| [];
		var platform_match = /(ipad)/.exec(ua) || /(ipod)/.exec(ua)
				|| /(windows phone)/.exec(ua) || /(iphone)/.exec(ua)
				|| /(kindle)/.exec(ua) || /(silk)/.exec(ua)
				|| /(android)/.exec(ua) || /(win)/.exec(ua)
				|| /(mac)/.exec(ua) || /(linux)/.exec(ua)
				|| /(cros)/.exec(ua) || /(playbook)/.exec(ua)
				|| /(bb)/.exec(ua) || /(blackberry)/.exec(ua)
				|| [];
		var browser = {}, matched = {
			browser : match[5] || match[3] || match[1] || "",
			version : match[2] || match[4] || "0",
			versionNumber : match[4] || match[2] || "0",
			platform : platform_match[0] || ""
		};
		if (matched.browser) {
			browser[matched.browser] = true;
			browser.version = matched.version;
			browser.versionNumber = parseInt(matched.versionNumber, 10);
		}
		if (matched.platform) {
			browser[matched.platform] = true;
		}
		if (browser.android || browser.bb || browser.blackberry
				|| browser.ipad || browser.iphone || browser.ipod
				|| browser.kindle || browser.playbook || browser.silk
				|| browser["windows phone"]) {
			browser.mobile = true;
		}
		if (browser.cros || browser.mac || browser.linux || browser.win) {
			browser.desktop = true;
		}
		if (browser.chrome || browser.opr || browser.safari) {
			browser.webkit = true;
		}
		if (browser.rv || browser.iemobile) {
			var ie = "msie";
			matched.browser = ie;
			browser[ie] = true;
		}
		if (browser.edge) {
			delete browser.edge;
			var msedge = "msedge";
			matched.browser = msedge;
			browser[msedge] = true;
		}
		if (browser.safari && browser.blackberry) {
			var blackberry = "blackberry";
			matched.browser = blackberry;
			browser[blackberry] = true;
		}
		if (browser.safari && browser.playbook) {
			var playbook = "playbook";
			matched.browser = playbook;
			browser[playbook] = true;
		}
		if (browser.bb) {
			var bb = "blackberry";
			matched.browser = bb;
			browser[bb] = true;
		}
		if (browser.opr) {
			var opera = "opera";
			matched.browser = opera;
			browser[opera] = true;
		}
		if (browser.safari && browser.android) {
			var android = "android";
			matched.browser = android;
			browser[android] = true;
		}
		if (browser.safari && browser.kindle) {
			var kindle = "kindle";
			matched.browser = kindle;
			browser[kindle] = true;
		}
		if (browser.safari && browser.silk) {
			var silk = "silk";
			matched.browser = silk;
			browser[silk] = true;
		}
		browser.name = matched.browser;
		browser.platform = matched.platform;
		return browser;
	},
	"isMobile" : function(ua){
		var ie= '' ,
	        fireFox= '',
	        opera= '',
	        webkit= '',
	        chrome= '',
	        ieCompatibilityMode= '',
	        osMac= '',
	        osWindows= '',
	        osLinux= '',
	        android= '',
	        ie64= '',
	        iPhone= '',
	        iPad= '',
	        nativeApp= '',
	        mobile= '',
			g = /(?:MSIE.(\d+\.\d+))|(?:(?:Firefox|GranParadiso|Iceweasel).(\d+\.\d+))|(?:Opera(?:.+Version.|.)(\d+\.\d+))|(?:AppleWebKit.(\d+(?:\.\d+)?))|(?:Trident\/\d+\.\d+.*rv:(\d+\.\d+))/.exec(ua),
			h = /(Mac OS X)|(Windows)|(Linux)/.exec(ua);
			iPhone = /\b(iPhone|iP[ao]d)/.exec(ua);
			iPad = /\b(iP[ao]d)/.exec(ua);
			android = /Android/i.exec(ua);
			nativeApp = /FBAN\/\w+;/i.exec(ua);
			mobile = /Mobile/i.exec(ua);
			ie64 = !!/Win64/.exec(ua);
			if (g) {
	           (ie = g[1] ? parseFloat(g[1]) : g[5] ? parseFloat(g[5]) : NaN) && document && document.documentMode && (ie = document.documentMode);
	           var Trident = /(?:Trident\/(\d+.\d+))/.exec(ua);
	           ieCompatibilityMode = Trident ? parseFloat(Trident[1]) + 4 : this.ie;
	           fireFox = g[2] ? parseFloat(g[2]) : NaN;
	           opera = g[3] ? parseFloat(g[3]) : NaN;
	           chrome = (webkit = g[4] ? parseFloat(g[4]) : NaN) ? ((g = /(?:Chrome\/(\d+\.\d+))/.exec(ua)) && g[1] ? parseFloat(g[1]) : NaN) : NaN;
	        } else ie = fireFox = opera = chrome = webkit = NaN;
	        h ? ((this.osMac = h[1] ? ((ua = /(?:Mac OS X (\d+(?:[._]\d+)?))/.exec(ua)) ? parseFloat(ua[1].replace("_", ".")) : !0) : !1), (osWindows = !!h[2]), (osLinux = !!h[3])) : (osMac = osWindows = osLinux = !1);
        return {
        	"iPhone" : iPhone == undefined ? false : true,
        	"iPad" : iPad == undefined ? false : true,
        	"android" : android == undefined ? false : true,
        	"mobile" : mobile == undefined ? false : true,
        }
	},
	"requestError" : function(errorCd, errorMsg, obj){
		var errorIframe = document.createElement('iframe');
		errorIframe.id = "error_frame";
		errorIframe.name = "error_frame";
		errorIframe.width = "0px";
		errorIframe.height = "0px";
		document.body.appendChild(errorIframe);
		var newForm = document.createElement('form');
		newForm.id = "error_report";
		newForm.name = "error_report";
		newForm.method = "post";
		newForm.target = "error_frame";
		newForm.action = this.nicePaymentDomain + "/v1/errorReport/logging";
		errorIframe.appendChild(newForm)
		var NPsvcType = "01"
		if (this.platform_mobile.mobile == true){
			NPsvcType = "02"
		}
		var errorObj = {
			"svcType" : NPsvcType,
			"clientId" : this.clientId,
			"errLevel" : 'INFO',
			"errCd" : errorCd,
			"errMsg" : errorMsg,
			"isJs" : true,
			"clientNm" : this.NPjsVersion,
			"moid" : this.orderId,
			"amt" : this.amount,
			"goodsName" : this.goodsName,
			"method" : this.method,
			"errData" : JSON.stringify(obj) // e.data tracking
		};
		if(errorCd == "UT02"){
			errorObj.tid = obj ==  undefined  ? null : obj.tid;
			errorObj.transKey = obj ==  undefined  ? null : obj.authToken;
		}
		for(var key in errorObj){
			var newInput = document.createElement('input');
			newInput.name = key;
			newInput.id = key;
			newInput.value = errorObj[key];
			newInput.type = "hidden";
			newForm.appendChild(newInput);
		}
		newForm.submit();
		var _this = this;
		setTimeout(function() {
			_this.removeIframe()
			errorIframe.parentNode.removeChild(errorIframe);
		}, 1000);
	},
}

window.AUTHNICE = new AUTHNICE();