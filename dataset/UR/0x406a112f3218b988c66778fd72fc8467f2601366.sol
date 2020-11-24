 

pragma solidity 0.4.18;

 
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
    OwnershipTransferred(owner, newOwner);
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract IController is Pausable {
    event SetContractInfo(bytes32 id, address contractAddress, bytes20 gitCommitHash);

    function setContractInfo(bytes32 _id, address _contractAddress, bytes20 _gitCommitHash) external;
    function updateController(bytes32 _id, address _controller) external;
    function getContract(bytes32 _id) public view returns (address);
}

contract IManager {
    event SetController(address controller);
    event ParameterUpdate(string param);

    function setController(address _controller) external;
}

contract Manager is IManager {
     
    IController public controller;

     
    modifier onlyController() {
        require(msg.sender == address(controller));
        _;
    }

     
    modifier onlyControllerOwner() {
        require(msg.sender == controller.owner());
        _;
    }

     
    modifier whenSystemNotPaused() {
        require(!controller.paused());
        _;
    }

     
    modifier whenSystemPaused() {
        require(controller.paused());
        _;
    }

    function Manager(address _controller) public {
        controller = IController(_controller);
    }

     
    function setController(address _controller) external onlyController {
        controller = IController(_controller);

        SetController(_controller);
    }
}

 
contract ManagerProxyTarget is Manager {
     
    bytes32 public targetContractId;
}

 
contract ManagerProxy is ManagerProxyTarget {
     
    function ManagerProxy(address _controller, bytes32 _targetContractId) public Manager(_controller) {
        targetContractId = _targetContractId;
    }

     
    function() public payable {
        address target = controller.getContract(targetContractId);
         
        require(target > 0);

        assembly {
             
            let freeMemoryPtrPosition := 0x40
             
            let calldataMemoryOffset := mload(freeMemoryPtrPosition)
             
            mstore(freeMemoryPtrPosition, add(calldataMemoryOffset, calldatasize))
             
            calldatacopy(calldataMemoryOffset, 0x0, calldatasize)

             
            let ret := delegatecall(gas, target, calldataMemoryOffset, calldatasize, 0, 0)

             
            let returndataMemoryOffset := mload(freeMemoryPtrPosition)
             
            mstore(freeMemoryPtrPosition, add(returndataMemoryOffset, returndatasize))
             
            returndatacopy(returndataMemoryOffset, 0x0, returndatasize)

            switch ret
            case 0 {
                 
                 
                revert(returndataMemoryOffset, returndatasize)
            } default {
                 
                return(returndataMemoryOffset, returndatasize)
            }
        }
    }
}