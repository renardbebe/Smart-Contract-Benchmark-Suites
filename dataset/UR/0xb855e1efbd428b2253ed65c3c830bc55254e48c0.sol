 

pragma solidity ^0.4.24;

 

 

 
 
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

   
  function getFractionalAmount(uint256 _amount, uint256 _percentage)
  internal
  pure
  returns (uint256) {
    return div(mul(_amount, _percentage), 100);
  }

}

 

 
interface DBInterface {

  function setContractManager(address _contractManager)
  external;

     

    function setAddress(bytes32 _key, address _value)
    external;

    function setUint(bytes32 _key, uint _value)
    external;

    function setString(bytes32 _key, string _value)
    external;

    function setBytes(bytes32 _key, bytes _value)
    external;

    function setBytes32(bytes32 _key, bytes32 _value)
    external;

    function setBool(bytes32 _key, bool _value)
    external;

    function setInt(bytes32 _key, int _value)
    external;


      

    function deleteAddress(bytes32 _key)
    external;

    function deleteUint(bytes32 _key)
    external;

    function deleteString(bytes32 _key)
    external;

    function deleteBytes(bytes32 _key)
    external;

    function deleteBytes32(bytes32 _key)
    external;

    function deleteBool(bytes32 _key)
    external;

    function deleteInt(bytes32 _key)
    external;

     

    function uintStorage(bytes32 _key)
    external
    view
    returns (uint);

    function stringStorage(bytes32 _key)
    external
    view
    returns (string);

    function addressStorage(bytes32 _key)
    external
    view
    returns (address);

    function bytesStorage(bytes32 _key)
    external
    view
    returns (bytes);

    function bytes32Storage(bytes32 _key)
    external
    view
    returns (bytes32);

    function boolStorage(bytes32 _key)
    external
    view
    returns (bool);

    function intStorage(bytes32 _key)
    external
    view
    returns (bool);
}

 

contract Events {
  DBInterface public database;

  constructor(address _database) public{
    database = DBInterface(_database);
  }

  function message(string _message)
  external
  onlyApprovedContract {
      emit LogEvent(_message, keccak256(abi.encodePacked(_message)), tx.origin);
  }

  function transaction(string _message, address _from, address _to, uint _amount, address _token)
  external
  onlyApprovedContract {
      emit LogTransaction(_message, keccak256(abi.encodePacked(_message)), _from, _to, _amount, _token, tx.origin);
  }

  function registration(string _message, address _account)
  external
  onlyApprovedContract {
      emit LogAddress(_message, keccak256(abi.encodePacked(_message)), _account, tx.origin);
  }

  function contractChange(string _message, address _account, string _name)
  external
  onlyApprovedContract {
      emit LogContractChange(_message, keccak256(abi.encodePacked(_message)), _account, _name, tx.origin);
  }

  function asset(string _message, string _uri, address _assetAddress, address _manager)
  external
  onlyApprovedContract {
      emit LogAsset(_message, keccak256(abi.encodePacked(_message)), _uri, keccak256(abi.encodePacked(_uri)), _assetAddress, _manager, tx.origin);
  }

  function escrow(string _message, address _assetAddress, bytes32 _escrowID, address _manager, uint _amount)
  external
  onlyApprovedContract {
      emit LogEscrow(_message, keccak256(abi.encodePacked(_message)), _assetAddress, _escrowID, _manager, _amount, tx.origin);
  }

  function order(string _message, bytes32 _orderID, uint _amount, uint _price)
  external
  onlyApprovedContract {
      emit LogOrder(_message, keccak256(abi.encodePacked(_message)), _orderID, _amount, _price, tx.origin);
  }

  function exchange(string _message, bytes32 _orderID, address _assetAddress, address _account)
  external
  onlyApprovedContract {
      emit LogExchange(_message, keccak256(abi.encodePacked(_message)), _orderID, _assetAddress, _account, tx.origin);
  }

  function operator(string _message, bytes32 _id, string _name, string _ipfs, address _account)
  external
  onlyApprovedContract {
      emit LogOperator(_message, keccak256(abi.encodePacked(_message)), _id, _name, _ipfs, _account, tx.origin);
  }

  function consensus(string _message, bytes32 _executionID, bytes32 _votesID, uint _votes, uint _tokens, uint _quorum)
  external
  onlyApprovedContract {
    emit LogConsensus(_message, keccak256(abi.encodePacked(_message)), _executionID, _votesID, _votes, _tokens, _quorum, tx.origin);
  }

   
  event LogEvent(string message, bytes32 indexed messageID, address indexed origin);
  event LogTransaction(string message, bytes32 indexed messageID, address indexed from, address indexed to, uint amount, address token, address origin);  
  event LogAddress(string message, bytes32 indexed messageID, address indexed account, address indexed origin);
  event LogContractChange(string message, bytes32 indexed messageID, address indexed account, string name, address indexed origin);
  event LogAsset(string message, bytes32 indexed messageID, string uri, bytes32 indexed assetID, address asset, address manager, address indexed origin);
  event LogEscrow(string message, bytes32 indexed messageID, address asset, bytes32  escrowID, address indexed manager, uint amount, address indexed origin);
  event LogOrder(string message, bytes32 indexed messageID, bytes32 indexed orderID, uint amount, uint price, address indexed origin);
  event LogExchange(string message, bytes32 indexed messageID, bytes32 orderID, address indexed asset, address account, address indexed origin);
  event LogOperator(string message, bytes32 indexed messageID, bytes32 id, string name, string ipfs, address indexed account, address indexed origin);
  event LogConsensus(string message, bytes32 indexed messageID, bytes32 executionID, bytes32 votesID, uint votes, uint tokens, uint quorum, address indexed origin);


   
   
   
  modifier onlyApprovedContract() {
      require(database.boolStorage(keccak256(abi.encodePacked("contract", msg.sender))));
      _;
  }

}

 

 
interface KyberInterface {
  function getExpectedRate(address src, address dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
  function trade(address src, uint srcAmount, address dest, address destAddress, uint maxDestAmount,uint minConversionRate, address walletId) external payable returns(uint);
}

 

interface MinterInterface {
  function cloneToken(string _uri, address _erc20Address) external returns (address asset);

