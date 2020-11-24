 

pragma solidity ^0.4.9; 
 
 

 
contract BaseAgriChainContract {
    address creator; 
    bool public isSealed;
    function BaseAgriChainContract() public    {  creator = msg.sender; EventCreated(this,creator); }
    modifier onlyIfNotSealed()  
    {
        if (isSealed)
            throw;
        _;
    }

    modifier onlyBy(address _account)  
    {
        if (msg.sender != _account)
            throw;
        _;
    }
    
    function kill() onlyBy(creator)   { suicide(creator); }     
    function setCreator(address _creator)  onlyBy(creator)  { creator = _creator;     }
    function setSealed()  onlyBy(creator)  { isSealed = true;  EventSealed(this);   }  

    event EventCreated(address self,address creator);
    event EventSealed(address self);  
    event EventChanged(address self,string property);  
    event EventChangedInt32(address self,string property,int32 value);  
    event EventChangedString(address self,string property,string value);  
    event EventChangedAddress(address self,string property,address value);  
    
  
}







 
contract AgriChainContract   is BaseAgriChainContract    
{  
    string  public  Organization;       
    string  public  Product ;           
    string  public  Description ;       
    address public  AgriChainData;      
    string  public  AgriChainSeal;      
    string  public  Notes ;
    
    function   AgriChainProductionContract() public
    { 
       AgriChainData=address(this);
    }
    
    function setOrganization(string _Organization)  onlyBy(creator)  onlyIfNotSealed()
    {
          Organization = _Organization;
          EventChangedString(this,'Organization',_Organization);

    }
    
    function setProduct(string _Product)  onlyBy(creator) onlyIfNotSealed()
    {
          Product = _Product;
          EventChangedString(this,'Product',_Product);
        
    }
    
    function setDescription(string _Description)  onlyBy(creator) onlyIfNotSealed()
    {
          Description = _Description;
          EventChangedString(this,'Description',_Description);
    }
    function setAgriChainData(address _AgriChainData)  onlyBy(creator) onlyIfNotSealed()
    {
         AgriChainData = _AgriChainData;
         EventChangedAddress(this,'AgriChainData',_AgriChainData);
    }
    
    
    function setAgriChainSeal(string _AgriChainSeal)  onlyBy(creator) onlyIfNotSealed()
    {
         AgriChainSeal = _AgriChainSeal;
         EventChangedString(this,'AgriChainSeal',_AgriChainSeal);
    }
    
    
     
    function setNotes(string _Notes)  onlyBy(creator)
    {
         Notes =  _Notes;
         EventChanged(this,'Notes');
    }
}


 
contract AgriChainDataContract   is BaseAgriChainContract    
{  
    function   AgriChainDataContract() public
    {
        AgriChainNextData=address(this);
        AgriChainPrevData=address(this);
        AgriChainRootData=address(this);
    }
    
      address public  AgriChainNextData;
      address public  AgriChainPrevData;
      address public  AgriChainRootData;
      
      string public AgriChainType;
      string public AgriChainLabel;
      string public AgriChainLabelInt;
      string public AgriChainDescription;
      string public AgriChainDescriptionInt;
      
    function setChain(address _Next,address _Prev, address _Root)  onlyBy(creator)  
    {
         AgriChainNextData=_Next;
         AgriChainPrevData=_Prev;
         AgriChainRootData=_Root;
         EventChanged(this,'Chain');
    }
    
     
    function setData(string _Type,string _Label,string _Description)  onlyBy(creator) onlyIfNotSealed()
    {
          AgriChainType=_Type;
          AgriChainLabel=_Label;
          AgriChainDescription=_Description;
          EventChanged(this,'Data');
    }
   
     
    function setDataInt(string _LabelInt,string _DescriptionInt)  onlyBy(creator) onlyIfNotSealed()
    {
          
          AgriChainLabelInt=_LabelInt;
          AgriChainDescriptionInt=_DescriptionInt;
          EventChanged(this,'DataInt');
    }
   
      
}

 
contract AgriChainDocumentContract   is AgriChainDataContract    
{  
     
    string  public  Emitter;       
    string  public  Name;          
    string  public  Description ;  
    string  public  NameInt;          
    string  public  DescriptionInt ;  

    string  public  FileName;      
    string  public  FileHash;      
    string  public  FileData;      
   
    string  public  FileNameInt;   
    string  public  FileHashInt;   
    string  public  FileDataInt;   

    string  public  Notes ;
    address public  Revision; 
    
    function   AgriChainDocumentContract() public
    {
        Revision=address(this);
    }
    
    function setData(string _Emitter,string _Name,string _Description, string _FileName,string _FileHash,string _FileData)  onlyBy(creator) onlyIfNotSealed()
    {
          Emitter=_Emitter;
          Name=_Name;
          Description=_Description;
          FileName=_FileName;
          FileHash=_FileHash;
          FileData=_FileData;          
          EventChanged(this,'Data');
       
    } 
    
     
    
    function setRevision(address _Revision)  onlyBy(creator) onlyIfNotSealed()
    {
          Revision = _Revision;
        
    } 
     
     
    function setNotes(string _Notes)  onlyBy(creator)
    {
         Notes =  _Notes;
         
    }
}


 
contract AgriChainProductionLotContract   is AgriChainDataContract    
{  
    
     int32  public QuantityInitial;
     int32  public QuantityAvailable;
     string public QuantityUnit;
    
    function InitQuantity(int32 _Initial,string _Unit)  onlyBy(creator)  onlyIfNotSealed()
    {
          QuantityInitial = _Initial;
          QuantityAvailable = _Initial;
          QuantityUnit = _Unit;
          EventChangedInt32(this,'QuantityInitial',_Initial);

    }
  
    function UseQuantity(int32 _Use)  onlyBy(creator)  
    {
          QuantityAvailable = QuantityAvailable-_Use;
          EventChangedInt32(this,'QuantityAvailable',QuantityAvailable);

    }
  
}