import { LightningElement, track, wire } from 'lwc';
/* Apex Class */
import getDownloadLink from '@salesforce/apex/Sandi_ExportRecords.ExportCSV';

export default class Sandi_ConfirmedOrderForPartner extends LightningElement {

    @track conatctData = {}

    columnHeader = ['ID', 'Name', 'CreatedDate', 'LastmodifiedDate' ]

    @wire(getDownloadLink)
    async wiredData({ error, data }) {
        if (data) {
            console.log('Data', data);
            this.conatctData = data;
        } else if (error) {
            console.error('Error:', error);
        }
    }

    exportToXLSX(){
        // this.wirdedData();

        // Prepare a html table
        let doc = '<table>';
        // Add styles for the table
        // doc += '<style>';
        // doc += 'table, th, td {';
        // doc += '    border: 1px solid black;';
        // doc += '    border-collapse: collapse;';
        // doc += '}';          
        // doc += '</style>';
        // Add all the Table Headers
        doc += '<tr>';
        this.columnHeader.forEach(element => {            
            doc += '<th>'+ element +'</th>'           
        });
        doc += '</tr>';
        // Add the data rows
        this.conatctData.forEach(record => {
            doc += '<tr>';
            doc += '<th>'+record.Id+'</th>'; 
            doc += '<th>'+record.Name+'</th>'; 
            doc += '<th>'+record.CreatedDate+'</th>';
            doc += '<th>'+record.LastModifiedDate+'</th>'; 
            doc += '<th>운송장 번호</th>'; 
            doc += '</tr>';
        });
        doc += '</table>';
        var element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
        let downloadElement = document.createElement('a');
        downloadElement.href = element;
        downloadElement.target = '_self';
        // use .csv as extension on below line if you want to export data as csv
        downloadElement.download = 'Account Data.xls';
        document.body.appendChild(downloadElement);
        downloadElement.click();
    }
}