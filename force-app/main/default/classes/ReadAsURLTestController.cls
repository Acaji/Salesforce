// This controller is in its exploratory phase - used in ReadAsUrl page
public without sharing class ReadAsURLTestController
{
  public static ID            ParentCaseId { get; set; }
  
  public ReadAsURLTestController()
  {
        List<EcoSystemState__c> ECOlist = 
        [
            SELECT Id 
            FROM EcoSystemState__c 
            WHERE Id=:Apexpages.currentPage().getParameters().get('id')
        ];
        if ( !ECOlist.isEmpty() ) ParentCaseId = ECOlist[0].Id;
  }
  
  @RemoteAction
  public static Boolean UploadFile( Id PageObjectId, FileInformation fileInfo )
  {
      return true;
  }
  
   public class FileInformation
  {
    public Integer  size;
    public String  lastModifiedDate;
    public String  fileName;
    public Boolean  validForUpload;
    public blob    theFile;
    public String  status;
    public String  theCategory;
    public Integer  myChunk;
    public Integer  numChunks;
    public Integer  startByte;
    public Integer  chunkSize;
  }
  
  
}