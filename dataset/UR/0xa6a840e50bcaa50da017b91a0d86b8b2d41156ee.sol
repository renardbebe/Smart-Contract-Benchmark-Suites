 

pragma solidity ^0.4.16;


 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
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
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
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
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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

    function TokenTimelock(ERC20Basic _token, address _beneficiary, uint64 _releaseTime) public {
        require(_releaseTime > now);
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

     
    function release() public {
        require(now >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.safeTransfer(beneficiary, amount);
    }
}

contract EchoLinkToken is StandardToken {
    string public constant name = "EchoLink";
    string public constant symbol = "EKO";
    uint256 public constant decimals = 18;

     
    address public owner;

     
    address public saleTeamAddress;

     
    address public timelockContractAddress;

    uint64 contractCreatedDatetime;

    bool public tokenSaleClosed = false;

     
    uint256 public constant GOAL = 5000 * 5000 * 10**decimals;

     
    uint256 public constant TOKENS_HARD_CAP = 2 * 50000 * 5000 * 10**decimals;

     
    uint256 public constant TOKENS_SALE_HARD_CAP = 50000 * 5000 * 10**decimals;

     
    uint256 public issueIndex = 0;

     
    event Issue(uint _issueIndex, address addr, uint tokenAmount);

    event SaleSucceeded();

    event SaleFailed();

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    modifier onlyTeam {
        assert(msg.sender == saleTeamAddress || msg.sender == owner);
        _;
    }

    modifier inProgress {
        assert(!saleHardCapReached() && !tokenSaleClosed);
        _;
    }

    modifier beforeEnd {
        assert(!tokenSaleClosed);
        _;
    }

    function EchoLinkToken(address _saleTeamAddress) public {
        require(_saleTeamAddress != address(0));
        owner = msg.sender;
        saleTeamAddress = _saleTeamAddress;
        contractCreatedDatetime = uint64(block.timestamp);
    }

    function close(uint256 _echoTeamTokens) public onlyOwner beforeEnd {
        if (totalSupply < GOAL) {
            SaleFailed();
        } else {
            SaleSucceeded();
        }

         
        uint256 increasedTotalSupply = totalSupply.add(_echoTeamTokens);
         
        if(increasedTotalSupply > TOKENS_HARD_CAP) {
            revert();
        }

         
        totalSupply = increasedTotalSupply;

         
        TokenTimelock lockedTeamTokens = new TokenTimelock(this, owner, contractCreatedDatetime + (60 * 60 * 24 * 100));
         
         

        timelockContractAddress = address(lockedTeamTokens);

         
        balances[timelockContractAddress] = balances[timelockContractAddress].add(_echoTeamTokens);

         
        Issue(
        issueIndex++,
        timelockContractAddress,
        _echoTeamTokens
        );

        tokenSaleClosed = true;
    }

    function issueTokens(address _investor, uint256 _tokensAmount) public onlyTeam inProgress {
        require(_investor != address(0));

         
        uint256 increasedTotalSupply = totalSupply.add(_tokensAmount);
         
        if(increasedTotalSupply > TOKENS_SALE_HARD_CAP) {
            revert();
        }

         
        totalSupply = increasedTotalSupply;
         
        balances[_investor] = balances[_investor].add(_tokensAmount);
         
        Issue(
        issueIndex++,
        _investor,
        _tokensAmount
        );
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

     
    function saleHardCapReached() public view returns (bool) {
        return totalSupply >= TOKENS_SALE_HARD_CAP;
    }
}