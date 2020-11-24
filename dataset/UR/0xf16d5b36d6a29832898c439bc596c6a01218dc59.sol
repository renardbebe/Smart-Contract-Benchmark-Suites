 

pragma solidity ^0.4.24;


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
    mapping (address => bool) public whitelistPayee;


     
    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

    function checkTransfer(address _to) public view {
        bool permit = false;
        if (!transfersEnabled) {
            if (whitelistPayee[_to]) {
                permit = true;
            }
        } else {
            permit = true;
        }
        require(permit);
    }

     
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool) {
        checkTransfer(_to);
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
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
        checkTransfer(_to);

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

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}


 

contract MintableToken is StandardToken, Ownable {
    string public constant name = "PHOENIX INVESTMENT FUND";
    string public constant symbol = "PHI";
    uint8 public constant decimals = 18;

    event Mint(address indexed to, uint256 amount);

    bool public mintingFinished;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount, address _owner) canMint internal returns (bool) {
        require(_to != address(0));
        require(_owner != address(0));
        require(_amount <= balances[_owner]);

        balances[_to] = balances[_to].add(_amount);
        balances[_owner] = balances[_owner].sub(_amount);
        emit Mint(_to, _amount);
        emit Transfer(_owner, _to, _amount);
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
     
    address public wallet;

     
    uint256 public weiRaised;
    uint256 public tokenAllocated;

    constructor(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
    }
}


