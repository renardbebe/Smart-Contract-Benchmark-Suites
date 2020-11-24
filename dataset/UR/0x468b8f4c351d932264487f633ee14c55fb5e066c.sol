 

pragma solidity ^0.4.21;
 
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic, Ownable {
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

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 
contract MintableToken is StandardToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


contract TN is Ownable, MintableToken {
  using SafeMath for uint256;    
  string public constant name = "TNcoin";
  string public constant symbol = "TNC";
  uint32 public constant decimals = 18;
  address public addressTeam; 
  uint public summTeam;
  
  function TN() public {
    addressTeam =  0x799AAE2118f10d5148C9D7275EaF95bc0Cb6D6f9;
    summTeam = 5050000 * (10 ** uint256(decimals));
     
    mint(addressTeam, summTeam);
  }
}

 
contract Crowdsale is Ownable {
  using SafeMath for uint256;
   
  uint softcap;
   
  uint hardcap;  
  TN public token;
   
  mapping(address => uint) public balances;

   
   
     
  uint256 public startIco;
     
  uint256 public endIco;    

   
  

  uint256 public totalSoldTokens;
  
   
  uint256 public rateIco;   

   
  address public wallet;
  
 
  event TokenProcurement(address indexed contributor, address indexed beneficiary, uint256 value, uint256 amount);
  
  function Crowdsale() public {
    token = createTokenContract();
     
    softcap = 10000000 * 1 ether; 
    hardcap = 50000000 * 1 ether;  	

     
     
       
    startIco = 1526403600; 
       
    endIco = 1539622800; 

     
    rateIco = 670; 
    
     
    wallet = 0xaa6072Cb5EcB3A1567F8Fdb4601620C4a808fD6c;
  }

  function setRateIco(uint _rateIco) public onlyOwner  {
    rateIco = _rateIco;
  }   
  
   
  function () external payable {
    procureTokens(msg.sender);
  }
  
  function createTokenContract() internal returns (TN) {
    return new TN();
  }
    
   
  function procureTokens(address beneficiary) public payable {
    uint256 tokens;
    uint256 weiAmount = msg.value;
    uint256 backAmount;
    require(beneficiary != address(0));

     
    if (now >= startIco && now < endIco && totalSoldTokens < hardcap){
      tokens = weiAmount.mul(rateIco);
      if (hardcap.sub(totalSoldTokens) < tokens){
        tokens = hardcap.sub(totalSoldTokens); 
        weiAmount = tokens.div(rateIco);
        backAmount = msg.value.sub(weiAmount);
      }
      totalSoldTokens = totalSoldTokens.add(tokens);
    }        
    require(tokens > 0);
    balances[msg.sender] = balances[msg.sender].add(msg.value);
    token.mint(msg.sender, tokens);
    if (backAmount > 0){
      balances[msg.sender] = balances[msg.sender].sub(backAmount);         
      msg.sender.transfer(backAmount);    
    }
    emit TokenProcurement(msg.sender, beneficiary, weiAmount, tokens);
  }

  function refund() public{
    require(totalSoldTokens < softcap && now > endIco);
    require(balances[msg.sender] > 0);
    uint value = balances[msg.sender];
    balances[msg.sender] = 0;
    msg.sender.transfer(value);
  }
  
  function transferEthToMultisig() public onlyOwner {
    address _this = this;
    require(totalSoldTokens >= softcap && now > endIco);  
    wallet.transfer(_this.balance);
  } 
    
}