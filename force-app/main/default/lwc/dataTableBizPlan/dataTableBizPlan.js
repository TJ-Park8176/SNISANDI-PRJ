/**
 * Created by MZC01-DGCHOI on 2023-09-21.
 */

import { LightningElement, wire } from 'lwc';
import JqueryResource from '@salesforce/resourceUrl/jQuery360';
import dataTableCSS from '@salesforce/resourceUrl/DataTableCSS';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getAmountInfo from '@salesforce/apex/DataTableBizPlanController.getAmountInfo';
import getSumAmount from '@salesforce/apex/DataTableBizPlanController.getSumAmount';
import getWBSList from '@salesforce/apex/DataTableBizPlanController.getWBSList';
import getCSS from '@salesforce/apex/DataTableBizPlanController.getCSS';


let TOTAL_TD_MONTHS = 13; //13; //13*N : 현장=78(N=6), 운영=39(N=3)

export default class DataTableBizPlan extends LightningElement {

    amountInfo = [];
    error;

    loading = false;
    wbsId;
    wbsOrCc = 'WBS/CC';
    YorP;

    upperMap;
    middleMap;
    lowerMap;
    wbsList;

    searchInputDisabled = false; //검색박스 토글 : 초기값-활성화
    //loadToggle = true;

    //WBS search
    searchResults;
    selectedSearchResult;

    get selectedValue() {
        return this.selectedSearchResult ? this.selectedSearchResult.label : null;
    }

    search(event) {
        const input = event.detail.value.toLowerCase();
        const result = this.wbsList.filter((picklistOption) =>
          picklistOption.label.toLowerCase().includes(input)
        );
        this.searchResults = result;
    }

    selectSearchResult(event) {
        const selectedValue = event.currentTarget.dataset.value;
        this.selectedSearchResult = this.wbsList.find(
          (picklistOption) => picklistOption.value === selectedValue
        );
        this.clearSearchResults();

        this.locTypeDisabled = false; //현장/운영 구분 토글 활성화
        this.wbsId = selectedValue;
        this.fetchAmountInfo();
    }

    clearSearchResults() {
        this.searchResults = null;
    }

    showPicklistOptions() {
        if(!this.searchResults) {
          this.searchResults = this.wbsList;
        }
    }



    @wire(getCSS) cssStr;

    @wire(getWBSList)
    async wiredWBSList({data, error}) {
        if(data) {
            console.log(data);
            console.log(data.length);
            this.wbsList = data;

            if(this.wbsList.length == 0) {
                this.showToastMessage('조회할 WBS/CC가 없습니다.', '', 'info', 'dismissable');
                this.searchInputDisabled = true;
            }
        }
    }

    get wbsOptions() {
        console.log('get wbsOption() -->');
        console.log(this.wbsList);
        return this.wbsList;
    }

    async handleChangeWbs(event) {
        console.log('handleChangeWbs() -->')

        this.locTypeDisabled = false; //현장/운영 구분 토글 활성화

        this.wbsId = event.detail.value;

        this.fetchAmountInfo();
    }

    async connectedCallback() {
        //await this.fetchAmountInfoInit();

        Promise.all([
            loadScript(this, JqueryResource),
            loadStyle(this, dataTableCSS)
        ]).then(()=> {
            console.log('script loaded sucessfully');
        }).catch((error)=>{
            console.log("connectedCallback Promise Error");
            console.log(error);
            this.error = error;
            this.showToastMessage('ERROR', JSON.stringify(error), 'error', 'dismissable');
        }).finally(() => {
            this.onLoad();
        });  //connectedCallback END
    }

    onLoad() {
        this.loading = true;
    }


