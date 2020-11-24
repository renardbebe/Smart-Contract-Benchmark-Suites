 

pragma solidity ^0.4.21 ;

contract ERC20Basic {
  uint256 public totalSupply;
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
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);  
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
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


contract OG is Ownable , StandardToken {
 
  string public constant name = "OnlyGame Token";
  string public constant symbol = "OG";
  uint8 public constant decimals = 18;
  uint256 public constant totalsum =  1000000000 * 10 ** uint256(decimals);
   
  address public crowdSaleAddress;
  bool public locked;
 
  uint256 public __price = (1 ether / 20000  )   ;
 
  function OG() public {
      crowdSaleAddress = msg.sender;
       unlock(); 
      totalSupply = totalsum;   
      balances[msg.sender] = totalSupply; 
  }
 
   
  modifier onlyAuthorized() {
      if (msg.sender != owner && msg.sender != crowdSaleAddress) 
          revert();
      _;
  }
 
  function priceof() public view returns(uint256) {
    return __price;
  }
 
  function updateCrowdsaleAddress(address _crowdSaleAddress) public onlyOwner() {
    require(_crowdSaleAddress != address(0));
    crowdSaleAddress = _crowdSaleAddress; 
  }
 
  function updatePrice(uint256 price_) public onlyOwner() {
    require( price_ > 0);
    __price = price_; 
  }
 
  function unlock() public onlyAuthorized {
      locked = false;
  }
  function lock() public onlyAuthorized {
      locked = true;
  }
 
  function toEthers(uint256 tokens) public view returns(uint256) {
    return tokens.mul(__price) / ( 10 ** uint256(decimals));
  }
  function fromEthers(uint256 ethers) public view returns(uint256) {
    return ethers.div(__price) * 10 ** uint256(decimals);
  }
 
  function returnTokens(address _member, uint256 _value) public onlyAuthorized returns(bool) {
        balances[_member] = balances[_member].sub(_value);
        balances[crowdSaleAddress] = balances[crowdSaleAddress].add(_value);
        emit  Transfer(_member, crowdSaleAddress, _value);
        return true;
  }
 
  function buyOwn(address recipient, uint256 ethers) public payable onlyOwner returns(bool) {
    return mint(recipient, fromEthers(ethers));
  }
  function mint(address to, uint256 amount) public onlyOwner returns(bool)  {
    require(to != address(0) && amount > 0);
    totalSupply = totalSupply.add(amount);
    balances[to] = balances[to].add(amount );
    emit Transfer(address(0), to, amount);
    return true;
  }
  function burn(address from, uint256 amount) public onlyOwner returns(bool) {
    require(from != address(0) && amount > 0);
    balances[from] = balances[from].sub(amount );
    totalSupply = totalSupply.sub(amount );
    emit Transfer(from, address(0), amount );
    return true;
  }
  function sell(address recipient, uint256 tokens) public payable onlyOwner returns(bool) {
    burn(recipient, tokens);
    recipient.transfer(toEthers(tokens));
  }
 
  function mintbuy(address to, uint256 amount) public  returns(bool)  {
    require(to != address(0) && amount > 0);
    totalSupply = totalSupply.add(amount );
    balances[to] = balances[to].add(amount );
    emit Transfer(address(0), to, amount );
    return true;
  }
   function buy(address recipient) public payable returns(bool) {
    return mintbuy(recipient, fromEthers(msg.value));
  }

 
  function() public payable {
    buy(msg.sender);
  }

 
}