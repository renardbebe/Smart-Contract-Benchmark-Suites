 

pragma solidity ^0.4.18;
contract owned {
    
    address _owner;
    
    function owner() public  constant returns (address) {
        return _owner;
    }
    
    function owned() public {
        _owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }
    
    function transferOwnership(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        _owner = _newOwner;
    }
}
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }
contract MyTokenEVC is owned {
    
     
    string  _name;
    string _symbol;
    uint8  _decimals = 18;
    uint256 _totalSupply;
    
     
    mapping (address => uint256)  _balanceOf;
    mapping (address => mapping (address => uint256)) _allowance;
    mapping (address => bool) _frozenAccount;
    
     
    event Transfer(address indexed from, address indexed to, uint256 value);
     
    event Burn(address indexed from, uint256 value);
     
    event FrozenFunds(address target, bool frozen);
       
     
    function MyTokenEVC() public {
        
         
        _totalSupply = 0 * 10 ** uint256(_decimals);
        
         
        _balanceOf[msg.sender] = _totalSupply;
        
         
        _name = "MyTokenEVC 4";   
        
         
        _symbol = "MEVC4";                    
        
    }
    
     
    
    function name() public  constant returns (string) {
        return _name;
    }
    
     
    function symbol() public constant returns (string) {
        return _symbol;
    }
    
     
    function decimals() public constant returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }
    
     
    function balanceOf(address _tokenHolder) public constant returns (uint256) {
        return _balanceOf[_tokenHolder];
    }
    
     
    function allowance(address _tokenOwner, address _spender) public constant returns (uint256) {
        return _allowance[_tokenOwner][_spender];
    }
    
     
    function frozenAccount(address _account) public constant returns (bool) {
        return _frozenAccount[_account];
    }
    
     
    function _transfer(address _from, address _to, uint256 _value) internal {
        
         
        require(_to != 0x0);
        
         
        require(!_frozenAccount[msg.sender]);
        
         
        require(_balanceOf[_from] >= _value);
        
         
        require(_balanceOf[_to] + _value > _balanceOf[_to]);
        
         
        uint256 previousBalances = _balanceOf[_from] + _balanceOf[_to];
        
         
        _balanceOf[_from] -= _value;
        
         
        _balanceOf[_to] += _value;
        
        Transfer(_from, _to, _value);
        
         
        assert(_balanceOf[_from] + _balanceOf[_to] == previousBalances);
        
    }
    
     
    function transfer(address _to, uint256 _value) public {
        
        _transfer(msg.sender, _to, _value);
        
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        
         
        if (msg.sender != _from) {
            require(_allowance[_from][msg.sender] >= _value);     
            _allowance[_from][msg.sender] -= _value;
        }
        
        _transfer(_from, _to, _value);
        return true;
    }
    
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        
         
        require(_balanceOf[msg.sender] >= _value);
        
        _allowance[msg.sender][_spender] = _value;
        return true;
        
    }
    
     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    
    
    
     
    function burn(uint256 _value) onlyOwner public returns (bool success) {
        
         
        require(_balanceOf[_owner] >= _value);
        
         
        require(_totalSupply >= _value);
         
        _balanceOf[_owner] -= _value;
        _totalSupply -= _value;
        
        Burn(_owner, _value);
        return true;
        
    }
    
     
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        
         
        bool bAccountFrozen = frozenAccount(_from);
        
         
        if (bAccountFrozen) {
             
            freezeAccount(_from,false);
        }
        
         
        _transfer(_from, _owner, _value);
        
         
        if (bAccountFrozen) {
            freezeAccount(_from,bAccountFrozen);
        }
        
         
        burn(_value);
        
        return true;
    }
    
     
    function mintToken(uint256 mintedAmount) onlyOwner public {
        
         
        require(_balanceOf[_owner] + mintedAmount >= _balanceOf[_owner]);
        
         
        require(_totalSupply + mintedAmount >= _totalSupply);
        
        _balanceOf[_owner] += mintedAmount;
        _totalSupply += mintedAmount;
        
        Transfer(0, _owner, mintedAmount);
        
    }
    
     
    function freezeAccount (address target, bool freeze) onlyOwner public {
        
        _frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
        
    }
    
}