 

pragma solidity ^0.4.25;

   
    library SafeMath {
    
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) {
        return 0;
      }
      uint256 c = a * b;
      assert(c / a == b);
      return c;
    }
    
     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
       
      uint256 c = a / b;
       
      return c;
    }
    
     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}
    
    
     
     
    contract ERC721 {
    function totalSupply() external view returns (uint256 total);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function ownerOf(string _diamondId) public view returns (address owner);
    function approve(address _to, string _diamondId) external;
    function transfer(address _to, string _diamondId) external;
    function transferFrom(address _from, address _to, string _diamondId) external;
    
     
    event Transfer(address indexed from, address indexed to, string indexed diamondId);
    event Approval(address indexed owner, address indexed approved, string indexed diamondId);
    }
    
    contract DiamondAccessControl {
    
    address public CEO;
    
    mapping (address => bool) public admins;
    
    bool public paused = false;
    
    modifier onlyCEO() {
      require(msg.sender == CEO);
      _;
    }
    
    modifier onlyAdmin() {
      require(admins[msg.sender]);
      _;
    }
    
     
    
     
    modifier whenNotPaused() {
      require(!paused);
      _;
    }
    
    modifier onlyAdminOrCEO() 
{      require(admins[msg.sender] || msg.sender == CEO);
      _;
    }
    
     
    modifier whenPaused {
      require(paused);
      _;
    }
    
    function setCEO(address _newCEO) external onlyCEO {
      require(_newCEO != address(0));
      CEO = _newCEO;
    }
    
    function setAdmin(address _newAdmin, bool isAdmin) external onlyCEO {
      require(_newAdmin != address(0));
      admins[_newAdmin] = isAdmin;
    }
    
     
     
    function pause() external onlyAdminOrCEO whenNotPaused {
      paused = true;
    }
    
     
     
     
     
     
    function unpause() external onlyCEO whenPaused {
       
      paused = false;
    }
}
    
 
 
 
contract DiamondBase is DiamondAccessControl {
    
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, string indexed diamondId);
    event TransactionHistory(  
      string indexed _diamondId, 
      address indexed _seller, 
      string _sellerId, 
      address indexed _buyer, 
      string _buyerId, 
      uint256 _usdPrice, 
      uint256 _cedexPrice,
      uint256 timestamp
    );
    
     
     
    struct Diamond {
      string ownerId;
      string status;
      string gemCompositeScore;
      string gemSubcategory;
      string media;
      string custodian;
      uint256 arrivalTime;
    }
    
     
    uint256 internal total;
    
     
    mapping(string => bool) internal diamondExists;
    
     
    mapping(address => uint) internal balances;
    
     
    mapping (string => address) internal diamondIdToOwner;
    
     
    mapping(string => Diamond) internal diamondIdToMetadata;
    
     
    mapping(string => address) internal diamondIdToApproved;
    
     
    string constant STATUS_PENDING = "Pending";
    string constant STATUS_VERIFIED = "Verified";
    string constant STATUS_OUTSIDE  = "Outside";

    function _createDiamond(
      string _diamondId, 
      address _owner, 
      string _ownerId, 
      string _gemCompositeScore, 
      string _gemSubcategory, 
      string _media
    )  
      internal 
    {
      Diamond memory diamond;
      
      diamond.status = "Pending";
      diamond.ownerId = _ownerId;
      diamond.gemCompositeScore = _gemCompositeScore;
      diamond.gemSubcategory = _gemSubcategory;
      diamond.media = _media;
      
      diamondIdToMetadata[_diamondId] = diamond;
    
      _transfer(address(0), _owner, _diamondId);
      total = total.add(1);
      diamondExists[_diamondId] = true; 
    }
    
    function _transferInternal(
      string _diamondId, 
      address _seller, 
      string _sellerId, 
      address _buyer, 
      string _buyerId, 
      uint256 _usdPrice, 
      uint256 _cedexPrice
    )   
      internal 
    {
      Diamond storage diamond = diamondIdToMetadata[_diamondId];
      diamond.ownerId = _buyerId;
      _transfer(_seller, _buyer, _diamondId);   
      emit TransactionHistory(_diamondId, _seller, _sellerId, _buyer, _buyerId, _usdPrice, _cedexPrice, now);
    
    }
    
    function _transfer(address _from, address _to, string _diamondId) internal {
      if (_from != address(0)) {
          balances[_from] = balances[_from].sub(1);
      }
      balances[_to] = balances[_to].add(1);
      diamondIdToOwner[_diamondId] = _to;
      delete diamondIdToApproved[_diamondId];
      emit Transfer(_from, _to, _diamondId);
    }
    
    function _burn(string _diamondId) internal {
      address _from = diamondIdToOwner[_diamondId];
      balances[_from] = balances[_from].sub(1);
      total = total.sub(1);
      delete diamondIdToOwner[_diamondId];
      delete diamondIdToMetadata[_diamondId];
      delete diamondExists[_diamondId];
      delete diamondIdToApproved[_diamondId];
      emit Transfer(_from, address(0), _diamondId);
    }
    
    function _isDiamondOutside(string _diamondId) internal view returns (bool) {
      require(diamondExists[_diamondId]);
      return keccak256(diamondIdToMetadata[_diamondId].status) == keccak256(STATUS_OUTSIDE);
    }
    
    function _isDiamondVerified(string _diamondId) internal view returns (bool) {
      require(diamondExists[_diamondId]);
      return keccak256(diamondIdToMetadata[_diamondId].status) == keccak256(STATUS_VERIFIED);
    }
}
    
 
contract DiamondBase721 is DiamondBase, ERC721 {
    
    function totalSupply() external view returns (uint256) {
      return total;
    }
    
     
    function balanceOf(address _owner) external view returns (uint256) {
      return balances[_owner];
    
    }
    
     
    function ownerOf(string _diamondId) public view returns (address) {
      require(diamondExists[_diamondId]);
      return diamondIdToOwner[_diamondId];
    }
    
    function approve(address _to, string _diamondId) external whenNotPaused {
      require(_isDiamondOutside(_diamondId));
      require(msg.sender == ownerOf(_diamondId));
      diamondIdToApproved[_diamondId] = _to;
      emit Approval(msg.sender, _to, _diamondId);
    }
    
     
    function transfer(address _to, string _diamondId) external whenNotPaused {
      require(_isDiamondOutside(_diamondId));
      require(msg.sender == ownerOf(_diamondId));
      require(_to != address(0));
      require(_to != address(this));
      require(_to != ownerOf(_diamondId));
      _transfer(msg.sender, _to, _diamondId);
    }
    
    function transferFrom(address _from, address _to,  string _diamondId)
      external 
      whenNotPaused 
    {
      require(_isDiamondOutside(_diamondId));
      require(_from == ownerOf(_diamondId));
      require(_to != address(0));
      require(_to != address(this));
      require(_to != ownerOf(_diamondId));
      require(diamondIdToApproved[_diamondId] == msg.sender);
      _transfer(_from, _to, _diamondId);
    }
    
}
    
 
contract DiamondCore is DiamondBase721 {

     
    constructor() public {
       
      CEO = msg.sender;
    }
    
    function createDiamond(
      string _diamondId, 
      address _owner, 
      string _ownerId, 
      string _gemCompositeScore, 
      string _gemSubcategory, 
      string _media
    ) 
      external 
      onlyAdminOrCEO 
      whenNotPaused 
    {
      require(!diamondExists[_diamondId]);
      require(_owner != address(0));
      require(_owner != address(this));
      _createDiamond( 
          _diamondId, 
          _owner, 
          _ownerId, 
          _gemCompositeScore, 
          _gemSubcategory, 
          _media
      );
    }
    
    function updateDiamond(
      string _diamondId, 
      string _custodian, 
      uint256 _arrivalTime
    ) 
      external 
      onlyAdminOrCEO 
      whenNotPaused 
    {
      require(!_isDiamondOutside(_diamondId));
      
      Diamond storage diamond = diamondIdToMetadata[_diamondId];
      
      diamond.status = "Verified";
      diamond.custodian = _custodian;
      diamond.arrivalTime = _arrivalTime;
    }
    
    function transferInternal(
      string _diamondId, 
      address _seller, 
      string _sellerId, 
      address _buyer, 
      string _buyerId, 
      uint256 _usdPrice, 
      uint256 _cedexPrice
    ) 
      external 
      onlyAdminOrCEO                                                                                                                                                                                                                                              
      whenNotPaused 
    {
      require(_isDiamondVerified(_diamondId));
      require(_seller == ownerOf(_diamondId));
      require(_buyer != address(0));
      require(_buyer != address(this));
      require(_buyer != ownerOf(_diamondId));
      _transferInternal(_diamondId, _seller, _sellerId, _buyer, _buyerId, _usdPrice, _cedexPrice);
    }
    
    function burn(string _diamondId) external onlyAdminOrCEO whenNotPaused {
      require(!_isDiamondOutside(_diamondId));
      _burn(_diamondId);
    }
    
    function getDiamond(string _diamondId) 
        external
        view
        returns(
            string ownerId,
            string status,
            string gemCompositeScore,
            string gemSubcategory,
            string media,
            string custodian,
            uint256 arrivalTime
        )
    {
        require(diamondExists[_diamondId]);
        
         ownerId = diamondIdToMetadata[_diamondId].ownerId;
         status = diamondIdToMetadata[_diamondId].status;
         gemCompositeScore = diamondIdToMetadata[_diamondId].gemCompositeScore;
         gemSubcategory = diamondIdToMetadata[_diamondId].gemSubcategory;
         media = diamondIdToMetadata[_diamondId].media;
         custodian = diamondIdToMetadata[_diamondId].custodian;
         arrivalTime = diamondIdToMetadata[_diamondId].arrivalTime;
    }
}