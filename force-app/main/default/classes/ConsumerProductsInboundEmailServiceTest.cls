@isTest
public class ConsumerProductsInboundEmailServiceTest {
@isTest
    static void testHandleInboundEmail_ValidData() {
       
        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Consumer_Products' AND SObjectType = 'Lead' LIMIT 1].Id;
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromname = 'Virat kohli';  
        email.plainTextBody = 'This is a sample email body';  
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = Blob.valueOf('This is a test attachment');
        attachment.fileName = 'test_attachment.xlsx';
        
        email.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>{attachment};


        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        envelope.fromAddress = 'Virat@testcompany.com';  

        Test.startTest();
        
        
        ConsumerProductsInboundEmailService service = new ConsumerProductsInboundEmailService();
        Messaging.InboundEmailResult result = service.handleInboundEmail(email, envelope);
        
        Test.stopTest();

        System.assert(result.success == true, 'The inbound email processing failed');

        Lead createdLead = [SELECT FirstName, LastName, Status, Company, Email FROM Lead WHERE Email = :envelope.fromAddress LIMIT 1];
        ContentVersion cv = [SELECT Title, PathOnClient FROM ContentVersion WHERE Title = 'test_attachment.xlsx' LIMIT 1];
        System.assertEquals('Virat', createdLead.FirstName, 'First name mismatch');
        System.assertEquals('kohli', createdLead.LastName, 'Last name mismatch');
        System.assertEquals('New', createdLead.Status, 'Status mismatch');
        System.assertEquals('testcompany', createdLead.Company, 'Company mismatch');  
        
          
        System.assertEquals('test_attachment.xlsx', cv.Title, 'Attachment should have been saved correctly');

    }
 
}