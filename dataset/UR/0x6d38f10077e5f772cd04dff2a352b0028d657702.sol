 

pragma solidity 0.4.24;

 

 
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 

contract TokenSale is Pausable {

   
  bool public isFinalized = false;

   
  bool public isStarted = false;

   
  event Finalized();

   
  event Started();

   
  event Invested(address purchaser, address beneficiary, uint256 amount);

  modifier whenStarted() {
    require(isStarted);
    _;
  }

  modifier whenNotFinalized() {
    require(!isFinalized);
    _;
  }

  constructor() public  {
  }

   
  function start() public onlyOwner {
    require(!isStarted);
    require(!isFinalized);
    emit Started();
    isStarted = true;
  }

   
  function pause() public onlyOwner whenStarted whenNotFinalized whenNotPaused {
    super.pause();
  }

   
  function unpause() public onlyOwner whenStarted whenNotFinalized whenPaused {
    super.unpause();
  }

   
  function finalize() public onlyOwner {
    require(isStarted);
    require(!isFinalized);
    emit Finalized();
    isFinalized = true;
  }

  function () external payable {
    invest(msg.sender);
  }

   
  function invest(address _beneficiary)
    public
    whenStarted
    whenNotPaused
    whenNotFinalized
    payable {

    uint256 _weiAmount = msg.value;
    require(_beneficiary != address(0));
    require(_weiAmount != 0);

    emit Invested(msg.sender, _beneficiary, _weiAmount);

    owner.transfer(_weiAmount);
  }
}