  function mintAssetTokens(address _assetAddress, address _receiver, uint256 _amount) external returns (bool);

  function changeTokenController(address _assetAddress, address _newController) external returns (bool);
}

 

interface CrowdsaleGeneratorERC20_ERC20 {
  function balanceOf(address _who) external view returns (uint256);
  function approve(address _spender, uint256 _value) external returns (bool);
  function transfer(address _to, uint256 _value) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

 
 
 
contract CrowdsaleGeneratorERC20 {
  using SafeMath for uint256;

  DBInterface private database;
  Events private events;
  KyberInterface private kyber;
  MinterInterface private minter;
   

   

   
   
  constructor(address _database, address _events, address _kyber)
  public{
      database = DBInterface(_database);
      events = Events(_events);
      kyber = KyberInterface(_kyber);
      minter = MinterInterface(database.addressStorage(keccak256(abi.encodePacked("contract", "Minter"))));
  }

   
   
   
   
   
   
   
   
  function createAssetOrderERC20(string _assetURI, string _ipfs, bytes32 _modelID, uint _fundingLength, uint _amountToRaise, uint _assetManagerPerc, uint _escrow, address _fundingToken, address _paymentToken)
  payable
  external
  {
    if(_paymentToken == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)){
      require(msg.value == _escrow);
    } else {
      require(msg.value == 0);
    }
    require(_amountToRaise >= 100, "Crowdsale goal is too small");
    require((_assetManagerPerc + database.uintStorage(keccak256(abi.encodePacked("platform.percentage")))) < 100, "Manager percent need to be less than 100");
    require(database.addressStorage(keccak256(abi.encodePacked("model.operator", _modelID))) != address(0), "Model not set");
    require(!database.boolStorage(keccak256(abi.encodePacked("asset.uri", _assetURI))), "Asset URI is not unique");  
    address assetAddress = minter.cloneToken(_assetURI, _fundingToken);
    require(setCrowdsaleValues(assetAddress, _fundingLength, _amountToRaise));
    require(setAssetValues(assetAddress, _assetURI, _ipfs, _modelID, msg.sender, _assetManagerPerc, _amountToRaise, _fundingToken));
    uint minEscrow = calculateEscrowERC20(_amountToRaise, msg.sender, _modelID, _fundingToken);
    require(lockEscrowERC20(msg.sender, assetAddress, _paymentToken, _fundingToken, _escrow, minEscrow));
    events.asset('Asset funding started', _assetURI, assetAddress, msg.sender);
    events.asset('New asset ipfs', _ipfs, assetAddress, msg.sender);
  }

  function updateIPFS(address _assetAddress, string _ipfs)
  external {
    require(msg.sender == database.addressStorage(keccak256(abi.encodePacked("asset.manager", _assetAddress))));
    database.setString(keccak256(abi.encodePacked("asset.ipfs", _assetAddress)), _ipfs);
    events.asset('New asset ipfs', _ipfs, _assetAddress, msg.sender);
  }

   
  function destroy()
  onlyOwner
  external {
    events.transaction('CrowdsaleGeneratorERC20 destroyed', address(this), msg.sender, address(this).balance, address(0));
    selfdestruct(msg.sender);
  }

   
   
   

