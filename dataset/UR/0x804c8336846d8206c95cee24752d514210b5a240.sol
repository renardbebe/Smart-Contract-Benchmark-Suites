 

pragma solidity 0.4.25;


 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
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


interface IOrbsNetworkTopology {

     
    function getNetworkTopology()
        external
        view
        returns (bytes20[] nodeAddresses, bytes4[] ipAddresses);
}


interface IOrbsValidators {

    event ValidatorApproved(address indexed validator);
    event ValidatorRemoved(address indexed validator);

     
     
    function approve(address validator) external;

     
     
    function remove(address validator) external;

     
     
    function isValidator(address validator) external view returns (bool);

     
     
    function isApproved(address validator) external view returns (bool);

     
    function getValidators() external view returns (address[]);

     
     
    function getValidatorsBytes20() external view returns (bytes20[]);

     
     
    function getApprovalBlockNumber(address validator)
        external
        view
        returns (uint);
}


interface IOrbsValidatorsRegistry {

    event ValidatorLeft(address indexed validator);
    event ValidatorRegistered(address indexed validator);
    event ValidatorUpdated(address indexed validator);

     
     
     
     
     
     
     
     
    function register(
        string name,
        bytes4 ipAddress,
        string website,
        bytes20 orbsAddress
    )
        external;

     
     
     
     
     
     
    function update(
        string name,
        bytes4 ipAddress,
        string website,
        bytes20 orbsAddress
    )
        external;

     
    function leave() external;

     
     
    function getValidatorData(address validator)
        external
        view
        returns (
            string name,
            bytes4 ipAddress,
            string website,
            bytes20 orbsAddress
        );

     
     
     
    function getRegistrationBlockNumber(address validator)
        external
        view
        returns (uint registeredOn, uint lastUpdatedOn);

     
     
     
    function isValidator(address validator) external view returns (bool);

     
     
     
    function getOrbsAddress(address validator)
        external
        view
        returns (bytes20 orbsAddress);
}


contract OrbsValidators is Ownable, IOrbsValidators, IOrbsNetworkTopology {

     
    uint public constant VERSION = 1;

     
    uint internal constant MAX_VALIDATOR_LIMIT = 100;
    uint public validatorsLimit;

     
    IOrbsValidatorsRegistry public orbsValidatorsRegistry;

     
    address[] internal approvedValidators;

     
    mapping(address => uint) internal approvalBlockNumber;

     
     
     
     
    constructor(IOrbsValidatorsRegistry registry_, uint validatorsLimit_) public {
        require(registry_ != IOrbsValidatorsRegistry(0), "Registry contract address 0");
        require(validatorsLimit_ > 0, "Limit must be positive");
        require(validatorsLimit_ <= MAX_VALIDATOR_LIMIT, "Limit is too high");

        validatorsLimit = validatorsLimit_;
        orbsValidatorsRegistry = registry_;
    }

     
     
    function approve(address validator) external onlyOwner {
        require(validator != address(0), "Address must not be 0!");
        require(approvedValidators.length < validatorsLimit, "Can't add more members!");
        require(!isApproved(validator), "Address must not be already approved");

        approvedValidators.push(validator);
        approvalBlockNumber[validator] = block.number;
        emit ValidatorApproved(validator);
    }

     
     
    function remove(address validator) external onlyOwner {
        require(isApproved(validator), "Not an approved validator");

        uint approvedLength = approvedValidators.length;
        for (uint i = 0; i < approvedLength; ++i) {
            if (approvedValidators[i] == validator) {

                 
                approvedValidators[i] = approvedValidators[approvedLength - 1];
                approvedValidators.length--;

                 
                delete approvalBlockNumber[validator];

                emit ValidatorRemoved(validator);
                return;
            }
        }
    }

     
     
    function isValidator(address validator) public view returns (bool) {
        return isApproved(validator) && orbsValidatorsRegistry.isValidator(validator);
    }

     
     
    function isApproved(address validator) public view returns (bool) {
        return approvalBlockNumber[validator] > 0;
    }

     
    function getValidators() public view returns (address[] memory) {
        uint approvedLength = approvedValidators.length;
        address[] memory validators = new address[](approvedLength);

        uint pushAt = 0;
        for (uint i = 0; i < approvedLength; i++) {
            if (orbsValidatorsRegistry.isValidator(approvedValidators[i])) {
                validators[pushAt] = approvedValidators[i];
                pushAt++;
            }
        }

        return sliceArray(validators, pushAt);
    }

     
     
    function getValidatorsBytes20() external view returns (bytes20[]) {
        address[] memory validatorAddresses = getValidators();
        uint validatorAddressesLength = validatorAddresses.length;

        bytes20[] memory result = new bytes20[](validatorAddressesLength);

        for (uint i = 0; i < validatorAddressesLength; i++) {
            result[i] = bytes20(validatorAddresses[i]);
        }

        return result;
    }

     
     
    function getApprovalBlockNumber(address validator)
        public
        view
        returns (uint)
    {
        return approvalBlockNumber[validator];
    }

     
    function getNetworkTopology()
        external
        view
        returns (bytes20[] memory nodeAddresses, bytes4[] memory ipAddresses)
    {
        address[] memory validators = getValidators();  
        uint validatorsLength = validators.length;
        nodeAddresses = new bytes20[](validatorsLength);
        ipAddresses = new bytes4[](validatorsLength);

        for (uint i = 0; i < validatorsLength; i++) {
            bytes4 ip;
            bytes20 orbsAddr;
            ( , ip , , orbsAddr) = orbsValidatorsRegistry.getValidatorData(validators[i]);
            nodeAddresses[i] = orbsAddr;
            ipAddresses[i] = ip;
        }
    }

     
    function sliceArray(address[] memory arr, uint len)
        internal
        pure
        returns (address[] memory)
    {
        require(len <= arr.length, "sub array must be longer then array");

        address[] memory result = new address[](len);
        for(uint i = 0; i < len; i++) {
            result[i] = arr[i];
        }
        return result;
    }
}