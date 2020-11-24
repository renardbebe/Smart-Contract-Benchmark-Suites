 

 

pragma solidity ^0.4.24;


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

pragma solidity ^0.4.24;


 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

   
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

   
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

   
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

 

pragma solidity ^0.4.24;



 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

 

pragma solidity ^0.4.24;




 
contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

   
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

   
  function addAddressToWhitelist(address _operator)
    public
    onlyOwner
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

   
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

   
  function addAddressesToWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

   
  function removeAddressFromWhitelist(address _operator)
    public
    onlyOwner
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

   
  function removeAddressesFromWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}

 

pragma solidity ^0.4.24;



 
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 

pragma solidity ^0.4.24;


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

 
interface IKODAV2 {
  function mint(address _to, uint256 _editionNumber) external returns (uint256);

  function editionExists(uint256 _editionNumber) external returns (bool);

  function totalRemaining(uint256 _editionNumber) external view returns (uint256);

  function artistCommission(uint256 _editionNumber) external view returns (address _artistAccount, uint256 _artistCommission);

  function editionOptionalCommission(uint256 _editionNumber) external view returns (uint256 _rate, address _recipient);
}

 

pragma solidity 0.4.24;





 
interface IAuctionV2 {

  event BidPlaced(
    address indexed _bidder,
    uint256 indexed _editionNumber,
    uint256 _amount
  );

  event BidIncreased(
    address indexed _bidder,
    uint256 indexed _editionNumber,
    uint256 _amount
  );

  event BidWithdrawn(
    address indexed _bidder,
    uint256 indexed _editionNumber
  );

  event BidAccepted(
    address indexed _bidder,
    uint256 indexed _editionNumber,
    uint256 indexed _tokenId,
    uint256 _amount
  );

  event BidRejected(
    address indexed _caller,
    address indexed _bidder,
    uint256 indexed _editionNumber,
    uint256 _amount
  );

  event BidderRefunded(
    uint256 indexed _editionNumber,
    address indexed _bidder,
    uint256 _amount
  );

  event AuctionCancelled(
    uint256 indexed _editionNumber
  );

  event AuctionEnabled(
    uint256 indexed _editionNumber,
    address indexed _auctioneer
  );

  event AuctionDisabled(
    uint256 indexed _editionNumber,
    address indexed _auctioneer
  );

  function placeBid(uint256 _editionNumber) payable external returns (bool success);

  function increaseBid(uint256 _editionNumber) payable external returns (bool success);

  function withdrawBid(uint256 _editionNumber) external returns (bool success);

  function acceptBid(uint256 _editionNumber) external returns (uint256 tokenId);

  function rejectBid(uint256 _editionNumber) external returns (bool success);