  function setCrowdsaleValues(address _assetAddress, uint _fundingLength, uint _amountToRaise)
  private
  returns (bool){
    database.setUint(keccak256(abi.encodePacked("crowdsale.start", _assetAddress)), now);
    database.setUint(keccak256(abi.encodePacked("crowdsale.deadline", _assetAddress)), now.add(_fundingLength));
    database.setUint(keccak256(abi.encodePacked("crowdsale.goal", _assetAddress)), _amountToRaise);
    database.setUint(keccak256(abi.encodePacked("crowdsale.remaining", _assetAddress)), _amountToRaise.mul(uint(100).add(database.uintStorage(keccak256(abi.encodePacked("platform.fee"))))).div(100));
    return true;
  }

  function setAssetValues(address _assetAddress, string _assetURI, string _ipfs, bytes32 _modelID, address _assetManager, uint _assetManagerPerc, uint _amountToRaise, address _fundingToken)
  private
  returns (bool){
    uint totalTokens = _amountToRaise.mul(100).div(uint(100).sub(_assetManagerPerc).sub(database.uintStorage(keccak256(abi.encodePacked("platform.percentage")))));
     
    database.setUint(keccak256(abi.encodePacked("asset.managerTokens", _assetAddress)), totalTokens.getFractionalAmount(_assetManagerPerc));
    database.setUint(keccak256(abi.encodePacked("asset.platformTokens", _assetAddress)), totalTokens.getFractionalAmount(database.uintStorage(keccak256(abi.encodePacked("platform.percentage")))));
    database.setAddress(keccak256(abi.encodePacked("asset.manager", _assetAddress)), _assetManager);
    database.setBytes32(keccak256(abi.encodePacked("asset.modelID", _assetAddress)), _modelID);
    database.setString(keccak256(abi.encodePacked("asset.ipfs", _assetAddress)), _ipfs);
     
     
    database.setBool(keccak256(abi.encodePacked("asset.uri", _assetURI)), true);  
    return true;
  }

  function calculateEscrowERC20(uint _amount, address _manager, bytes32 _modelID, address _fundingToken)
  private
  view
  returns (uint){
    uint percent = database.uintStorage(keccak256(abi.encodePacked("collateral.base"))).add(database.uintStorage(keccak256(abi.encodePacked("collateral.level", database.uintStorage(keccak256(abi.encodePacked("manager.assets", _manager)))))));
    if(!database.boolStorage(keccak256(abi.encodePacked("model.payoutToken", _modelID, _fundingToken)))){
      percent = percent.mul(3);
    }
    if(!database.boolStorage(keccak256(abi.encodePacked("model.acceptsToken", _modelID, _fundingToken)))){
      percent = percent.add(100);
    }
    return _amount.getFractionalAmount(percent);
  }

  function lockEscrowERC20(address _assetManager, address _assetAddress, address _paymentTokenAddress, address _fundingTokenAddress, uint _amount, uint _min)
  private
  returns (bool) {
    uint amount;
    bytes32 assetManagerEscrowID = keccak256(abi.encodePacked(_assetAddress, _assetManager));
    address platformTokenAddress = database.addressStorage(keccak256(abi.encodePacked("platform.token")));
    if(_paymentTokenAddress == _fundingTokenAddress){
      require(_amount >= _min, "Insufficient collateral for asset manager risk");
    } else {
       
      (uint rate,) = kyber.getExpectedRate(_paymentTokenAddress, _fundingTokenAddress, _amount);
      require(_amount.mul(rate).div(10**18) >= _min);
    }
    if(_paymentTokenAddress != platformTokenAddress){
       
      if(_paymentTokenAddress == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)){
        amount = kyber.trade.value(_amount)(_paymentTokenAddress, _amount, platformTokenAddress, address(this), 2**255, 0, 0);  
      } else {
        CrowdsaleGeneratorERC20_ERC20 paymentToken = CrowdsaleGeneratorERC20_ERC20(_paymentTokenAddress);
        require(paymentToken.transferFrom(_assetManager, address(this), _amount));
        require(paymentToken.approve(address(kyber), _amount));
        amount = kyber.trade(_paymentTokenAddress, _amount, platformTokenAddress, address(this), 2**255, 0, 0);  
      }
      require(CrowdsaleGeneratorERC20_ERC20(platformTokenAddress).transfer(database.addressStorage(keccak256(abi.encodePacked("contract", "EscrowReserve"))), amount));
    } else {
      amount = _amount;
      require(CrowdsaleGeneratorERC20_ERC20(platformTokenAddress).transferFrom(_assetManager, database.addressStorage(keccak256(abi.encodePacked("contract", "EscrowReserve"))), amount));
    }
    database.setUint(keccak256(abi.encodePacked("asset.escrow", assetManagerEscrowID)), amount);
    events.escrow('Escrow locked', _assetAddress, assetManagerEscrowID, _assetManager, amount);
    return true;
  }


   
   
   

   
  modifier onlyOwner {
    require(database.boolStorage(keccak256(abi.encodePacked("owner", msg.sender))), "Not owner");
    _;
  }

  modifier checkRequirements {
    _;
  }
}