import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import LightningAlert from 'lightning/alert';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningModal from 'lightning/modal';
import { NavigationMixin } from 'lightning/navigation';

import getinitOrderList from '@salesforce/apex/PartnerCOrderController.getinitOrderList';
import changeStatus from '@salesforce/apex/PartnerCOrderController.changeStatus';
import getSearchOrderList from '@salesforce/apex/PartnerCOrderController.getSearchOrderList';

const columns = [
    { label: '주문번호', fieldName: 'orderName', type: 'button', initialWidth: 140,
    typeAttributes: {
        variant: 'base',
        label: { fieldName: 'orderName' },
        title: 'Click to OrderDetail',
        name: 'view_details'
    }},
    { label: '상태', fieldName: 'orderStatus',  hideDefaultActions : true , initialWidth: 90},
    { label: '주문일자', fieldName: 'createdDate', type: 'date', hideDefaultActions : true ,initialWidth: 105},
    { label: '고객명', fieldName: 'accountName',  hideDefaultActions : true ,initialWidth: 160},
    { label: '주소', fieldName: 'accountAddress',  hideDefaultActions : true ,initialWidth: 200 },
    { label: '전화번호', fieldName: 'accountPhone', hideDefaultActions : true,initialWidth: 150},
    { label: '최종판매가', fieldName: 'orderfta',  hideDefaultActions : true ,initialWidth: 95 , cellAttributes: { alignment: 'right', wrapText: false }},
    { label: '상품명', fieldName: 'orderPName', hideDefaultActions : true ,initialWidth: 200},
    { label: '수량', fieldName: 'orderQuantity', hideDefaultActions : true ,initialWidth: 60 , cellAttributes: { alignment: 'right', wrapText: false }},
    { label: '운송장번호', fieldName: 'ordertdnumber', hideDefaultActions : true ,initialWidth: 115},
    { label: '택배사', fieldName: 'orderDCompany', hideDefaultActions : true ,initialWidth: 115},
];

export default class PartnerCOrder extends NavigationMixin(LightningElement) {
    @api recordId;
    statuscomboboxvalue = 'all';
    searchvalue = 'OrderName';
    startdatevalue;
    enddatevalue;
    @track datalength;
    buttonLabel;
    showModal = false;
    statusToChange = '';
    @api searchcontentvalue;
    @track data;
    @track updatedata;
    @track newData;
    columns = columns;
    @track selectedIds = [];
    @track selectedOrderRow = [];
    isSpinner = false;

