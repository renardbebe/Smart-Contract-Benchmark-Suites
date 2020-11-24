 

pragma solidity 0.4.23;


 
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

 
contract Ownable {
    address public owner;

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }
}

 
contract TokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;

    event Released(uint256 amount);
    event Revoked();

     
    address public beneficiary;

    uint256 public cliff;
    uint256 public start;
    uint256 public duration;

    bool public revocable;

    mapping (address => uint256) public released;
    mapping (address => bool) public revoked;

     
    constructor(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
        require(_beneficiary != address(0));
        require(_cliff <= _duration);

        beneficiary = _beneficiary;
        revocable = _revocable;
        duration = _duration;
        cliff = _start.add(_cliff);
        start = _start;
    }

     
    function release(ERC20Basic token) public {
        uint256 unreleased = releasableAmount(token);

        require(unreleased > 0);

        released[token] = released[token].add(unreleased);

        token.safeTransfer(beneficiary, unreleased);

        emit Released(unreleased);
    }

     
    function revoke(ERC20Basic token) public onlyOwner {
        require(revocable);
        require(!revoked[token]);

        uint256 balance = token.balanceOf(this);

        uint256 unreleased = releasableAmount(token);
        uint256 refund = balance.sub(unreleased);

        revoked[token] = true;

        token.safeTransfer(owner, refund);

        emit Revoked();
    }

     
    function releasableAmount(ERC20Basic token) public view returns (uint256) {
        return vestedAmount(token).sub(released[token]);
    }

     
    function vestedAmount(ERC20Basic token) public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(this);
        uint256 totalBalance = currentBalance.add(released[token]);

        if (now < cliff) {
            return 0;
        } else if (now >= start.add(duration) || revoked[token]) {
            return totalBalance;
        } else {
            return totalBalance.mul(now.sub(start)).div(duration);
        }
    }
}

contract LccxToken is BurnableToken, Ownable {
    string public constant name = "London Exchange Token";
    string public constant symbol = "LXT";
    uint8 public constant decimals = 18;

     
    uint256 public constant HARD_CAP = 100000000 * 10**uint256(decimals);

     
    address public lccxTeamAddress;

     
    address public lccxTeamTokensVesting;

     
    address public saleTokensAddress;

     
    address public advisorsTokensAddress;

     
    address public referralTokensAddress;

     
    bool public saleClosed = false;

     
    modifier beforeSaleClosed {
        require(!saleClosed);
        _;
    }

    constructor(address _lccxTeamAddress, address _advisorsTokensAddress, 
                        address _referralTokensAddress, address _saleTokensAddress) public {
        require(_lccxTeamAddress != address(0));
        require(_advisorsTokensAddress != address(0));
        require(_referralTokensAddress != address(0));
        require(_saleTokensAddress != address(0));

        lccxTeamAddress = _lccxTeamAddress;
        advisorsTokensAddress = _advisorsTokensAddress;
        saleTokensAddress = _saleTokensAddress;
        referralTokensAddress = _referralTokensAddress;

         
         
        uint256 saleTokens = 60000000 * 10**uint256(decimals);
        totalSupply = saleTokens;
        balances[saleTokensAddress] = saleTokens;
        emit Transfer(0x0, saleTokensAddress, saleTokens);

         
        uint256 referralTokens = 8000000 * 10**uint256(decimals);
        totalSupply = totalSupply.add(referralTokens);
        balances[referralTokensAddress] = referralTokens;
        emit Transfer(0x0, referralTokensAddress, referralTokens);

         
        uint256 advisorsTokens = 14000000 * 10**uint256(decimals);
        totalSupply = totalSupply.add(advisorsTokens);
        balances[advisorsTokensAddress] = advisorsTokens;
        emit Transfer(0x0, advisorsTokensAddress, advisorsTokens);
        
         
        uint256 teamTokens = 18000000 * 10**uint256(decimals);
        totalSupply = totalSupply.add(teamTokens);
        lccxTeamTokensVesting = address(new TokenVesting(lccxTeamAddress, now, 30 days, 540 days, false));
        balances[lccxTeamTokensVesting] = teamTokens;
        emit Transfer(0x0, lccxTeamTokensVesting, teamTokens);
        
        require(totalSupply <= HARD_CAP);
    }

     
    function closeSale() external onlyOwner beforeSaleClosed {
        uint256 unsoldTokens = balances[saleTokensAddress];

        if(unsoldTokens > 0) {
            balances[saleTokensAddress] = 0;
            totalSupply = totalSupply.sub(unsoldTokens);
            emit Burn(saleTokensAddress, unsoldTokens);
            emit Transfer(saleTokensAddress, 0x0, unsoldTokens);
        }

        saleClosed = true;
    }
}