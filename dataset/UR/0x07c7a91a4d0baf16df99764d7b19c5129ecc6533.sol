 

pragma solidity ^0.4.18;

contract ERC721 {
     
     
     
     
    function totalSupply() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint balance);
    function ownerOf(uint256 _tokenId) public constant returns (address owner);
    function approve(address _to, uint256 _tokenId) public ;
    function allowance(address _owner, address _spender) public constant returns (uint256 tokenId);
    function transfer(address _to, uint256 _tokenId) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    
     
     
     
     
    
     
    event Transfer(address _from, address _to, uint256 _tokenId);
    event Approval(address _owner, address _approved, uint256 _tokenId);
}

contract ERC20 {
     
    function totalSupply() public constant returns (uint256 _totalSupply);
 
     
    function balanceOf(address _owner) public constant returns (uint256 balance);
 
     
    function transfer(address _to, uint256 _value) public returns (bool success);
    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
  
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract SpecialGift is ERC721 {
    string public name = "VirtualGift";             
    uint8 public decimals = 0;                
    string public symbol = "VTG";                 
    string public version = "1.0";  

    address private defaultGiftOwner;
    
    mapping(address => bool) allowPermission;

    ERC20 private Gifto = ERC20(0x00C5bBaE50781Be1669306b9e001EFF57a2957b09d);
    
    event Creation(address indexed _owner, uint256 indexed tokenId);
     
    GiftToken[] giftStorageArry;
     
    GiftTemplateToken[] giftTemplateStorageArry;
     
    mapping(address => uint256) private balances;
     
    mapping(uint256 => address) private giftIndexToOwners;
     
    mapping(uint256 => bool) private giftExists;
     
    mapping(address => mapping (address => uint256)) private ownerToApprovedAddsToGifIds;
     
    mapping(uint256 => uint256[]) private giftTemplateIdToGiftids;
     
    mapping(address => mapping(uint256 => uint256)) private addressToBoughtSum;
     
    mapping(uint256 => uint256) private giftTypeToGiftLimit;
     
    uint256 constant NO_LIMIT = 0;
    uint256 private singleAddressBuyLimit = 1;
    
     
    mapping(uint256 => uint256) private giftTypeToSelledSum;

     
    struct GiftTemplateToken {
        uint256 giftPrice;
        uint256 giftLimit;
         
        string giftImgUrl;
         
        string giftName;
    }
     
    struct GiftToken {
        uint256 giftPrice;
        uint256 giftType;
         
        string giftImgUrl;
         
        string giftName;
    }     

    modifier onlyHavePermission(){
        require(allowPermission[msg.sender] == true || msg.sender == defaultGiftOwner);
        _;
    }

    modifier onlyOwner(){
         require(msg.sender == defaultGiftOwner);
         _;
    }

     
    function SpecialGift() public {

        defaultGiftOwner = msg.sender;
        
        GiftToken memory newGift = GiftToken({
            giftPrice: 0,
            giftType: 0,
            giftImgUrl: "",
            giftName: ""
        });

         GiftTemplateToken memory newGiftTemplate = GiftTemplateToken({
                giftPrice: 0,
                giftLimit: 0,
                giftImgUrl: "",
                giftName: ""
            });
        
        giftStorageArry.push(newGift);  
        giftTemplateStorageArry.push(newGiftTemplate);
       
    }

    function addPermission(address _addr) 
    public 
    onlyOwner{
        allowPermission[_addr] = true;
    }
    
    function removePermission(address _addr) 
    public 
    onlyOwner{
        allowPermission[_addr] = false;
    }


      
      
    function sendGift(uint256 _type, 
                      address recipient)
                     public 
                     onlyHavePermission
                     returns(uint256 _giftId)
                     {
         
        require(addressToBoughtSum[recipient][_type] < singleAddressBuyLimit);
         
        require(giftTypeToSelledSum[_type] < giftTemplateStorageArry[_type].giftLimit);
          
        require(_type > 0 && _type < giftTemplateStorageArry.length);
         
        _giftId = _mintGift(_type, recipient);
        giftTypeToSelledSum[_type]++;
        addressToBoughtSum[recipient][_type]++;
        return _giftId;
    }

     
    function _mintGift(uint256 _type, 
                       address recipient)
                     internal returns (uint256) 
                     {

        GiftToken memory newGift = GiftToken({
            giftPrice: giftTemplateStorageArry[_type].giftPrice,
            giftType: _type,
            giftImgUrl: giftTemplateStorageArry[_type].giftImgUrl,
            giftName: giftTemplateStorageArry[_type].giftName
        });
        
        uint256 giftId = giftStorageArry.push(newGift) - 1;
         
        giftTemplateIdToGiftids[_type].push(giftId);
        giftExists[giftId] = true;
         
        _transfer(0, recipient, giftId);
         
        Creation(msg.sender, giftId);
        return giftId;
    }

     
     
    function createGiftTemplate(uint256 _price,
                         uint256 _limit, 
                         string _imgUrl,
                         string _giftName) 
                         public onlyHavePermission
                         returns (uint256 giftTemplateId)
                         {
         
        require(_price > 0);
        bytes memory imgUrlStringTest = bytes(_imgUrl);
        bytes memory giftNameStringTest = bytes(_giftName);
        require(imgUrlStringTest.length > 0);
        require(giftNameStringTest.length > 0);
        require(_limit > 0);
        require(msg.sender != address(0));
         
        GiftTemplateToken memory newGiftTemplate = GiftTemplateToken({
                giftPrice: _price,
                giftLimit: _limit,
                giftImgUrl: _imgUrl,
                giftName: _giftName
        });
         
        giftTemplateId = giftTemplateStorageArry.push(newGiftTemplate) - 1;
        giftTypeToGiftLimit[giftTemplateId] = _limit;
        return giftTemplateId;
        
    }
    
    function updateTemplate(uint256 templateId, 
                            uint256 _newPrice, 
                            uint256 _newlimit, 
                            string _newUrl, 
                            string _newName)
    public
    onlyOwner {
        giftTemplateStorageArry[templateId].giftPrice = _newPrice;
        giftTemplateStorageArry[templateId].giftLimit = _newlimit;
        giftTemplateStorageArry[templateId].giftImgUrl = _newUrl;
        giftTemplateStorageArry[templateId].giftName = _newName;
    }
    
    function getGiftSoldFromType(uint256 giftType)
    public
    constant
    returns(uint256){
        return giftTypeToSelledSum[giftType];
    }

     
    function getGiftsByTemplateId(uint256 templateId) 
    public 
    constant 
    returns(uint256[] giftsId) {
        return giftTemplateIdToGiftids[templateId];
    }
 
     
    function getAllGiftTemplateIds() 
    public 
    constant 
    returns(uint256[]) {
        
        if (giftTemplateStorageArry.length > 1) {
            uint256 theLength = giftTemplateStorageArry.length - 1;
            uint256[] memory resultTempIds = new uint256[](theLength);
            uint256 resultIndex = 0;
           
            for (uint256 i = 1; i <= theLength; i++) {
                resultTempIds[resultIndex] = i;
                resultIndex++;
            }
             return resultTempIds;
        }
        require(giftTemplateStorageArry.length > 1);
       
    }

     
    function getGiftTemplateById(uint256 templateId) 
                                public constant returns(
                                uint256 _price,
                                uint256 _limit,
                                string _imgUrl,
                                string _giftName
                                ){
        require(templateId > 0);
        require(templateId < giftTemplateStorageArry.length);
        GiftTemplateToken memory giftTemplate = giftTemplateStorageArry[templateId];
        _price = giftTemplate.giftPrice;
        _limit = giftTemplate.giftLimit;
        _imgUrl = giftTemplate.giftImgUrl;
        _giftName = giftTemplate.giftName;
        return (_price, _limit, _imgUrl, _giftName);
    }

     
    function getGift(uint256 _giftId) 
                    public constant returns (
                    uint256 giftType,
                    uint256 giftPrice,
                    string imgUrl,
                    string giftName
                    ) {
        require(_giftId < giftStorageArry.length);
        GiftToken memory gToken = giftStorageArry[_giftId];
        giftType = gToken.giftType;
        giftPrice = gToken.giftPrice;
        imgUrl = gToken.giftImgUrl;
        giftName = gToken.giftName;
        return (giftType, giftPrice, imgUrl, giftName);
    }

     
     
     
    function transfer(address _to, uint256 _giftId) external returns (bool success){
        require(giftExists[_giftId]);
        require(_to != 0x0);
        require(msg.sender != _to);
        require(msg.sender == ownerOf(_giftId));
        require(_to != address(this));
        _transfer(msg.sender, _to, _giftId);
        return true;
    }

     
     
    function setGiftoAddress(address newAddress) public onlyOwner {
        Gifto = ERC20(newAddress);
    }
    
     
    function getGiftoAddress() public constant returns (address giftoAddress) {
        return address(Gifto);
    }

     
    function totalSupply() public  constant returns (uint256){
        return giftStorageArry.length - 1;
    }
    
     
     
     
    function balanceOf(address _owner)  public  constant  returns (uint256 giftSum) {
        return balances[_owner];
    }
    
     
     
    function ownerOf(uint256 _giftId) public constant returns (address _owner) {
        require(giftExists[_giftId]);
        return giftIndexToOwners[_giftId];
    }
    
     
     
    function approve(address _to, uint256 _giftId) public {
        require(msg.sender == ownerOf(_giftId));
        require(msg.sender != _to);
        
        ownerToApprovedAddsToGifIds[msg.sender][_to] = _giftId;
         
        Approval(msg.sender, _to, _giftId);
    }
    
     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 giftId) {
        return ownerToApprovedAddsToGifIds[_owner][_spender];
    }
    
     
     
    function takeOwnership(uint256 _giftId) public {
         
        require(giftExists[_giftId]);
        
        address oldOwner = ownerOf(_giftId);
        address newOwner = msg.sender;
        
        require(newOwner != oldOwner);
         
        require(ownerToApprovedAddsToGifIds[oldOwner][newOwner] == _giftId);

         
        _transfer(oldOwner, newOwner, _giftId);
        delete ownerToApprovedAddsToGifIds[oldOwner][newOwner];
         
        Transfer(oldOwner, newOwner, _giftId);
    }
    
     
     
     
     
    function _transfer(address _from, address _to, uint256 _giftId) internal {
        require(balances[_to] + 1 > balances[_to]);
        balances[_to]++;
        giftIndexToOwners[_giftId] = _to;
   
        if (_from != address(0)) {
            balances[_from]--;
        }
        
         
        Transfer(_from, _to, _giftId);
    }
    
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _giftId) external {

        require(_to != address(0));
        require(_to != address(this));
         
        require(ownerToApprovedAddsToGifIds[_from][_to] == _giftId);
        require(_from == ownerOf(_giftId));

         
        _transfer(_from, _to, _giftId);
         
        delete ownerToApprovedAddsToGifIds[_from][_to];
    }
    
     
    function giftsOfOwner(address _owner)  public view returns (uint256[] ownerGifts) {
        
        uint256 giftCount = balanceOf(_owner);
        if (giftCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](giftCount);
            uint256 total = totalSupply();
            uint256 resultIndex = 0;

            uint256 giftId;
            
            for (giftId = 0; giftId <= total; giftId++) {
                if (giftIndexToOwners[giftId] == _owner) {
                    result[resultIndex] = giftId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
     
     
    function withdrawGTO() 
    onlyOwner 
    public { 
        Gifto.transfer(defaultGiftOwner, Gifto.balanceOf(address(this))); 
    }
    
    function withdraw()
    onlyOwner
    public
    returns (bool){
        return defaultGiftOwner.send(this.balance);
    }
}