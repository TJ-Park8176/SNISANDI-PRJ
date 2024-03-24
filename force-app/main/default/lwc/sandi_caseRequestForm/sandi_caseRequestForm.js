import { api, track  } from 'lwc';
import LightningModal from 'lightning/modal';
import userId from "@salesforce/user/Id";
import getContactInfo from '@salesforce/apex/Sandi_OpptyRequestController.getContactInfo';

export default class Sandi_caseRequestForm extends LightningModal {
    @track options = [{label : '구분1', value : '구분1'}, {label : '구분2', value : '구분2'}];
    @api myRecordId;
    @track loginInfo;
    @track isReadonly;
    @track uploadFiles = [];

    get encryptedToken() {
        //use apex to get
    }

    get acceptedFormats() {
        return ['.pdf', '.png'];
    }

    connectedCallback(){
        if(userId) this.callContactInfo();
    }

    callContactInfo(){
        console.log("userId", userId);
        getContactInfo({
            userId :  userId
        })
        .then(result => {
            console.log("getContactInfo => ", result);
            if(!result?.isGuest) {
                this.loginInfo = result; 
                this.isReadonly = true;
                this.setAutoInfo();
            }
        })
        .catch(error => {
            console.log('getContactInfo error msg : ', error);
        })
    }

    setAutoInfo(){
        const lastName = this.refs.lastName;
        const firstName = this.refs.firstName;
        const email = this.refs.email;
        const phone = this.refs.phone;

        lastName.value = this.loginInfo?.LastName;
        firstName.value = this.loginInfo?.FirstName;
        email.value = this.loginInfo?.Email;
        phone.value = this.loginInfo?.Phone;
    }


    validateContent(){
        return new Promise((resolve, reject)=>{
            const allValid = [
                ...this.template.querySelectorAll('.validate-target'),
            ].reduce((validSoFar, inputCmp) => {
                if(!inputCmp.value){
                    inputCmp.setCustomValidity('error');
                } else if(inputCmp.type === 'email' && inputCmp.value && !(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(inputCmp.value))){
                    inputCmp.setCustomValidity('error');
                } else if(inputCmp.type === 'tel' && inputCmp.value && !(/\+[0-9]/i.test(inputCmp.value))){
                    inputCmp.setCustomValidity('error');
                } else{
                    inputCmp.setCustomValidity('');
                }

                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity() && inputCmp.value;
            }, true);

            resolve(allValid);
        })
    }

    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        alert('No. of files uploaded : ' + uploadedFiles.length);
    }

    
    changeFiles(event){
        /**
         * 1024 = 1KB
            1024 * 1024 = 1MB
            1024 * 1024 * 1024 = 1GB
            1024 * 1024 * 1024 * 1024 = 1TB
         */
        let files = [...event.target.files];
        let sizeCheck = false;
        for (let i = 0; i < files.length; i++) {
            if (files[i].size > (1024 * 1024 * 25)) { // 25MB 용량제한
                sizeCheck = true
            }
        }

        if(sizeCheck) {
            alert("파일사이즈 크다");
            return false;
        }

        //let imageTypes = ["jpg", "png", "jpeg", "bmp", "gif", "svg"];
        for (let i = 0; i < files.length; i++) {
            const reader = new FileReader;
            reader.readAsDataURL(files[i]);
            reader.onloadend = function() {
                console.log("files", files[i]);
            }
        }

        this.uploadFiles = files;
    }

    deleteFileItem(event){
        const target  = event.currentTarget;
        const targetIndex = target.dataset.index;
        const result = this.uploadFiles.filter((item, index)=>{
            return index != Number(targetIndex)
        })

        this.uploadFiles = result;
    }

    async requestCase(){
        const result = await this.validateContent();

        if(!result) return false;

        let requestObj = new Object;
        const lastName = this.refs.lastName;
        const firstName = this.refs.firstName;
        const email = this.refs.email;
        const phone = this.refs.phone;
        const detail = this.refs.detail;
        const type = this.refs.type;
        const title = this.refs.title;
        const file = this.refs.file;

        requestObj.lastName = lastName?.value || '';
        requestObj.firstName = firstName?.value || '';
        requestObj.email = email?.value || '';
        requestObj.phone = phone?.value || '';
        requestObj.detail = detail?.value || '';
        requestObj.type = type?.value || '';
        requestObj.title = title?.value || '';
        requestObj.file = file?.value || '';
        
        console.log("고객문의 보내는 값 : ", requestObj);

        this.close();
    }
}