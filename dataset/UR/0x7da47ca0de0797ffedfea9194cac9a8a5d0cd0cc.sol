 

pragma solidity ^0.4.13;

interface ERC721Metadata {

     
     
     
     
     

     
     
     
    function name() external pure returns (string _name);

     
     
    function symbol() external pure returns (string _symbol);

     
     
    function deedName(uint256 _deedId) external pure returns (string _deedName);

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function deedUri(uint256 _deedId) external view returns (string _deedUri);
}

contract ReentrancyGuard {

   
  bool private reentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
  }

}

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
     
     
     
    return a / b;
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

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

interface ERC721 {

     

     
     
     

     
     
     
     
     
     
     
     

     
     
     
     
    function supportsInterface(bytes4 _interfaceID) external pure returns (bool);

     

     
     
     
     
     
     
    function ownerOf(uint256 _deedId) external view returns (address _owner);

     
     
     
    function countOfDeeds() external view returns (uint256 _count);

     
     
     
     
    function countOfDeedsByOwner(address _owner) external view returns (uint256 _count);

     
     
     
     
     
     
     
    function deedOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _deedId);

     

     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _deedId);

     
     
     
     
     
     
     
     
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _deedId);

     
     
     
     
     
     
     
    function approve(address _to, uint256 _deedId) external payable;

     
     
     
     
     
    function takeOwnership(uint256 _deedId) external payable;
}

contract ERC721Deed is ERC721 {
  using SafeMath for uint256;

   
  uint256 private totalDeeds;

   
  mapping (uint256 => address) private deedOwner;

   
  mapping (uint256 => address) private deedApprovedFor;

   
  mapping (address => uint256[]) private ownedDeeds;

   
  mapping(uint256 => uint256) private ownedDeedsIndex;

   
  modifier onlyOwnerOf(uint256 _deedId) {
    require(deedOwner[_deedId] == msg.sender);
    _;
  }

   
  function ownerOf(uint256 _deedId)
  external view returns (address _owner) {
    require(deedOwner[_deedId] != address(0));
    _owner = deedOwner[_deedId];
  }

   
  function countOfDeeds()
  external view returns (uint256) {
    return totalDeeds;
  }

   
  function countOfDeedsByOwner(address _owner)
  external view returns (uint256 _count) {
    require(_owner != address(0));
    _count = ownedDeeds[_owner].length;
  }

   
  function deedOfOwnerByIndex(address _owner, uint256 _index)
  external view returns (uint256 _deedId) {
    require(_owner != address(0));
    require(_index < ownedDeeds[_owner].length);
    _deedId = ownedDeeds[_owner][_index];
  }

   
  function deedsOf(address _owner)
  external view returns (uint256[] _ownedDeedIds) {
    require(_owner != address(0));
    _ownedDeedIds = ownedDeeds[_owner];
  }

   
  function approve(address _to, uint256 _deedId)
  external onlyOwnerOf(_deedId) payable {
    require(msg.value == 0);
    require(_to != msg.sender);
    if(_to != address(0) || approvedFor(_deedId) != address(0)) {
      emit Approval(msg.sender, _to, _deedId);
    }
    deedApprovedFor[_deedId] = _to;
  }

   
  function takeOwnership(uint256 _deedId)
  external payable {
    require(approvedFor(_deedId) == msg.sender);
    clearApprovalAndTransfer(deedOwner[_deedId], msg.sender, _deedId);
  }

   
  function approvedFor(uint256 _deedId)
  public view returns (address) {
    return deedApprovedFor[_deedId];
  }

   
  function transfer(address _to, uint256 _deedId)
  public onlyOwnerOf(_deedId) {
    clearApprovalAndTransfer(msg.sender, _to, _deedId);
  }

   
  function _mint(address _to, uint256 _deedId)
  internal {
    require(_to != address(0));
    addDeed(_to, _deedId);
    emit Transfer(0x0, _to, _deedId);
  }

   
   
   
   
   
   
   
   
   

   
  function clearApprovalAndTransfer(address _from, address _to, uint256 _deedId)
  internal {
    require(_to != address(0));
    require(_to != _from);
    require(deedOwner[_deedId] == _from);

    clearApproval(_from, _deedId);
    removeDeed(_from, _deedId);
    addDeed(_to, _deedId);
    emit Transfer(_from, _to, _deedId);
  }

   
  function clearApproval(address _owner, uint256 _deedId)
  private {
    require(deedOwner[_deedId] == _owner);
    deedApprovedFor[_deedId] = 0;
    emit Approval(_owner, 0, _deedId);
  }

   
  function addDeed(address _to, uint256 _deedId)
  private {
    require(deedOwner[_deedId] == address(0));
    deedOwner[_deedId] = _to;
    uint256 length = ownedDeeds[_to].length;
    ownedDeeds[_to].push(_deedId);
    ownedDeedsIndex[_deedId] = length;
    totalDeeds = totalDeeds.add(1);
  }

   
  function removeDeed(address _from, uint256 _deedId)
  private {
    require(deedOwner[_deedId] == _from);

    uint256 deedIndex = ownedDeedsIndex[_deedId];
    uint256 lastDeedIndex = ownedDeeds[_from].length.sub(1);
    uint256 lastDeed = ownedDeeds[_from][lastDeedIndex];

    deedOwner[_deedId] = 0;
    ownedDeeds[_from][deedIndex] = lastDeed;
    ownedDeeds[_from][lastDeedIndex] = 0;
     
     
     

    ownedDeeds[_from].length--;
    ownedDeedsIndex[_deedId] = 0;
    ownedDeedsIndex[lastDeed] = deedIndex;
    totalDeeds = totalDeeds.sub(1);
  }
}

contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

   
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(address(this).balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    payee.transfer(payment);
  }

   
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }
}

contract FactbarDeed is ERC721Deed, Pausable, PullPayment, ReentrancyGuard {

  using SafeMath for uint256;

   
   
  event Creation(uint256 indexed id, bytes32 indexed name, address factTeam);

   
   
  event Appropriation(uint256 indexed id, address indexed oldOwner, 
  address indexed newOwner, uint256 oldPrice, uint256 newPrice,
  uint256 transferFeeAmount, uint256 excess,  uint256 oldOwnerPaymentAmount );

   
  event Payment(uint256 indexed id, address indexed sender, address 
  indexed factTeam, uint256 amount);

   
   

   
  
  struct Factbar {
    bytes32 name;
    address factTeam;
    uint256 price;
    uint256 created;
  }

   
  mapping (uint256 => Factbar) private deeds;

   
  mapping (bytes32 => bool) private deedNameExists;

   
  uint256[] private deedIds;

   
  mapping (address => bool) private admins;

   

   
  uint256 private creationPrice = 0.0005 ether; 

   
  string public url = "https://fact-bar.org/facts/";

   
  bytes4 internal constant INTERFACE_SIGNATURE_ERC165 =  
      bytes4(keccak256('supportsInterface(bytes4)'));

  bytes4 internal constant INTERFACE_SIGNATURE_ERC721 =  
      bytes4(keccak256('ownerOf(uint256)')) ^
      bytes4(keccak256('countOfDeeds()')) ^
      bytes4(keccak256('countOfDeedsByOwner(address)')) ^
      bytes4(keccak256('deedOfOwnerByIndex(address,uint256)')) ^
      bytes4(keccak256('approve(address,uint256)')) ^
      bytes4(keccak256('takeOwnership(uint256)'));

  bytes4 internal constant INTERFACE_SIGNATURE_ERC721Metadata =  
      bytes4(keccak256('name()')) ^
      bytes4(keccak256('symbol()')) ^
      bytes4(keccak256('deedUri(uint256)'));


  function FactbarDeed() public {}

   
  function() public {}

  modifier onlyExistingNames(uint256 _deedId) {
    require(deedNameExists[deeds[_deedId].name]);
    _;
  }

  modifier noExistingNames(bytes32 _name) {
    require(!deedNameExists[_name]);
    _;
  }
  
  modifier onlyAdmins() {
    require(admins[msg.sender]);
    _;
  }


    

  function name()
  external pure returns (string) {
    return "Factbar";
  }

  function symbol()
  external pure returns (string) {
    return "FTBR";
  }

  function supportsInterface(bytes4 _interfaceID)
  external pure returns (bool) {
    return (
      _interfaceID == INTERFACE_SIGNATURE_ERC165
      || _interfaceID == INTERFACE_SIGNATURE_ERC721
      || _interfaceID == INTERFACE_SIGNATURE_ERC721Metadata
    );
  }

  function deedUri(uint256 _deedId)
  external view onlyExistingNames(_deedId) returns (string _uri) {
    _uri = _strConcat(url, _bytes32ToString(deeds[_deedId].name));
  }

  function deedName(uint256 _deedId)
  external view onlyExistingNames(_deedId) returns (string _name) {
    _name = _bytes32ToString(deeds[_deedId].name);
  }


   
  function getPendingPaymentAmount(address _account)
  external view returns (uint256 _balance) {
     uint256 payment = payments[_account];
    _balance = payment;
  }

   
  function getDeedIds()
  external view returns (uint256[]) {
    return deedIds;
  }
 
   
  function nextPriceOf (uint256 _deedId) public view returns (uint256 _nextPrice) {
    return calculateNextPrice(priceOf(_deedId));
  }

  uint256 private increaseLimit1 = 0.02 ether;
  uint256 private increaseLimit2 = 0.5 ether;
  uint256 private increaseLimit3 = 2.0 ether;
  uint256 private increaseLimit4 = 5.0 ether;

  function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
    if (_price < increaseLimit1) {
      return _price.mul(200).div(100);
    } else if (_price < increaseLimit2) {
      return _price.mul(135).div(100);
    } else if (_price < increaseLimit3) {
      return _price.mul(125).div(100);
    } else if (_price < increaseLimit4) {
      return _price.mul(117).div(100);
    } else {
      return _price.mul(115).div(100);
    }
  }

  function calculateTransferFee (uint256 _price) public view returns (uint256 _devCut) {
    if (_price < increaseLimit1) {
      return _price.mul(5).div(100);  
    } else if (_price < increaseLimit2) {
      return _price.mul(4).div(100);  
    } else if (_price < increaseLimit3) {
      return _price.mul(3).div(100);  
    } else if (_price < increaseLimit4) {
      return _price.mul(3).div(100);  
    } else {
      return _price.mul(3).div(100);  
    }
  }


   
   
  function appropriate(uint256 _deedId)
  external whenNotPaused nonReentrant payable {

     
    uint256 price = priceOf(_deedId);

      
    address oldOwner = this.ownerOf(_deedId);
    address newOwner = msg.sender;
    require(oldOwner != newOwner);
    
     
    require(priceOf(_deedId) > 0); 
    
     
    require(msg.value >= price); 

     
    uint256 excess = msg.value.sub(price);

     
    clearApprovalAndTransfer(oldOwner, newOwner, _deedId);
    uint256 nextPrice = nextPriceOf(_deedId);
    deeds[_deedId].price = nextPrice;
    
     
    uint256 transferFee = calculateTransferFee(price);

     
    uint256 oldOwnerPayment = price.sub(transferFee);

     
    asyncSend(factTeamOf(_deedId), transferFee);
    asyncSend(oldOwner, oldOwnerPayment);

    if (excess > 0) {
       asyncSend(newOwner, excess);
    }

    emit Appropriation(_deedId, oldOwner, newOwner, price, nextPrice,
    transferFee, excess, oldOwnerPayment);
  }

   
   
   

   
  function pay(uint256 _deedId)
  external nonReentrant payable {
    address factTeam = factTeamOf(_deedId);
    asyncSend(factTeam, msg.value);
    emit Payment(_deedId, msg.sender, factTeam, msg.value);
  }

   
  function withdraw()
  external nonReentrant {
    withdrawPayments();
    if (msg.sender == owner) {
       
       
      uint256 surplus = address(this).balance.sub(totalPayments);
      if (surplus > 0) {
        owner.transfer(surplus);
      }
    }
  }

   

   
   
   
  function create(bytes32 _name, address _factTeam)
  public onlyAdmins noExistingNames(_name) {
    deedNameExists[_name] = true;
    uint256 deedId = deedIds.length;
    deedIds.push(deedId);
    super._mint(owner, deedId);
    deeds[deedId] = Factbar({
      name: _name,
      factTeam: _factTeam,
      price: creationPrice,
      created: now
       
    });
    emit Creation(deedId, _name, owner);
  }

   

  function addAdmin(address _admin)  
  public onlyOwner{
    admins[_admin] = true;
  }

  function removeAdmin (address _admin)  
  public onlyOwner{
    delete admins[_admin];
  }

   

  function setCreationPrice(uint256 _price)
  public onlyOwner {
    creationPrice = _price;
  }

  function setUrl(string _url)
  public onlyOwner {
    url = _url;
  }

   

   
  function priceOf(uint256 _deedId)
  public view returns (uint256 _price) {
    _price = deeds[_deedId].price;
  }

   
  function factTeamOf(uint256 _deedId)
  public view returns (address _factTeam) {
    _factTeam = deeds[_deedId].factTeam;
  }


           

  function _bytes32ToString(bytes32 _bytes32)
  private pure returns (string) {
    bytes memory bytesString = new bytes(32);
    uint charCount = 0;
    for (uint j = 0; j < 32; j++) {
      byte char = byte(bytes32(uint(_bytes32) * 2 ** (8 * j)));
      if (char != 0) {
        bytesString[charCount] = char;
        charCount++;
      }
    }
    bytes memory bytesStringTrimmed = new bytes(charCount);
    for (j = 0; j < charCount; j++) {
      bytesStringTrimmed[j] = bytesString[j];
    }

    return string(bytesStringTrimmed);
  }

  function _strConcat(string _a, string _b)
  private pure returns (string) {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    string memory ab = new string(_ba.length + _bb.length);
    bytes memory bab = bytes(ab);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
    for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
    return string(bab);
  }

}

 
 
 

 
 
 
 
 
 
 
 
 

 
 

 
 
 
 
 
 
 