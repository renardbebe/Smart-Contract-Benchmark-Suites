 

 
pragma solidity ^0.4.24;

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract Owned {
    address public ownerAddr;
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        ownerAddr = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == ownerAddr);
        _;
    }
    
    function transferOwnership(address _newOwner) onlyOwner public {
        require(_newOwner != 0x0);
        ownerAddr = _newOwner;
        emit TransferOwnership(ownerAddr, _newOwner);
    }
}

contract ERC20 {
     
    function totalSupply() public view returns (uint256 _totalSupply);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract YomiToken is Owned, ERC20{
    using SafeMath for uint256;
    
     
    string constant public name = "YOMI Token";
    string constant public symbol = "YOMI";
    uint8 constant public decimals = 18;
    uint256 total_supply = 1000000000e18;  
    uint256 constant public teamReserve = 100000000e18;  
    uint256 constant public foundationReserve = 200000000e18;  
    uint256 constant public startTime = 1533110400;  
    uint256 public lockReleaseDate6Month;  
    uint256 public lockReleaseDate1Year;  
    address public teamAddr;
    address public foundationAddr;
    
     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public frozenAccounts;
    
     
    event FrozenFunds(address _target, bool _freeze);
    
     
    constructor(address _teamAddr, address _foundationAddr) public {
        teamAddr = _teamAddr;
        foundationAddr = _foundationAddr;
        lockReleaseDate6Month = startTime + 182 days;
        lockReleaseDate1Year = startTime + 365 days;
        balances[ownerAddr] = total_supply;  
    }
    
     
    function freezeAccount(address _target, bool _freeze) onlyOwner public {
        frozenAccounts[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }
    
     
    function totalSupply() public view returns (uint256 _totalSupply) {
        _totalSupply = total_supply;
    }
    
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
     
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);
        
         
        if (_from == teamAddr && now < lockReleaseDate6Month) {
            require(balances[_from].sub(_value) >= teamReserve);
        }
         
        if (_from == foundationAddr && now < lockReleaseDate1Year) {
            require(balances[_from].sub(_value) >= foundationReserve);
        }
        
         
        require(balances[_from] >= _value); 
         
        require(balances[_to] + _value > balances[_to]); 
         
        require(!frozenAccounts[_from]);
        require(!frozenAccounts[_to]);
        
         
        uint256 previousBalances = balances[_from].add(balances[_to]);
         
        balances[_from] = balances[_from].sub(_value);
         
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
         
        assert(balances[_from] + balances[_to] == previousBalances);
    }
    
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != 0x0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}