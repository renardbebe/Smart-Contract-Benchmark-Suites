 

pragma solidity ^0.4.8;

 

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract VNET is SafeMath {
    string constant tokenName = 'VNET';
    string constant tokenSymbol = 'VNET';
    uint8 constant decimalUnits = 8;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply = 100 * (10**8) * (10**8);  

    address public owner;
    
    mapping(address => bool) restrictedAddresses;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    modifier onlyOwner {
        assert(owner == msg.sender);
        _;
    }

     
    function VNET() public {
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalUnits;                             
        owner = msg.sender;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);               
        require(balanceOf[_to] + _value >= balanceOf[_to]);     
        require(!restrictedAddresses[msg.sender]);
        require(!restrictedAddresses[_to]);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);    
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                  
        Transfer(msg.sender, _to, _value);                   
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;             
        Approval(msg.sender, _spender, _value);               
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                   
        require(balanceOf[_to] + _value >= balanceOf[_to]);    
        require(_value <= allowance[_from][msg.sender]);       
        require(!restrictedAddresses[_from]);
        require(!restrictedAddresses[msg.sender]);
        require(!restrictedAddresses[_to]);
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);     
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);         
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function totalSupply() constant public returns (uint256 Supply) {
        return totalSupply;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balanceOf[_owner];
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
      return allowance[_owner][_spender];
    }

    function() public payable {
        revert();
    }

     
    function editRestrictedAddress(address _newRestrictedAddress) public onlyOwner {
        restrictedAddresses[_newRestrictedAddress] = !restrictedAddresses[_newRestrictedAddress];
    }

    function isRestrictedAddress(address _querryAddress) constant public returns (bool answer) {
        return restrictedAddresses[_querryAddress];
    }
}