    get statusoptions() {
        return [
            {label: '전체', value: 'all'},
            {label: '할당', value: 'Allocated'},
            {label: '접수', value: 'Assigned'},
            {label: '거절', value: 'Rejected'},
            {label: '배송중', value: 'Fulfilled'},
            {label: '배송 완료', value: 'Delivery Completed'},
            {label: '주문 취소', value: 'Canceled'},
        ];
    }
    get searchoptions() {
        return [
            {label: '주문 번호', value: 'OrderName'},
            {label: '고객', value: 'AccountName'},
            {label: '제품 이름', value: 'ProductName'},
            {label: '운송장 번호', value: 'TransportDocNumber'},
        ];
    }
    get isDataLength (){
        return this.data?.length ? true : false
    }
    get checkRecord() {
        return this.selectedIds.length > 0 ? false : true; 
    }
    connectedCallback() {
        this.isSpinner = !this.isSpinner;
        this.inintsetingdate();
         
    }
    @api inintsetingdate(){
      
        const today = new Date();
        const sevenDays = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
        this.startdatevalue = sevenDays;
        this.enddatevalue = new Date().toISOString().split('T')[0];
        this.statuscomboboxvalue = 'all';
        this.searchvalue = 'OrderName';
        this.searchcontentvalue = '';
        getinitOrderList({})
        .then( result => {
            if(result && result.orderList && result.orderList.length > 0) {
                this.data = result.orderList;
                this.datalength = result.orderList.length;
                console.log(' datas:', JSON.stringify(this.data)); 
            }else{
                this.datalength = '0';
            }
        })
        .catch( error => {
            console.log('error: ', error);
        })
        .finally(() => {
            this.isSpinner = !this.isSpinner;
        })
    }
    handleChange(event) {
        this.statuscomboboxvalue = event.detail.value;
        console.log('statuscomboboxvalue: ', this.statuscomboboxvalue);
    }
    handlesearchChange(event) {
        this.searchvalue = event.detail.value;
        console.log('searchvalue: ', this.searchvalue);
    }
    handlesearchcontentChange(event) {
        this.searchcontentvalue = event.detail.value;
        console.log('searchcontentvalue: ', this.searchcontentvalue);
    }
    selectToday() {
        const today = new Date().toISOString().split('T')[0];
        this.startdatevalue = today;
        this.enddatevalue = today;
        console.log('Selected today:', today);
    }
    selectWeekend() {
        const today = new Date();
        const sevenDays = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
        this.startdatevalue = sevenDays;
        this.enddatevalue = new Date().toISOString().split('T')[0];
    }
    selectMonth() {
        const today = new Date();
        const lastmonth = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
        this.startdatevalue = lastmonth;
        this.enddatevalue = new Date().toISOString().split('T')[0];
    }
    select3Month() {
        const today = new Date();
        const last3month = new Date(today.getFullYear(), today.getMonth() - 2, today.getDate()).toISOString().split('T')[0];
        this.startdatevalue = last3month;
        this.enddatevalue = new Date().toISOString().split('T')[0];
    }
    selectTotal() {
        this.startdatevalue = null;
        this.enddatevalue = null;
    }
    handleStartDateChange(event) {
        let selectedDate = event.target.value;
        if(selectedDate) {
            let startDate = new Date(selectedDate);
            let today = new Date();
            let endDate = this.enddatevalue ? new Date(this.enddatevalue) : null;
            if(today < startDate) {
                this.handleAlertOpen('오늘 이후의 날짜는 선택하실수 없습니다.', 'error', 'Error');
                this.startdatevalue = null;
                this.template.querySelector('lightning-input[data-my-id=startDate]').value = null;
            }else if(endDate && endDate < startDate){
                this.handleAlertOpen('End Date 이후의 날짜는 선택하실수 없습니다.', 'error', 'Error');
                this.startdatevalue = null;
                this.template.querySelector('lightning-input[data-my-id=startDate]').value = null;
            }else {
                this.startdatevalue = selectedDate;
            }
        }else {
            this.startdatevalue = null;
        }
    }
    handleEndDateChange(event) {
        let selectedDate = event.target.value;
        if(selectedDate) {
            let startDate = this.startdatevalue ? new Date(this.startdatevalue) : null;
            let endDate = new Date(selectedDate);
            let today = new Date();
            if(today < endDate) {
                this.handleAlertOpen('오늘 이후의 날짜는 선택하실수 없습니다.', 'error', 'Error');
                this.endDate = null;
                this.template.querySelector('lightning-input[data-my-id=endDate]').value = null;
            }else if(startDate && startDate > endDate){
                this.handleAlertOpen('Start Date 이후의 날짜를 선택해주세요.', 'error', 'Error');
                this.endDate = null;
                this.template.querySelector('lightning-input[data-my-id=endDate]').value = null;
            }else {
                this.endDate = selectedDate;
            }
        }else {
            this.endDate = null;
        }
    }
    
    handleKeyUp(event) {
        const isEnterKey = event.keyCode === 13;
        if (isEnterKey) {
            this.handleSearch();  
            console.log('enter press: ');
        }
    }
    /**
    * 조건 검색버튼
    */
    handleSearch(){
        this.isSpinner = !this.isSpinner;
        console.log('검색: 1', this.startdatevalue);
        console.log('검색: 2', this.enddatevalue);
        console.log('검색: 3', this.statuscomboboxvalue);
        console.log('검색: 4', this.searchvalue);
        console.log('검색: 6', this.searchcontentvalue);
        const StartDate = this.startdatevalue;
        const EndDate = this.enddatevalue;
        const Status = this.statuscomboboxvalue;
        const Filter = this.searchvalue;
        const SearchContents = this.searchcontentvalue;
        this.data = [];

        getSearchOrderList({
            StartDate : StartDate,
            EndDate : EndDate,
            Status : Status,
            Filter : Filter,
            SearchContents : SearchContents,
        })
        .then( result => {
            if(result && result.searchorderList && result.searchorderList.length > 0) {
                this.data = result.searchorderList;
                this.datalength = result.searchorderList.length;
                console.log(' datas:', JSON.stringify(this.data))   
            }else{
                this.datalength = '0';
            }
            
        })
        .catch( error => {
            console.log('error: ', error);
        })
        .finally(() => {
            this.isSpinner = !this.isSpinner;
        })
        
        
    }
    /**
    * Order Detail Page 새탭으로이동
    */
    handleRowAction(event){
        const actionName = event.detail.action.name;
        console.log('actionName:::::::::::', actionName);
        const row = event.detail.row;
        if (actionName === 'view_details') {
            console.log('row:::::::::::', JSON.stringify(row));
            let url = 'https://snicorp--dev.sandbox.my.site.com/sandipartner/s/confirmedorder/' + row.orderId;
            window.open(url, '_blank');
        }
    }
  
