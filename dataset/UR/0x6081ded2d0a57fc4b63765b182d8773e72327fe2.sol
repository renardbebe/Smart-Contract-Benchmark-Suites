 

pragma solidity ^0.4.24;

contract Owned {
    
     
     
    address public owner;
    address internal newOwner;
    
     
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    event updateOwner(address _oldOwner, address _newOwner);
    
     
    function changeOwner(address _newOwner) public onlyOwner returns(bool) {
        require(owner != _newOwner);
        newOwner = _newOwner;
        return true;
    }
    
     
    function acceptNewOwner() public returns(bool) {
        require(msg.sender == newOwner);
        emit updateOwner(owner, newOwner);
        owner = newOwner;
        return true;
    }
}

contract SafeMath {
     
    function safeMul(uint a, uint b) pure internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
     
    function safeSub(uint a, uint b) pure internal returns (uint) {
        assert(b <= a);
        return a - b;
    }
    
     
    function safeAdd(uint a, uint b) pure internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

}

contract Pausable is Owned{
    
    bool private _paused = false;
    
    event Paused();
    event Unpaused();
    
     
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }
    
     
    modifier whenPaused() {
        require(_paused);
        _;
    }
    
     
    function pause() whenNotPaused public onlyOwner {
        _paused = true;
        emit Paused();
    } 
    
     
    function unpause() whenPaused public onlyOwner {
        _paused = false;
        emit Unpaused();
    }
    
     
    function paused() view public returns(bool) {
        return _paused;
    }
}


contract ERC20Token {
     
     
    uint256 public totalSupply;
    
     
    mapping (address => uint256) public balances;
    
     
     
    function balanceOf(address _owner) constant public returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);
    
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract CUSEtoken is ERC20Token, Pausable, SafeMath {
    
    string public name = "USE Call Option";
    string public symbol = "CUSE";
    uint public decimals = 18;
    
    uint256 public totalSupply = 0;
    
    function transfer(address _to, uint256 _value) whenNotPaused public returns (bool success) {
     
     
     
        if (balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool success) {
     
        if (balances[_from] >= _value && allowances[_from][msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
          balances[_to] += _value;
          balances[_from] -= _value;
          allowances[_from][msg.sender] -= _value;
          emit Transfer(_from, _to, _value);
          return true;
        } else { return false; }
    }
    
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }
    
    function approve(address _spender, uint256 _value) whenNotPaused public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
    
    function increaseAllowance(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        allowances[msg.sender][_spender] = safeAdd(allowances[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }
    
    function decreaseAllowance(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        allowances[msg.sender][_spender] = safeSub(allowances[msg.sender][_spender], _subtractedValue);
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }
    
    mapping (address => uint256) public balances;
    
    mapping (address => mapping (address => uint256)) allowances;
}

contract CUSEcontract is CUSEtoken{
    
    address public usechainAddress;
    uint constant public INITsupply = 9e27;
    uint constant public CUSE12 = 75e24;
    uint constant public USEsold = 3811759890e18;
    function () payable public {
        revert();
    }
    
    constructor(address _usechainAddress) public {
        usechainAddress = _usechainAddress;
        totalSupply = INITsupply - CUSE12 - USEsold;
        balances[usechainAddress] = totalSupply;
        emit Transfer(address(this), usechainAddress, totalSupply);
    }

}