 

pragma solidity ^0.4.23;

 

 
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

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
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

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

contract MidasToken is StandardToken, Pausable {
    string public constant name = 'MidasProtocol';
    string public constant symbol = 'MAS';
    uint256 public constant minTomoContribution = 100 ether;
    uint256 public constant minEthContribution = 0.1 ether;
    uint256 public constant maxEthContribution = 500 ether;
    uint256 public constant ethConvertRate = 10000;  
    uint256 public constant tomoConvertRate = 10;  
    uint256 public totalTokenSold = 0;
    uint256 public maxCap = maxEthContribution.mul(ethConvertRate);  

    uint256 public constant decimals = 18;
    address public tokenSaleAddress;
    address public midasDepositAddress;
    address public ethFundDepositAddress;
    address public midasFounderAddress;
    address public midasAdvisorOperateMarketingAddress;

    uint256 public fundingStartTime;
    uint256 public fundingEndTime;

    uint256 public constant midasDeposit = 500000000 * 10 ** decimals;  
    uint256 public constant tokenCreationCap = 5000000 * 10 ** 18;  

    mapping(address => bool) public frozenAccount;
    mapping(address => uint256) public participated;

    mapping(address => uint256) public whitelist;
    bool public isFinalized;
    bool public isTransferable;

     
    event FrozenFunds(address target, bool frozen);
    event BuyByEth(address from, address to, uint256 val);
    event BuyByTomo(address from, address to, uint256 val);
    event ListAddress(address _user, uint256 cap, uint256 _time);
    event RefundMidas(address to, uint256 val);

     

    constructor (address _midasDepositAddress, address _ethFundDepositAddress, address _midasFounderAddress, address _midasAdvisorOperateMarketingAddress, uint256 _fundingStartTime, uint256 _fundingEndTime) public {
        midasDepositAddress = _midasDepositAddress;
        ethFundDepositAddress = _ethFundDepositAddress;
        midasFounderAddress = _midasFounderAddress;
        midasAdvisorOperateMarketingAddress = _midasAdvisorOperateMarketingAddress;

        fundingStartTime = _fundingStartTime;
        fundingEndTime = _fundingEndTime;

        balances[midasDepositAddress] = midasDeposit;
        emit Transfer(0x0, midasDepositAddress, midasDeposit);
        totalSupply_ = midasDeposit;
        isFinalized = false;
        isTransferable = true;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
        require(isTransferable == true || msg.sender == midasAdvisorOperateMarketingAddress || msg.sender == midasDepositAddress);
        return super.transfer(_to, _value);
    }

    function setTransferStatus(bool status) public onlyOwner {
        isTransferable = status;
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
        return super.approve(_spender, _value);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner);
    }

    function freezeAccount(address _target, bool _freeze) onlyOwner public {
        frozenAccount[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }

    function freezeAccounts(address[] _targets, bool _freeze) onlyOwner public {
        for (uint i = 0; i < _targets.length; i++) {
            freezeAccount(_targets[i], _freeze);
        }
    }

     

     

    function listAddress(address _user, uint256 cap) public onlyOwner {
        whitelist[_user] = cap;
        emit ListAddress(_user, cap, now);
    }

    function listAddresses(address[] _users, uint256[] _caps) public onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            listAddress(_users[i], _caps[i]);
        }
    }

    function getCap(address _user) public view returns (uint) {
        return whitelist[_user];
    }

     

    function() public payable {
        buyByEth(msg.sender, msg.value);
    }

    function buyByEth(address _recipient, uint256 _value) public returns (bool success) {
        require(_value > 0);
        require(now >= fundingStartTime);
        require(now <= fundingEndTime);
        require(_value >= minEthContribution);
        require(_value <= maxEthContribution);
        require(!isFinalized);
        require(totalTokenSold < tokenCreationCap);

        uint256 tokens = _value.mul(ethConvertRate);

        uint256 cap = getCap(_recipient);
        require(cap > 0);

        uint256 tokensToAllocate = 0;
        uint256 tokensToRefund = 0;
        uint256 etherToRefund = 0;

        tokensToAllocate = maxCap.sub(participated[_recipient]);

         
        if (tokens > tokensToAllocate) {
            tokensToRefund = tokens.sub(tokensToAllocate);
            etherToRefund = tokensToRefund.div(ethConvertRate);
        } else {
             
            tokensToAllocate = tokens;
        }

        uint256 checkedTokenSold = totalTokenSold.add(tokensToAllocate);

         
        if (tokenCreationCap < checkedTokenSold) {
            tokensToAllocate = tokenCreationCap.sub(totalTokenSold);
            tokensToRefund = tokens.sub(tokensToAllocate);
            etherToRefund = tokensToRefund.div(ethConvertRate);
            totalTokenSold = tokenCreationCap;
        } else {
            totalTokenSold = checkedTokenSold;
        }

         
        participated[_recipient] = participated[_recipient].add(tokensToAllocate);

         
        balances[midasDepositAddress] = balances[midasDepositAddress].sub(tokensToAllocate);
        balances[_recipient] = balances[_recipient].add(tokensToAllocate);

         
        if (etherToRefund > 0) {
             
            emit RefundMidas(msg.sender, etherToRefund);
            msg.sender.transfer(etherToRefund);
        }
        ethFundDepositAddress.transfer(address(this).balance);
         
        emit BuyByEth(midasDepositAddress, _recipient, _value);
        return true;
    }

    function buyByTomo(address _recipient, uint256 _value) public onlyOwner returns (bool success) {
        require(_value > 0);
        require(now >= fundingStartTime);
        require(now <= fundingEndTime);
        require(_value >= minTomoContribution);
        require(!isFinalized);
        require(totalTokenSold < tokenCreationCap);

        uint256 tokens = _value.mul(tomoConvertRate);

        uint256 cap = getCap(_recipient);
        require(cap > 0);

        uint256 tokensToAllocate = 0;
        uint256 tokensToRefund = 0;
        tokensToAllocate = maxCap;
         
        if (tokens > tokensToAllocate) {
            tokensToRefund = tokens.sub(tokensToAllocate);
        } else {
             
            tokensToAllocate = tokens;
        }

        uint256 checkedTokenSold = totalTokenSold.add(tokensToAllocate);

         
        if (tokenCreationCap < checkedTokenSold) {
            tokensToAllocate = tokenCreationCap.sub(totalTokenSold);
            totalTokenSold = tokenCreationCap;
        } else {
            totalTokenSold = checkedTokenSold;
        }

         
        balances[midasDepositAddress] = balances[midasDepositAddress].sub(tokensToAllocate);
        balances[_recipient] = balances[_recipient].add(tokensToAllocate);

        emit BuyByTomo(midasDepositAddress, _recipient, _value);
        return true;
    }

     
    function finalize() external onlyOwner {
        require(!isFinalized);
         
        isFinalized = true;
        ethFundDepositAddress.transfer(address(this).balance);
    }
}