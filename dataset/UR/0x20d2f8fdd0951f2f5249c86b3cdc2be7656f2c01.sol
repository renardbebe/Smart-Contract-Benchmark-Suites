 

pragma solidity ^0.4.18;

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

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract MyTokenEVC is owned {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public _totalSupply;
     
    mapping (address => uint256) public _balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
     
    event Transfer(address indexed from, address indexed to, uint256 value);
     
    event Burn(address indexed from, uint256 value);
     
    function MyTokenEVC() public {
        _totalSupply = 0 * 10 ** uint256(decimals);   
        _balanceOf[msg.sender] = _totalSupply;                 
        name = "MyTokenEVC 2";                                    
        symbol = "MEVC2";                                
    }
    
    function name() public constant returns (string) {
        return name;
    }
    
    function symbol() public constant returns (string) {
        return symbol;
    }
    
    function decimals() public constant returns (uint8) {
        return decimals;
    }
    
    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address tokenHolder) public constant returns (uint256) {
        return _balanceOf[tokenHolder];
    }
    
    mapping (address => bool) public frozenAccount;
    
    event FrozenFunds(address target, bool frozen);

    function freezeAccount (address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    
    
     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(_balanceOf[_from] >= _value);
         
        require(_balanceOf[_to] + _value > _balanceOf[_to]);
         
        require(!frozenAccount[msg.sender]);
         
        uint previousBalances = _balanceOf[_from] + _balanceOf[_to];
         
        _balanceOf[_from] -= _value;
         
        _balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(_balanceOf[_from] + _balanceOf[_to] == previousBalances);
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
     
    function burn(uint256 _value) onlyOwner public returns (bool success) {
        require(_balanceOf[msg.sender] >= _value);    
        _balanceOf[msg.sender] -= _value;             
        _totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }
     
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(_balanceOf[_from] >= _value);                 
     
        _balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        _totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
     
     
    function mintToken(uint256 mintedAmount) onlyOwner public {
        _balanceOf[owner] += mintedAmount;
        _totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
    }
}