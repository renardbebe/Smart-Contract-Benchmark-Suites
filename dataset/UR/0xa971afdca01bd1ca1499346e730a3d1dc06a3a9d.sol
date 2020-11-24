 

pragma solidity ^0.4.11;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract Ownable {
    address public owner;

     
    function Ownable() {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value);
    function approve(address spender, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
}

 
contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) {
        var _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }

     
    function approve(address _spender, uint256 _value) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

 
contract TKRPToken is StandardToken {
    event Destroy(address indexed _from);

    string public name = "TKRPToken";
    string public symbol = "TKRP";
    uint256 public decimals = 18;
    uint256 public initialSupply = 500000;

     
    function TKRPToken() {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
    }

     
    function destroyFrom(address _from) onlyOwner returns (bool) {
        uint256 balance = balanceOf(_from);
        require(balance > 0);

        balances[_from] = 0;
        totalSupply = totalSupply.sub(balance);

        Destroy(_from);
    }
}

 
contract TKRToken is StandardToken {
    event Destroy(address indexed _from, address indexed _to, uint256 _value);

    string public name = "TKRToken";
    string public symbol = "TKR";
    uint256 public decimals = 18;
    uint256 public initialSupply = 65500000 * 10 ** 18;

     
    function TKRToken() {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
    }

     
    function destroy(uint256 _value) onlyOwner returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Destroy(msg.sender, 0x0, _value);
    }
}

 
contract Crowdsale is Ownable {
    using SafeMath for uint256;

     
    struct Contributor {
        uint256 contributed;
        uint256 received;
    }

     
    mapping(address => Contributor) public contributors;

     
    event TokensSent(address indexed to, uint256 value);
    event ContributionReceived(address indexed to, uint256 value);
    event MigratedTokens(address indexed _address, uint256 value);

     
    uint256 public constant TOKEN_CAP = 58500000 * 10 ** 18;
    uint256 public constant MINIMUM_CONTRIBUTION = 10 finney;
    uint256 public constant TOKENS_PER_ETHER = 5000 * 10 ** 18;
    uint256 public constant CROWDSALE_DURATION = 30 days;

     
    TKRToken public token;
    TKRPToken public preToken;
    address public crowdsaleOwner;
    uint256 public etherReceived;
    uint256 public tokensSent;
    uint256 public crowdsaleStartTime;
    uint256 public crowdsaleEndTime;

     
    modifier crowdsaleRunning() {
        require(now < crowdsaleEndTime && crowdsaleStartTime != 0);
        _;
    }

     
    function Crowdsale(address _tokenAddress, address _preTokenAddress, address _to) {
        token = TKRToken(_tokenAddress);
        preToken = TKRPToken(_preTokenAddress);
        crowdsaleOwner = _to;
    }

     
    function() crowdsaleRunning payable {
        processContribution(msg.sender);
    }

     
    function start() onlyOwner {
        require(crowdsaleStartTime == 0);

        crowdsaleStartTime = now;            
        crowdsaleEndTime = now + CROWDSALE_DURATION;    
    }

     
    function drain() onlyOwner {
        assert(crowdsaleOwner.send(this.balance));
    }

     
    function finalize() onlyOwner {
        require((crowdsaleStartTime != 0 && now > crowdsaleEndTime) || tokensSent == TOKEN_CAP);

        uint256 remainingBalance = token.balanceOf(this);
        if (remainingBalance > 0) token.destroy(remainingBalance);

        assert(crowdsaleOwner.send(this.balance));
    }

     
    function migrate() crowdsaleRunning {
        uint256 preTokenBalance = preToken.balanceOf(msg.sender);
        require(preTokenBalance != 0);
        uint256 tokenBalance = preTokenBalance * 10 ** 18;

        preToken.destroyFrom(msg.sender);
        token.transfer(msg.sender, tokenBalance);
        MigratedTokens(msg.sender, tokenBalance);
    }

     
    function processContribution(address sender) internal {
        require(msg.value >= MINIMUM_CONTRIBUTION);

         
        uint256 contributionInTokens = bonus(msg.value.mul(TOKENS_PER_ETHER).div(1 ether));
        require(contributionInTokens.add(tokensSent) <= TOKEN_CAP);

         
        token.transfer(sender, contributionInTokens);

         
        Contributor storage contributor = contributors[sender];
        contributor.received = contributor.received.add(contributionInTokens);
        contributor.contributed = contributor.contributed.add(msg.value);

         
        etherReceived = etherReceived.add(msg.value);
        tokensSent = tokensSent.add(contributionInTokens);

         
        TokensSent(sender, contributionInTokens);
        ContributionReceived(sender, msg.value);
    }

     
    function bonus(uint256 amount) internal constant returns (uint256) {
         
        if (now < crowdsaleStartTime.add(2 days)) return amount.add(amount.div(5));

         
        if (now < crowdsaleStartTime.add(14 days)) return amount.add(amount.div(10));

         
        if (now < crowdsaleStartTime.add(21 days)) return amount.add(amount.div(20));

         
        return amount;
    }
}