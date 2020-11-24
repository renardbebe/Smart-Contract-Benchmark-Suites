 

pragma solidity 0.5.3;







 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


 
contract OwnableSecondary is Ownable {
  address private _primary;

  event PrimaryTransferred(
    address recipient
  );

   
  constructor() internal {
    _primary = msg.sender;
    emit PrimaryTransferred(_primary);
  }

   
   modifier onlyPrimaryOrOwner() {
     require(msg.sender == _primary || msg.sender == owner(), "not the primary user nor the owner");
     _;
   }

    
  modifier onlyPrimary() {
    require(msg.sender == _primary, "not the primary user");
    _;
  }

   
  function primary() public view returns (address) {
    return _primary;
  }

   
  function transferPrimary(address recipient) public onlyOwner {
    require(recipient != address(0), "new primary address is null");
    _primary = recipient;
    emit PrimaryTransferred(_primary);
  }
}


contract StatementRegisteryInterface is OwnableSecondary {
   
   
   
  function recordStatement(string calldata buildingPermitId, uint[] calldata statementDataLayout, bytes calldata statementData) external returns(bytes32);

   
   
   
  function statementIdsByBuildingPermit(string calldata id) external view returns(bytes32[] memory);

  function statementExists(bytes32 statementId) public view returns(bool);

  function getStatementString(bytes32 statementId, string memory key) public view returns(string memory);

  function getStatementPcId(bytes32 statementId) external view returns (string memory);

  function getStatementAcquisitionDate(bytes32 statementId) external view returns (string memory);

  function getStatementRecipient(bytes32 statementId) external view returns (string memory);

  function getStatementArchitect(bytes32 statementId) external view returns (string memory);

  function getStatementCityHall(bytes32 statementId) external view returns (string memory);

  function getStatementMaximumHeight(bytes32 statementId) external view returns (string memory);

  function getStatementDestination(bytes32 statementId) external view returns (string memory);

  function getStatementSiteArea(bytes32 statementId) external view returns (string memory);

  function getStatementBuildingArea(bytes32 statementId) external view returns (string memory);

  function getStatementNearImage(bytes32 statementId) external view returns(string memory);

  function getStatementFarImage(bytes32 statementId) external view returns(string memory);

  function getAllStatements() external view returns(bytes32[] memory);
}





contract OwnablePausable is Ownable {

  event Paused();
  event Unpaused();
  bool private _paused;

  constructor() internal {
    _paused = false;
    emit Unpaused();
  }

   
  function paused() public view returns (bool) {
      return _paused;
  }

   
  modifier whenNotPaused() {
      require(!_paused);
      _;
  }

   
  modifier whenPaused() {
      require(_paused);
      _;
  }

   
  function pause() public onlyOwner whenNotPaused {
      _paused = true;
      emit Paused();
  }

   
  function unpause() public onlyOwner whenPaused {
      _paused = false;
      emit Unpaused();
  }
}


contract Controller is OwnablePausable {
  StatementRegisteryInterface public registery;
  uint public price = 0;
  address payable private _wallet;
  address private _serverSide;

  event LogEvent(string content);
  event NewStatementEvent(string indexed buildingPermitId, bytes32 statementId);

   
   
   
  constructor(address registeryAddress, address payable walletAddr, address serverSideAddr) public {
    require(registeryAddress != address(0), "null registery address");
    require(walletAddr != address(0), "null wallet address");
    require(serverSideAddr != address(0), "null server side address");

    registery = StatementRegisteryInterface(registeryAddress);
    _wallet = walletAddr;
    _serverSide = serverSideAddr;
  }

   
  function setPrice(uint priceInWei) external whenNotPaused {
    require(msg.sender == owner() || msg.sender == _serverSide);

    price = priceInWei;
  }

  function setWallet(address payable addr) external onlyOwner whenNotPaused {
    require(addr != address(0), "null wallet address");

    _wallet = addr;
  }

  function setServerSide(address payable addr) external onlyOwner whenNotPaused {
    require(addr != address(0), "null server side address");

    _serverSide = addr;
  }

   
  function recordStatement(string calldata buildingPermitId, uint[] calldata statementDataLayout, bytes calldata statementData) external payable whenNotPaused returns(bytes32) {
      if(msg.sender != owner() && msg.sender != _serverSide) {
        require(msg.value >= price, "received insufficient value");

        uint refund = msg.value - price;

        _wallet.transfer(price);  

        if(refund > 0) {
          msg.sender.transfer(refund);  
        }
      }

      bytes32 statementId = registery.recordStatement(
        buildingPermitId,
        statementDataLayout,
        statementData
      );

      emit NewStatementEvent(buildingPermitId, statementId);

      return statementId;
  }

   
   
   
  function wallet() external view returns (address) {
    return _wallet;
  }

  function serverSide() external view returns (address) {
    return _serverSide;
  }

  function statementExists(bytes32 statementId) external view returns (bool) {
    return registery.statementExists(statementId);
  }

  function getStatementIdsByBuildingPermit(string calldata buildingPermitId) external view returns(bytes32[] memory) {
    return registery.statementIdsByBuildingPermit(buildingPermitId);
  }

  function getAllStatements() external view returns(bytes32[] memory) {
    return registery.getAllStatements();
  }

  function getStatementPcId(bytes32 statementId) external view returns (string memory) {
    return registery.getStatementPcId(statementId);
  }

  function getStatementAcquisitionDate(bytes32 statementId) external view returns (string memory) {
    return registery.getStatementAcquisitionDate(statementId);
  }

  function getStatementRecipient(bytes32 statementId) external view returns (string memory) {
    return registery.getStatementRecipient(statementId);
  }

  function getStatementArchitect(bytes32 statementId) external view returns (string memory) {
    return registery.getStatementArchitect(statementId);
  }

  function getStatementCityHall(bytes32 statementId) external view returns (string memory) {
    return registery.getStatementCityHall(statementId);
  }

  function getStatementMaximumHeight(bytes32 statementId) external view returns (string memory) {
    return registery.getStatementMaximumHeight(statementId);
  }

  function getStatementDestination(bytes32 statementId) external view returns (string memory) {
    return registery.getStatementDestination(statementId);
  }

  function getStatementSiteArea(bytes32 statementId) external view returns (string memory) {
    return registery.getStatementSiteArea(statementId);
  }

  function getStatementBuildingArea(bytes32 statementId) external view returns (string memory) {
    return registery.getStatementBuildingArea(statementId);
  }

  function getStatementNearImage(bytes32 statementId) external view returns(string memory) {
    return registery.getStatementNearImage(statementId);
  }

  function getStatementFarImage(bytes32 statementId) external view returns(string memory) {
    return registery.getStatementFarImage(statementId);
  }
}