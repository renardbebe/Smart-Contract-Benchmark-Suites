 

pragma solidity ^0.4.24;

 

 
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

 

contract PassThroughStorage {
    bytes4 public constant ERC721_Received = 0x150b7a02;
    uint256 public constant MAX_EXPIRATION_TIME = (365 * 2 days);
    mapping(bytes4 => uint256) public disableMethods;

    address public estateRegistry;
    address public operator;
    address public target;

    event MethodAllowed(
      address indexed _caller,
      bytes4 indexed _signatureBytes4,
      string _signature
    );

    event MethodDisabled(
      address indexed _caller,
      bytes4 indexed _signatureBytes4,
      string _signature
    );

    event TargetChanged(
      address indexed _caller,
      address indexed _oldTarget,
      address indexed _newTarget
    );
}

 

contract PassThrough is Ownable, PassThroughStorage {
     
    constructor(address _estateRegistry, address _operator) Ownable() public {
        estateRegistry = _estateRegistry;
        operator = _operator;

         
        setTarget(estateRegistry);

         
        disableMethod("approve(address,uint256)", MAX_EXPIRATION_TIME);
        disableMethod("setApprovalForAll(address,bool)", MAX_EXPIRATION_TIME);
        disableMethod("transferFrom(address,address,uint256)", MAX_EXPIRATION_TIME);
        disableMethod("safeTransferFrom(address,address,uint256)", MAX_EXPIRATION_TIME);
        disableMethod("safeTransferFrom(address,address,uint256,bytes)", MAX_EXPIRATION_TIME);

         
        disableMethod("transferLand(uint256,uint256,address)", MAX_EXPIRATION_TIME);
        disableMethod("transferManyLands(uint256,uint256[],address)", MAX_EXPIRATION_TIME);
        disableMethod("safeTransferManyFrom(address,address,uint256[])", MAX_EXPIRATION_TIME);
        disableMethod("safeTransferManyFrom(address,address,uint256[],bytes)", MAX_EXPIRATION_TIME);

    }

     
    function() external {
        require(
            isOperator() && isMethodAllowed(msg.sig) || isOwner(),
            "Permission denied"
        );

        bytes memory _calldata = msg.data;
        uint256 _calldataSize = msg.data.length;
        address _dst = target;

         
        assembly {
            let result := call(sub(gas, 10000), _dst, 0, add(_calldata, 0x20), _calldataSize, 0, 0)
            let size := returndatasize

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

             
             
            if iszero(result) { revert(ptr, size) }
            return(ptr, size)
        }
    }

     
    function isOperator() internal view returns (bool) {
        return msg.sender == operator;
    }

     
    function isMethodAllowed(bytes4 _signature) internal view returns (bool) {
        return disableMethods[_signature] < block.timestamp;
    }

    function setTarget(address _target) public {
        require(
            isOperator() || isOwner(),
            "Permission denied"
        );

        emit TargetChanged(msg.sender, target, _target);
        target = _target;
    }

     
    function disableMethod(string memory _signature, uint256 _time) public onlyOwner {
        require(_time > 0, "Time should be greater than 0");
        require(_time <= MAX_EXPIRATION_TIME, "Time should be lower than 2 years");

        bytes4 signatureBytes4 = convertToBytes4(abi.encodeWithSignature(_signature));
        disableMethods[signatureBytes4] = block.timestamp + _time;

        emit MethodDisabled(msg.sender, signatureBytes4, _signature);
    }

     
    function allowMethod(string memory _signature) public onlyOwner {
        bytes4 signatureBytes4 = convertToBytes4(abi.encodeWithSignature(_signature));
        require(!isMethodAllowed(signatureBytes4), "Method is already allowed");

        disableMethods[signatureBytes4] = 0;

        emit MethodAllowed(msg.sender, signatureBytes4, _signature);
    }

     
    function convertToBytes4(bytes memory _signature) internal pure returns (bytes4) {
        require(_signature.length == 4, "Invalid method signature");
        bytes4 signatureBytes4;
         
        assembly {
            signatureBytes4 := mload(add(_signature, 32))
        }
        return signatureBytes4;
    }

     
    function onERC721Received(
        address  ,
        address  ,
        uint256  ,
        bytes memory  
    )
        public
        view
        returns (bytes4)
    {
        require(msg.sender == estateRegistry, "Token not accepted");
        return ERC721_Received;
    }
}