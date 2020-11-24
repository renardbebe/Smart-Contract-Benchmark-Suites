 

pragma solidity ^0.4.13;

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
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

 
contract BasicToken is ERC20Basic {

    using SafeMath for uint256;

                       mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
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
        require(newOwner != address(0));
        owner = newOwner;
    }

}

 

contract MintableToken is StandardToken, Ownable {

    event Mint(address indexed to, uint256 amount);

    event MintFinished();
    event MintStarted();

    bool public mintingActive = true;

    uint256 public maxTokenCount;

    modifier canMint() {
        require(mintingActive);
        _;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
        require(totalSupply <= maxTokenCount);

        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        return true;
    }

     
    function stopMinting() onlyOwner returns (bool) {
        mintingActive = false;
        MintFinished();
        return true;
    }

     
    function startMinting() onlyOwner returns (bool) {
        mintingActive = true;
        MintStarted();
        return true;
    }
}


 
contract HDLToken is MintableToken
{

    string public constant name = "Handelion  token";

    string public constant symbol = "HDLT";

    uint32 public constant decimals = 18;

    function HDLToken()
    {
     	maxTokenCount = 29750000 * 1 ether;
    }
}


contract HDLContract is Ownable {

    using SafeMath for uint;

	 
	address _ownerAddress;

     
    address _vaultAddress;

     
    address[] public _investorAddresses;

     
    mapping (address => uint256) _investors;

     
    HDLToken public token;

     
    uint _start;

     
    uint _period;

     
    uint public _goal;

     
    uint _rate;

     
    uint256 public issuedTokens;

     
    uint256 public collectedFunds;

     
     
    bool public isFinished = false;

     
    bool public isRefunding = false;

     
    event InvestorRefunded(address indexed beneficiary, uint256 weiAmount);

     
    event FundingAccepted(address indexed investor, uint256 weiAmount, uint tokenAmount);

     
    event AllInvestorsRefunded(uint refundedInvestorCount);

     
    event WithdrawAllFunds(uint256 withdrawnAmount);

     
    event CrowdsaleFinished();

     
    event GoalReached();

    function HDLContract(address aVaultAddress, uint aStart, uint aPeriod, uint aGoal, uint aRate) {
        _ownerAddress = msg.sender;
        _vaultAddress =  aVaultAddress;
        token = new HDLToken();
        _rate =  aRate;
        _start = aStart;
        _period = aPeriod;
        _goal =  aGoal * 1 ether;

        issuedTokens = 0;
        collectedFunds = 0;
    }

     
    function TransferTokenOwnership(address newTokenOwner) public onlyOwner
	{
		token.transferOwnership(newTokenOwner);
	}

     
    function finish() public onlyOwner {
        require(!isFinished);

        token.stopMinting();
        isFinished = true;

        if (issuedTokens < _goal)
        {
            isRefunding = true;
        } else
        {
            withdraw();
        }

        CrowdsaleFinished();
    }

     
    function requestRefunding() public
    {
        require(isRefunding);

        address investorAddress = msg.sender;
        refundInvestor(investorAddress);
    }

     
    function buyTokens() payable
    {
        require(!isFinished);
        require(isContractActive());
        require(!isGoalReached());

        uint tokens = _rate.mul(msg.value);

        token.mint(this, tokens);
        token.transfer(msg.sender, tokens);

        issuedTokens = issuedTokens.add(tokens);
        _investors[msg.sender] = _investors[msg.sender].add(msg.value);
        _investorAddresses.push(msg.sender);

        collectedFunds = collectedFunds.add(msg.value);

        FundingAccepted(msg.sender, msg.value, tokens);

        if (issuedTokens >= _goal)
        {
            GoalReached();
        }
    }

    function() external payable {
        buyTokens();
    }

    function closeContract() onlyOwner {
        token.stopMinting();
        isFinished = true;
    }

    function withdraw() onlyOwner {
        if (this.balance > 0) {
            _vaultAddress.transfer(this.balance);
        }

        WithdrawAllFunds(this.balance);
    }

    function refundInvestor(address aInvestorAddress) onlyOwner returns(bool)
    {
        if (aInvestorAddress == 0x0)
        {
            return false;
        }

        uint256 depositedValue = _investors[aInvestorAddress];

        if (depositedValue <= 0)
        {
            return false;
        }

        _investors[aInvestorAddress] = 0;

        aInvestorAddress.transfer(depositedValue);
        InvestorRefunded(aInvestorAddress, depositedValue);

        return true;
    }

    function isContractActive() returns (bool)
    {
        return (now > _start) && (now < (_start + _period * 1 days));
    }

    function isGoalReached() returns (bool)
    {
        return issuedTokens >= _goal;
    }
}