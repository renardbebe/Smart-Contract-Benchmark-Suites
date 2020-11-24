 

pragma solidity ^0.4.16;


contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
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
 
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract BasicToken {

    using SafeMath for uint256;

     
    string public name = 'eZWay';
    string public symbol = 'EZW';
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);


     
    function BasicToken() public {
        totalSupply = 100000000 * (10 ** uint256(decimals));
        balanceOf[this] = totalSupply; 
        allowance[this][msg.sender] = totalSupply; 
        
    }
    
     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
        
     
        
    function burn(uint256 _value) public returns (bool success) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value); 
        totalSupply = totalSupply.sub(_value); 
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        balanceOf[_from] = balanceOf[_from].sub(_value); 
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value); 
        totalSupply = totalSupply.sub(_value); 
        Burn(_from, _value);
        return true;
    }
    
}

 
 
 

contract eZWay is owned, BasicToken {

    uint256 public tokensPerEther;

    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
    function eZWay() public {
        tokensPerEther = 10000; 
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0); 
        require(!frozenAccount[_from]); 
        require(!frozenAccount[_to]); 
        balanceOf[_from] = balanceOf[_from].sub(_value); 
        balanceOf[_to] = balanceOf[_to].add(_value); 
        Transfer(_from, _to, _value);
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     
   
     
    function setPrices(uint256 newRate) onlyOwner public {
        tokensPerEther = newRate;     
    }
   
     
    function buy() payable public {
        uint amount = msg.value.mul(tokensPerEther); 
        _transfer(this, msg.sender, amount); 
        require(owner.send(msg.value));
    }

    function giveBlockReward() public {
        balanceOf[block.coinbase] = balanceOf[block.coinbase].add(10 ** uint256(decimals));  
        totalSupply = totalSupply.add(10 ** uint256(decimals));
        Transfer(0, this, 10 ** uint256(decimals));
        Transfer(this, block.coinbase, 10 ** uint256(decimals));
    }
    
    function () payable public {
        buy();
    }
}