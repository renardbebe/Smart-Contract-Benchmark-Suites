 

pragma solidity ^0.5.0;


 
contract Spawn {
  constructor(
    address logicContract,
    bytes memory initializationCalldata
  ) public payable {
     
    (bool ok, ) = logicContract.delegatecall(initializationCalldata);
    if (!ok) {
       
      assembly {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }

     
    bytes memory runtimeCode = abi.encodePacked(
      bytes10(0x363d3d373d3d3d363d73),
      logicContract,
      bytes15(0x5af43d82803e903d91602b57fd5bf3)
    );

     
    assembly {
      return(add(0x20, runtimeCode), 45)  
    }
  }
}

 
contract Spawner {
   
  function _spawn(
    address logicContract,
    bytes memory initializationCalldata
  ) internal returns (address spawnedContract) {
     
    bytes memory initCode = abi.encodePacked(
      type(Spawn).creationCode,
      abi.encode(logicContract, initializationCalldata)
    );

     
    (bytes32 salt, address target) = _getSaltAndTarget(initCode);

     
    spawnedContract = _spawnCreate2(initCode, salt, target);
  }

   
  function _spawnSalty(
    address logicContract,
    bytes memory initializationCalldata,
    bytes32 salt
  ) internal returns (address spawnedContract) {
     
    bytes memory initCode = abi.encodePacked(
      type(Spawn).creationCode,
      abi.encode(logicContract, initializationCalldata)
    );

    address target = _computeTargetAddress(logicContract, initializationCalldata, salt);

    uint256 codeSize;
    assembly { codeSize := extcodesize(target) }
    require(codeSize == 0, "contract already deployed with supplied salt");

     
    spawnedContract = _spawnCreate2(initCode, salt, target);
  }

   
  function _getNextAddress(
    address logicContract,
    bytes memory initializationCalldata
  ) internal view returns (address target) {
     
    bytes memory initCode = abi.encodePacked(
      type(Spawn).creationCode,
      abi.encode(logicContract, initializationCalldata)
    );

     
    (, target) = _getSaltAndTarget(initCode);
  }

   
  function _computeTargetAddress(
    bytes32 initCodeHash,
    bytes32 salt
  ) internal view returns (address target) {
    target = address(     
      uint160(                    
        uint256(                  
          keccak256(              
            abi.encodePacked(     
              bytes1(0xff),       
              address(this),      
              salt,               
              initCodeHash        
            )
          )
        )
      )
    );
  }

   
  function _computeTargetAddress(
    address logicContract,
    bytes memory initializationCalldata,
    bytes32 salt
  ) internal view returns (address target) {
     
    bytes memory initCode = abi.encodePacked(
      type(Spawn).creationCode,
      abi.encode(logicContract, initializationCalldata)
    );
     
    bytes32 initCodeHash = keccak256(initCode);

    target = _computeTargetAddress(initCodeHash, salt);
  }

   
  function _spawnCreate2(
    bytes memory initCode,
    bytes32 salt,
    address target
  ) private returns (address spawnedContract) {
    assembly {
      let encoded_data := add(0x20, initCode)  
      let encoded_size := mload(initCode)      
      spawnedContract := create2(              
        callvalue,                             
        encoded_data,                          
        encoded_size,                          
        salt                                   
      )

       
      if iszero(spawnedContract) {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }

    require(spawnedContract == target, "attempted deployment to unexpected address");
  }

   
  function _getSaltAndTarget(
    bytes memory initCode
  ) private view returns (bytes32 salt, address target) {
     
    bytes32 initCodeHash = keccak256(initCode);

     
    uint256 nonce = 0;

     
    uint256 codeSize;

    while (true) {
       
      salt = keccak256(abi.encodePacked(msg.sender, nonce));

      target = _computeTargetAddress(initCodeHash, salt);

       
      assembly { codeSize := extcodesize(target) }

       
      if (codeSize == 0) {
        break;
      }

       
      nonce++;
    }
  }
}



interface iRegistry {

    enum FactoryStatus { Unregistered, Registered, Retired }

    event FactoryAdded(address owner, address factory, uint256 factoryID, bytes extraData);
    event FactoryRetired(address owner, address factory, uint256 factoryID);
    event InstanceRegistered(address instance, uint256 instanceIndex, address indexed creator, address indexed factory, uint256 indexed factoryID);

     

    function addFactory(address factory, bytes calldata extraData ) external;
    function retireFactory(address factory) external;

     

    function getFactoryCount() external view returns (uint256 count);
    function getFactoryStatus(address factory) external view returns (FactoryStatus status);
    function getFactoryID(address factory) external view returns (uint16 factoryID);
    function getFactoryData(address factory) external view returns (bytes memory extraData);
    function getFactoryAddress(uint16 factoryID) external view returns (address factory);
    function getFactory(address factory) external view returns (FactoryStatus state, uint16 factoryID, bytes memory extraData);
    function getFactories() external view returns (address[] memory factories);
    function getPaginatedFactories(uint256 startIndex, uint256 endIndex) external view returns (address[] memory factories);

     

    function register(address instance, address creator, uint80 extraData) external;

     

    function getInstanceType() external view returns (bytes4 instanceType);
    function getInstanceCount() external view returns (uint256 count);
    function getInstance(uint256 index) external view returns (address instance);
    function getInstances() external view returns (address[] memory instances);
    function getPaginatedInstances(uint256 startIndex, uint256 endIndex) external view returns (address[] memory instances);
}


 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract EventMetadata {

    event MetadataSet(bytes metadata);

     

    function _setMetadata(bytes memory metadata) internal {
        emit MetadataSet(metadata);
    }
}



contract Operated {

    address private _operator;
    bool private _status;

    event OperatorUpdated(address operator, bool status);

     

    function _setOperator(address operator) internal {
        require(_operator != operator, "cannot set same operator");
        _operator = operator;
        emit OperatorUpdated(operator, hasActiveOperator());
    }

    function _transferOperator(address operator) internal {
         
        require(_operator != address(0), "operator not set");
        _setOperator(operator);
    }

    function _renounceOperator() internal {
        require(hasActiveOperator(), "only when operator active");
        _operator = address(0);
        _status = false;
        emit OperatorUpdated(address(0), false);
    }

    function _activateOperator() internal {
        require(!hasActiveOperator(), "only when operator not active");
        _status = true;
        emit OperatorUpdated(_operator, true);
    }

    function _deactivateOperator() internal {
        require(hasActiveOperator(), "only when operator active");
        _status = false;
        emit OperatorUpdated(_operator, false);
    }

     

    function getOperator() public view returns (address operator) {
        operator = _operator;
    }

    function isOperator(address caller) public view returns (bool ok) {
        return (caller == getOperator());
    }

    function hasActiveOperator() public view returns (bool ok) {
        return _status;
    }

    function isActiveOperator(address caller) public view returns (bool ok) {
        return (isOperator(caller) && hasActiveOperator());
    }

}



 
contract Deadline {

    uint256 private _deadline;

    event DeadlineSet(uint256 deadline);

     

    function _setDeadline(uint256 deadline) internal {
        _deadline = deadline;
        emit DeadlineSet(deadline);
    }

     

    function getDeadline() public view returns (uint256 deadline) {
        deadline = _deadline;
    }

     
     
    function isAfterDeadline() public view returns (bool status) {
        if (_deadline == 0) {
            status = false;
        } else {
            status = (now >= _deadline);
        }
    }

}


 
library DecimalMath {
    using SafeMath for uint256;

    uint256 internal constant e18 = uint256(10) ** uint256(18);

     
    function mul(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, y), (e18) / 2) / (e18);
    }

     
    function div(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, (e18)), y / 2) / y;
    }

}


 
 interface iFactory {

     event InstanceCreated(address indexed instance, address indexed creator, string initABI, bytes initData);

     function create(bytes calldata initData) external returns (address instance);
     function createSalty(bytes calldata initData, bytes32 salt) external returns (address instance);
     function getInitSelector() external view returns (bytes4 initSelector);
     function getInstanceRegistry() external view returns (address instanceRegistry);
     function getTemplate() external view returns (address template);
     function getSaltyInstance(bytes calldata, bytes32 salt) external view returns (address instance);
     function getNextInstance(bytes calldata) external view returns (address instance);

     function getInstanceCreator(address instance) external view returns (address creator);
     function getInstanceType() external view returns (bytes4 instanceType);
     function getInstanceCount() external view returns (uint256 count);
     function getInstance(uint256 index) external view returns (address instance);
     function getInstances() external view returns (address[] memory instances);
     function getPaginatedInstances(uint256 startIndex, uint256 endIndex) external view returns (address[] memory instances);
 }