contract PHICrowdsale is Ownable, Crowdsale, MintableToken {
    using SafeMath for uint256;

    uint256 public ratePreIco  = 600;
    uint256 public rateIco  = 400;

    uint256 public weiMin = 0.03 ether;

    mapping (address => uint256) public deposited;

    uint256 public constant INITIAL_SUPPLY = 63 * 10**6 * (10 ** uint256(decimals));
    uint256 public    fundForSale = 60250 * 10**3 * (10 ** uint256(decimals));

    uint256 fundTeam =          150 * 10**3 * (10 ** uint256(decimals));
    uint256 fundAirdropPreIco = 250 * 10**3 * (10 ** uint256(decimals));
    uint256 fundAirdropIco =    150 * 10**3 * (10 ** uint256(decimals));
    uint256 fundBounty     =    100 * 10**3 * (10 ** uint256(decimals));
    uint256 fundAdvisor   =    210 * 10**3 * (10 ** uint256(decimals));
    uint256 fundReferal    =    1890 * 10**3 * (10 ** uint256(decimals));

    uint256 limitPreIco = 12 * 10**5 * (10 ** uint256(decimals));

    address addressFundTeam = 0x26cfc82A77ECc5a493D72757936A78A089FA592a;
    address addressFundAirdropPreIco = 0x87953BAE7A92218FAcE2DDdb30AB2193263394Ef;
    address addressFundAirdropIco = 0xaA8C9cA32cC8A6A7FF5eCB705787C22d9400F377;

    address addressFundBounty =  0x253fBeb28dA7E85c720F66bbdCFC4D9418196EE5;
    address addressFundAdvisor = 0x61eAEe13A2a3805b57B46571EE97B6faf95fC34d;
    address addressFundReferal = 0x4BfB1bA71952DAC3886DCfECDdE2a4Fea2A06bDb;

    uint256 public startTimePreIco = 1538406000;  
    uint256 public endTimePreIco =   1539129600;  
    uint256 public startTimeIco =    1541300400;  
    uint256 public endTimeIco =      1542931200;  

    uint256 percentReferal = 5;

    uint256 public countInvestor;

    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenLimitReached(address indexed sender, uint256 tokenRaised, uint256 purchasedToken);
    event MinWeiLimitReached(address indexed sender, uint256 weiAmount);
    event Burn(address indexed burner, uint256 value);
    event CurrentPeriod(uint period);
    event ChangeTime(address indexed owner, uint256 newValue, uint256 oldValue);
    event ChangeAddressFund(address indexed owner, address indexed newAddress, address indexed oldAddress);

    constructor(address _owner, address _wallet) public
    Crowdsale(_wallet)
    {
        require(_owner != address(0));
        owner = _owner;
         
        transfersEnabled = false;
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
        makeReferalBonus(tokens);

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
                amountOfTokens = _weiAmount.mul(ratePreIco);
                if (tokenAllocated.add(amountOfTokens) > limitPreIco) {
                    currentPeriod = currentPeriod.add(1);
                }
            }
            if(currentPeriod == 2){
                amountOfTokens = _weiAmount.mul(rateIco);
            }
        }
        emit CurrentPeriod(currentPeriod);
        return amountOfTokens;
    }

    function getPeriod(uint256 _currentDate) public view returns (uint) {
        if(_currentDate < startTimePreIco){
            return 0;
        }
        if( startTimePreIco <= _currentDate && _currentDate <= endTimePreIco){
            return 1;
        }
        if( endTimePreIco < _currentDate && _currentDate < startTimeIco){
            return 0;
        }
        if( startTimeIco <= _currentDate && _currentDate <= endTimeIco){
            return 2;
        }
        return 0;
    }

    function deposit(address investor) internal {
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function makeReferalBonus(uint256 _amountToken) internal returns(uint256 _refererTokens) {
        _refererTokens = 0;
        if(msg.data.length == 20) {
            address referer = bytesToAddress(bytes(msg.data));
            require(referer != msg.sender);
            _refererTokens = _amountToken.mul(percentReferal).div(100);
            if(balanceOf(addressFundReferal) >= _refererTokens.mul(2)) {
                mint(referer, _refererTokens, addressFundReferal);
                mint(msg.sender, _refererTokens, addressFundReferal);
            }
        }
    }

    function bytesToAddress(bytes source) internal pure returns(address) {
        uint result;
        uint mul = 1;
        for(uint i = 20; i > 0; i--) {
            result += uint8(source[i-1])*mul;
            mul = mul*256;
        }
        return address(result);
    }

    function mintForFund(address _walletOwner) internal returns (bool result) {
        result = false;
        require(_walletOwner != address(0));
        balances[_walletOwner] = balances[_walletOwner].add(fundForSale);

        balances[addressFundTeam] = balances[addressFundTeam].add(fundTeam);
        balances[addressFundAirdropPreIco] = balances[addressFundAirdropPreIco].add(fundAirdropPreIco);
        balances[addressFundAirdropIco] = balances[addressFundAirdropIco].add(fundAirdropIco);
        balances[addressFundBounty] = balances[addressFundBounty].add(fundBounty);
        balances[addressFundAdvisor] = balances[addressFundAdvisor].add(fundAdvisor);
        balances[addressFundReferal] = balances[addressFundReferal].add(fundReferal);

        result = true;
    }

    function getDeposited(address _investor) public view returns (uint256){
        return deposited[_investor];
    }

    function validPurchaseTokens(uint256 _weiAmount) public returns (uint256) {
        uint256 addTokens = getTotalAmountOfTokens(_weiAmount);
        if (_weiAmount < weiMin) {
            emit MinWeiLimitReached(msg.sender, _weiAmount);
            return 0;
        }
        if (tokenAllocated.add(addTokens) > fundForSale) {
            emit TokenLimitReached(msg.sender, tokenAllocated, addTokens);
            return 0;
        }
        return addTokens;
    }

     
    function ownerBurnToken(uint _value) public onlyOwner {
        require(_value > 0);
        require(_value <= balances[owner]);
        require(_value <= totalSupply);
        require(_value <= fundForSale);

        balances[owner] = balances[owner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        fundForSale = fundForSale.sub(_value);
        emit Burn(msg.sender, _value);
    }

     
    function setStartTimePreIco(uint256 _value) public onlyOwner {
        require(_value > 0);
        uint256 _oldValue = startTimePreIco;
        startTimePreIco = _value;
        emit ChangeTime(msg.sender, _value, _oldValue);
    }


     
    function setEndTimePreIco(uint256 _value) public onlyOwner {
        require(_value > 0);
        uint256 _oldValue = endTimePreIco;
        endTimePreIco = _value;
        emit ChangeTime(msg.sender, _value, _oldValue);
    }

     
    function setStartTimeIco(uint256 _value) public onlyOwner {
        require(_value > 0);
        uint256 _oldValue = startTimeIco;
        startTimeIco = _value;
        emit ChangeTime(msg.sender, _value, _oldValue);
    }

     
    function setEndTimeIco(uint256 _value) public onlyOwner {
        require(_value > 0);
        uint256 _oldValue = endTimeIco;
        endTimeIco = _value;
        emit ChangeTime(msg.sender, _value, _oldValue);
    }

     
    function setAddressFundReferal(address _newAddress) public onlyOwner {
        require(_newAddress != address(0));
        address _oldAddress = addressFundReferal;
        addressFundReferal = _newAddress;
        emit ChangeAddressFund(msg.sender, _newAddress, _oldAddress);
    }

    function setWallet(address _newWallet) public onlyOwner {
        require(_newWallet != address(0));
        address _oldWallet = wallet;
        wallet = _newWallet;
        emit ChangeAddressFund(msg.sender, _newWallet, _oldWallet);
    }

     
    function addToWhitelist(address _payee) public onlyOwner {
        whitelistPayee[_payee] = true;
    }

     
    function removeFromWhitelist(address _payee) public onlyOwner {
        whitelistPayee[_payee] = false;
    }

    function setTransferActive(bool _status) public onlyOwner {
        transfersEnabled = _status;
    }
}