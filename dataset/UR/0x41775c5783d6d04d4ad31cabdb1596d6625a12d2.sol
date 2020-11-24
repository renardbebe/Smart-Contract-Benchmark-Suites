 

pragma solidity ^0.4.18;


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


 
contract StandardToken {
    using SafeMath for uint256;

    uint256 public totalSupply;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
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
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
}


contract StupidToken is StandardToken {

    string public constant name = "Stupid token";
    string public constant symbol = "BBZ";
    uint8 public constant decimals = 18;

    address public owner;

    uint256 public constant totalSupply = 2200000000 * (10 ** uint256(decimals));
    uint256 public constant lockedAmount = 440000000 * (10 ** uint256(decimals));

    uint256 public lockReleaseTime;

    bool public allowTrading = false;

    function StupidToken() public {
        owner = msg.sender;
        balances[owner] = totalSupply;
        lockReleaseTime = now + 1 years;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        if (!allowTrading) {
            require(msg.sender == owner);
        }
        
         
        if (msg.sender == owner && now < lockReleaseTime) {
            require(balances[msg.sender].sub(_value) >= lockedAmount); 
        }

        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (!allowTrading) {
            require(_from == owner);
        }

         
        if (_from == owner && now < lockReleaseTime) {
            require(balances[_from].sub(_value) >= lockedAmount); 
        }

        return super.transferFrom(_from, _to, _value);
    }

    function setAllowTrading(bool _allowTrading) public {
        require(msg.sender == owner);
        allowTrading = _allowTrading;
    }
}