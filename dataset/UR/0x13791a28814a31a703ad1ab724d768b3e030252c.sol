 

pragma solidity ^0.4.16;


contract owned {

    address public owner;
    address[] public admins;
    mapping (address => bool) public isAdmin;

    function owned() public {
        owner = msg.sender;
        isAdmin[msg.sender] = true;
        admins.push(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin {
        require(isAdmin[msg.sender]);
        _;
    }

    function addAdmin(address user) onlyOwner public {
        require(!isAdmin[user]);
        isAdmin[user] = true;
        admins.push(user);
    }

    function removeAdmin(address user) onlyOwner public {
        require(isAdmin[user]);
        isAdmin[user] = false;
        for (uint i = 0; i < admins.length - 1; i++)
            if (admins[i] == user) {
                admins[i] = admins[admins.length - 1];
                break;
            }
        admins.length -= 1;
    }

    function replaceAdmin(address oldAdmin, address newAdmin) onlyOwner public {
        require(isAdmin[oldAdmin]);
        require(!isAdmin[newAdmin]);
        for (uint i = 0; i < admins.length; i++)
            if (admins[i] == oldAdmin) {
                admins[i] = newAdmin;
                break;
            }
        isAdmin[oldAdmin] = false;
        isAdmin[newAdmin] = true;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    function getAdmins() public view returns (address[]) {
        return admins;
    }

}


interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; 
}


contract TokenERC20 {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20(
        uint256 initialSupply,
        address initTarget,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[initTarget] = totalSupply;                     
        name = tokenName;                                        
        symbol = tokenSymbol;                                    
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
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


contract ZingCoin is owned, TokenERC20 {

    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

     
    function ZingCoin(
        uint256 initialSupply,
        address initTarget,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, initTarget, tokenName, tokenSymbol) public {}

     
    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        Transfer(_from, _to, _value);
    }

     
    function rollIn(address target, uint256 amount) onlyAdmin public {
        balanceOf[target] += amount;
        totalSupply += amount;
        Transfer(0, this, amount);
        Transfer(this, target, amount);
    }

     
    function rollOut(address target, uint256 amount) onlyAdmin public returns (bool success) {
        require(balanceOf[target] >= amount);        
        balanceOf[target] -= amount;                 
        totalSupply -= amount;                       
        Burn(target, amount);
        return true;
    }

     
    function freezeAccount(address target, bool freeze) onlyAdmin public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function changeName(string _name) onlyOwner public {
        name = _name;
    }

    function changeSymbol(string _symbol) onlyOwner public {
        symbol = _symbol;
    }

}