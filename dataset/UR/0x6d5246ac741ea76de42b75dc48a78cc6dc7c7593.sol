 

pragma solidity ^0.4.24;

 

interface IDeployer {
    function deploy(bytes data) external returns(address mtkn);
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

 

contract MultiTokenRegistry is Pausable {

    event NewMultitoken(address indexed mtkn);
    event NewDeployer(uint256 indexed index, address indexed oldDeployer, address indexed newDeployer);

    address[] public multitokens;
    mapping(uint256 => IDeployer) public deployers;

    function multitokensCount() public view returns(uint256) {
        return multitokens.length;
    }
    
    function allMultitokens() public view returns(address[]) {
        return multitokens;
    }

    function setDeployer(uint256 index, IDeployer deployer) public onlyOwner whenNotPaused {
        emit NewDeployer(index, deployers[index], deployer);
        deployers[index] = deployer;
    }

    function deploy(uint256 index, bytes data) public whenNotPaused {
        address mtkn = deployers[index].deploy(data);
        multitokens.push(mtkn);
        emit NewMultitoken(mtkn);
    }
}