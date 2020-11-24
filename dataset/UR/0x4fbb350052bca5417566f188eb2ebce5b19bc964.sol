 

 

pragma solidity 0.4.25;
pragma experimental "v0.5.0";

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
        assert(c>=a && c>=b);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface ERC20Face {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);

    function balanceOf(address _who) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
}

contract ERC20 is ERC20Face {

    function transfer(address _to, uint256 _value)
        external
        returns (bool success)
    {
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
        external
        returns (bool success)
    {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        external
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function balanceOf(address _owner)
        external
        view
        returns (uint256)
    {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    uint256 public totalSupply;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract UnlimitedAllowanceToken is ERC20 {

    uint256 constant MAX_UINT = 2**256 - 1;

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value)
        external
        returns (bool)
    {
        uint256 allowance = allowed[_from][msg.sender];
        require(
            balances[_from] >= _value
            && allowance >= _value
            && balances[_to] + _value >= balances[_to]
        );
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }
}

 
 
 
contract RigoToken is UnlimitedAllowanceToken, SafeMath {

    string constant public name = "Rigo Token";
    string constant public symbol = "GRG";
    uint8 constant public decimals = 18;

    uint256 public totalSupply = 10**25;  
    address public minter;
    address public rigoblock;

     
    event TokenMinted(address indexed recipient, uint256 amount);

     
    modifier onlyMinter {
        require(msg.sender == minter);
        _;
    }

    modifier onlyRigoblock {
        require(msg.sender == rigoblock);
        _;
    }

    constructor(address _setMinter, address _setRigoblock) public {
        minter = _setMinter;
        rigoblock = _setRigoblock;
        balances[msg.sender] = totalSupply;
    }

     
     
     
     
    function mintToken(
        address _recipient,
        uint256 _amount)
        external
        onlyMinter
    {
        balances[_recipient] = safeAdd(balances[_recipient], _amount);
        totalSupply = safeAdd(totalSupply, _amount);
        emit TokenMinted(_recipient, _amount);
    }

     
     
    function changeMintingAddress(address _newAddress)
        external
        onlyRigoblock
    {
        minter = _newAddress;
    }

     
     
    function changeRigoblockAddress(address _newAddress)
        external
        onlyRigoblock
    {
        rigoblock = _newAddress;
    }
}