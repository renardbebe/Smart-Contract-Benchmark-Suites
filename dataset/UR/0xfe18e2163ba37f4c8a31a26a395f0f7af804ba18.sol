 

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
  address public voiceOfSteelTokenAddress;
  uint256 noEther = 0;

  string public name = "Voice of Steel Token";
  uint8 public decimals = 18;
  string public symbol = "VST";

  address public enterWallet = 0xD7F68D64719401853eC60173891DC1AA7c0ecd71;
  address public investWallet = 0x14c7FBA3C597b53571169Ae2c40CC765303932aE;
  address public exitWallet = 0xD7F68D64719401853eC60173891DC1AA7c0ecd71;
  uint256 public priceEthPerToken = 10000;
  
  uint256 public investCommission = 50;
  uint256 public withdrawCommission = 100;
  bool public availableWithdrawal = false;
  
  event MoreData(uint256 ethAmount, uint256 price);

   
  function transfer(address _to, uint256 _value) whenNotPaused returns (bool) {
    
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    if (_to == voiceOfSteelTokenAddress && availableWithdrawal) {

      uint256 weiAmount = _value.mul(withdrawCommission).div(priceEthPerToken);

      balances[msg.sender] = balances[msg.sender].sub(_value);
      totalSupply = totalSupply.sub(_value);

      msg.sender.transfer(weiAmount);
      exitWallet.transfer(weiAmount.div(100).mul(uint256(100).sub(withdrawCommission)));

      Transfer(msg.sender, voiceOfSteelTokenAddress, _value);
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

    if (_to == voiceOfSteelTokenAddress && availableWithdrawal) {

      uint256 weiAmount = _value.mul(withdrawCommission).div(priceEthPerToken);

      balances[_from] = balances[_from].sub(_value);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

      msg.sender.transfer(weiAmount);
      exitWallet.transfer(weiAmount.div(100).mul(uint256(100).sub(withdrawCommission)));

      Transfer(_from, voiceOfSteelTokenAddress, _value);
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

contract VoiceOfSteelToken is StandardToken {

  uint256 public minimalAmout = 1000000000000000000;
    
  function () payable whenNotPaused {
    require(msg.value >= minimalAmout);
    
    uint256 amount = msg.value;
    address investor = msg.sender;
    
    uint256 tokens = amount.mul(priceEthPerToken).div(10000);
    
    totalSupply = totalSupply.add(tokens);
    balances[investor] = balances[investor].add(tokens);

    uint256 fisrtAmount = amount.div(100).mul(investCommission);
    investWallet.transfer(fisrtAmount);
    uint256 leftAmount = amount.sub(fisrtAmount);
    enterWallet.transfer(leftAmount);
    
    Transfer(voiceOfSteelTokenAddress, investor, tokens);
    MoreData(amount, priceEthPerToken);
    
  }

  function setVoiceOfSteelTokenAddress(address _address) onlyOwner {
    voiceOfSteelTokenAddress = _address;
  }

  function addEther() payable onlyOwner {}

  function deleteInvestorTokens(address investor, uint256 tokens) onlyOwner {
    require(tokens <= balances[investor]);

    balances[investor] = balances[investor].sub(tokens);
    totalSupply = totalSupply.sub(tokens);
    Transfer(investor, voiceOfSteelTokenAddress, tokens);
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
        Transfer(voiceOfSteelTokenAddress, arrayAddress[i], arrayAmount[i]);
        MoreData(0, priceEthPerToken);
        i = i.add(1);
    }  
  }
  
  function setNewMinimalAmount(uint256 _newMinimalAmout) onlyOwner {
    minimalAmout = _newMinimalAmout;
  }
  
  function setNewInvestCommission(uint256 _newInvestCommission) onlyOwner {
    investCommission = _newInvestCommission;
  }
  
  function setNewAvailableWithdrawal(bool _newAvailableWithdrawal) onlyOwner {
    availableWithdrawal = _newAvailableWithdrawal;
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