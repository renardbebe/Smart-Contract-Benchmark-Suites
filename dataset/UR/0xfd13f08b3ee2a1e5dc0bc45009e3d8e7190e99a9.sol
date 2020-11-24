 

pragma solidity ^0.4.24;

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


 
contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
library SafeERC20 {
  function safeTransfer(
    ERC20 _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
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


 
contract Destructible is Ownable {
   
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
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

 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 
contract HasNoContracts is Ownable {

   
  function reclaimContract(address _contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(_contractAddr);
    contractInst.transferOwnership(owner);
  }
}

 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20;

   
  function reclaimToken(ERC20 _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(owner, balance);
  }

}

 
contract BobBuyback is Claimable, HasNoContracts, CanReclaimToken, Destructible {
    using SafeMath for uint256;    

    ERC20 public token;                  
    uint256 public maxGasPrice;          
    uint256 public maxTxValue;           
    uint256 public roundStartTime;       
    uint256 public rate;                 

    event Buyback(address indexed from, uint256 amountBob, uint256 amountEther);

    constructor(ERC20 _token, uint256 _maxGasPrice, uint256 _maxTxValue) public {
        token = _token;
        maxGasPrice = _maxGasPrice;
        maxTxValue = _maxTxValue;
        roundStartTime = 0;
        rate = 0;
    }

     
    function buyback(uint256 _amount) external {
        require(tx.gasprice <= maxGasPrice);
        require(_amount <= maxTxValue);
        require(isRunning());

        uint256 amount = _amount;
        uint256 reward = calcReward(amount);

        if(address(this).balance < reward) {
             
            reward = address(this).balance;
            amount = reward.mul(rate);
        }

        require(token.transferFrom(msg.sender, address(this), amount));
        msg.sender.transfer(reward);
        emit Buyback(msg.sender, amount, reward);
    }

     
    function calcReward(uint256 amount) view public returns(uint256) {
        if(rate == 0) return 0;      
        return amount.div(rate);     
    }

     
    function calcTokensAvailableToBuyback() view public returns(uint256) {
        return address(this).balance.mul(rate);
    }

     
    function isRunning() view public returns(bool) {
        return (rate > 0) && (now >= roundStartTime) && (address(this).balance > 0);
    }

     
    function setup(uint256 _maxGasPrice, uint256 _maxTxValue) onlyOwner external {
        maxGasPrice = _maxGasPrice;
        maxTxValue = _maxTxValue;
    }

     
    function startBuyback(uint256 _roundStartTime, uint256 _rate) onlyOwner external payable {
        require(_roundStartTime > now);
        roundStartTime = _roundStartTime;
        rate = _rate;    
    }

     
    function claimTokens() onlyOwner external {
        require(token.transfer(owner, token.balanceOf(address(this))));
    }
     
    function claimTokens(uint256 amount, address beneficiary) onlyOwner external {
        require(token.transfer(beneficiary, amount));
    }

     
    function reclaimEther()  onlyOwner external {
        owner.transfer(address(this).balance);
    }

}