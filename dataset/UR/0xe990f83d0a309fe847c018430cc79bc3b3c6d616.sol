 

pragma solidity 0.4.21;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;


    event Burn(address indexed burner, uint256 value);

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }

}


contract CryptoRoboticsToken is StandardToken {
    using SafeMath for uint256;

    string public constant name = "CryptoRobotics";
    string public constant symbol = "ROBO";
    uint8 public constant decimals = 18;

    address public advisors;
    address public bounty;
    address public reserve_fund;

    uint256 public constant INITIAL_SUPPLY = 120000000 * (10 ** uint256(decimals));

     
    function CryptoRoboticsToken() public {
        totalSupply = INITIAL_SUPPLY;

        advisors = 0x24Eff98D6c10f9132a62B02dF415c917Bf6b4D12;
        bounty = 0x23b8A6dD54bd6107EA9BD11D9B3856f8de4De10B;
        reserve_fund = 0x7C88C296B9042946f821F5456bd00EA92a13B3BB;

        balances[advisors] = getPercent(INITIAL_SUPPLY,7);
        emit Transfer(address(0), advisors, getPercent(INITIAL_SUPPLY,7));

        balances[bounty] = getPercent(INITIAL_SUPPLY,3);
        emit Transfer(address(0), bounty, getPercent(INITIAL_SUPPLY,3));

        balances[reserve_fund] = getPercent(INITIAL_SUPPLY,9);
        emit Transfer(address(0), reserve_fund, getPercent(INITIAL_SUPPLY,9));

        balances[msg.sender] = getPercent(INITIAL_SUPPLY,81);  
        emit Transfer(address(0), msg.sender, getPercent(INITIAL_SUPPLY,81));
         
    }

    function getPercent(uint _value, uint _percent) internal pure returns(uint quotient)
    {
        uint _quotient = _value.mul(_percent).div(100);
        return ( _quotient);
    }

}