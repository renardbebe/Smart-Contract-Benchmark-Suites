 

pragma solidity ^0.4.25;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}


contract ERC20Basic {
    uint256 public totalSupply;

    bool public transfersEnabled;

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 {
    uint256 public totalSupply;

    bool public transfersEnabled;

    function balanceOf(address _owner) public constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping (address => uint256) balances;

     
    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

     
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(transfersEnabled);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
}


contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(transfersEnabled);

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

     
    function allowance(address _owner, address _spender) public onlyPayloadSize(2) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}


 
contract Ownable {
    address public owner;

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function changeOwner(address _newOwner) onlyOwner internal {
        require(_newOwner != address(0));
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

}


 

contract MintableToken is StandardToken, Ownable {
    string public constant name = "WebSpaceX";
    string public constant symbol = "WSPX";
    uint8 public constant decimals = 18;
    mapping(uint8 => uint8) public approveOwner;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount, address _owner) canMint internal returns (bool) {
        balances[_to] = balances[_to].add(_amount);
        balances[_owner] = balances[_owner].sub(_amount);
        emit Mint(_to, _amount);
        emit Transfer(_owner, _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint internal returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

     
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }
        MintableToken token = MintableToken(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        emit Transfer(_token, owner, balance);
    }
}


 
contract Crowdsale is Ownable {
    using SafeMath for uint256;
     
    address public wallet;
    uint256 public hardWeiCap = 15830 ether;

     
    uint256 public weiRaised;
    uint256 public tokenAllocated;

    constructor(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
    }
}


contract WSPXCrowdsale is Ownable, Crowdsale, MintableToken {
    using SafeMath for uint256;

    uint256 public rate  = 312500;

    mapping (address => uint256) public deposited;
    mapping (address => bool) internal isRefferer;

    uint256 public weiMinSale = 0.1 ether;

    uint256 public constant INITIAL_SUPPLY = 9 * 10**9 * (10 ** uint256(decimals));

    uint256 public fundForSale   = 6 * 10**9 * (10 ** uint256(decimals));
    uint256 public    fundTeam   = 1 * 10**9 * (10 ** uint256(decimals));
    uint256 public    fundBounty = 2 * 10**9 * (10 ** uint256(decimals));

    address public addressFundTeam   = 0xA2434A8F6457fe7CF29AEa841cf3D0B0FE3217c8;
    address public addressFundBounty = 0x8828c48DEc2764868aD3bBf7fE9e8aBE773E3064;

     
    uint256 startTimeIcoStage1 = 1546300800;  
    uint256 endTimeIcoStage1 =   1547596799;  

     
    uint256 startTimeIcoStage2 = 1547596800;  
    uint256 endTimeIcoStage2   = 1548979199;  

     
    uint256 startTimeIcoStage3 = 1548979200;  
    uint256 endTimeIcoStage3   = 1554076799;  

    uint256 limitStage1 =  2 * 10**9 * (10 ** uint256(decimals));
    uint256 limitStage2 =  4 * 10**9 * (10 ** uint256(decimals));
    uint256 limitStage3 =  6 * 10**9 * (10 ** uint256(decimals));

    uint256 public countInvestor;

    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenLimitReached(address indexed sender, uint256 tokenRaised, uint256 purchasedToken);
    event CurrentPeriod(uint period);
    event ChangeTime(address indexed owner, uint256 newValue, uint256 oldValue);
    event ChangeAddressWallet(address indexed owner, address indexed newAddress, address indexed oldAddress);
    event ChangeRate(address indexed owner, uint256 newValue, uint256 oldValue);
    event Burn(address indexed burner, uint256 value);
    event HardCapReached();


    constructor(address _owner, address _wallet) public
    Crowdsale(_wallet)
    {
        require(_owner != address(0));
        owner = _owner;
         
        transfersEnabled = true;
        mintingFinished = false;
        totalSupply = INITIAL_SUPPLY;
        bool resultMintForOwner = mintForFund(owner);
        require(resultMintForOwner);
    }

     
    function() payable public {
        buyTokens(msg.sender);
    }

    function buyTokens(address _investor) public payable returns (uint256){
        require(_investor != address(0));
        uint256 weiAmount = msg.value;
        uint256 tokens = validPurchaseTokens(weiAmount);
        if (tokens == 0) {revert();}
        weiRaised = weiRaised.add(weiAmount);
        tokenAllocated = tokenAllocated.add(tokens);
        mint(_investor, tokens, owner);

        emit TokenPurchase(_investor, weiAmount, tokens);
        if (deposited[_investor] == 0) {
            countInvestor = countInvestor.add(1);
        }
        deposit(_investor);
        wallet.transfer(weiAmount);
        return tokens;
    }

    function getTotalAmountOfTokens(uint256 _weiAmount) internal returns (uint256) {
        uint256 currentDate = now;
         
        uint currentPeriod = 0;
        currentPeriod = getPeriod(currentDate);
        uint256 amountOfTokens = 0;
        if(currentPeriod > 0){
            if(currentPeriod == 1){
                amountOfTokens = _weiAmount.mul(rate).mul(130).div(100);
                if (tokenAllocated.add(amountOfTokens) > limitStage1) {
                    currentPeriod = currentPeriod.add(1);
                    amountOfTokens = 0;
                }
            }
            if(currentPeriod == 2){
                amountOfTokens = _weiAmount.mul(rate).mul(120).div(100);
                if (tokenAllocated.add(amountOfTokens) > limitStage2) {
                    currentPeriod = currentPeriod.add(1);
                    amountOfTokens = 0;
                }
            }
            if(currentPeriod == 3){
                amountOfTokens = _weiAmount.mul(rate).mul(110).div(100);
                if (tokenAllocated.add(amountOfTokens) > limitStage3) {
                    currentPeriod = 0;
                    amountOfTokens = 0;
                }
            }
        }
        emit CurrentPeriod(currentPeriod);
        return amountOfTokens;
    }

    function getPeriod(uint256 _currentDate) public view returns (uint) {
        if(_currentDate < startTimeIcoStage1){
            return 0;
        }
        if( startTimeIcoStage1 <= _currentDate && _currentDate <= endTimeIcoStage1){
            return 1;
        }
        if( startTimeIcoStage2 <= _currentDate && _currentDate <= endTimeIcoStage2){
            return 2;
        }
        if( startTimeIcoStage3 <= _currentDate && _currentDate <= endTimeIcoStage3){
            return 3;
        }
        return 0;
    }

    function deposit(address investor) internal {
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function mintForFund(address _walletOwner) internal returns (bool result) {
        result = false;
        require(_walletOwner != address(0));
        balances[_walletOwner] = balances[_walletOwner].add(fundForSale);
        balances[addressFundTeam] = balances[addressFundTeam].add(fundTeam);
        balances[addressFundBounty] = balances[addressFundBounty].add(fundBounty);
        result = true;
    }

    function getDeposited(address _investor) external view returns (uint256){
        return deposited[_investor];
    }

    function validPurchaseTokens(uint256 _weiAmount) public returns (uint256) {
        uint256 addTokens = getTotalAmountOfTokens(_weiAmount);
        if (tokenAllocated.add(addTokens) > balances[owner]) {
            emit TokenLimitReached(msg.sender, tokenAllocated, addTokens);
            return 0;
        }
        if (weiRaised.add(_weiAmount) > hardWeiCap) {
            emit HardCapReached();
            return 0;
        }
        if (_weiAmount < weiMinSale) {
            return 0;
        }

    return addTokens;
    }

     
    function ownerBurnToken(uint _value) public onlyOwner {
        require(_value > 0);
        require(_value <= balances[owner]);
        require(_value <= totalSupply);

        balances[owner] = balances[owner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
    }

     
    function setStartTimeIcoStage1(uint256 _value) external onlyOwner {
        require(_value > 0);
        uint256 _oldValue = startTimeIcoStage1;
        startTimeIcoStage1 = _value;
        emit ChangeTime(msg.sender, _value, _oldValue);
    }

     
    function setEndTimeIcoStage1(uint256 _value) external onlyOwner {
        require(_value > 0);
        uint256 _oldValue = endTimeIcoStage1;
        endTimeIcoStage1 = _value;
        emit ChangeTime(msg.sender, _value, _oldValue);
    }

     
    function setStartTimeIcoStage2(uint256 _value) external onlyOwner {
        require(_value > 0);
        uint256 _oldValue = startTimeIcoStage2;
        startTimeIcoStage2 = _value;
        emit ChangeTime(msg.sender, _value, _oldValue);
    }


     
    function setEndTimeIcoStage2(uint256 _value) external onlyOwner {
        require(_value > 0);
        uint256 _oldValue = endTimeIcoStage2;
        endTimeIcoStage2 = _value;
        emit ChangeTime(msg.sender, _value, _oldValue);
    }

     
    function setStartTimeIcoStage3(uint256 _value) external onlyOwner {
        require(_value > 0);
        uint256 _oldValue = startTimeIcoStage3;
        startTimeIcoStage3 = _value;
        emit ChangeTime(msg.sender, _value, _oldValue);
    }


     
    function setEndTimeIcoStage3(uint256 _value) external onlyOwner {
        require(_value > 0);
        uint256 _oldValue = endTimeIcoStage3;
        endTimeIcoStage3 = _value;
        emit ChangeTime(msg.sender, _value, _oldValue);
    }

     
    function setWallet(address _newWallet) external onlyOwner {
        require(_newWallet != address(0));
        address _oldWallet = wallet;
        wallet = _newWallet;
        emit ChangeAddressWallet(msg.sender, _newWallet, _oldWallet);
    }

     
    function setRate(uint256 _newRate) external onlyOwner {
        require(_newRate > 0);
        uint256 _oldRate = rate;
        rate = _newRate;
        emit ChangeRate(msg.sender, _newRate, _oldRate);
    }
}