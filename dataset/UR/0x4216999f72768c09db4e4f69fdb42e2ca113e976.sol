 

 
 

 
 

 

pragma solidity ^0.4.24;

contract cryptodiamondwatch {
    
    string private ID;  
    string private name;
    string private surname;
    string private comment;
    string private metadataURL;
    
    uint256 private nID=1;  
    
    uint256 private amount;
    
    uint256 private unlockTime;
    
    address private tokenERC721Address;
    address private owner;
    address private cryptodiamondAddress;
    
     
    event Created(string _id, address _address);
    event InfoSetted(string _name, string _surname, string _comment);
    event OwnershipChanged(address _address, address _newOwner,string _comment);
    event Received(address _address ,uint _value);
    
     
    constructor(string _ID, address _tokenERC721Address)public{
        ID = _ID;
        tokenERC721Address = _tokenERC721Address;
        cryptodiamondAddress = msg.sender;
        name = "not assigned yet";
        surname = "not assigned yet";
        comment = "not assigned yet";
        unlockTime=0;
        amount=0;
        owner=msg.sender;
        emit Created(_ID,msg.sender);
    }
    
    
    modifier onlyOwner() { 
    	require (msg.sender == owner); 
    	_; 
    }
    
    modifier onlyCryptodiamond() { 
    	require (msg.sender == cryptodiamondAddress); 
    	_; 
    }
    
    modifier onlyToken() { 
    	require (msg.sender == tokenERC721Address); 
    	_; 
    }
    
    
    function setInfo(string _name, string _surname, string _comment)public onlyCryptodiamond{
        name = _name;
        surname = _surname;
        comment = _comment;
    }
    
    function fee(uint256 _amount,uint256 _fee) private returns(uint256){
        uint256 calcFee;
        calcFee=(_fee*_amount)/100;
        return(_fee*amount/100);
    }
    
     
    function () public payable{
        uint256 cFee = fee(msg.value,1);
        owner.transfer(msg.value-cFee);
        cryptodiamondAddress.transfer(cFee);
        emit Received(msg.sender,msg.value);
    }
    
    
     
    function ethIN() public payable onlyCryptodiamond{
            amount+=msg.value;
            unlockTime=now+7889400;     
            emit Received(msg.sender,msg.value);
    }
    
    function allEthOUT() public onlyOwner{
        if(now>=unlockTime){
            owner.transfer(amount);
            amount = 0;
            unlockTime = 0;
        }
        else
            revert();
    }

   function transferOwnershipTo(address _newOwner, string _comment) external onlyToken{
         
         
        require(_newOwner != address(0));
        require(_newOwner != cryptodiamondAddress);
        emit OwnershipChanged(msg.sender,_newOwner,_comment);
   		owner = _newOwner;
   }
    
    function getOwner() public constant returns (address){
        return owner;
    }
    function getCryptodiamondAddress() public constant returns (address){
        return cryptodiamondAddress;
    }
    function getID() public constant returns (string){
        return ID;
    }
    
    function getNID() public constant returns (uint256){
        return nID;
    }

    function getMetadataURL() public constant returns (string){
        return metadataURL;
    }
    
    function getName() public constant returns (string){
        return name;
    }
    function getSurname() public constant returns (string){
        return surname;
    }
    
    function getUnlocktime() public constant returns (uint){
        return unlockTime;
    }
    
    function getAmount() external constant returns (uint){
        return amount;
    }
    
    
}