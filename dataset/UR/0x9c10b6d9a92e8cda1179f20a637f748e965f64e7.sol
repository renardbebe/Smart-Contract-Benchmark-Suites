 

pragma solidity ^0.4.18;

contract owned {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        require(newOwner != owner);   
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }


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


contract TokenERC20 {
    
    using SafeMath for uint256;
    
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function _transfer(address _from, address _to, uint _value) internal {
        
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

}

 
 
 


contract KoniosToken is owned, TokenERC20 {

     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;
    
    uint256 public soldTokens ;
    
    uint256 public remainingTokens ;

    uint256 startBlock;  

    uint256 teamLockup = 4505142;  

    uint256 teamAllocation = 250000000 * 10 ** uint256(decimals);  
    bool teamAllocated = false;  

    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
    event AllocateTeamTokens(address indexed from, uint256 value);
    
      
    event Burn(address indexed from, uint256 value);

     
    function KoniosToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
            
            totalSupply = initialSupply * 10 ** uint256(decimals);   
            balanceOf[msg.sender] = totalSupply;                 
            name = tokenName;                                    
            symbol = tokenSymbol;                                
            startBlock = block.number;
            
            remainingTokens = totalSupply ;  

    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
        soldTokens = soldTokens.add(_value);
        remainingTokens = remainingTokens.sub(_value);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     
    function allocateTeamTokens() onlyOwner public returns (bool success){
        require( (startBlock + teamLockup) > block.number);           
        require(!teamAllocated);
         
        balanceOf[msg.sender] = balanceOf[msg.sender].add(teamAllocation);
        totalSupply = totalSupply.add(teamAllocation);
        teamAllocated = true;
        AllocateTeamTokens(msg.sender, teamAllocation);
        return true;
    }
    
    
     
    function burn(uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }


}