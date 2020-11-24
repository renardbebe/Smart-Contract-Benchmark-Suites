 

pragma solidity ^0.4.18;

 
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
        assert(b > 0);
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

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        Unpause();
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
        Transfer(msg.sender, _to, _value);
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

        uint256 _allowance = allowed[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
}

 

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    address public mintAddress;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier onlyMint() {
        require(msg.sender == mintAddress);
        _;
    }

     
    function setMintAddress(address _mintAddress) public onlyOwner {
        require(_mintAddress != address(0));
        mintAddress = _mintAddress;
    }

     
    function mint(address _to, uint256 _amount) public onlyMint canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() public onlyMint canMint returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

 
contract TokenTimelock {
     
    ERC20Basic public token;

     
    address public beneficiary;

     
    uint256 public releaseTime;

     
    function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
        require(_releaseTime > now);
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

     
    function release() public {
        require(now >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.transfer(beneficiary, amount);
    }
}

 
contract CraftyCrowdsale is Pausable {
    using SafeMath for uint256;

     
    mapping(address => uint256) received;

     
    MintableToken public token;

     
    uint256 public preSaleStart;
    uint256 public preSaleEnd;
    uint256 public saleStart;
    uint256 public saleEnd;

     
    uint256 public issuedTokens = 0;

     
    uint256 public constant hardCap = 5000000000 * 10**8;  

     
    uint256 constant teamCap = 1450000000 * 10**8;  
    uint256 constant advisorCap = 450000000 * 10**8;  
    uint256 constant bountyCap = 100000000 * 10**8;  
    uint256 constant fundCap = 3000000000 * 10**8;  

     
    uint256 constant lockTime = 180 days;

     
    address public etherWallet;
    address public teamWallet;
    address public advisorWallet;
    address public fundWallet;
    address public bountyWallet;

     
    TokenTimelock teamTokens;

    uint256 public rate;

    enum State { BEFORE_START, SALE, REFUND, CLOSED }
    State currentState = State.BEFORE_START;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 amount);

     
    event Refund(address indexed to, uint256 amount);

     
    modifier saleIsOn() {
        require(
            (
                (now >= preSaleStart && now < preSaleEnd) || 
                (now >= saleStart && now < saleEnd)
            ) && 
            issuedTokens < hardCap && 
            currentState == State.SALE
        );
        _;
    }

     
    modifier beforeSale() {
        require( now < preSaleStart);
        _;
    }

     
    modifier inState(State _state) {
        require(currentState == _state);
        _;
    }

     
    function CraftyCrowdsale(address _token, uint256 _preSaleStart, uint256 _preSaleEnd, uint256 _saleStart, uint256 _saleEnd, uint256 _rate) public {
        require(_token != address(0));
        require(_preSaleStart < _preSaleEnd && _preSaleEnd < _saleStart && _saleStart < _saleEnd);
        require(_rate > 0);

        token = MintableToken(_token);
        preSaleStart = _preSaleStart;
        preSaleEnd = _preSaleEnd;
        saleStart = _saleStart;
        saleEnd = _saleEnd;
        rate = _rate;
    }

     
    function () public payable {
        if(msg.sender != owner)
            buyTokens();
    }

     
    function buyTokens() public saleIsOn whenNotPaused payable {
        require(msg.sender != address(0));
        require(msg.value >= 20 finney);

        uint256 weiAmount = msg.value;
        uint256 currentRate = getRate(weiAmount);

         
        uint256 newTokens = weiAmount.mul(currentRate).div(10**18);

        require(issuedTokens.add(newTokens) <= hardCap);
        
        issuedTokens = issuedTokens.add(newTokens);
        received[msg.sender] = received[msg.sender].add(weiAmount);
        token.mint(msg.sender, newTokens);
        TokenPurchase(msg.sender, msg.sender, newTokens);

        etherWallet.transfer(msg.value);
    }

     
    function setRate(uint256 _rate) public onlyOwner beforeSale {
        require(_rate > 0);

        rate = _rate;
    }

     
    function setWallets(address _etherWallet, address _teamWallet, address _advisorWallet, address _bountyWallet, address _fundWallet) public onlyOwner inState(State.BEFORE_START) {
        require(_etherWallet != address(0));
        require(_teamWallet != address(0));
        require(_advisorWallet != address(0));
        require(_bountyWallet != address(0));
        require(_fundWallet != address(0));

        etherWallet = _etherWallet;
        teamWallet = _teamWallet;
        advisorWallet = _advisorWallet;
        bountyWallet = _bountyWallet;
        fundWallet = _fundWallet;

        uint256 releaseTime = saleEnd + lockTime;

         
        teamTokens = new TokenTimelock(token, teamWallet, releaseTime);
        token.mint(teamTokens, teamCap);

         
        token.mint(advisorWallet, advisorCap);
        token.mint(bountyWallet, bountyCap);
        token.mint(fundWallet, fundCap);

        currentState = State.SALE;
    }

     
    function generateTokens(address beneficiary, uint256 newTokens) public onlyOwner {
        require(beneficiary != address(0));
        require(newTokens > 0);
        require(issuedTokens.add(newTokens) <= hardCap);

        issuedTokens = issuedTokens.add(newTokens);
        token.mint(beneficiary, newTokens);
        TokenPurchase(msg.sender, beneficiary, newTokens);
    }

     
    function finishCrowdsale() public onlyOwner inState(State.SALE) {
        require(now > saleEnd);
         
        uint256 unspentTokens = hardCap.sub(issuedTokens);
        token.mint(fundWallet, unspentTokens);

        currentState = State.CLOSED;

        token.finishMinting();
    }

     
    function enableRefund() public onlyOwner inState(State.CLOSED) {
        currentState = State.REFUND;
    }

     
    function receivedFrom(address beneficiary) public view returns (uint256) {
        return received[beneficiary];
    }

     
    function claimRefund() public whenNotPaused inState(State.REFUND) {
        require(received[msg.sender] > 0);

        uint256 amount = received[msg.sender];
        received[msg.sender] = 0;
        msg.sender.transfer(amount);
        Refund(msg.sender, amount);
    }

     
    function releaseTeamTokens() public {
        teamTokens.release();
    }

     
    function reclaimEther() public onlyOwner {
        owner.transfer(this.balance);
    }

     
    function getRate(uint256 amount) internal view returns (uint256) {
        if(now < preSaleEnd) {
            require(amount >= 6797 finney);

            if(amount <= 8156 finney)
                return rate.mul(105).div(100);
            if(amount <= 9515 finney)
                return rate.mul(1055).div(1000);
            if(amount <= 10874 finney)
                return rate.mul(1065).div(1000);
            if(amount <= 12234 finney)
                return rate.mul(108).div(100);
            if(amount <= 13593 finney)
                return rate.mul(110).div(100);
            if(amount <= 27185 finney)
                return rate.mul(113).div(100);
            if(amount > 27185 finney)
                return rate.mul(120).div(100);
        }

        return rate;
    }
}