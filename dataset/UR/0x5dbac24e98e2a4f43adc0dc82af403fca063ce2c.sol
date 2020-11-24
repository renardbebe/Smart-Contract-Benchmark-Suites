 

pragma solidity ^0.4.21;


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


contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


contract PoolRole is Ownable {
    mapping (address => bool) internal poolRoleBearer;

    event PoolRoleGranted(address indexed addr);
    event PoolRoleRevoked(address indexed addr);

     
    function grantPoolRole(address addr) public onlyOwner {
        poolRoleBearer[addr] = true;
        emit PoolRoleGranted(addr);
    }

     
    function revokePoolRole(address addr) public onlyOwner {
        poolRoleBearer[addr] = false;
        emit PoolRoleRevoked(addr);
    }

     
    function hasPoolRole(address addr) view public returns (bool)
    {
        return poolRoleBearer[addr];
    }

}


contract HasNoEther is Ownable, PoolRole {

     
    function HasNoEther() public payable {
        require(msg.value == 0);
    }

     
    function() external {
    }

     
    function reclaimEther() external onlyOwner {
        assert(owner.send(address(this).balance));
    }
}


contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
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

}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
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
         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

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

}


contract BurnableToken is StandardToken, Ownable {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) onlyOwner public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
    }
}


contract MintableToken is StandardToken, Ownable {

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(uint256 _amount) onlyOwner canMint public {
        totalSupply = totalSupply.add(_amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        emit Mint(msg.sender, _amount);
        emit Transfer(address(0), msg.sender, _amount);
    }

     
    function finishMinting() onlyOwner canMint public {
        mintingFinished = true;
        emit MintFinished();
    }
}


 
contract EngagementToken is BurnableToken, MintableToken, HasNoEther {

    string public constant name = "EngagementToken";

    string public constant symbol = "EGT";

    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 1e9 * (10 ** uint256(decimals));

     
    uint256 public constant FREEZE_END = 1529020799;

     
    function EngagementToken() public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(now >= FREEZE_END || msg.sender == owner || hasPoolRole(_to) || hasPoolRole(msg.sender));
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(now >= FREEZE_END || msg.sender == owner || hasPoolRole(_to) || hasPoolRole(msg.sender));
        return super.transferFrom(_from, _to, _value);
    }

    function multiTransfer(address[] recipients, uint256[] amounts) public {
        require(recipients.length == amounts.length);
        for (uint i = 0; i < recipients.length; i++) {
            transfer(recipients[i], amounts[i]);
        }
    }
}