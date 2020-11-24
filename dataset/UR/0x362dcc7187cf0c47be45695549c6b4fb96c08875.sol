 

pragma solidity ^0.4.16;

contract owned {
    address public owner;
    address public admin;

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
    
    function adminCreat(address _admin) onlyOwner public {
       admin = _admin;
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    function transferAdmin(address newAdmin) onlyOwner public {
        admin = newAdmin;
    }
    
    
    
    
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
     
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

contract Membership is owned {
   
    mapping (address => uint) public memberId;
    mapping (address => uint) balances;
    Member[] public members;
    
    uint256 public totalSupply;
    
    
    
    event MembershipChanged(address member, bool isMember);

    struct Member {
        address member;
        string name;
        uint memberSince;
    }
    
        modifier onlyMembers {
        require(memberId[msg.sender] != 0);
        _;
    }
    
        function addMember(address targetMember, string memberName) onlyOwner public {
        uint id = memberId[targetMember];
        if (id == 0) {
            memberId[targetMember] = members.length;
            id = members.length++;
        }

        members[id] = Member({member: targetMember, memberSince: now, name: memberName});
        MembershipChanged(targetMember, true);
    }
    
        function removeMember(address targetMember) onlyOwner public {
        require(memberId[targetMember] != 0);

        for (uint i = memberId[targetMember]; i<members.length-1; i++){
            members[i] = members[i+1];
        }
        delete members[members.length-1];
        members.length--;
    }
    
    
}

 
 
 

contract bonusToken is owned, TokenERC20, Membership  {

    uint256 public sellPrice;
    uint256 public buyPrice;
    uint256 public dividend;
    uint256 public pantry;
    uint256 public pantryT;
    uint256 public stopSetPrice = 1000000000000000000000000;

    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
    function bonusToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] > _value);                 
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        Transfer(_from, _to, _value);
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    
     
        function _mintToken(address target, uint256 mintedAmount) internal {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
        dividend += mintedAmount / 10;
        totalSupply += mintedAmount / 10;
    }

   

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     
     
     
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        require (totalSupply <= stopSetPrice) ;
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

     
    function buy() payable public {
        uint amount = msg.value * buyPrice;                
        _mintToken(msg.sender, amount);                     
        
    }

     
     
    function sell(uint256 amount) public {
        amount = amount * 10 ** uint256(decimals) ;
        require(this.balance >= amount / sellPrice);       
        _transfer(msg.sender, this, amount);               
        msg.sender.transfer(amount / sellPrice);           
    }

     
        function dividendDistribution () onlyOwner public {
         Transfer(0, this, dividend);
         uint256 divsum = dividend / members.length; 
         dividend = 0;
         for (uint i = 0; i < members.length; i++) {
        address AdToDiv = members[i].member ;
         balanceOf[AdToDiv] += divsum;
         Transfer(this, AdToDiv, divsum);
                }
       
}
     
    function remainPantry () onlyOwner public returns (uint256, uint256) {
        pantry = this.balance;
        pantryT = balanceOf[this];
        
        return (pantry, pantryT);
             
           
    }
    
     
     
    function robPantry (address target, uint256 amount) onlyOwner public {
        uint256 rob = amount * 10 ** uint256(decimals) ;
        require(rob <= this.balance);
        target.transfer(rob);
    }
    
     
     
     
     function mintToClient(address client, uint256 amount) onlyAdmin public {
        _mintToken(client, amount);                     
        
    
}
      
        function robPantryT (address target, uint256 amount) onlyOwner public {
        require(amount <= balanceOf[this]);
        balanceOf[this] -= amount;                          
        balanceOf[target] += amount;                            
        Transfer(this, target, amount);
     }
}