contract iNMR {

     
    function totalSupply() external returns (uint256);
    function balanceOf(address _owner) external returns (uint256);
    function allowance(address _owner, address _spender) external returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool ok);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool ok);
    function approve(address _spender, uint256 _value) external returns (bool ok);
    function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) external returns (bool ok);

     
    function mint(uint256 _value) external returns (bool ok);
     
    function numeraiTransfer(address _to, uint256 _value) external returns (bool ok);
}




contract Factory is Spawner {

    address[] private _instances;
    mapping (address => address) private _instanceCreator;

     
    address private _templateContract;
    bytes4 private _initSelector;
    address private _instanceRegistry;
    bytes4 private _instanceType;

    event InstanceCreated(address indexed instance, address indexed creator, bytes callData);

    function _initialize(address instanceRegistry, address templateContract, bytes4 instanceType, bytes4 initSelector) internal {
         
        _instanceRegistry = instanceRegistry;
         
        _templateContract = templateContract;
         
        _initSelector = initSelector;
         
        require(instanceType == iRegistry(instanceRegistry).getInstanceType(), 'incorrect instance type');
         
        _instanceType = instanceType;
    }

     

    function create(bytes memory callData) public returns (address instance) {
         
        instance = Spawner._spawn(getTemplate(), callData);

        _createHelper(instance, callData);
    }

    function createSalty(bytes memory callData, bytes32 salt) public returns (address instance) {
         
        instance = Spawner._spawnSalty(getTemplate(), callData, salt);

        _createHelper(instance, callData);
    }

    function _createHelper(address instance, bytes memory callData) private {
         
        _instances.push(instance);
         
        _instanceCreator[instance] = msg.sender;
         
        iRegistry(getInstanceRegistry()).register(instance, msg.sender, uint80(0));
         
        emit InstanceCreated(instance, msg.sender, callData);
    }

    function getSaltyInstance(
        bytes memory callData,
        bytes32 salt
    ) public view returns (address target) {
        return Spawner._computeTargetAddress(getTemplate(), callData, salt);
    }

    function getNextInstance(
        bytes memory callData
    ) public view returns (address target) {
        return Spawner._getNextAddress(getTemplate(), callData);
    }

    function getInstanceCreator(address instance) public view returns (address creator) {
        creator = _instanceCreator[instance];
    }

    function getInstanceType() public view returns (bytes4 instanceType) {
        instanceType = _instanceType;
    }

    function getInitSelector() public view returns (bytes4 initSelector) {
        initSelector = _initSelector;
    }

    function getInstanceRegistry() public view returns (address instanceRegistry) {
        instanceRegistry = _instanceRegistry;
    }

    function getTemplate() public view returns (address template) {
        template = _templateContract;
    }

    function getInstanceCount() public view returns (uint256 count) {
        count = _instances.length;
    }

    function getInstance(uint256 index) public view returns (address instance) {
        require(index < _instances.length, "index out of range");
        instance = _instances[index];
    }

    function getInstances() public view returns (address[] memory instances) {
        instances = _instances;
    }

     
    function getPaginatedInstances(uint256 startIndex, uint256 endIndex) public view returns (address[] memory instances) {
        require(startIndex < endIndex, "startIndex must be less than endIndex");
        require(endIndex <= _instances.length, "end index out of range");

         
        address[] memory range = new address[](endIndex - startIndex);

         
        for (uint256 i = startIndex; i < endIndex; i++) {
            range[i - startIndex] = _instances[i];
        }

         
        instances = range;
    }

}




 
contract Countdown is Deadline {

    using SafeMath for uint256;

    uint256 private _length;

    event LengthSet(uint256 length);

     

    function _setLength(uint256 length) internal {
        _length = length;
        emit LengthSet(length);
    }

    function _start() internal returns (uint256 deadline) {
        deadline = _length.add(now);
        Deadline._setDeadline(deadline);
    }

     

    function getLength() public view returns (uint256 length) {
        length = _length;
    }

     
     
    function isOver() public view returns (bool status) {
         
         
        if (Deadline.getDeadline() == 0) {
            status = false;
        } else {
            status = Deadline.isAfterDeadline();
        }
    }

     
     
    function timeRemaining() public view returns (uint256 time) {
        if (now >= Deadline.getDeadline()) {
            time = 0;
        } else {
            time = Deadline.getDeadline().sub(now);
        }
    }

}