    setTableHeader() {
        console.log('---setTableHeader---');

        const titleColumInfos = [];
        for(let i=1; i<=12; i++) {
            let tmp = { Label: i+'월', APIKey: i};
            titleColumInfos.push(tmp);
        }

        let numColumInfos = [
            { Label: '사업 계획', APIKey: ''}
        ];

        const columnInfos = [
            { Label: '상위 구분', APIKey: 'UpperSort__c'},
            { Label: '중위 구분', APIKey: 'MiddleSort__c'},
            { Label: '하위 구분', APIKey: 'LowerSort__c'},
            { Label: '계정 코드', APIKey: 'AccountSubjectCode__c'},
            { Label: '계정 과목', APIKey: 'Name'},
        ];

        let thead = this.template.querySelector('table thead');

        $(thead).empty().append(
            `<tr class="titleCol">
                <th>WBS/CC</th>
                <th colspan="5" style="min-width:500px;">계정 과목 구분</th>
                <th style="min-width:165px;">연간 합계</th>
             </tr>`
         );

        const titleCol = this.template.querySelector('.titleCol');

        titleColumInfos.forEach(col => {
            $(titleCol).append(`<th>${col.Label}</th>`);
        });

        let tableHeaders = `<tr class="subTitleCol">
                                <th>${this.wbsOrCc}</th>`;

        columnInfos.forEach(col => {
            tableHeaders += `<th>
                                ${col.Label}
                            </th>`;
                            //<span class="sortToggle asc" data-filter="${col.APIKey}"></span>
        });
        tableHeaders += '</tr>';
        $(thead).append(tableHeaders);

        const subTitleCol = this.template.querySelector('.subTitleCol');

//23.05.30 dgchoi 연간합계 열 수정
        $(subTitleCol).append(
            `<th class="numColum">사업 계획</th>`
        );

//23.05.30 dgchoi 연간합계 열 수정
        for(let i=0; i<12; i++) {
            numColumInfos.forEach((col,index) => {
                $(subTitleCol).append(
                    `<th class="numColum">
                        ${col.Label}
                    </th>`
                );
            });
        }

    } //setTableHeader END

