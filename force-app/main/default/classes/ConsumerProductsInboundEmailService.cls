global class ConsumerProductsInboundEmailService implements Messaging.InboundEmailHandler {
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        
        string str = email.fromname;
        String emailBody = email.plainTextBody;
        
        if (str != null && str.contains(' ')) {
            list<string> strList = str.split(' ', 2);
            
            if (strList.size() > 1) {
                Lead led = new Lead();
                led.FirstName = strList[0];
                led.LastName = strList[1];
                led.Status = 'New';
 			    led.LeadSource = 'Email';
                led.Email = envelope.fromAddress;
                
                led.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Consumer_Products').getRecordTypeId();
                // Extract domain name from email address and assign it to Company field (without .com or other TLD)
                String fromEmail =  envelope.fromAddress;
                if (fromEmail != null && fromEmail.contains('@')) {
                    String domainName = fromEmail.split('@')[1]; // Get domain after '@'
                    
                    // Remove TLD (after first dot)
                    Integer dotIndex = domainName.indexOf('.');
                    if (dotIndex != -1) {
                        domainName = domainName.substring(0, dotIndex); // Get only the part before the first dot
                    }
                    
                    led.Company = domainName; 
                } 
                
                try{
                    insert led;
                    saveEmailAttachments(email, led.Id);
                }
                catch(Exception ex){
                    System.debug('There is an exception : '+ex.getMessage());
                }
            }
           
        } 
        
        
        
        return result;
    }
    
   /* public static String extractValuesFromEmailBody(String phrase, String emailBody) {
        if (emailBody != null && phrase != null) {
            Pattern p = Pattern.compile(phrase + ' -\\s*(.*)');
            Matcher m = p.matcher(emailBody);
            
            if (m.find()) {
                return m.group(1);
            }
        } else {
            System.debug('Email body or phrase is null.');
        }
        return null;
    }*/
    
    public static void saveEmailAttachments(Messaging.InboundEmail email, String leadId) {
        if(email.binaryAttachments != null && email.binaryAttachments.size() > 0){
            for(Messaging.InboundEmail.BinaryAttachment attachment : email.binaryAttachments){
                if (attachment != null) {
                    // Create a new ContentVersion (Files)
                    ContentVersion newContentVersion = new ContentVersion();
                    newContentVersion.Title = attachment.fileName;
                    newContentVersion.PathOnClient = attachment.fileName;
                    newContentVersion.VersionData = attachment.body;
                    newContentVersion.Origin = 'H';
                    
                    try {
                        insert newContentVersion;
                        
                        ContentVersion contentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :newContentVersion.Id LIMIT 1];
                        
                        
                        ContentDocumentLink docLink = new ContentDocumentLink();
                        docLink.ContentDocumentId = contentVersion.ContentDocumentId;
                        docLink.LinkedEntityId = leadId; // ID of the record you want to link the file to (e.g., Lead)
                        docLink.ShareType = 'V'; // View access
                        docLink.Visibility = 'InternalUsers';
                        
                        
                        try {
                            insert docLink;
                        } catch (Exception Ex) {
                            System.debug('Exception during ContentDocumentLink insert: ' + Ex.getMessage());
                        }
                    } catch (Exception Ex) {
                        System.debug('Exception during ContentVersion insert: ' + Ex.getMessage());
                    }
                } 
            }
        } else {
            System.debug('There are no attachments.');
        }
    }
}