contract Template {

    address private _factory;

     

    modifier initializeTemplate() {
         
        _factory = msg.sender;

         
        uint32 codeSize;
        assembly { codeSize := extcodesize(address) }
        require(codeSize == 0, "must be called within contract constructor");
        _;
    }

     

    function getCreator() public view returns (address creator) {
         
        creator = iFactory(_factory).getInstanceCreator(address(this));
    }

    function isCreator(address caller) public view returns (bool ok) {
        ok = (caller == getCreator());
    }

    function getFactory() public view returns (address factory) {
        factory = _factory;
    }

}


 
contract BurnNMR {

     
    address private constant _Token = address(0x1776e1F26f98b1A5dF9cD347953a26dd3Cb46671);

     
    function _burn(uint256 value) internal {
        require(iNMR(_Token).mint(value), "nmr burn failed");
    }

     
    function _burnFrom(address from, uint256 value) internal {
        require(iNMR(_Token).numeraiTransfer(from, value), "nmr burnFrom failed");
    }

    function getToken() public pure returns (address token) {
        token = _Token;
    }

}





contract Staking is BurnNMR {

    using SafeMath for uint256;

    mapping (address => uint256) private _stake;

    event StakeAdded(address staker, address funder, uint256 amount, uint256 newStake);
    event StakeTaken(address staker, address recipient, uint256 amount, uint256 newStake);
    event StakeBurned(address staker, uint256 amount, uint256 newStake);

    function _addStake(address staker, address funder, uint256 currentStake, uint256 amountToAdd) internal {
         
        require(currentStake == _stake[staker], "current stake incorrect");

         
        require(amountToAdd > 0, "no stake to add");

         
        uint256 newStake = currentStake.add(amountToAdd);

         
        _stake[staker] = newStake;

         
        require(IERC20(BurnNMR.getToken()).transferFrom(funder, address(this), amountToAdd), "token transfer failed");

         
        emit StakeAdded(staker, funder, amountToAdd, newStake);
    }

    function _takeStake(address staker, address recipient, uint256 currentStake, uint256 amountToTake) internal {
         
        require(currentStake == _stake[staker], "current stake incorrect");

         
        require(amountToTake > 0, "no stake to take");

         
        require(amountToTake <= currentStake, "cannot take more than currentStake");

         
        uint256 newStake = currentStake.sub(amountToTake);

         
        _stake[staker] = newStake;

         
        require(IERC20(BurnNMR.getToken()).transfer(recipient, amountToTake), "token transfer failed");

         
        emit StakeTaken(staker, recipient, amountToTake, newStake);
    }

    function _takeFullStake(address staker, address recipient) internal returns (uint256 stake) {
         
        stake = _stake[staker];

         
        _takeStake(staker, recipient, stake, stake);
    }

    function _burnStake(address staker, uint256 currentStake, uint256 amountToBurn) internal {
         
        require(currentStake == _stake[staker], "current stake incorrect");

         
        require(amountToBurn > 0, "no stake to burn");

         
        require(amountToBurn <= currentStake, "cannot burn more than currentStake");

         
        uint256 newStake = currentStake.sub(amountToBurn);

         
        _stake[staker] = newStake;

         
        BurnNMR._burn(amountToBurn);

         
        emit StakeBurned(staker, amountToBurn, newStake);
    }

    function _burnFullStake(address staker) internal returns (uint256 stake) {
         
        stake = _stake[staker];

         
        _burnStake(staker, stake, stake);
    }

     

    function getStake(address staker) public view returns (uint256 stake) {
        stake = _stake[staker];
    }

}