    setTableBody() {
        console.log('setTableBody() start---');
        const tbody = this.template.querySelector('.mTable tbody');

        let body = '';
        let self = this;

console.log('amountInfo forEach START------');
        this.amountInfo.forEach(rec => {
            body += `<tr class="mTableTr targetTr"
                            data-upper="${rec.AccountSubject.Upper}"
                            data-middle="${rec.AccountSubject.Middle}"
                            data-lower="${rec.AccountSubject.Lower}">
                        <td class="upper"> ${rec.AccountSubject.Upper != undefined ? rec.AccountSubject.Upper : ''} </td>
                        <td class="middle"> ${rec.AccountSubject.Middle != undefined ? rec.AccountSubject.Middle : ''} </td>
                        <td class="lower"> ${rec.AccountSubject.Lower != undefined ? rec.AccountSubject.Lower : ''} </td>
                        <td class="asCode"> ${rec.AccountSubject.AccountSubjectCode != undefined ? rec.AccountSubject.AccountSubjectCode : ''} </td>
                        <td class="asName"> <a href="/lightning/r/AccountSubject__c/${rec.AccountSubject.Id}/view"> ${rec.AccountSubject.AccountSubjectName} </a> </td>`;

            let pList = rec.Performance;

            pList.forEach(p => {
                body += `<td class="amt" data-month="${p.CalMonth}">${p.PlanAmt}</td>`;
            });

            body += `</tr>`;
        });
console.log('------------amountInfo forEach END');

        tbody.innerHTML = body;

console.log('----------------TableBody Append END');

        let upperTd  = this.template.querySelectorAll('.upper');
        let middleTd = this.template.querySelectorAll('.middle');
        let lowerTd  = this.template.querySelectorAll('.lower');

console.log('upperTd forEach START----------------->');
        let target = '';
        upperTd.forEach(e => { //Upper합 껍데기줄 생성
            let thisContext = e.textContent;

            if(target != thisContext) {
                target = thisContext;

                let trBody = '';
                for(let i=0; i<TOTAL_TD_MONTHS; i++) {
                    trBody += '<td class="upper totalTd sumUpper amt" style="background-color:#8A98AD"></td>';
                }

                let tr = `<tr class="totalUpper mTableTr totalTr" data-upper="${thisContext}">
                            <td class="upper totalTd foldUpper" colspan="5" style="background-color:#8A98AD">
                                ${thisContext}
                                <span class="folder unfold"></span>
                            </td>
                            ${trBody}
                          </tr>`;

                $(e).parent().before(tr);
            } //else {
               // e.style.visibility = 'hidden';
               //}
        });
console.log('---------------->upperTd forEach END');


console.log('---------------->middleTd forEach START');
        target = '';
        middleTd.forEach(e => { //Middle합 껍데기줄 생성
            let thisContext = e.textContent;
            let eUpper = $(e).parent().attr('data-upper');
            let eMiddle = $(e).parent().attr('data-middle');

            if(target != thisContext && thisContext != '') {
                target = thisContext;

                let trBody = '';
                for(let i=0; i<TOTAL_TD_MONTHS; i++) {
                    trBody += '<td class="middle totalTd sumMiddle amt" style="background-color:#ADB5C2"></td>';
                }

                let tr = `<tr class="totalMiddle mTableTr totalTr" data-upper="${eUpper}" data-middle="${eMiddle}">
                            <td class="upper"></td>
                            <td class="middle totalTd foldMiddle" colspan="4" style="background-color:#ADB5C2"> ${thisContext} </td>
                            ${trBody}
                          </tr>`;

                $(e).parent().before(tr);
            }
        });
console.log('---------------->middleTd forEach END');

console.log('---------------->lowerTd forEach START');
        target = '';
        lowerTd.forEach(e => { //Lower합 껍데기줄 생성
            let thisContext = e.textContent;
            let eUpper = $(e).parent().attr('data-upper');
            let eMiddle = $(e).parent().attr('data-middle');
            let eLower = $(e).parent().attr('data-lower');

            if(target != thisContext && thisContext != '') {
                target = thisContext;

                let trBody = '';
                for(let i=0; i<TOTAL_TD_MONTHS; i++) {
                    trBody += '<td class="lower totalTd sumLower amt" style="background-color:#C6CAD0"></td>';
                }

                let tr = `<tr class="totalLower mTableTr totalTr" data-upper="${eUpper}" data-middle="${eMiddle}" data-lower="${eLower}">
                            <td class="upper"></td>
                            <td class="middle"></td>
                            <td class="lower totalTd foldLower" colspan="3" style="background-color:#C6CAD0"> ${thisContext} </td>
                            ${trBody}
                          </tr>`;

                $(e).parent().before(tr);
            }
        });
console.log('---------------->lowerTd forEach END');

        let firstTr = $(this.template.querySelector('table tbody tr:first-child'));
        let trSize = $(this.template.querySelectorAll('table tbody tr')).length + 1;
        firstTr.prepend(`<td class="wbs" rowspan="${trSize}"> ${this.amountInfo[0].WBS.Name} </td>`)

        //this.checkLocTypeDisplay();

console.log('---------------->setTableBody END');
    } //setTableBody END

