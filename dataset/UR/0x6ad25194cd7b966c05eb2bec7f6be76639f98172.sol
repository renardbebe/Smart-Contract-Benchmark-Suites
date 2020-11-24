 

pragma solidity ^0.4.24;

 
library SafeMath {
 
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract Ownable {
    address public owner;
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
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

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}


 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract VANMToken is ERC20, Ownable {
    using SafeMath for uint256;

     
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    uint256 public presaleSupply;
    address public presaleAddress;

    uint256 public crowdsaleSupply;
    address public crowdsaleAddress;

    uint256 public platformSupply;
    address public platformAddress;

    uint256 public incentivisingSupply;
    address public incentivisingAddress;

    uint256 public teamSupply;
    address public teamAddress;

    uint256 public crowdsaleEndsAt;

    uint256 public teamVestingPeriod;

    bool public presaleFinalized = false;

    bool public crowdsaleFinalized = false;

     
     
    modifier onlyPresale() {
        require(msg.sender == presaleAddress);
        _;
    }

     
    modifier onlyCrowdsale() {
        require(msg.sender == crowdsaleAddress);
        _;
    }

     
    modifier notBeforeCrowdsaleEnds(){
        require(block.timestamp >= crowdsaleEndsAt);
        _;
    }

     
    modifier checkTeamVestingPeriod() {
        require(block.timestamp >= teamVestingPeriod);
        _;
    }

     
    event PresaleFinalized(uint tokensRemaining);

    event CrowdsaleFinalized(uint tokensRemaining);

     
    constructor() public {

         
        symbol = "VANM";
        name = "VANM";
        decimals = 18;

         
        _totalSupply = 240000000 * 10**uint256(decimals);

         
        presaleSupply = 24000000 * 10**uint256(decimals);

         
        crowdsaleSupply = 120000000 * 10**uint256(decimals);

         
        platformSupply = 24000000 * 10**uint256(decimals);

         
        incentivisingSupply = 48000000 * 10**uint256(decimals);

         
        teamSupply = 24000000 * 10**uint256(decimals);

        platformAddress = 0x6962371D5a9A229C735D936df5CE6C690e66b718;

        teamAddress = 0xB9e54846da59C27eFFf06C3C08D5d108CF81FEae;

         
        crowdsaleEndsAt = 1556668800;

         
        teamVestingPeriod = crowdsaleEndsAt.add(2 * 365 * 1 days);

        balances[platformAddress] = platformSupply;
        emit Transfer(0x0, platformAddress, platformSupply);

        balances[incentivisingAddress] = incentivisingSupply;
    }

     
     
    function setPresaleAddress(address _presaleAddress) external onlyOwner {
        require(presaleAddress == 0x0);
        presaleAddress = _presaleAddress;
        balances[_presaleAddress] = balances[_presaleAddress].add(presaleSupply);
    }

     
    function finalizePresale() external onlyPresale {
        require(presaleFinalized == false);
        uint256 amount = balanceOf(presaleAddress);
        if (amount > 0) {
            balances[presaleAddress] = 0;
            balances[crowdsaleAddress] = balances[crowdsaleAddress].add(amount);
        }
        presaleFinalized = true;
        emit PresaleFinalized(amount);
    }

     
    function setCrowdsaleAddress(address _crowdsaleAddress) external onlyOwner {
        require(presaleAddress != 0x0);
        require(crowdsaleAddress == 0x0);
        crowdsaleAddress = _crowdsaleAddress;
        balances[_crowdsaleAddress] = balances[_crowdsaleAddress].add(crowdsaleSupply);
    }

     
    function finalizeCrowdsale() external onlyCrowdsale {
        require(presaleFinalized == true && crowdsaleFinalized == false);
        uint256 amount = balanceOf(crowdsaleAddress);
        if (amount > 0) {
            balances[crowdsaleAddress] = 0;
            balances[platformAddress] = balances[platformAddress].add(amount);
            emit Transfer(0x0, platformAddress, amount);
        }
        crowdsaleFinalized = true;
        emit CrowdsaleFinalized(amount);
    }

     
     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function transfer(address _to, uint256 _value) public
    notBeforeCrowdsaleEnds
    returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public
    notBeforeCrowdsaleEnds
    returns (bool) {
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

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
     
    function transferFromIncentivising(address _to, uint256 _value) public
    onlyOwner
    returns (bool) {
    require(_value <= balances[incentivisingAddress]);
        balances[incentivisingAddress] = balances[incentivisingAddress].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(0x0, _to, _value);
        return true;
    }

     
    function transferFromPresale(address _to, uint256 _value) public
    onlyPresale
    returns (bool) {
    require(_value <= balances[presaleAddress]);
        balances[presaleAddress] = balances[presaleAddress].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(0x0, _to, _value);
        return true;
    }

     
    function transferFromCrowdsale(address _to, uint256 _value) public
    onlyCrowdsale
    returns (bool) {
    require(_value <= balances[crowdsaleAddress]);
        balances[crowdsaleAddress] = balances[crowdsaleAddress].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(0x0, _to, _value);
        return true;
    }

     
    function releaseTeamTokens() public checkTeamVestingPeriod onlyOwner returns(bool) {
        require(teamSupply > 0);
        balances[teamAddress] = teamSupply;
        emit Transfer(0x0, teamAddress, teamSupply);
        teamSupply = 0;
        return true;
    }

     
    function checkIncentivisingBalance() public view returns (uint256) {
        return balances[incentivisingAddress];
    }

     
    function checkPresaleBalance() public view returns (uint256) {
        return balances[presaleAddress];
    }

     
    function checkCrowdsaleBalance() public view returns (uint256) {
        return balances[crowdsaleAddress];
    }

     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

     
    function () public payable {
revert();
    }
}

contract VANMCrowdsale is Ownable {
    using SafeMath for uint256;

     
    uint256 public crowdsaleStartsAt;
    uint256 public crowdsaleEndsAt;

    uint256 public weiRaised;
    address public crowdsaleWallet;

    address public tokenAddress;
    VANMToken public token;

     
    mapping(address => bool) public whitelist;

     
     
    modifier whileCrowdsale {
        require(block.timestamp >= crowdsaleStartsAt && block.timestamp <= crowdsaleEndsAt);
        _;
    }

     
    modifier notBeforeCrowdsaleEnds {
        require(block.timestamp > crowdsaleEndsAt);
        _;
    }

     
    modifier isWhitelisted(address _to) {
        require(whitelist[_to]);
        _;
    }

     
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

    event AmountRaised(address beneficiary, uint amountRaised);

    event WalletChanged(address _wallet);

     
    constructor() public {

         
        crowdsaleStartsAt = 1546300800;

         
        crowdsaleEndsAt = 1556668800;

         
        weiRaised = 0;

         
        crowdsaleWallet = 0xedaFdA45fedcCE4D2b81e173F1D2F21557E97aA5;

         
        tokenAddress = 0x0d155aaa5C94086bCe0Ad0167EE4D55185F02943;
        token = VANMToken(tokenAddress);
    }

     
     
    function addToWhitelist(address _to) external onlyOwner {
        whitelist[_to] = true;
    }

     
    function addManyToWhitelist(address[] _to) external onlyOwner {
        for (uint256 i = 0; i < _to.length; i++) {
            whitelist[_to[i]] = true;
        }
    }

     
    function removeFromWhitelist(address _to) external onlyOwner {
        whitelist[_to] = false;
    }

     
    function removeManyFromWhitelist(address[] _to) external onlyOwner {
        for (uint256 i = 0; i < _to.length; i++) {
            whitelist[_to[i]] = false;
        }
    }

     
    function changeWallet(address _crowdsaleWallet) external onlyOwner {
        crowdsaleWallet = _crowdsaleWallet;
        emit WalletChanged(_crowdsaleWallet);
    }

     
     
    function closeCrowdsale() external notBeforeCrowdsaleEnds onlyOwner returns (bool) {
        emit AmountRaised(crowdsaleWallet, weiRaised);
        token.finalizeCrowdsale();
        return true;
    }

     
     
    function crowdsaleHasClosed() public view returns (bool) {
        return block.timestamp > crowdsaleEndsAt;
    }

     
    function () public payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _to) public
    whileCrowdsale
    isWhitelisted (_to)
    payable {
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount * getCrowdsaleRate();
        weiRaised = weiRaised.add(weiAmount);
        crowdsaleWallet.transfer(weiAmount);
        if (!token.transferFromCrowdsale(_to, tokens)) {
            revert();
        }
        emit TokenPurchase(_to, weiAmount, tokens);
    }

     
    function getCrowdsaleRate() public view returns (uint price) {
        if (token.checkCrowdsaleBalance() < ((token.crowdsaleSupply() * 25) / 100)) {
            return 2000;  
        } else if (token.checkCrowdsaleBalance() < ((token.crowdsaleSupply() * 50) / 100)) {
            return 2100;  
        } else if (token.checkCrowdsaleBalance() < ((token.crowdsaleSupply() * 75) / 100)) {
            return 2250;  
        } else if (token.checkCrowdsaleBalance() < (token.crowdsaleSupply())) {
            return 2400;  
        } else {
            return 2600;  
        }
    }

 
    function transferAnyERC20Token(address ERC20Address, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(ERC20Address).transfer(owner, tokens);
    }
}