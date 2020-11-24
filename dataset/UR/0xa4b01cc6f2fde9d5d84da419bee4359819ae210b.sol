 

pragma solidity ^0.4.18;

contract ERC721 {
     
     
     
     
    function totalSupply() public constant returns (uint256);
    function balanceOf(address _owner) public constant returns (uint balance);
    function ownerOf(uint256 _tokenId) public constant returns (address owner);
    function approve(address _to, uint256 _tokenId) public ;
    function allowance(address _owner, address _spender) public constant returns (uint256 tokenId);
    function transfer(address _to, uint256 _tokenId) external ;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    
     
     
     
     
    
     
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
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

contract VirtualGift is ERC721 {
    
     
    ERC20 GTO = ERC20(0x00C5bBaE50781Be1669306b9e001EFF57a2957b09d);
    
     
    struct Gift {
         
        uint256 price;
         
        string description;
    }
    
    address public owner;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _GiftId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _GiftId);
    event Creation(address indexed _owner, uint256 indexed GiftId);
    
    string public constant name = "VirtualGift";
    string public constant symbol = "VTG";
    
     
    Gift[] giftStorage;
    
     
    mapping(address => uint256) private balances;
    
     
    mapping(uint256 => address) private GiftIndexToOwners;
    
     
    mapping(uint256 => bool) private GiftExists;
    
     
    mapping(address => mapping (address => uint256)) private allowed;
    
     
    mapping(address => mapping(uint256 => uint256)) private ownerIndexToGifts;
    
     
    mapping(uint256 => string) GiftLinks;

    modifier onlyOwner(){
         require(msg.sender == owner);
         _;
    }

    modifier onlyGiftOwner(uint256 GiftId){
        require(msg.sender == GiftIndexToOwners[GiftId]);
        _;
    }
    
    modifier validGift(uint256 GiftId){
        require(GiftExists[GiftId]);
        _;
    }

     
    function VirtualGift()
    public{
        owner = msg.sender;
         
        Gift memory newGift = Gift({
            price: 0,
            description: "MYTHICAL"
        });
         
        uint256 mythicalGift = giftStorage.push(newGift) - 1;  
         
        GiftExists[mythicalGift] = false;
         
        GiftLinks[mythicalGift] = "mythicalGift";
         
         
        _transfer(0, msg.sender, mythicalGift);
         
        Creation(msg.sender, mythicalGift);
    }
    
     
     
     
    function changeGTOAddress(address newAddress)
    public
    onlyOwner{
        GTO = ERC20(newAddress);
    }
    
     
    function getGTOAddress()
    public
    constant
    returns (address) {
        return address(GTO);
    }
    
     
     
    function totalSupply()
    public 
    constant
    returns (uint256){
         
        return giftStorage.length - 1;
    }
    
     
     
    function buy(uint256 GiftId) 
    validGift(GiftId)
    public {
         
        address oldowner = ownerOf(GiftId);
         
         
        require(GTO.transferFrom(msg.sender, oldowner, giftStorage[GiftId].price) == true);
         
         
        _transfer(oldowner, msg.sender, GiftId);
    }
    
     
     
     
    function sendGift(address recipient, uint256 GiftId)
    onlyGiftOwner(GiftId)
    validGift(GiftId)
    public {
         
         
         
        _transfer(msg.sender, recipient, GiftId);
    }
    
     
     
     
    function balanceOf(address _owner) 
    public 
    constant 
    returns (uint256 balance){
        return balances[_owner];
    }
    
    function isExist(uint256 GiftId)
    public
    constant
    returns(bool){
        return GiftExists[GiftId];
    }
    
     
     
     
    function ownerOf(uint256 _GiftId)
    public
    constant 
    returns (address _owner) {
        require(GiftExists[_GiftId]);
        return GiftIndexToOwners[_GiftId];
    }
    
     
     
     
    function approve(address _to, uint256 _GiftId)
    validGift(_GiftId)
    public {
        require(msg.sender == ownerOf(_GiftId));
        require(msg.sender != _to);
        
        allowed[msg.sender][_to] = _GiftId;
        Approval(msg.sender, _to, _GiftId);
    }
    
     
     
     
     
    function allowance(address _owner, address _spender) 
    public 
    constant 
    returns (uint256 GiftId) {
        return allowed[_owner][_spender];
    }
    
     
     
    function takeOwnership(uint256 _GiftId)
    validGift(_GiftId)
    public {
         
        address oldOwner = ownerOf(_GiftId);
         
        address newOwner = msg.sender;
        
        require(newOwner != oldOwner);
         
        require(allowed[oldOwner][newOwner] == _GiftId);

         
        _transfer(oldOwner, newOwner, _GiftId);

         
        delete allowed[oldOwner][newOwner];

        Transfer(oldOwner, newOwner, _GiftId);
    }
    
     
     
     
     
    function _transfer(address _from, address _to, uint256 _GiftId) 
    internal {
         
        balances[_to]++;
         
        GiftIndexToOwners[_GiftId] = _to;
         
        if (_from != address(0)) {
            balances[_from]--;
        }
         
        Transfer(_from, _to, _GiftId);
    }
    
     
     
     
    function transfer(address _to, uint256 _GiftId)
    validGift(_GiftId)
    external {
         
        require(_to != 0x0);
         
        require(msg.sender != _to);
         
        require(msg.sender == ownerOf(_GiftId));
         
        require(_to != address(this));
        
        _transfer(msg.sender, _to, _GiftId);
    }
    
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _GiftId)
    validGift(_GiftId)
    external {
        require(_from == ownerOf(_GiftId));
         
        require(allowance(_from, msg.sender) == _GiftId);
         
        require(_from != _to);
        
         
        require(_to != address(0));
         
         
        require(_to != address(this));

         
        _transfer(_from, _to, _GiftId);
    }
    
     
     
     
     
     
    function GiftsOfOwner(address _owner) 
    public 
    view 
    returns(uint256[] ownerGifts) {
        
        uint256 GiftCount = balanceOf(_owner);
        if (GiftCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](GiftCount);
            uint256 total = totalSupply();
            uint256 resultIndex = 0;

             
             
            uint256 GiftId;
            
             
            for (GiftId = 0; GiftId <= total; GiftId++) {
                if (GiftIndexToOwners[GiftId] == _owner) {
                    result[resultIndex] = GiftId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
    
     
     
     
     
     
     
     
    function giftOwnerByIndex(address _owner, uint256 _index)
    external
    constant 
    returns (uint256 GiftId) {
        uint256[] memory ownerGifts = GiftsOfOwner(_owner);
        return ownerGifts[_index];
    }
    
     
     
     
    function GiftMetadata(uint256 _GiftId)
    public
    constant
    returns (string infoUrl) {
        return GiftLinks[_GiftId];
    }
    
     
     
     
     
    function createGift(uint256 _price, string _description, string _url)
    public
    onlyOwner
    returns (uint256) {
         
        Gift memory newGift = Gift({
            price: _price,
            description: _description
        });
         
        uint256 newGiftId = giftStorage.push(newGift) - 1;
         
        GiftExists[newGiftId] = true;
         
        GiftLinks[newGiftId] = _url;
         
        Creation(msg.sender, newGiftId);
        
         
         
        _transfer(0, msg.sender, newGiftId);
        
        return newGiftId;
    }
    
     
     
     
    function getGift(uint256 GiftId)
    public
    constant 
    returns (uint256, string){
        if(GiftId > giftStorage.length){
            return (0, "");
        }
        Gift memory newGift = giftStorage[GiftId];
        return (newGift.price, newGift.description);
    }
    
     
     
     
     
     
    function updateGift(uint256 GiftId, uint256 _price, string _description, string _giftUrl)
    public
    onlyOwner {
         
        require(GiftExists[GiftId]);
         
        giftStorage[GiftId].price = _price;
        giftStorage[GiftId].description = _description;
        GiftLinks[GiftId] = _giftUrl;
    }
    
     
     
    function removeGift(uint256 GiftId)
    public
    onlyOwner {
         
        GiftExists[GiftId] = false;
    }
    
     
    function withdrawGTO()
    onlyOwner
    public {
        GTO.transfer(owner, GTO.balanceOf(address(this)));
    }
    
}