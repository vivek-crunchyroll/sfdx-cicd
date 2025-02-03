public with sharing class FetchLeadFile {
    @AuraEnabled
    public static String getFileContent(Id leadId) {
        List<ContentDocumentLink> contentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :leadId];
        system.debug('Fetched document'+contentLinks);

        if (contentLinks.isEmpty()) {
            throw new AuraHandledException('No files found for this Lead.');
        }
        //Fetch first file Content
        ContentDocument document = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Id = :contentLinks[0].ContentDocumentId LIMIT 1];
        ContentVersion version = [SELECT Id, Title, VersionData FROM ContentVersion WHERE Id = :document.LatestPublishedVersionId LIMIT 1];
        system.debug('Fetched document'+version);
        
        //return base64 encoded content
        String base64Content = EncodingUtil.base64Encode(version.VersionData);
        return base64Content;
    }    
}