  function cancelAuction(uint256 _editionNumber) external returns (bool success);
}

 
contract ArtistAcceptingBidsV2 is Whitelist, Pausable, IAuctionV2 {
  using SafeMath for uint256;

   
  mapping(uint256 => address) public editionNumberToArtistControlAddress;

   
  mapping(uint256 => bool) public enabledEditions;

   
  mapping(uint256 => address) public editionHighestBid;

   
  mapping(uint256 => mapping(address => uint256)) internal editionBids;

   
  uint256[] public editionsOnceEnabledForAuctions;

   
  uint256 public minBidAmount = 0.01 ether;

   
  IKODAV2 public kodaAddress;

   
  address public koCommissionAccount;

   
   
   

   
  modifier whenAuctionEnabled(uint256 _editionNumber) {
    require(enabledEditions[_editionNumber], "Edition is not enabled for auctions");
    _;
  }

   
  modifier whenCallerIsController(uint256 _editionNumber) {
    require(editionNumberToArtistControlAddress[_editionNumber] == msg.sender || whitelist(msg.sender), "Edition not managed by calling address");
    _;
  }

   
  modifier whenPlacedBidIsAboveMinAmount(uint256 _editionNumber) {
    address currentHighestBidder = editionHighestBid[_editionNumber];
    uint256 currentHighestBidderAmount = editionBids[_editionNumber][currentHighestBidder];
    require(currentHighestBidderAmount.add(minBidAmount) <= msg.value, "Bids must be higher than previous bids plus minimum bid");
    _;
  }

   
  modifier whenBidIncreaseIsAboveMinAmount() {
    require(minBidAmount <= msg.value, "Bids must be higher than minimum bid amount");
    _;
  }

   
  modifier whenCallerNotAlreadyTheHighestBidder(uint256 _editionNumber) {
    address currentHighestBidder = editionHighestBid[_editionNumber];
    require(currentHighestBidder != msg.sender, "Cant bid anymore, you are already the current highest");
    _;
  }

   
  modifier whenCallerIsHighestBidder(uint256 _editionNumber) {
    require(editionHighestBid[_editionNumber] == msg.sender, "Can only withdraw a bid if you are the highest bidder");
    _;
  }

   
  modifier whenEditionNotSoldOut(uint256 _editionNumber) {
    uint256 totalRemaining = kodaAddress.totalRemaining(_editionNumber);
    require(totalRemaining > 0, "Unable to accept any more bids, edition is sold out");
    _;
  }

   
  modifier whenEditionExists(uint256 _editionNumber) {
    bool editionExists = kodaAddress.editionExists(_editionNumber);
    require(editionExists, "Edition does not exist");
    _;
  }

   
   
   

   
  constructor(IKODAV2 _kodaAddress) public {
    kodaAddress = _kodaAddress;
    koCommissionAccount = msg.sender;
    super.addAddressToWhitelist(msg.sender);
  }

   
   
   

   
  function placeBid(uint256 _editionNumber)
  public
  payable
  whenNotPaused
  whenEditionExists(_editionNumber)
  whenAuctionEnabled(_editionNumber)
  whenPlacedBidIsAboveMinAmount(_editionNumber)
  whenCallerNotAlreadyTheHighestBidder(_editionNumber)
  whenEditionNotSoldOut(_editionNumber)
  returns (bool success)
  {
     
    _refundHighestBidder(_editionNumber);

     
    editionBids[_editionNumber][msg.sender] = msg.value;

     
    editionHighestBid[_editionNumber] = msg.sender;

     
    emit BidPlaced(msg.sender, _editionNumber, msg.value);

    return true;
  }

   
  function increaseBid(uint256 _editionNumber)
  public
  payable
  whenNotPaused
  whenBidIncreaseIsAboveMinAmount
  whenEditionExists(_editionNumber)
  whenAuctionEnabled(_editionNumber)
  whenEditionNotSoldOut(_editionNumber)
  whenCallerIsHighestBidder(_editionNumber)
  returns (bool success)
  {
     
    editionBids[_editionNumber][msg.sender] = editionBids[_editionNumber][msg.sender].add(msg.value);

     
    emit BidIncreased(msg.sender, _editionNumber, editionBids[_editionNumber][msg.sender]);

    return true;
  }

   
  function withdrawBid(uint256 _editionNumber)
  public
  whenNotPaused
  whenEditionExists(_editionNumber)
  whenCallerIsHighestBidder(_editionNumber)
  returns (bool success)
  {
     
    _refundHighestBidder(_editionNumber);

     
    emit BidWithdrawn(msg.sender, _editionNumber);

    return true;
  }

   
  function cancelAuction(uint256 _editionNumber)
  public
  onlyIfWhitelisted(msg.sender)
  whenEditionExists(_editionNumber)
  returns (bool success)
  {
     
    _refundHighestBidder(_editionNumber);

     
    enabledEditions[_editionNumber] = false;

     
    emit AuctionCancelled(_editionNumber);

    return true;
  }

   
  function rejectBid(uint256 _editionNumber)
  public
  whenNotPaused
  whenEditionExists(_editionNumber)
  whenCallerIsController(_editionNumber)  
  whenAuctionEnabled(_editionNumber)  
  returns (bool success)
  {
    address rejectedBidder = editionHighestBid[_editionNumber];
    uint256 rejectedBidAmount = editionBids[_editionNumber][rejectedBidder];

     
    _refundHighestBidder(_editionNumber);

    emit BidRejected(msg.sender, rejectedBidder, _editionNumber, rejectedBidAmount);

    return true;
  }

   
  function acceptBid(uint256 _editionNumber)
  public
  whenNotPaused
  whenCallerIsController(_editionNumber)  
  whenAuctionEnabled(_editionNumber)  
  returns (uint256 tokenId)
  {
     
    uint256 totalRemaining = kodaAddress.totalRemaining(_editionNumber);
    require(totalRemaining > 0, "Unable to accept bid, edition is sold out");

     
    address winningAccount = editionHighestBid[_editionNumber];
    require(winningAccount != address(0), "Cannot win an auction when there is no highest bidder");

    uint256 winningBidAmount = editionBids[_editionNumber][winningAccount];
    require(winningBidAmount >= 0, "Cannot win an auction when no bid amount set");

     
    uint256 _tokenId = kodaAddress.mint(winningAccount, _editionNumber);
    require(_tokenId != 0, "Failed to mint new token");

     
    _handleFunds(_editionNumber, winningBidAmount);

     
    delete editionHighestBid[_editionNumber];

     
    if (totalRemaining.sub(1) == 0) {
      enabledEditions[_editionNumber] = false;
    }

     
    emit BidAccepted(winningAccount, _editionNumber, _tokenId, winningBidAmount);

    return _tokenId;
  }

   
  function _handleFunds(uint256 _editionNumber, uint256 _winningBidAmount) internal {

     
    (address artistAccount, uint256 artistCommission) = kodaAddress.artistCommission(_editionNumber);

     
    uint256 artistPayment = _winningBidAmount.div(100).mul(artistCommission);
    artistAccount.transfer(artistPayment);

     
    (uint256 optionalCommissionRate, address optionalCommissionRecipient) = kodaAddress.editionOptionalCommission(_editionNumber);

     
    if (optionalCommissionRate > 0) {
      uint256 rateSplit = _winningBidAmount.div(100).mul(optionalCommissionRate);
      optionalCommissionRecipient.transfer(rateSplit);
    }

     
    uint256 remainingCommission = _winningBidAmount.sub(artistPayment).sub(rateSplit);
    koCommissionAccount.transfer(remainingCommission);
  }

   
  function _refundHighestBidder(uint256 _editionNumber) internal {
     
    address currentHighestBidder = editionHighestBid[_editionNumber];

     
    uint256 currentHighestBiddersAmount = editionBids[_editionNumber][currentHighestBidder];

    if (currentHighestBidder != address(0) && currentHighestBiddersAmount > 0) {

       
      delete editionHighestBid[_editionNumber];

       
      currentHighestBidder.transfer(currentHighestBiddersAmount);

       
      emit BidderRefunded(_editionNumber, currentHighestBidder, currentHighestBiddersAmount);
    }
  }

   
   
   

   
  function enableEditionForArtist(uint256 _editionNumber)
  public
  whenNotPaused
  whenEditionExists(_editionNumber)
  returns (bool)
  {
     
    (address artistAccount, uint256 artistCommission) = kodaAddress.artistCommission(_editionNumber);
    require(whitelist(msg.sender) || msg.sender == artistAccount, "Cannot enable when not the edition artist");

     
    require(!enabledEditions[_editionNumber], "Edition already enabled");

     
    enabledEditions[_editionNumber] = true;

     
    editionsOnceEnabledForAuctions.push(_editionNumber);

     
    editionNumberToArtistControlAddress[_editionNumber] = artistAccount;

    emit AuctionEnabled(_editionNumber, msg.sender);

    return true;
  }

   
  function enableEdition(uint256 _editionNumber)
  onlyIfWhitelisted(msg.sender)
  public returns (bool) {
    enabledEditions[_editionNumber] = true;
    emit AuctionEnabled(_editionNumber, msg.sender);
    return true;
  }

   
  function disableEdition(uint256 _editionNumber)
  onlyIfWhitelisted(msg.sender)
  public returns (bool) {
    enabledEditions[_editionNumber] = false;
    emit AuctionDisabled(_editionNumber, msg.sender);
    return true;
  }

   
  function setArtistsControlAddress(uint256 _editionNumber, address _address)
  onlyIfWhitelisted(msg.sender)
  public returns (bool) {
    editionNumberToArtistControlAddress[_editionNumber] = _address;
    return true;
  }

   
  function setArtistsControlAddressAndEnabledEdition(uint256 _editionNumber, address _address)
  onlyIfWhitelisted(msg.sender)
  public returns (bool) {
    require(!enabledEditions[_editionNumber], "Edition already enabled");

     
    enabledEditions[_editionNumber] = true;

     
    editionNumberToArtistControlAddress[_editionNumber] = _address;

     
    editionsOnceEnabledForAuctions.push(_editionNumber);

    emit AuctionEnabled(_editionNumber, _address);

    return true;
  }

   
  function setMinBidAmount(uint256 _minBidAmount) onlyIfWhitelisted(msg.sender) public {
    minBidAmount = _minBidAmount;
  }

   
  function setKodavV2(IKODAV2 _kodaAddress) onlyIfWhitelisted(msg.sender) public {
    kodaAddress = _kodaAddress;
  }

   
  function setKoCommissionAccount(address _koCommissionAccount) public onlyIfWhitelisted(msg.sender) {
    require(_koCommissionAccount != address(0), "Invalid address");
    koCommissionAccount = _koCommissionAccount;
  }

   
   
   

   
  function withdrawStuckEther(address _withdrawalAccount)
  onlyIfWhitelisted(msg.sender)
  public {
    require(_withdrawalAccount != address(0), "Invalid address provided");
    require(address(this).balance != 0, "No more ether to withdraw");
    _withdrawalAccount.transfer(address(this).balance);
  }

   
  function withdrawStuckEtherOfAmount(address _withdrawalAccount, uint256 _amount)
  onlyIfWhitelisted(msg.sender)
  public {
    require(_withdrawalAccount != address(0), "Invalid address provided");
    require(_amount != 0, "Invalid amount to withdraw");
    require(address(this).balance >= _amount, "No more ether to withdraw");
    _withdrawalAccount.transfer(_amount);
  }

   
  function manualOverrideEditionHighestBidAndBidder(uint256 _editionNumber, address _bidder, uint256 _amount)
  onlyIfWhitelisted(msg.sender)
  public returns (bool) {
    editionBids[_editionNumber][_bidder] = _amount;
    editionHighestBid[_editionNumber] = _bidder;
    return true;
  }

   
  function manualDeleteEditionBids(uint256 _editionNumber, address _bidder)
  onlyIfWhitelisted(msg.sender)
  public returns (bool) {
    delete editionHighestBid[_editionNumber];
    delete editionBids[_editionNumber][_bidder];
    return true;
  }

   
   
   

   
  function auctionDetails(uint256 _editionNumber) public view returns (bool _enabled, address _bidder, uint256 _value, address _controller) {
    address highestBidder = editionHighestBid[_editionNumber];
    uint256 bidValue = editionBids[_editionNumber][highestBidder];
    address controlAddress = editionNumberToArtistControlAddress[_editionNumber];
    return (
    enabledEditions[_editionNumber],
    highestBidder,
    bidValue,
    controlAddress
    );
  }

   
  function highestBidForEdition(uint256 _editionNumber) public view returns (address _bidder, uint256 _value) {
    address highestBidder = editionHighestBid[_editionNumber];
    uint256 bidValue = editionBids[_editionNumber][highestBidder];
    return (highestBidder, bidValue);
  }

   
  function isEditionEnabled(uint256 _editionNumber) public view returns (bool) {
    return enabledEditions[_editionNumber];
  }

   
  function editionController(uint256 _editionNumber) public view returns (address) {
    return editionNumberToArtistControlAddress[_editionNumber];
  }

   
  function addedEditions() public view returns (uint256[]) {
    return editionsOnceEnabledForAuctions;
  }

}