    setTotalData() { //apex에서 합 가져와서 뿌려줘.......
        console.log('--setTotalData()--');

        let totalUpper  = this.template.querySelectorAll('.totalUpper');
        let totalMiddle = this.template.querySelectorAll('.totalMiddle');
        let totalLower  = this.template.querySelectorAll('.totalLower');

console.log('totalUpper START-------');
        totalUpper.forEach((e) => {
            let upperValue  = $(e).attr('data-upper'); //upper
            let amountList = this.upperMap[upperValue];

            let targetUpper = $(e).children('.sumUpper');

            for(let i=0; i<targetUpper.length; i++) {
                targetUpper[i].innerHTML = amountList[i];
            }
        });
console.log('totalUpper 크기: ' + totalUpper.length);

console.log('totalMiddle START-------');
        totalMiddle.forEach((e) => {
            //let upperValue  = $(e).attr('data-upper'); //upper
            let middleValue = $(e).attr('data-middle');
            let amountList = this.middleMap[middleValue];

            let targetMiddle = $(e).children('.sumMiddle');

            for(let i=0; i<targetMiddle.length; i++) {
                targetMiddle[i].innerHTML = amountList[i];
            }

        });
console.log('totalMiddle 크기: ' + totalMiddle.length);

console.log('totalLower START-------');
        totalLower.forEach((e) => {
            //let upperValue  = $(e).attr('data-upper'); //upper
            //let middleValue = $(e).attr('data-middle');
            let lowerValue  = $(e).attr('data-lower');
            let amountList = this.lowerMap[lowerValue];

            let targetLower = $(e).children('.sumLower');

            for(let i=0; i<targetLower.length; i++) {
                targetLower[i].innerHTML = amountList[i];
            }
        });
        console.log('totalLower 크기: ' + totalLower.length);

        //매출총이익 upper 생성
        console.log('wbsOrCc: ' + this.wbsOrCc);
        console.log('yorP: ' + this.YorP);

        if(this.wbsOrCc == 'WBS') {
            let INIT_TARGET_NUM = 4;
            let INIT_UPPER1_NUM = 2;
            let newHtml = `<tr class="mTableTr totalTr totalUpper" data-upper="">
                             <td class="upper totalTd" colspan="5" style="background-color:#8A98AD"> 매출총이익 </td>`;

            for(let i=0; i<TOTAL_TD_MONTHS; i++) {
                let tdNum = INIT_UPPER1_NUM + i;
                let targetTdNum = INIT_TARGET_NUM + i;
                let upper1 = $(this.template.querySelector(`.totalUpper[data-upper="매출액"] td:nth-child(${tdNum+1})`)).html();
                let upper2 = $(this.template.querySelector(`.totalUpper[data-upper="총매출원가"] td:nth-child(${tdNum})`)).html();

                let subUpperValue = parseFloat(upper1.replaceAll(',', '')) - parseFloat(upper2.replaceAll(',',''));

                subUpperValue = subUpperValue.toLocaleString();

                newHtml += `<td class="upper totalTd amt" style="background-color:#8A98AD"> ${subUpperValue} </td>`;
            }

            newHtml += `</tr>`;
            $(this.template.querySelector('table tbody')).append(newHtml);
        }


        //event
        const self = this;
        $(this.template.querySelectorAll('.foldUpper')).on('click', function() {
             console.log('totalUpper Click---');

             let upperId = $(this).parent().attr('data-upper').replaceAll('(', "\\(").replaceAll(')', "\\)");
             let ele = $(this).find('.folder');

             console.log('upperId: ' + upperId);
             console.log(ele);

             if(ele.hasClass('fold')) {
                 ele.removeClass('fold');
                 ele.addClass('unfold');
                 $(self.template.querySelectorAll('.mTableTr[data-upper="'+ upperId +'"]:not(.totalUpper)')).removeClass('disabled');

             } else if(ele.hasClass('unfold')) {
                 ele.removeClass('unfold');
                 ele.addClass('fold');
                 $(self.template.querySelectorAll('.mTableTr[data-upper="'+ upperId +'"]:not(.totalUpper)')).addClass('disabled');
             }

        });
    } //setTotalData END


/*
    async fetchAmountInfoInit() {
        this.loading = false;
        await getAmountInfo()
        .then(data => {
            console.log("fetchAmountInfo() start--");
            console.log(JSON.parse(data));
            if (data) {
                this.amountInfo = JSON.parse(data);
                this.wbsOrCc = this.amountInfo[0].WBS.WBSorCC;
                this.YorP    = this.amountInfo[0].WBS.YorP;
            }
        }).catch(error => {
            console.log(error);
            this.error = error;
            this.amountInfo = undefined;
            this.error = 'Unknown error';
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error In fetchAmountInfo-Init()',
                    message: error,
                    variant: 'error',
                }),
            );
        })
    }
*/

