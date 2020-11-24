 

pragma solidity 0.4.18;


contract Owned {

    
    
    address internal _owner;
    
     
    function Owned() public {
        
        _owner = msg.sender;
        
    }
    
    function owner() public view returns (address) {
        
        return _owner;
        
    }
    
    modifier onlyOwner {
        
        require(msg.sender == _owner);
        _;
        
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        
        require(_newOwner != address(0));
        _owner = _newOwner;
        
    }
}


contract VOCTOP25 is Owned {
    
     
    string  internal _name;
    string  internal _symbol;
    uint8   internal _decimals;
    uint256 internal _totalSupply;
    
     
    mapping (address => uint256)  internal _balanceOf;
    mapping (address => mapping (address => uint256)) internal _allowance;
    mapping (address => bool) internal _frozenAccount;
    
     
    event Transfer(address indexed _from, address indexed _to, uint _value);
     
    event Mint(address indexed _to, uint256 _value);
     
    event Burn(address indexed _from, uint256 _value);
     
    event Approval(address indexed _owner, address indexed _spender, uint _value);
     
    event AccountFrozen(address indexed _account, bool _value);
       
     
    function VOCTOP25() public {
        
         
        _decimals = 18;
        
         
        _totalSupply = 0 * 10 ** uint256(_decimals);
        
         
        _balanceOf[msg.sender] = _totalSupply;
        
         
        _name = "Voice Of Coins TOP 25 Index Fund";   
        
         
        _symbol = "VOC25";   
        
    }
      
     
    function name() public view returns (string) {
        
        return _name;
        
    }
    
     
    function symbol() public view returns (string) {
        
        return _symbol;
        
    }
    
     
    function decimals() public view returns (uint8) {
        
        return _decimals;
        
    }
    
     
    function totalSupply() public view returns (uint256) {
        
        return _totalSupply;
        
    }
    
     
    function balanceOf(address _tokenHolder) public view returns (uint256) {
        
        return _balanceOf[_tokenHolder];
        
    }
    
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        
         
        bool transferResult = _transfer(msg.sender, _to, _value);  

        return transferResult;
        
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        
         
        if (msg.sender != _from) {
            require(_allowance[_from][msg.sender] >= _value);     
            _allowance[_from][msg.sender] -= _value;
        }
        
         
        bool transferResult = _transfer(_from, _to, _value); 

        return transferResult;
    }
    
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        
         
        _allowance[msg.sender][_spender] = _value;

         
        Approval(msg.sender, _spender, _value);

        return true;
        
    }
    
     
    function allowance(address _tokenOwner, address _spender) public view returns (uint256) {
        
        return _allowance[_tokenOwner][_spender];
        
    }
    
     
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
      
         
        require(_allowance[msg.sender][_spender] + _addedValue >= _allowance[msg.sender][_spender]);

         
        _allowance[msg.sender][_spender] += _addedValue;

         
        Approval(msg.sender, _spender, _allowance[msg.sender][_spender]);

        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
    
         
         
        if (_subtractedValue > _allowance[msg.sender][_spender]) {

            _allowance[msg.sender][_spender] = 0;

        } else {

            _allowance[msg.sender][_spender] -= _subtractedValue;

        }

         
        Approval(msg.sender, _spender, _allowance[msg.sender][_spender]);

        return true;
    }
    
     
    function burn(uint256 _value) public onlyOwner returns (bool success) {
        
         
        require(!_frozenAccount[_owner]);
        
         
        require(_balanceOf[_owner] >= _value);
        
         
        _balanceOf[_owner] -= _value;
        _totalSupply -= _value;
        
         
        Burn(_owner, _value);
        
        return true;
        
    }
    
     
    function burnFrom(address _from, uint256 _value) public onlyOwner returns (bool success) {
        
         
        bool bAccountFrozen = frozenAccount(_from);
        
         
        if (bAccountFrozen) {
             
            freezeAccount(_from, false);
        }
        
         
        _transfer(_from, _owner, _value);
        
         
        if (bAccountFrozen) {
            freezeAccount(_from, bAccountFrozen);
        }
        
         
        burn(_value);
        
        return true;
        
    }
    
     
    function mintToken(uint256 _mintedAmount) public onlyOwner {
        
         
        require(!_frozenAccount[_owner]);
        
         
        require(_balanceOf[_owner] + _mintedAmount >= _balanceOf[_owner]);
        
         
        require(_totalSupply + _mintedAmount >= _totalSupply);
        
        _balanceOf[_owner] += _mintedAmount;
        _totalSupply += _mintedAmount;
        
         
        Mint(_owner, _mintedAmount);
         
        Transfer(0, _owner, _mintedAmount);
        
    }
    
     
    function freezeAccount(address _target, bool _freeze) public onlyOwner returns (bool) {
        
         
        _frozenAccount[_target] = _freeze;
        
        
         
        AccountFrozen(_target, _freeze);
        
        return true;
    }
    
     
    function frozenAccount(address _account) public view returns (bool) {
        
        return _frozenAccount[_account];
        
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool success) {
        
         
        require(_to != 0x0);
        
         
        require(!_frozenAccount[_from]);
        require(!_frozenAccount[_to]);
        
         
        require(_balanceOf[_from] >= _value);
        
         
        require(_balanceOf[_to] + _value >= _balanceOf[_to]);
        
         
        _balanceOf[_from] -= _value;
        
         
        _balanceOf[_to] += _value;
            
         
        Transfer(_from, _to, _value);    

        return true;
        
    }
    
}