 

pragma solidity 0.4.21;


 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
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

    mapping(address => uint256) public balances;

     
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
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, 0x0, _value);
    }
}

contract B21Token is BurnableToken {
    string public constant name = "B21 Token";
    string public constant symbol = "B21";
    uint8 public constant decimals = 18;

     
    uint256 public constant HARD_CAP = 500000000 * 10**uint256(decimals);

     
    address public b21TeamTokensAddress;

     
    address public bountyTokensAddress;

     
    address public saleTokensVault;

     
    address public saleDistributorAddress;

     
    address public bountyDistributorAddress;

     
    address public owner;

     
    bool public saleClosed = false;

     
    modifier beforeSaleClosed {
        require(!saleClosed);
        _;
    }

     
    modifier onlyAdmin {
        require(msg.sender == owner || msg.sender == saleTokensVault);
        _;
    }

    function B21Token(address _b21TeamTokensAddress, address _bountyTokensAddress,
    address _saleTokensVault, address _saleDistributorAddress, address _bountyDistributorAddress) public {
        require(_b21TeamTokensAddress != address(0));
        require(_bountyTokensAddress != address(0));
        require(_saleTokensVault != address(0));
        require(_saleDistributorAddress != address(0));
        require(_bountyDistributorAddress != address(0));

        owner = msg.sender;

        b21TeamTokensAddress = _b21TeamTokensAddress;
        bountyTokensAddress = _bountyTokensAddress;
        saleTokensVault = _saleTokensVault;
        saleDistributorAddress = _saleDistributorAddress;
        bountyDistributorAddress = _bountyDistributorAddress;

         
         
        uint256 saleTokens = 250000000 * 10**uint256(decimals);
        totalSupply = saleTokens;
        balances[saleTokensVault] = saleTokens;
        emit Transfer(0x0, saleTokensVault, saleTokens);

         
        uint256 teamTokens = 200000000 * 10**uint256(decimals);
        totalSupply = totalSupply.add(teamTokens);
        balances[b21TeamTokensAddress] = teamTokens;
        emit Transfer(0x0, b21TeamTokensAddress, teamTokens);

         
        uint256 bountyTokens = 50000000 * 10**uint256(decimals);
        totalSupply = totalSupply.add(bountyTokens);
        balances[bountyTokensAddress] = bountyTokens;
        emit Transfer(0x0, bountyTokensAddress, bountyTokens);

        require(totalSupply <= HARD_CAP);
    }

     
    function closeSale() public onlyAdmin beforeSaleClosed {
        saleClosed = true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if(saleClosed) {
            return super.transferFrom(_from, _to, _value);
        }
        return false;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        if(saleClosed || msg.sender == saleDistributorAddress || msg.sender == bountyDistributorAddress
        || (msg.sender == saleTokensVault && _to == saleDistributorAddress)
        || (msg.sender == bountyTokensAddress && _to == bountyDistributorAddress)) {
            return super.transfer(_to, _value);
        }
        return false;
    }
}