contract Griefing is Staking {

    enum RatioType { NaN, Inf, Dec }

    mapping (address => GriefRatio) private _griefRatio;
    struct GriefRatio {
        uint256 ratio;
        RatioType ratioType;
   }

    event RatioSet(address staker, uint256 ratio, RatioType ratioType);
    event Griefed(address punisher, address staker, uint256 punishment, uint256 cost, bytes message);

    uint256 internal constant e18 = uint256(10) ** uint256(18);

     

    function _setRatio(address staker, uint256 ratio, RatioType ratioType) internal {
        if (ratioType == RatioType.NaN || ratioType == RatioType.Inf) {
            require(ratio == 0, "ratio must be 0 when ratioType is NaN or Inf");
        }

         
        _griefRatio[staker].ratio = ratio;
        _griefRatio[staker].ratioType = ratioType;

         
        emit RatioSet(staker, ratio, ratioType);
    }

    function _grief(
        address punisher,
        address staker,
        uint256 currentStake,
        uint256 punishment,
        bytes memory message
    ) internal returns (uint256 cost) {

         
         
        require(currentStake <= Staking.getStake(staker), "current stake incorrect");

         
        uint256 ratio = _griefRatio[staker].ratio;
        RatioType ratioType = _griefRatio[staker].ratioType;

        require(ratioType != RatioType.NaN, "no punishment allowed");

         
         
        cost = getCost(ratio, punishment, ratioType);

         
        BurnNMR._burnFrom(punisher, cost);

         
        Staking._burnStake(staker, currentStake, punishment);

         
        emit Griefed(punisher, staker, punishment, cost, message);
    }

     

    function getRatio(address staker) public view returns (uint256 ratio, RatioType ratioType) {
         
        ratio = _griefRatio[staker].ratio;
        ratioType = _griefRatio[staker].ratioType;
    }

     

    function getCost(uint256 ratio, uint256 punishment, RatioType ratioType) public pure returns(uint256 cost) {
         
        if (ratioType == RatioType.Dec) {
            return DecimalMath.mul(SafeMath.mul(punishment, e18), ratio) / e18;
        }
        if (ratioType == RatioType.Inf)
            return 0;
        if (ratioType == RatioType.NaN)
            revert("ratioType cannot be RatioType.NaN");
    }

    function getPunishment(uint256 ratio, uint256 cost, RatioType ratioType) public pure returns(uint256 punishment) {
         
        if (ratioType == RatioType.Dec) {
            return DecimalMath.div(SafeMath.mul(cost, e18), ratio) / e18;
        }
        if (ratioType == RatioType.Inf)
            revert("ratioType cannot be RatioType.Inf");
        if (ratioType == RatioType.NaN)
            revert("ratioType cannot be RatioType.NaN");
    }

}








 
contract SimpleGriefing is Griefing, EventMetadata, Operated, Template {

    using SafeMath for uint256;

    Data private _data;
    struct Data {
        address staker;
        address counterparty;
    }

    event Initialized(address operator, address staker, address counterparty, uint256 ratio, Griefing.RatioType ratioType, bytes metadata);

    function initialize(
        address operator,
        address staker,
        address counterparty,
        uint256 ratio,
        Griefing.RatioType ratioType,
        bytes memory metadata
    ) public initializeTemplate() {
         
        _data.staker = staker;
        _data.counterparty = counterparty;

         
        if (operator != address(0)) {
            Operated._setOperator(operator);
            Operated._activateOperator();
        }

         
        Griefing._setRatio(staker, ratio, ratioType);

         
        if (metadata.length != 0) {
            EventMetadata._setMetadata(metadata);
        }

         
        emit Initialized(operator, staker, counterparty, ratio, ratioType, metadata);
    }

     

    function setMetadata(bytes memory metadata) public {
         
        require(isStaker(msg.sender) || Operated.isActiveOperator(msg.sender), "only staker or active operator");

         
        EventMetadata._setMetadata(metadata);
    }

    function increaseStake(uint256 currentStake, uint256 amountToAdd) public {
         
        require(isStaker(msg.sender) || Operated.isActiveOperator(msg.sender), "only staker or active operator");

         
        Staking._addStake(_data.staker, msg.sender, currentStake, amountToAdd);
    }

    function reward(uint256 currentStake, uint256 amountToAdd) public {
         
        require(isCounterparty(msg.sender) || Operated.isActiveOperator(msg.sender), "only counterparty or active operator");

         
        Staking._addStake(_data.staker, msg.sender, currentStake, amountToAdd);
    }

    function punish(uint256 currentStake, uint256 punishment, bytes memory message) public returns (uint256 cost) {
         
        require(isCounterparty(msg.sender) || Operated.isActiveOperator(msg.sender), "only counterparty or active operator");

         
        cost = Griefing._grief(msg.sender, _data.staker, currentStake, punishment, message);
    }

    function releaseStake(uint256 currentStake, uint256 amountToRelease) public {
         
        require(isCounterparty(msg.sender) || Operated.isActiveOperator(msg.sender), "only counterparty or active operator");

         
        Staking._takeStake(_data.staker, _data.staker, currentStake, amountToRelease);
    }

    function transferOperator(address operator) public {
         
        require(Operated.isActiveOperator(msg.sender), "only active operator");

         
        Operated._transferOperator(operator);
    }

    function renounceOperator() public {
         
        require(Operated.isActiveOperator(msg.sender), "only active operator");

         
        Operated._renounceOperator();
    }

     

    function isStaker(address caller) public view returns (bool validity) {
        validity = (caller == _data.staker);
    }

    function isCounterparty(address caller) public view returns (bool validity) {
        validity = (caller == _data.counterparty);
    }
}




contract SimpleGriefing_Factory is Factory {

    constructor(address instanceRegistry, address templateContract) public {
        SimpleGriefing template;
         
        bytes4 instanceType = bytes4(keccak256(bytes('Agreement')));
         
        bytes4 initSelector = template.initialize.selector;
         
        Factory._initialize(instanceRegistry, templateContract, instanceType, initSelector);
    }

}