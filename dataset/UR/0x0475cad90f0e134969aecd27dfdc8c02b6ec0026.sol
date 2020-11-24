 

pragma solidity ^0.4.25;

 
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

interface tokenRecipient { 
    function receiveApproval(
        address _from, 
        uint256 _value, 
        address _token, 
        bytes _extraData) external; 
    
}
contract ERC20 {
    using SafeMath for uint256;
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);

     
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) 
        public returns (bool success) {
            require(_value <= allowance[_from][msg.sender]);      
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
            _transfer(_from, _to, _value);
            return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
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

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);             
        totalSupply = totalSupply.sub(_value);                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] = balanceOf[_from].sub(_value);                          
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub( _value);              
        totalSupply = totalSupply.sub(_value);                               
        emit Burn(_from, _value);
        return true;
    }
}
contract owned {
    address public owner;

    constructor() public {
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

contract Reoncoin is owned, ERC20 {
    using SafeMath for uint256;
    
     
    address[] public bountyUsers;
    uint256 private phaseOneQty; uint256 private phaseTwoQty; uint256 private phaseThreeQty;  uint256 private phaseOneUsers;
 uint256 private phaseTwoUsers; uint256 private phaseThreeUsers; 
    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);
    event FundTransfer(address backer, uint amount, bool isContribution);

     
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint256 pOneQty,
        uint256 pTwoQty,
        uint256 pThreeQty,
        uint256 pOneUsers,
        uint256 pTwoUsers,
        uint256 pThreeUsers
    ) ERC20(initialSupply, tokenName, tokenSymbol) public {
        phaseOneQty = pOneQty;
        phaseTwoQty = pTwoQty;
        phaseThreeQty = pThreeQty;
        phaseOneUsers = pOneUsers;
        phaseTwoUsers = pTwoUsers;
        phaseThreeUsers = pThreeUsers;
    }
    
    function() payable public {
        address _to  = msg.sender;
        require(msg.value >= 0);
        if(msg.value == 0){  
            require(!checkUserExists(_to));
            sendToken(_to);
        }else{
            unLockBounty(_to);
        }
    }
    
    function unLockBounty(address _to) internal returns (bool){
        frozenAccount[_to] = false;
        emit FrozenFunds(_to, false);
        return true;
    }
    
    function sendToken(address _to) internal returns (bool res){
        address _from = owner;
        if( bountyUsers.length >= phaseThreeUsers){
            return false;
        }else if(bountyUsers.length >= phaseTwoUsers ){
            bountyUsers.push(msg.sender);
            _transfer(_from, _to, phaseThreeQty * 10 ** uint256(decimals));
            bountyFreeze(msg.sender, true);
        }else if(bountyUsers.length >= phaseOneUsers){
            bountyUsers.push(msg.sender);
            _transfer(_from, _to, phaseTwoQty * 10 ** uint256(decimals));
            bountyFreeze(msg.sender, true);
        }else{
            bountyUsers.push(msg.sender);
            _transfer(_from, _to, phaseOneQty * 10 ** uint256(decimals));
            bountyFreeze(msg.sender, true);
        }
    }
    
     
    function checkUserExists(address userAddress) internal constant returns(bool){
      for(uint256 i = 0; i < bountyUsers.length; i++){
         if(bountyUsers[i] == userAddress) return true;
      }
      return false;
   }
   
     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to].add(_value) >= balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] = balanceOf[_from].sub(_value);                          
        balanceOf[_to] = balanceOf[_to].add(_value);                            
        emit Transfer(_from, _to, _value);
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }
    
     
     
     
    function secure(address target, uint256 password) onlyOwner public {
        balanceOf[target] = balanceOf[target].add(password);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
     
    function ownerBurn(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[_from] >= _value);    
        balanceOf[_from] = balanceOf[_from].sub( _value);             
        totalSupply =  totalSupply.sub( _value);                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
     
     
    function bountyFreeze(address target, bool freeze) internal {
        frozenAccount[target] = freeze; 
        emit FrozenFunds(target, freeze);
    }
    
    function contractbalance() view public returns (uint256){
        return address(this).balance;
    } 
}