    /**
    * 조건창 초기화 시켜주는 함수
    */
    handleReset(){
        const today = new Date();
        const sevenDays = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
        this.startdatevalue = sevenDays;
        this.enddatevalue = new Date().toISOString().split('T')[0];
        this.statuscomboboxvalue = 'all';
        this.searchvalue = 'OrderName'
        this.searchcontentvalue = '';
        //this.template.querySelector('lightning-input[data-my-id=searchid]').value = null;

    }
     /**
     * Data Table 선택된 Row Id 값과 Rowdata 받아오는 함수
     * @param {*} event 
     */
     handleSelectedRow(event) {
       
        this.selectedIds = event.detail.selectedRows.map(row => row.orderId);
        this.selectedOrderRow = event.detail.selectedRows;

    }
    /**
    * 상태변경버튼들
    * @param {*} event
    */
    handleChangeStatus(event) {
        const selectedIds = this.selectedIds;
        this.statusToChange = event.target.dataset.value;
        this.buttonLabel = event.target.label;
        this.showModal = true;
    }
    /**
    * 상태변경 mocal 창 확인
    */
    handleConfirmModal(){
        this.isSpinner = !this.isSpinner;
        const selectedIds = this.selectedIds;
        const statusaction = this.statusToChange;

        changeStatus({
            statusaction : statusaction,
            selectedIds : selectedIds
        })
        .then( result => {
            if(result.updateorderList.length > 0) {
                this.updatedata = result.updateorderList;

                let newData = [...this.data]; 
                this.updatedata.forEach(updateItem => {
                    let index = newData.findIndex(item => item.orderId === updateItem.orderId);
                    if (index !== -1) {
                        newData[index] = { ...newData[index], ...updateItem}; 
                    }
                });
        
                this.data = [...newData];
            }
        })
        .catch( error => {
            console.log('error: ', error);
        })
        .finally(() => {
            this.isSpinner = !this.isSpinner;
        })
        this.showModal = false;
    }
    /**
    * 상태변경 mocal 창 끄기
    */
    handleCloseModal() {
        this.showModal = false;
    }
   
    /**
    * Excel 다운
    */
    async handleExcelExport(){
        try {
            const headerMap = {
                'accountAddress': '주소',
                'accountName': '고객명',
                'orderQuantity': '수량',
                'orderStatus': '주문 상태',
                'ordertdnumber': '운송장 번호',
                'accountPhone': '전화번호',
                'createdDate': '주문일자',
                'orderDCompany': '택배사',
                'orderfta': '최종판매가',
                'orderId': '주문 ID',
                'orderName': '주문 번호',
                'orderPName': '상품명'
               
            };
            
            const header = Object.keys(this.selectedOrderRow[0]).filter(key => key !== 'orderId').map(key => headerMap[key]).join(',') + '\n';
            console.log('header:', header);
            const csv = this.selectedOrderRow.map(row => {
                return Object.entries(row)
                    .filter(([key]) => key !== 'orderId') 
                    .map(([key, value]) => typeof value === 'string' && value.includes(',') ? `"${value}"` : value)
                    .join(',');
            }).join('\n');

            console.log('csv:', csv);
            const csvData = '\uFEFF'+ header + csv; //'\uFEFF' 한글 encoding
           
            const encodedUri = encodeURI(csvData);

            const a = document.createElement('a');
            a.setAttribute('download', 'Order_data.csv');
            a.setAttribute('href', 'data:text/csv;charset=utf-8,' + encodedUri);
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
        } catch (error) {
            this.showToast('Error', error.message, 'error');
        }

    }
    /**
    * 알림창
    */
    async handleAlertOpen(message, variant, title) {
        await LightningAlert.open({
            message: message,
            theme: variant, 
            label: title, 
        });
    }
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}