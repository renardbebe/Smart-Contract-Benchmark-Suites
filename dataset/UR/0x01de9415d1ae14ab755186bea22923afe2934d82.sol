 

pragma solidity ^0.4.24;

interface ERC721   {
     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

     
     
     
     
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

     
     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
     
     
     
     
    function balanceOf(address _owner) external view returns (uint256);

     
     
     
     
     
    function ownerOf(uint256 _tokenId) external view returns (address);

     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;

     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

     
     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
     
     
     
     
     
    function approve(address _approved, uint256 _tokenId) external;

     
     
     
     
     
     
    function setApprovalForAll(address _operator, bool _approved) external;

     
     
     
     
    function getApproved(uint256 _tokenId) external view returns (address);

     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

 
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

 
contract Operator is Ownable {
    address[] public operators;

    uint public MAX_OPS = 20;  

    mapping(address => bool) public isOperator;

    event OperatorAdded(address operator);
    event OperatorRemoved(address operator);

     
    modifier onlyOperator() {
        require(
            isOperator[msg.sender] || msg.sender == owner,
            "Permission denied. Must be an operator or the owner."
        );
        _;
    }

     
    function addOperator(address _newOperator) public onlyOwner {
        require(
            _newOperator != address(0),
            "Invalid new operator address."
        );

         
        require(
            !isOperator[_newOperator],
            "New operator exists."
        );

         
        require(
            operators.length < MAX_OPS,
            "Overflow."
        );

        operators.push(_newOperator);
        isOperator[_newOperator] = true;

        emit OperatorAdded(_newOperator);
    }

     
    function removeOperator(address _operator) public onlyOwner {
         
        require(
            operators.length > 0,
            "No operator."
        );

         
        require(
            isOperator[_operator],
            "Not an operator."
        );

         
         
         
        address lastOperator = operators[operators.length - 1];
        for (uint i = 0; i < operators.length; i++) {
            if (operators[i] == _operator) {
                operators[i] = lastOperator;
            }
        }
        operators.length -= 1;  

        isOperator[_operator] = false;
        emit OperatorRemoved(_operator);
    }

     
    function removeAllOps() public onlyOwner {
        for (uint i = 0; i < operators.length; i++) {
            isOperator[operators[i]] = false;
        }
        operators.length = 0;
    }
}

interface BitizenCarService {
  function isBurnedCar(uint256 _carId) external view returns (bool);
  function getOwnerCars(address _owner) external view returns(uint256[]);
  function getBurnedCarIdByIndex(uint256 _index) external view returns (uint256);
  function getCarInfo(uint256 _carId) external view returns(string, uint8, uint8);
  function createCar(address _owner, string _foundBy, uint8 _type, uint8 _ext) external returns(uint256);
  function updateCar(uint256 _carId, string _newFoundBy, uint8 _newType, uint8 _ext) external;
  function burnCar(address _owner, uint256 _carId) external;
}

contract BitizenCarOperator is Operator {

  event CreateCar(address indexed _owner, uint256 _carId);
  
  BitizenCarService internal carService;

  ERC721 internal ERC721Service;

  uint16 PER_USER_MAX_CAR_COUNT = 1;

  function injectCarService(BitizenCarService _service) public onlyOwner {
    carService = BitizenCarService(_service);
    ERC721Service = ERC721(_service);
  }

  function setMaxCount(uint16 _count) public onlyOwner {
    PER_USER_MAX_CAR_COUNT = _count;
  }

  function getOwnerCars() external view returns(uint256[]) {
    return carService.getOwnerCars(msg.sender);
  }

  function getCarInfo(uint256 _carId) external view returns(string, uint8, uint8){
    return carService.getCarInfo(_carId);
  }
  
  function createCar(string _foundBy) external returns(uint256) {
    require(ERC721Service.balanceOf(msg.sender) < PER_USER_MAX_CAR_COUNT,"user owned car count overflow");
    uint256 carId = carService.createCar(msg.sender, _foundBy, 1, 1);
    emit CreateCar(msg.sender, carId);
    return carId;
  }

  function createCarByOperator(address _owner, string _foundBy, uint8 _type, uint8 _ext) external onlyOperator returns (uint256) {
    uint256 carId = carService.createCar(_owner, _foundBy, _type, _ext);
    emit CreateCar(msg.sender, carId);
    return carId;
  }

}