    async fetchAmountInfo() {
        console.log('fetchAmountInfo() start--');
        this.loading = false;

        await getAmountInfo({
            wbsId   : this.wbsId
        }).then(data => {
            console.log("fetchAmountInfo(" + this.wbsId + ") return Success");
            console.log(JSON.parse(data));
            if(data.length > 0) {
                this.amountInfo = JSON.parse(data);
                this.wbsOrCc = this.amountInfo[0].WBS.WBSorCC;
                this.YorP    = this.amountInfo[0].WBS.YorP;
                this.setTableHeader();
                this.setTableBody();
            }
        }).then(() => {
            this.fetchSumAmount();
        }).catch(error => {
            console.log(error);
            this.error = error;
            this.amountInfo = undefined;
            this.error = 'Unknown error';
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
            this.showToastMessage('Error', 'error in fetchAmountInfo()', 'error', 'dismissable');
        });
    }

    async fetchSumAmount() {
        console.log('fetchSumAmount() start--');

        this.loading = false;

        await getSumAmount({
            wbsId : this.wbsId
        }).then(data => {
            console.log("fetchAmountInfo(" + this.wbsId + ") return Success");
            console.log(data);
            this.upperMap = data.Upper;
            this.middleMap = data.Middle;
            this.lowerMap = data.Lower;
        }).then(() => {
            this.setTotalData();
            //this.template.querySelector('.scrollBox').style.visibility = 'visible';
        }).catch(error => {
            console.log(error);
        }).finally(() => {
            this.onLoad();
        });
    }

    tableToCSV() {
        console.log('---tableToCSV---');
        let csv_data = [];
        let rows = this.template.querySelectorAll('tr');
        rows.forEach((e, i) => {
            let cols = $(e).find('td, th');

            let csvrow = [];
            for(let j=0; j<cols.length; j++) {
                csvrow.push(cols[j].html());
            }

            csv_data.push(csvrow.join(","));
        });
        csv_data = csv_data.join('\n');

        return csv_data;
    }

    downloadCSVFile() {
        console.log('---downloadCSVFile---');

        let tableHead = `<head><style> ${this.cssStr.data} </style></head>`;
        let tableHtml = '<body>' + this.template.querySelector('table').outerHTML + '</body>';
        let content = '<html>' + tableHead + tableHtml + '</html>';

        console.log('--------tableCss----------');
        console.log(content);

        let element = 'data:application/vnd.ms-excel,' + encodeURIComponent(content);
        let downloadElement = document.createElement('a');
        downloadElement.href = element;
        downloadElement.target = '_self';
        // use .csv as extension on below line if you want to export data as csv
        downloadElement.download = '사업계획 손익계산서.xls';
        document.body.appendChild(downloadElement);
        downloadElement.click();
    }

    //현장/운영 disable True/False
    /*
    checkLocTypeDisplay() {

        if(this.wbsOrCc == 'CC') {
            this.loadToggle = false; // 현장/운영 클릭해도 로드해오지않게......

            let radio_site = this.template.querySelector('input[name="locType"][value="현장"]'); //현장 라디오 버튼
            radio_site.click();
            this.loadToggle = true;
        }

        let radio_ops = this.template.querySelectorAll('input[name="locType"][value="운영"]');

        if(this.wbsOrCc == 'CC') {
            $(radio_ops).attr('disabled', true);
        } else {
            $(radio_ops).attr('disabled', false);
        }
    }
    */

    handleSearchWbs(event) {
        const searchTerm = event.detail.value.toLowerCase();
        const filteredOptions = options.filter(option => option.label.toLowerCase().includes(searchTerm));
        this.template.querySelector('lightning-combobox').setOptions(filteredOptions);
    }

    showToastMessage(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }


}