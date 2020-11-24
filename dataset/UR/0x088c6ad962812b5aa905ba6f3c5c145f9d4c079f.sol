 

pragma solidity ^0.4.18;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract CryptoCatsMarket {
    
     
    modifier onlyBy(address _account)
    {
        require(msg.sender == _account);
        _;
    }


     
    string public imageHash = "3b82cfd5fb39faff3c2c9241ca5a24439f11bdeaa7d6c0771eb782ea7c963917";

     
    address owner;
    string public standard = 'CryptoCats';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;
    
     
     
    address public previousContractAddress = 0x9508008227b6b3391959334604677d60169EF540;

     
     

    uint8 public contractVersion;
    bool public totalSupplyIsLocked;

    bool public allCatsAssigned = false;         
    uint public catsRemainingToAssign = 0;    
    uint public currentReleaseCeiling;        

     
    mapping (uint => address) public catIndexToAddress;
    
     
    mapping (uint32 => uint) public catReleaseToPrice;

     
    mapping (uint => uint) public catIndexToPriceException;

     
    mapping (address => uint) public balanceOf;
     
    mapping (uint => string) public attributeType;
     
    mapping (uint => string[6]) public catAttributes;

     
    struct Offer {
        bool isForSale;          
        uint catIndex;
        address seller;          
        uint minPrice;        
        address sellOnlyTo;      
    }

    uint[] public releaseCatIndexUpperBound;

     
    mapping (uint => Offer) public catsForSale;

     
    mapping (address => uint) public pendingWithdrawals;

     
    event CatTransfer(address indexed from, address indexed to, uint catIndex);
    event CatOffered(uint indexed catIndex, uint minPrice, address indexed toAddress);
    event CatBought(uint indexed catIndex, uint price, address indexed fromAddress, address indexed toAddress);
    event CatNoLongerForSale(uint indexed catIndex);

     
    event Assign(address indexed to, uint256 catIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
     
    event ReleaseUpdate(uint256 indexed newCatsAdded, uint256 totalSupply, uint256 catPrice, string newImageHash);
     
    event UpdateReleasePrice(uint32 releaseId, uint256 catPrice);
     
    event UpdateAttribute(uint indexed attributeNumber, address indexed ownerAddress, bytes32 oldValue, bytes32 newValue);

     
    function CryptoCatsMarket() payable {
        owner = msg.sender;                           
        _totalSupply = 625;                           
        catsRemainingToAssign = _totalSupply;         
        name = "CRYPTOCATS";                          
        symbol = "CCAT";                              
        decimals = 0;                                 
        contractVersion = 3;
        currentReleaseCeiling = 625;
        totalSupplyIsLocked = false;

        releaseCatIndexUpperBound.push(12);              
        releaseCatIndexUpperBound.push(189);             
        releaseCatIndexUpperBound.push(_totalSupply);    

        catReleaseToPrice[0] = 0;                        
        catReleaseToPrice[1] = 0;                        
        catReleaseToPrice[2] = 80000000000000000;        
    }
    
     
    function lockTotalSupply()
        onlyBy(owner)
    {
        totalSupplyIsLocked = true;
    }

     
    function setAttributeType(uint attributeIndex, string descriptionText)
        onlyBy(owner)
    {
        require(attributeIndex >= 0 && attributeIndex < 6);
        attributeType[attributeIndex] = descriptionText;
    }
    
     
    function releaseCats(uint32 _releaseId, uint numberOfCatsAdded, uint256 catPrice, string newImageHash) 
        onlyBy(owner)
        returns (uint256 newTotalSupply) 
    {
        require(!totalSupplyIsLocked);                   
        require(numberOfCatsAdded > 0);                  
        currentReleaseCeiling = currentReleaseCeiling + numberOfCatsAdded;   
        uint _previousSupply = _totalSupply;
        _totalSupply = _totalSupply + numberOfCatsAdded;
        catsRemainingToAssign = catsRemainingToAssign + numberOfCatsAdded;   
        imageHash = newImageHash;                                            

        catReleaseToPrice[_releaseId] = catPrice;                            
        releaseCatIndexUpperBound.push(_totalSupply);                        

        ReleaseUpdate(numberOfCatsAdded, _totalSupply, catPrice, newImageHash);  
        return _totalSupply;                                                     
    }

     
    function updateCatReleasePrice(uint32 _releaseId, uint256 catPrice)
        onlyBy(owner)
    {
        require(_releaseId <= releaseCatIndexUpperBound.length);             
        catReleaseToPrice[_releaseId] = catPrice;                            
        UpdateReleasePrice(_releaseId, catPrice);                            
    }
   
     
    function migrateCatOwnersFromPreviousContract(uint startIndex, uint endIndex) 
        onlyBy(owner)
    {
        PreviousCryptoCatsContract previousCatContract = PreviousCryptoCatsContract(previousContractAddress);
        for (uint256 catIndex = startIndex; catIndex <= endIndex; catIndex++) {      
            address catOwner = previousCatContract.catIndexToAddress(catIndex);      

            if (catOwner != 0x0) {                                                   
                catIndexToAddress[catIndex] = catOwner;                              
                uint256 ownerBalance = previousCatContract.balanceOf(catOwner);     
                balanceOf[catOwner] = ownerBalance;                                  
            }
        }

        catsRemainingToAssign = previousCatContract.catsRemainingToAssign();         
    }
    
     
    function setCatAttributeValue(uint catIndex, uint attrIndex, string attrValue) {
        require(catIndex < _totalSupply);                       
        require(catIndexToAddress[catIndex] == msg.sender);     
        require(attrIndex >= 0 && attrIndex < 6);               
        bytes memory tempAttributeTypeText = bytes(attributeType[attrIndex]);
        require(tempAttributeTypeText.length != 0);             
        catAttributes[catIndex][attrIndex] = attrValue;         
    }

     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (_value < _totalSupply &&                     
            catIndexToAddress[_value] == msg.sender &&   
            balanceOf[msg.sender] > 0) {                 
            balanceOf[msg.sender]--;                     
            catIndexToAddress[_value] = _to;             
            balanceOf[_to]++;                            
            Transfer(msg.sender, _to, _value);           
            success = true;                              
        } else {
            success = false;                             
        }
        return success;                                  
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        require(balanceOf[_owner] != 0);     
        return balanceOf[_owner];            
    }

     
    function totalSupply() constant returns (uint256 totalSupply) {
        return _totalSupply;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     

     
    function getCatRelease(uint catIndex) returns (uint32) {
        for (uint32 i = 0; i < releaseCatIndexUpperBound.length; i++) {      
            if (releaseCatIndexUpperBound[i] > catIndex) {                   
                return i;                                                    
            }
        }   
    }

     
    function getCatPrice(uint catIndex) returns (uint catPrice) {
        require(catIndex < _totalSupply);                    

        if(catIndexToPriceException[catIndex] != 0) {        
            return catIndexToPriceException[catIndex];       
        }

        uint32 releaseId = getCatRelease(catIndex);         
        return catReleaseToPrice[releaseId];                 
    }

     
    function setCatPrice(uint catIndex, uint catPrice)
        onlyBy(owner) 
    {
        require(catIndex < _totalSupply);                    
        require(catPrice > 0);                               
        catIndexToPriceException[catIndex] = catPrice;       
    }

     
    function getCat(uint catIndex) payable {
        require(!allCatsAssigned);                       
        require(catsRemainingToAssign != 0);             
        require(catIndexToAddress[catIndex] == 0x0);     
        require(catIndex < _totalSupply);                
        require(catIndex < currentReleaseCeiling);       
        require(getCatPrice(catIndex) <= msg.value);     

        catIndexToAddress[catIndex] = msg.sender;        
        balanceOf[msg.sender]++;                         
        catsRemainingToAssign--;                         
        pendingWithdrawals[owner] += msg.value;          
        Assign(msg.sender, catIndex);                    
                                                         
    }

     
    function getCatOwner(uint256 catIndex) public returns (address) {
        require(catIndexToAddress[catIndex] != 0x0);
        return catIndexToAddress[catIndex];              
    }

     
    function getContractOwner() public returns (address) {
        return owner;                                    
    }

     
    function catNoLongerForSale(uint catIndex) {
        require (catIndexToAddress[catIndex] == msg.sender);                 
        require (catIndex < _totalSupply);                                   
        catsForSale[catIndex] = Offer(false, catIndex, msg.sender, 0, 0x0);  
        CatNoLongerForSale(catIndex);                                        
    }

     
    function offerCatForSale(uint catIndex, uint minSalePriceInWei) {
        require (catIndexToAddress[catIndex] == msg.sender);                 
        require (catIndex < _totalSupply);                                   
        catsForSale[catIndex] = Offer(true, catIndex, msg.sender, minSalePriceInWei, 0x0);   
        CatOffered(catIndex, minSalePriceInWei, 0x0);                        
    }

     
    function offerCatForSaleToAddress(uint catIndex, uint minSalePriceInWei, address toAddress) {
        require (catIndexToAddress[catIndex] == msg.sender);                 
        require (catIndex < _totalSupply);                                   
        catsForSale[catIndex] = Offer(true, catIndex, msg.sender, minSalePriceInWei, toAddress);  
        CatOffered(catIndex, minSalePriceInWei, toAddress);                  
    }

     
    function buyCat(uint catIndex) payable {
        require (catIndex < _totalSupply);                       
        Offer offer = catsForSale[catIndex];
        require (offer.isForSale);                               
        require (msg.value >= offer.minPrice);                   
        require (offer.seller == catIndexToAddress[catIndex]);   
        if (offer.sellOnlyTo != 0x0) {                           
            require (offer.sellOnlyTo == msg.sender);            
        }
        
        address seller = offer.seller;

        catIndexToAddress[catIndex] = msg.sender;                
        balanceOf[seller]--;                                     
        balanceOf[msg.sender]++;                                 
        Transfer(seller, msg.sender, 1);                         

        CatNoLongerForSale(catIndex);                            
        pendingWithdrawals[seller] += msg.value;                 
        CatBought(catIndex, msg.value, seller, msg.sender);      

    }

     
    function withdraw() {
        uint amount = pendingWithdrawals[msg.sender];    
        pendingWithdrawals[msg.sender] = 0;              
        msg.sender.transfer(amount);                     
    }
}

contract PreviousCryptoCatsContract {

     
    string public imageHash = "e055fe5eb1d95ea4e42b24d1038db13c24667c494ce721375bdd827d34c59059";

     
    address owner;
    string public standard = 'CryptoCats';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;
    
     
     
    address public previousContractAddress = 0xa185B9E63FB83A5a1A13A4460B8E8605672b6020;
     
     
    uint8 public contractVersion;
    bool public totalSupplyIsLocked;

    bool public allCatsAssigned = false;         
    uint public catsRemainingToAssign = 0;    
    uint public currentReleaseCeiling;        

     
    mapping (uint => address) public catIndexToAddress;

     
    mapping (address => uint) public balanceOf;

     
    function PreviousCryptoCatsContract() payable {
        owner = msg.sender;                           
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        require(balanceOf[_owner] != 0);     
        return balanceOf[_owner];            
    }

     
    function totalSupply() constant returns (uint256 totalSupply) {
        return _totalSupply;
    }

     
    function getCatOwner(uint256 catIndex) public returns (address) {
        require(catIndexToAddress[catIndex] != 0x0);
        return catIndexToAddress[catIndex];              
    }

     
    function getContractOwner() public returns (address) {
        return owner;                                    
    }

}