 

pragma solidity 0.4.25;


 
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

 
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

 
contract TokenTimelock {
    using SafeERC20 for ERC20Basic;

     
    ERC20Basic public token;

     
    address public beneficiary;

     
    uint64 public releaseTime;

    constructor(ERC20Basic _token, address _beneficiary, uint64 _releaseTime) public {
        require(_releaseTime > uint64(block.timestamp));
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

     
    function release() public {
        require(uint64(block.timestamp) >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.safeTransfer(beneficiary, amount);
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

 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
    }
}

contract BitwingsToken is BurnableToken, Owned {
    string public constant name = "BITWINGS TOKEN";
    string public constant symbol = "BWN";
    uint8 public constant decimals = 18;

     
    uint256 public constant HARD_CAP = 300000000 * 10**uint256(decimals);

     
    address public teamAdvisorsTokensAddress;

     
    address public saleTokensAddress;

     
    address public reserveTokensAddress;

     
    address public bountyAirdropTokensAddress;

     
    address public referralTokensAddress;

     
    bool public saleClosed = false;

     
    mapping(address => bool) public whitelisted;

     
    modifier beforeSaleClosed {
        require(!saleClosed);
        _;
    }

    constructor(address _teamAdvisorsTokensAddress, address _reserveTokensAddress,
                address _saleTokensAddress, address _bountyAirdropTokensAddress, address _referralTokensAddress) public {
        require(_teamAdvisorsTokensAddress != address(0));
        require(_reserveTokensAddress != address(0));
        require(_saleTokensAddress != address(0));
        require(_bountyAirdropTokensAddress != address(0));
        require(_referralTokensAddress != address(0));

        teamAdvisorsTokensAddress = _teamAdvisorsTokensAddress;
        reserveTokensAddress = _reserveTokensAddress;
        saleTokensAddress = _saleTokensAddress;
        bountyAirdropTokensAddress = _bountyAirdropTokensAddress;
        referralTokensAddress = _referralTokensAddress;

         
         
        uint256 saleTokens = 189000000 * 10**uint256(decimals);
        totalSupply_ = saleTokens;
        balances[saleTokensAddress] = saleTokens;
        emit Transfer(address(0), saleTokensAddress, balances[saleTokensAddress]);

         
        uint256 teamAdvisorsTokens = 15000000 * 10**uint256(decimals);
        totalSupply_ = totalSupply_.add(teamAdvisorsTokens);
        balances[teamAdvisorsTokensAddress] = teamAdvisorsTokens;
        emit Transfer(address(0), teamAdvisorsTokensAddress, balances[teamAdvisorsTokensAddress]);

         
        uint256 reserveTokens = 60000000 * 10**uint256(decimals);
        totalSupply_ = totalSupply_.add(reserveTokens);
        balances[reserveTokensAddress] = reserveTokens;
        emit Transfer(address(0), reserveTokensAddress, balances[reserveTokensAddress]);

         
        uint256 bountyAirdropTokens = 31000000 * 10**uint256(decimals);
        totalSupply_ = totalSupply_.add(bountyAirdropTokens);
        balances[bountyAirdropTokensAddress] = bountyAirdropTokens;
        emit Transfer(address(0), bountyAirdropTokensAddress, balances[bountyAirdropTokensAddress]);

         
        uint256 referralTokens = 5000000 * 10**uint256(decimals);
        totalSupply_ = totalSupply_.add(referralTokens);
        balances[referralTokensAddress] = referralTokens;
        emit Transfer(address(0), referralTokensAddress, balances[referralTokensAddress]);

        whitelisted[saleTokensAddress] = true;
        whitelisted[teamAdvisorsTokensAddress] = true;
        whitelisted[bountyAirdropTokensAddress] = true;
        whitelisted[referralTokensAddress] = true;

        require(totalSupply_ == HARD_CAP);
    }

     
    function closeSale() external onlyOwner beforeSaleClosed {
         

        uint256 unsoldTokens = balances[saleTokensAddress];
        balances[reserveTokensAddress] = balances[reserveTokensAddress].add(unsoldTokens);
        balances[saleTokensAddress] = 0;
        emit Transfer(saleTokensAddress, reserveTokensAddress, unsoldTokens);

        saleClosed = true;
    }

     
     
    function whitelist(address _address) external onlyOwner {
        whitelisted[_address] = true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if(saleClosed) {
            return super.transferFrom(_from, _to, _value);
        }
        return false;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        if(saleClosed || whitelisted[msg.sender]) {
            return super.transfer(_to, _value);
        }
        return false;
    }
}