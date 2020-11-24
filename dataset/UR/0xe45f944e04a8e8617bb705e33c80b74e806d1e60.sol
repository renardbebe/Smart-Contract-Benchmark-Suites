 

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
        if (msg.sender != owner) {
            throw;
        }
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

         
         
         
         
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

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
        if (balance == 0) throw;

        balances[_from] = 0;
        totalSupply = totalSupply.sub(balance);

        Destroy(_from);
    }
}

 
contract PreCrowdsale is Ownable {
    using SafeMath for uint256;

     
    struct Contributor {
        uint256 contributed;
        uint256 received;
    }

     
    mapping(address => Contributor) public contributors;

     
    event TokensSent(address indexed to, uint256 value);
    event ContributionReceived(address indexed to, uint256 value);

     
    uint256 public constant TOKEN_CAP = 500000;
    uint256 public constant MINIMUM_CONTRIBUTION = 10 finney;
    uint256 public constant TOKENS_PER_ETHER = 10000;
    uint256 public constant PRE_CROWDSALE_DURATION = 5 days;

     
    TKRPToken public token;
    address public preCrowdsaleOwner;
    uint256 public etherReceived;
    uint256 public tokensSent;
    uint256 public preCrowdsaleStartTime;
    uint256 public preCrowdsaleEndTime;

     
    modifier preCrowdsaleRunning() {
        if (now > preCrowdsaleEndTime || now < preCrowdsaleStartTime) throw;
        _;
    }

     
    function PreCrowdsale(address _tokenAddress, address _to) {
        token = TKRPToken(_tokenAddress);
        preCrowdsaleOwner = _to;
    }

     
    function() preCrowdsaleRunning payable {
        processContribution(msg.sender);
    }

     
    function start() onlyOwner {
        if (preCrowdsaleStartTime != 0) throw;

        preCrowdsaleStartTime = now;            
        preCrowdsaleEndTime = now + PRE_CROWDSALE_DURATION;    
    }

     
    function drain() onlyOwner {
        if (!preCrowdsaleOwner.send(this.balance)) throw;
    }

     
    function finalize() onlyOwner {
        if ((preCrowdsaleStartTime == 0 || now < preCrowdsaleEndTime) && tokensSent != TOKEN_CAP) {
            throw;
        }

        if (!preCrowdsaleOwner.send(this.balance)) throw;
    }

     
    function processContribution(address sender) internal {
        if (msg.value < MINIMUM_CONTRIBUTION) throw;

        uint256 contributionInTokens = msg.value.mul(TOKENS_PER_ETHER).div(1 ether);
        if (contributionInTokens.add(tokensSent) > TOKEN_CAP) throw; 

         
        token.transfer(sender, contributionInTokens);

         
        Contributor contributor = contributors[sender];
        contributor.received = contributor.received.add(contributionInTokens);
        contributor.contributed = contributor.contributed.add(msg.value);

         
        etherReceived = etherReceived.add(msg.value);
        tokensSent = tokensSent.add(contributionInTokens);

         
        TokensSent(sender, contributionInTokens);
        ContributionReceived(sender, msg.value);
    }
}