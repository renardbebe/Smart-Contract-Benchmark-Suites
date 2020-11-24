 

pragma solidity 0.4.23;

 
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

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
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

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
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

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

 
contract MintableToken is StandardToken, Owned {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract BidoohToken is MintableToken {
    string public constant name = "Bidooh Token";
    string public constant symbol = "DOOH";
    uint8 public constant decimals = 18;

     
    address public teamTokensAddress;

     
    address public reserveTokensAddress;

     
    address public saleTokensAddress;

     
    address public bidoohAdminAddress;

     
    bool public saleClosed = false;

     
    modifier beforeSaleClosed {
        require(!saleClosed);
        _;
    }

    constructor(address _teamTokensAddress, address _reserveTokensAddress,
                address _saleTokensAddress, address _bidoohAdminAddress) public {
        require(_teamTokensAddress != address(0));
        require(_reserveTokensAddress != address(0));
        require(_saleTokensAddress != address(0));
        require(_bidoohAdminAddress != address(0));

        teamTokensAddress = _teamTokensAddress;
        reserveTokensAddress = _reserveTokensAddress;
        saleTokensAddress = _saleTokensAddress;
        bidoohAdminAddress = _bidoohAdminAddress;

         
         
        uint256 saleTokens = 88200000000 * 10**uint256(decimals);
        totalSupply_ = saleTokens;
        balances[saleTokensAddress] = saleTokens;

         
        uint256 reserveTokens = 18900000000 * 10**uint256(decimals);
        totalSupply_ = totalSupply_.add(reserveTokens);
        balances[reserveTokensAddress] = reserveTokens;

         
        uint256 teamTokens = 18900000000 * 10**uint256(decimals);
        totalSupply_ = totalSupply_.add(teamTokens);
        balances[teamTokensAddress] = teamTokens;
    }

     
    function close() public onlyOwner beforeSaleClosed {
        uint256 unsoldTokens = balances[saleTokensAddress];
        balances[reserveTokensAddress] = balances[reserveTokensAddress].add(unsoldTokens);
        balances[saleTokensAddress] = 0;
        emit Transfer(saleTokensAddress, reserveTokensAddress, unsoldTokens);

        owner = bidoohAdminAddress;
        saleClosed = true;
    }
}