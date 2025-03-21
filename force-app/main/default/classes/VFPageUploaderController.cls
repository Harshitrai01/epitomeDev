public with sharing class VFPageUploaderController {
    @AuraEnabled
    public static String saveVFAsAttachment(String vfPageUrl, Id recordId) {
        try {
            // Call the VF Page and get PDF content
            PageReference pdfPage = new PageReference(vfPageUrl);
            Blob pdfBlob;
            if(!Test.isRunningTest()){
                pdfBlob= pdfPage.getContent();
            }else{
                    pdfBlob= Blob.valueOf('test');
            }
            

            // Create attachment record
            Attachment attach = new Attachment();
            attach.Name = 'VFPage_' + System.currentTimeMillis() + '.pdf';
            attach.Body = pdfBlob;
            attach.ParentId = recordId;
            insert attach;

            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}