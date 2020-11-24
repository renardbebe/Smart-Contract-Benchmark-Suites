 

pragma solidity ^0.4.16;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}

contract Ownable {
  address public owner;

   
  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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

contract ERC20Basic is Pausable {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 tokens);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  address public rubusOrangeAddress;
  uint256 noEther = 0;

  string public name = "Rubus Fund Orange Token";
  uint8 public decimals = 18;
  string public symbol = "RTO";

  address public enterWallet = 0x73D5f035B8CB58b4aF065d6cE49fC8E7288536F3;
  address public investWallet = 0xD074B636Ccbf1A3482e20b54bF013c1D0c1045b0;
  address public exitWallet = 0xec097d01A6b2C6d415D430B0D4e92f70CACB948D;
  uint256 public priceEthPerToken = 33333;
  
  uint256 public depositCommission = 95;
  uint256 public investCommission = 70;
  uint256 public withdrawCommission = 97;
  
  event MoreData(uint256 ethAmount, uint256 price);

   
  function transfer(address _to, uint256 _value) whenNotPaused returns (bool) {
    
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    if (_to == rubusOrangeAddress) {

      uint256 weiAmount = _value.mul(withdrawCommission).div(priceEthPerToken);

      balances[msg.sender] = balances[msg.sender].sub(_value);
      totalSupply = totalSupply.sub(_value);

      msg.sender.transfer(weiAmount);
      exitWallet.transfer(weiAmount.div(100).mul(uint256(100).sub(withdrawCommission)));

      Transfer(msg.sender, rubusOrangeAddress, _value);
      MoreData(weiAmount, priceEthPerToken);
      return true;

    } else {
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      Transfer(msg.sender, _to, _value);
      MoreData(0, priceEthPerToken);
      return true;
    }
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

  function transferFrom(address _from, address _to, uint256 _value) whenNotPaused returns (bool) {
    
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    if (_to == rubusOrangeAddress) {

      uint256 weiAmount = _value.mul(withdrawCommission).div(priceEthPerToken);

      balances[_from] = balances[_from].sub(_value);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

      msg.sender.transfer(weiAmount);
      exitWallet.transfer(weiAmount.div(100).mul(uint256(100).sub(withdrawCommission)));

      Transfer(_from, rubusOrangeAddress, _value);
      MoreData(weiAmount, priceEthPerToken);
      return true;

    } else {
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        MoreData(0, priceEthPerToken);
        return true;
    }
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract RubusFundOrangeToken is StandardToken {
    
  function () payable whenNotPaused {
    
    uint256 amount = msg.value;
    address investor = msg.sender;
    
    uint256 tokens = amount.mul(depositCommission).mul(priceEthPerToken).div(10000);
    
    totalSupply = totalSupply.add(tokens);
    balances[investor] = balances[investor].add(tokens);

    investWallet.transfer(amount.div(100).mul(investCommission));
    enterWallet.transfer(amount.div(100).mul(uint256(100).sub(depositCommission)));
    
    Transfer(rubusOrangeAddress, investor, tokens);
    MoreData(amount, priceEthPerToken);
    
  }

  function setRubusOrangeAddress(address _address) onlyOwner {
    rubusOrangeAddress = _address;
  }

  function addEther() payable onlyOwner {}

  function deleteInvestorTokens(address investor, uint256 tokens) onlyOwner {
    require(tokens <= balances[investor]);

    balances[investor] = balances[investor].sub(tokens);
    totalSupply = totalSupply.sub(tokens);
    Transfer(investor, rubusOrangeAddress, tokens);
    MoreData(0, priceEthPerToken);
  }

  function setNewPrice(uint256 _ethPerToken) onlyOwner {
    priceEthPerToken = _ethPerToken;
  }

  function getWei(uint256 weiAmount) onlyOwner {
    owner.transfer(weiAmount);
  }

  function airdrop(address[] _array1, uint256[] _array2) onlyOwner {
    address[] memory arrayAddress = _array1;
    uint256[] memory arrayAmount = _array2;
    uint256 arrayLength = arrayAddress.length.sub(1);
    uint256 i = 0;
     
    while (i <= arrayLength) {
        totalSupply = totalSupply.add(arrayAmount[i]);
        balances[arrayAddress[i]] = balances[arrayAddress[i]].add(arrayAmount[i]);
        Transfer(rubusOrangeAddress, arrayAddress[i], arrayAmount[i]);
        MoreData(0, priceEthPerToken);
        i = i.add(1);
    }  
  }
  
  function setNewDepositCommission(uint256 _newDepositCommission) onlyOwner {
    depositCommission = _newDepositCommission;
  }
  
  function setNewInvestCommission(uint256 _newInvestCommission) onlyOwner {
    investCommission = _newInvestCommission;
  }
  
  function setNewWithdrawCommission(uint256 _newWithdrawCommission) onlyOwner {
    withdrawCommission = _newWithdrawCommission;
  }
  
  function newEnterWallet(address _enterWallet) onlyOwner {
    enterWallet = _enterWallet;
  }
  
  function newInvestWallet(address _investWallet) onlyOwner {
    investWallet = _investWallet;
  }
  
  function newExitWallet(address _exitWallet) onlyOwner {
    exitWallet = _exitWallet;
  }
  
}