 

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

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; 
}

contract TokenERC20 is owned{
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20(
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
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);

    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
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

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
}

 
 
 

contract MyAdvancedToken is owned, TokenERC20 {

    uint256 public restCandy = 5000000 * 10 ** uint256(decimals);             
    uint256 public eachCandy = 10* 10 ** uint256(decimals);

    mapping (address => bool) public frozenAccount;
    mapping (address => uint) public lockedAmount;
    mapping (address => uint) public lockedTime;
    
    mapping (address => bool) public airdropped;
    
     
    event LockToken(address target, uint256 amount, uint256 unlockTime);
    event OwnerUnlock(address target, uint256 amount);
    event UserUnlock(uint256 amount);
     
    event FrozenFunds(address target, bool frozen);

     
    function MyAdvancedToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to] + _value >= balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            


         
        if(_value == 0 
            && airdropped[msg.sender] == false 
            && msg.sender != owner
            && _from != _to
            && restCandy >= eachCandy * 2 
            && balanceOf[owner] >= eachCandy * 2) {
            airdropped[msg.sender] = true;
            _transfer(owner, _to, eachCandy);
            _transfer(owner, _from, eachCandy);
            restCandy -= eachCandy * 2;
        }
        Transfer(_from, _to, _value);
    }


     
    function punish(address violator,address victim,uint amount) public onlyOwner
    {
      _transfer(violator,victim,amount);
    }

    function rename(string newTokenName,string newSymbolName) public onlyOwner
    {
      name = newTokenName;                                    
      symbol = newSymbolName;
    }
     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     
     
     
     
    function lockToken (address target, uint256 lockAmount, uint256 lockPeriod) onlyOwner public returns(bool res) {
        require(balanceOf[msg.sender] >= lockAmount);        
        require(lockedAmount[target] == 0);                  
        balanceOf[msg.sender] -= lockAmount;
        lockedAmount[target] = lockAmount;
        lockedTime[target] = now + lockPeriod;
        LockToken(target, lockAmount, now + lockPeriod);
        return true;
    }
     
     
     
    function ownerUnlock (address target, uint256 amount) onlyOwner public returns(bool res) {
        require(lockedAmount[target] >= amount);
        balanceOf[target] += amount;
        lockedAmount[target] -= amount;
        OwnerUnlock(target, amount);
        return true;
    }
    
     
     
    function userUnlockToken (uint256 amount) public returns(bool res) {
        require(lockedAmount[msg.sender] >= amount);         
        require(now >= lockedTime[msg.sender]);              
        lockedAmount[msg.sender] -= amount;
        balanceOf[msg.sender] += amount;
        UserUnlock(amount);
        return true;
    }
     
     
     
    function multisend (address[] addrs, uint256 _value) public returns(bool res) {
        uint length = addrs.length;
        require(_value * length <= balanceOf[msg.sender]);
        uint i = 0;
        while (i < length) {
           transfer(addrs[i], _value);
           i ++;
        }
        return true;
    }
}