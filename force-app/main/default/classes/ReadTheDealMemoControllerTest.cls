@isTest
public class ReadTheDealMemoControllerTest {
    
    @isTest
    static void testGetFileContent() {
        // Create a test Lead
        Lead testLead = new Lead(LastName = 'Test', Company = 'Test Company');
        insert testLead;
        
        // Create a ContentDocument and ContentVersion
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.xlsx',
            VersionData = Blob.valueOf('Sample content for the Excel file'),
            IsMajorVersion = true
        );
        insert contentVersion;
        
        // Query the ContentDocumentId from ContentVersion
        ContentVersion insertedVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        
        // Link the ContentDocument to the Lead
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = insertedVersion.ContentDocumentId,
            LinkedEntityId = testLead.Id,
            ShareType = 'V'
        );
        insert contentDocumentLink;
        
        // Call the method
        Test.startTest();
        String fileContent = ReadTheDealMemoController.getFileContent(testLead.Id);
        Test.stopTest();
        
        // Verify the result
        System.assertNotEquals(null, fileContent, 'File content should not be null');
    }
    
    @isTest
    static void testSaveExtractData() {
        // Create a test Lead
        Lead testLead = new Lead(LastName = 'Test', Company = 'Test Company');
        insert testLead;
        
        // Create a ContentVersion
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.xlsx',
            VersionData = Blob.valueOf('Sample content for the Excel file'),
            IsMajorVersion = true
        );
        insert contentVersion;
        
        // Query the ContentDocumentId from ContentVersion
        ContentVersion insertedVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        
        // Link the ContentDocument to the Lead
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
            ContentDocumentId = insertedVersion.ContentDocumentId,
            LinkedEntityId = testLead.Id,
            ShareType = 'V'
        );
        insert contentDocumentLink;
        
        // Create test data for extracted data
        String jsonData = '{"ApplicationType": "New Application", "ApplicationDate": "2025-05-01", "Applicant": "John Doe", "Jurisdiction": "California", "ApplicantAddress": "123 Test St", "Telephone": "1234567890", "VAT": "123456789", "ApplicantContact": "John Doe", "ApplicantEmail": "jane.doe@example.com", "SignatoryContact": "John Smith", "SignatoryEmail": "john.smith@example.com", "AccountsPayableContact": "Alice Johnson", "AccountsPayableEmail": "alice.johnson@example.com", "CreativeContact": "Bob Brown", "CreativeContactEmail": "bob.brown@example.com", "SubmissionsContact": "Charlie Black", "SubmissionsContactEmail": "charlie.black@example.com", "property": "Test Property", "Territory": "Test Territory", "DistributionChannels": "Toy/Hobby", "Exclusivity": "Exclusive", "CountryofProduction": "USA", "TargetDemographic": "Adults", "TermLengthStart": "2025-05-01", "TermLengthEnd": "2026-05-01", "MinimumGuarantee": 1000, "Advance": 500, "MGPaymentSchedule": "Monthly", "RoyaltyRate":" % Wholesale", "LATAM": 1, "NA": 1, "ANZ": 1, "EMEA": 1, "Products": [{"categoryName": "Product A", "MinNumberofDesigns": 5, "MinQuantityPerDesign": 10, "Retail": 20.0, "Wholesale": 15.0, "Royalty": 0.12, "ProductionQuantity": 100, "RoyaltyAmount": 12.0, "InitialLaunchDate": "2025-05-01"}]}';
        
        // Call the method
        Test.startTest();
        ReadTheDealMemoController.saveExtractData(testLead.Id, jsonData);
        Test.stopTest();
        
        // Verify that the Lead was updated
        Lead updatedLead = [SELECT Applicant_Contact__c, Applicant_Type__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('John Doe', updatedLead.Applicant_Contact__c, 'Applicant contact should be updated');
        System.assertEquals('New Application', updatedLead.Applicant_Type__c, 'Applicant type should be updated');
        
        // Verify that the Titles Interested records were created
        //List<Titles_Interested__c> titlesInterested = [SELECT Id, Lead__c, Category__c FROM Titles_Interested__c WHERE Lead__c = :testLead.Id];
        //System.assertEquals(1, titlesInterested.size(), 'One Titles Interested record should be created');
        //System.assertEquals('Product A', titlesInterested[0].Category__c, 'Category should match the extracted data');
    }
    
    @isTest
    static void testSaveExtractDataWithMatchedProducts() {
        // Create a test Lead
        Lead testLead = new Lead(LastName = 'Test', Company = 'Test Company');
        insert testLead;

        // Create a Product2 record
        Product2 testProduct = new Product2(Name = 'Chainsaw Man S1', IsActive = true, Rightsline_ID__c = '1234567');
        insert testProduct;

        // Create test data for extracted data
        String jsonData = '{"ApplicationType": "New Application", "ApplicationDate": "2025-05-01", "Applicant": "John Doe", "Jurisdiction": "California", "ApplicantAddress": "123 Test St", "Telephone": "1234567890", "VAT": "123456789", "ApplicantContact": "John Doe", "ApplicantEmail": "jane.doe@example.com", "SignatoryContact": "John Smith", "SignatoryEmail": "john.smith@example.com", "AccountsPayableContact": "Alice Johnson", "AccountsPayableEmail": "alice.johnson@example.com", "CreativeContact": "Bob Brown", "CreativeContactEmail": "bob.brown@example.com", "SubmissionsContact": "Charlie Black", "SubmissionsContactEmail": "charlie.black@example.com", "property": "Chainsaw Man S1;pikachu", "Territory": "Test Territory", "DistributionChannels": "Toy/Hobby", "Exclusivity": "Exclusive", "CountryofProduction": "USA", "TargetDemographic": "Adults", "TermLengthStart": "2025-05-01", "TermLengthEnd": "2026-05-01", "MinimumGuarantee": 1000, "Advance": 500, "MGPaymentSchedule": "Monthly", "LATAM": 1, "NA": 1, "ANZ": 1, "EMEA": 1}';
        
        // Call the method
        Test.startTest();
        ReadTheDealMemoController.saveExtractData(testLead.Id, jsonData);
        Test.stopTest();
        
        // Verify that the Lead was updated
        Lead updatedLead = [SELECT Applicant_Contact__c, Applicant_Type__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('John Doe', updatedLead.Applicant_Contact__c, 'Applicant contact should be updated');
        System.assertEquals('New Application', updatedLead.Applicant_Type__c, 'Applicant type should be updated');
        
        // Verify that the Titles Interested records were created
        List<Titles_Interested__c> titlesInterested = [SELECT Id, Lead__c, Title__c FROM Titles_Interested__c WHERE Lead__c = :testLead.Id];
        System.assertEquals(1, titlesInterested.size(), 'One Titles Interested record should be created');
        System.assertEquals(testProduct.Id, titlesInterested[0].Title__c, 'Title should match the extracted product');
    }
    
    
    @isTest
    static void testSaveExtractDataWithUnmatchedProducts() {
        // Create a test Lead
        Lead testLead = new Lead(LastName = 'Test', Company = 'Test Company');
        insert testLead;

        // Create a Product2 record
        Product2 testProduct = new Product2(Name = 'Chainsaw Man S1', IsActive = true, Rightsline_ID__c = '1234567');
        insert testProduct;

        // Create test data for extracted data with an unmatched product
        String jsonData = '{"ApplicationType": "New Application", "ApplicationDate": "2025-05-01", "Applicant": "John Doe", "Jurisdiction": "California", "ApplicantAddress": "123 Test St", "Telephone": "1234567890", "VAT": "123456789", "ApplicantContact": "John Doe", "ApplicantEmail": "jane.doe@example.com", "SignatoryContact": "John Smith", "SignatoryEmail": "john.smith@example.com", "AccountsPayableContact": "Alice Johnson", "AccountsPayableEmail": "alice.johnson@example.com", "CreativeContact": "Bob Brown", "CreativeContactEmail": "bob.brown@example.com", "SubmissionsContact": "Charlie Black", "SubmissionsContactEmail": "charlie.black@example.com", "property": "Chainsaw Man S1;Nonexistent Product", "Territory": "Test Territory", "DistributionChannels": "Toy/Hobby", "Exclusivity": "Exclusive", "CountryofProduction": "USA", "TargetDemographic": "Adults", "TermLengthStart": "2025-05-01", "TermLengthEnd": "2026-05-01", "MinimumGuarantee": 1000, "Advance": 500, "MGPaymentSchedule": "Monthly", "LATAM": 1, "NA": 1, "ANZ": 1, "EMEA": 1}';
        
        // Call the method
        Test.startTest();
        ReadTheDealMemoController.saveExtractData(testLead.Id, jsonData);
        Test.stopTest();
        
        // Verify that the Lead was updated
        Lead updatedLead = [SELECT Applicant_Contact__c, Applicant_Type__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('John Doe', updatedLead.Applicant_Contact__c, 'Applicant contact should be updated');
        System.assertEquals('New Application', updatedLead.Applicant_Type__c, 'Applicant type should be updated');
        
        // Verify that the Titles Interested records were created
        List<Titles_Interested__c> titlesInterested = [SELECT Id, Lead__c, Title__c FROM Titles_Interested__c WHERE Lead__c = :testLead.Id];
        System.assertEquals(1, titlesInterested.size(), 'One Titles Interested record should be created');
        System.assertEquals(testProduct.Id, titlesInterested[0].Title__c, 'Title should match the extracted product');
    }
    
    @isTest
    static void testSaveExtractDataWithNoProducts() {
        // Create a test Lead
        Lead testLead = new Lead(LastName = 'Test', Company = 'Test Company');
        insert testLead;

        // Create test data for extracted data with no products
        String jsonData = '{"ApplicationType": "New Application", "ApplicationDate": "2025-05-01", "Applicant": "John Doe", "Jurisdiction": "California", "ApplicantAddress": "123 Test St", "Telephone": "1234567890", "VAT": "123456789", "ApplicantContact": "John Doe", "ApplicantEmail": "jane.doe@example.com", "SignatoryContact": "John Smith", "SignatoryEmail": "john.smith@example.com", "AccountsPayableContact": "Alice Johnson", "AccountsPayableEmail": "alice.johnson@example.com", "CreativeContact": "Bob Brown", "CreativeContactEmail": "bob.brown@example.com", "SubmissionsContact": "Charlie Black", "SubmissionsContactEmail": "charlie.black@example.com", "property": "", "Territory": "Test Territory", "DistributionChannels": "Toy/Hobby", "Exclusivity": "Exclusive", "CountryofProduction": "USA", "TargetDemographic": "Adults", "TermLengthStart": "2025-05-01", "TermLengthEnd": "2026-05-01", "MinimumGuarantee": 1000, "Advance": 500, "MGPaymentSchedule": "Monthly", "LATAM": 1, "NA": 1, "ANZ": 1, "EMEA": 1}';
        
        // Call the method
        Test.startTest();
        ReadTheDealMemoController.saveExtractData(testLead.Id, jsonData);
        Test.stopTest();
        
        // Verify that the Lead was updated
        Lead updatedLead = [SELECT Applicant_Contact__c, Applicant_Type__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('John Doe', updatedLead.Applicant_Contact__c, 'Applicant contact should be updated');
        System.assertEquals('New Application', updatedLead.Applicant_Type__c, 'Applicant type should be updated');
        
        // Verify that no Titles Interested records were created
        List<Titles_Interested__c> titlesInterested = [SELECT Id, Lead__c, Title__c FROM Titles_Interested__c WHERE Lead__c = :testLead.Id];
        System.assertEquals(0, titlesInterested.size(), 'No Titles Interested records should be created');
    }
    
     @isTest
    static void testSaveSelectedCategories() {
        // Create a test Lead
        Lead testLead = new Lead(LastName = 'Test', Company = 'Test Company');
        insert testLead;

        // Create Media_Rights__c records
        Media_Rights__c mediaRight1 = new Media_Rights__c(Name = 'Category 1');
        Media_Rights__c mediaRight2 = new Media_Rights__c(Name = 'Category 2');
        insert new List<Media_Rights__c>{mediaRight1, mediaRight2};

        // Create test categories
        List<String> categories = new List<String>{'Category 1', 'Category 2'};

        // Call the method
        Test.startTest();
        ReadTheDealMemoController.saveSelectedCategories(testLead.Id, categories);
        Test.stopTest();

        // Verify that the Media__c records were created
        List<Media__c> mediaRecords = [SELECT Id, Name FROM Media__c WHERE Rights_Set__c IN (SELECT Id FROM Rights_Set__c WHERE Lead__c = :testLead.Id)];
        System.assertEquals(2, mediaRecords.size(), 'Two Media records should be created');
    }
}