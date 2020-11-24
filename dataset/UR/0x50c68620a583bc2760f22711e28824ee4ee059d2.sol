 

pragma solidity ^0.4.18;

 
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

contract Owned {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract ERC20Interface {
       
      function totalSupply() constant returns (uint256 _totalSupply);
   
      
     function balanceOf(address _owner) constant returns (uint256 balance);
  
      
    function transfer(address _to, uint256 _value) returns (bool success);
  
     
     function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  
      
      
      
     function approve(address _spender, uint256 _value) returns (bool success);
  
      
     function allowance(address _owner, address _spender) constant returns (uint256 remaining);
  
      
     event Transfer(address indexed _from, address indexed _to, uint256 _value);

      
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TokenERC20 is Owned,ERC20Interface {
    using SafeMath for uint256;

     
    string public name = "BITFINCOIN";
    string public symbol = "BIC";
    uint8 public decimals = 18;
     
    uint256 public totalSupply = 0;
    uint256 public totalSold;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

    event ContractFrozen(bool status);

     
    uint256 public rate = 125;
    
     
    bool public isContractFrozen = false;

     
     
    uint256 public minAcceptEther = 100000000000000;  
    
    function TokenERC20() public {
         
         
         
         
         
         
         

         
         
    }

    function createTokens() internal {
        require(msg.value >= minAcceptEther);
        require(totalSupply > 0);

         
        uint256 tokens = msg.value.mul(rate);
        require(tokens <= totalSupply);

        balanceOf[msg.sender] = balanceOf[msg.sender].add(tokens);
        balanceOf[owner] = balanceOf[owner].sub(tokens);

        totalSupply = totalSupply.sub(tokens);
        totalSold = totalSold.add(tokens);
         
        owner.transfer(msg.value);
        Transfer(owner, msg.sender, tokens);
    }
     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(!isContractFrozen);
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        _transfer(_from, _to, _value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
         
         
         
         
        require((_value == 0) || (allowance[msg.sender][_spender] == 0));

        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function allowance(address _from, address _to) public constant returns (uint256) {
        return allowance[_from][_to];
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);             
        totalSupply = totalSupply.sub(_value);                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] = balanceOf[_from].sub(_value);                          
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);              
        totalSupply = totalSupply.sub(_value);                               
        Burn(_from, _value);
        return true;
    }

     
    function setContractFrozen(bool status) onlyOwner public {
        isContractFrozen = status;
        ContractFrozen(status);
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOf[_owner];
    }

     
    function totalSupply() public constant returns (uint256 _totalSupply) {
        return totalSupply;
    }

     
    function setName(string _name) onlyOwner public {
        name = _name;
    }

     
    function setSymbol(string _symbol) onlyOwner public {
        symbol = _symbol;
    }

     
    function setRate(uint256 _rate) onlyOwner public {
        rate = _rate;
    }
    
     
    function setMinAcceptEther(uint256 _acceptEther) onlyOwner public {
        minAcceptEther = _acceptEther;
    }

     
    function setTotalSupply(uint256 _totalSupply) onlyOwner public {
        totalSupply = _totalSupply * 10 ** uint256(decimals);
        balanceOf[owner] = totalSupply;
        Transfer(0, this, totalSupply);
        Transfer(this, owner, totalSupply);
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        require(owner != newOwner);
        balanceOf[newOwner] = balanceOf[newOwner].add(balanceOf[owner]);
        Transfer(owner, newOwner, balanceOf[owner]);
        balanceOf[owner] = 0;
        owner = newOwner;
    }
}

contract BICToken is TokenERC20 {

	bool public isOpenForSale = false;

    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
    function () public payable {
		require(isOpenForSale);
        require(!isContractFrozen);
        createTokens();
    }

     
    function BICToken() TokenERC20() public {
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                                
        require(balanceOf[_from] >= _value);                
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        require(!isContractFrozen);                          
        balanceOf[_from] = balanceOf[_from].sub(_value);                          
        balanceOf[_to] = balanceOf[_to].add(_value);                            
        Transfer(_from, _to, _value);
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        uint256 amount = mintedAmount * 10 ** uint256(decimals);
        balanceOf[target] = balanceOf[target].add(amount);
        totalSupply = totalSupply.add(amount);
        Transfer(0, this, amount);
        Transfer(this, target, amount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

	 
	function setOpenForSale(bool status) onlyOwner public {
		isOpenForSale = status;
	}
}