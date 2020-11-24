 

pragma solidity ^0.4.24;


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
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


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


 
contract VeloxCrowdsale is Ownable {
    using SafeMath for uint256;

     
    ERC20 public token;

     
    uint256 public startTime;
    uint256 public endTime;

     
    uint256 public rate;

     
    uint256 public cap;

     
    address public wallet;

     
    uint256 public sold;

     
    constructor(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _cap,
        address _wallet,
        ERC20 _token
    ) public {
        require(_startTime >= block.timestamp && _endTime >= _startTime);
        require(_rate > 0);
        require(_cap > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        cap = _cap;
        wallet = _wallet;
        token = _token;
    }

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        require(_beneficiary != address(0));
        require(weiAmount != 0);
        require(block.timestamp >= startTime && block.timestamp <= endTime);
        uint256 tokens = weiAmount.div(rate);
        require(tokens != 0 && sold.add(tokens) <= cap);
        sold = sold.add(tokens);
        require(token.transfer(_beneficiary, tokens));
        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens
        );
    }

     
    function capReached() public view returns (bool) {
        return sold >= cap;
    }

     
    bool public isFinalized = false;

     
    event Finalized();

     
    function finalize() external onlyOwner {
        require(!isFinalized);
        require(block.timestamp > endTime || sold >= cap);
        token.transfer(wallet, token.balanceOf(this));
        wallet.transfer(address(this).balance);
        emit Finalized();
        isFinalized = true;
    }

     
    function forwardFunds() external onlyOwner {
        require(!isFinalized);
        require(block.timestamp > startTime);
        uint256 balance = address(this).balance;
        require(balance > 0);
        wallet.transfer(balance);
    }
}