 

pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

contract TrueGymCoin {
    using SafeMath for uint;
     
    string constant public standard = "ERC20";
    string constant public name = "True Gym Coin";
    string constant public symbol = "TGC";
    uint8 constant public decimals = 18;
    uint _totalSupply = 1626666667e18;

    address public generatorAddr;
    address public icoAddr;
    address public preicoAddr;
    address public privatesellAddr;
    address public companyAddr;
    address public teamAddr;
    address public bountyAddr;

     
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed _owner, address indexed spender, uint value);
    event Burned(uint amount);

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

     
    function allowance(address _owner, address _spender) private view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

     
    function totalSupply() public view returns (uint totSupply) {
        totSupply = _totalSupply;
    }

     
    constructor(address _generatorAddr, address _icoAddr, address _preicoAddr, address _privatesellAddr, address _companyAddr, address _teamAddr, address _bountyAddr) public {
        balances[_generatorAddr] = 1301333334e18;  
        balances[_icoAddr] = 130133333e18;  
        balances[_preicoAddr] = 65066666e18;  
        balances[_privatesellAddr] = 48800000e18;  
        balances[_companyAddr] = 48800000e18;  
        balances[_teamAddr] = 16266667e18;  
        balances[_bountyAddr] = 16266667e18;  
    }

     
    function transfer(address _to, uint _value) public payable {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns(bool) {

        uint _allowed = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);  
        balances[_to] = balances[_to].add(_value);  
        allowed[_from][msg.sender] = _allowed.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
     
    function approve(address _spender, uint _value) public returns (bool) {
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function burn(uint _value) public {
        balances[msg.sender].sub(_value);
        _totalSupply.sub(_value);
        emit Burned(_value);
    }

}