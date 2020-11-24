 

 
 
pragma solidity ^0.4.14;

contract ERC20Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
 
contract Owned {
     
     
    modifier onlyOwner() {
        require(msg.sender == owner) ;
        _;
    }

    address public owner;

     
    function Owned() {
        owner = msg.sender;
    }

     
    function transferOwnership(address _newOwner) onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

}

contract SafeMath {
    function add(uint x, uint y) internal constant returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal constant returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal constant returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal constant returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal constant returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal constant returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal constant returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal constant returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal constant returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal constant returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal constant returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function rpow(uint x, uint n) internal constant returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

 
contract StandardToken is ERC20Token {
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
         
         
         
         
        require ((_value==0) || (allowed[msg.sender][_spender] ==0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract LSTToken is StandardToken, Owned {
     
    string public constant name = "LIVESHOW Token";
    string public constant symbol = "LST";
    string public version = "1.0";
    uint256 public constant decimals = 18;
    uint256 public constant MILLION = (10**6 * 10**decimals);
    bool public disabled;
     
    function LSTToken() {
        uint _amount = 100 * MILLION;
        totalSupply = _amount; 
        balances[msg.sender] = _amount;
    }

    function getTotalSupply() external constant returns(uint256) {
        return totalSupply;
    }

    function setDisabled(bool flag) external onlyOwner {
        disabled = flag;
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        require(!disabled);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(!disabled);
        return super.transferFrom(_from, _to, _value);
    }
    function kill() onlyOwner {
        selfdestruct(owner);
    }
}