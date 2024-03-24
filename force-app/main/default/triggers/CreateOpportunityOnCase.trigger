//Created By PTJ 2024.01.29
// Apex Trigger on Case Object
//로직 추가 필요 : 변경되는 Case의 ID를 가져와서 해당 ID에 할당된 기회가 있으면 기회를 생성 하지 않고 없으면 생성함. (해당 로직 추가) 
trigger CreateOpportunityOnCase on Case (after update) {
     // List to store newly created Opportunities
     List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
    
     // Iterate through updated Cases
     for (Case updatedCase : Trigger.new) {
         // Case 상태가 종료 이고 Type이 견적 일때 처리됨.
         if (updatedCase.Status == 'Closed' && updatedCase.type == '견적문의') {
             // Create a new Opportunity(기회 필수 필드: 수주명, 고객사이름, 마감일자, 단계)
             Opportunity newOpportunity = new Opportunity(
                 RecordTypeId = '0121y000003WkLcAAK',
                 Name = '견적문의 관련 영업기회: ' + updatedCase.CaseNumber,
                 AccountId = updatedCase.AccountId,
                 StageName = '잠재고객', // Set the appropriate stage
                 CloseDate = System.today() + 15 // Set the close date as needed
                 // Set other required Opportunity fields accordingly
             );             
             // Add the Opportunity to the list
             opportunitiesToInsert.add(newOpportunity);
         }                 

     }
     //System.debug('Test!!' + '/' + updatedCase.Status + '/' + updatedCase.type);     
     // Insert the newly created Opportunities
     insert opportunitiesToInsert;     

}