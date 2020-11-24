 

pragma solidity ^0.4.22;

 
 
 

 

 
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

    function minus(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);

        return a - b;
    }

    function plus(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);

        return c;
    }
}

 

 
contract ERC20Token {
    uint256 public totalSupply;   
    
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

 
contract TokenSafe {
    using SafeMath for uint;

     
    ERC20Token token;

    struct Group {
         
         
        uint256 releaseTimestamp;
         
        uint256 remaining;
         
        mapping (address => uint) balances;
    }

     
    mapping (uint8 => Group) public groups;

     
    constructor(address _token) public {
        token = ERC20Token(_token);
    }

     
    function init(uint8 _id, uint _releaseTimestamp) internal {
        require(_releaseTimestamp > 0, "TokenSafe group release timestamp is not set");
        
        Group storage group = groups[_id];
        group.releaseTimestamp = _releaseTimestamp;
    }

     
    function add(uint8 _id, address _account, uint _balance) internal {
        Group storage group = groups[_id];
        group.balances[_account] = group.balances[_account].plus(_balance);
        group.remaining = group.remaining.plus(_balance);
    }

     
    function release(uint8 _id, address _account) public {
        Group storage group = groups[_id];
        require(now >= group.releaseTimestamp, "Group funds are not released yet");
        
        uint tokens = group.balances[_account];
        require(tokens > 0, "The account is empty or non-existent");
        
        group.balances[_account] = 0;
        group.remaining = group.remaining.minus(tokens);
        
        if (!token.transfer(_account, tokens)) {
            revert("Token transfer failed");
        }
    }
}

 

 
contract StandardToken is ERC20Token {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

     
    constructor(string _name, string _symbol, uint8 _decimals) internal {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

     
    function balanceOf(address _address) public view returns (uint256 balance) {
        return balances[_address];
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        executeTransfer(msg.sender, _to, _value);

        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender], "Insufficient allowance");

        allowed[_from][msg.sender] = allowed[_from][msg.sender].minus(_value);
        executeTransfer(_from, _to, _value);

        return true;
    }

     
    function executeTransfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid transfer to address zero");
        require(_value <= balances[_from], "Insufficient account balance");

        balances[_from] = balances[_from].minus(_value);
        balances[_to] = balances[_to].plus(_value);

        emit Transfer(_from, _to, _value);
    }
}

 

 
contract MintableToken is StandardToken {
     
    address public minter;

     
    bool public mintingDisabled = false;

     
    event MintingDisabled();

     
    modifier canMint() {
        require(!mintingDisabled, "Minting is disabled");
        _;
    }

     
    modifier onlyMinter() {
        require(msg.sender == minter, "Only the minter address can mint");
        _;
    }

     
    constructor(address _minter) internal {
        minter = _minter;
    }

     
    function mint(address _to, uint256 _value) public onlyMinter canMint {
        totalSupply = totalSupply.plus(_value);
        balances[_to] = balances[_to].plus(_value);

        emit Transfer(0x0, _to, _value);
    }

     
    function disableMinting() public onlyMinter canMint {
        mintingDisabled = true;
       
        emit MintingDisabled();
    }
}

 

 
contract HasOwner {
     
    address public owner;

     
    address public newOwner;

     
    constructor(address _owner) public {
        owner = _owner;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

     
    event OwnershipTransfer(address indexed _oldOwner, address indexed _newOwner);

     
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
 
     
    function acceptOwnership() public {
        require(msg.sender == newOwner, "Only the newOwner can accept ownership");

        emit OwnershipTransfer(owner, newOwner);

        owner = newOwner;
    }
}

 

contract AbstractFundraiser {
     
    ERC20Token public token;

     
    event FundsReceived(address indexed _address, uint _ethers, uint _tokens);


     
    function initializeFundraiserToken(address _token) internal
    {
        token = ERC20Token(_token);
    }

     
    function() public payable {
        receiveFunds(msg.sender, msg.value);
    }

     
    function getConversionRate() public view returns (uint256);

     
    function hasEnded() public view returns (bool);

     
    function receiveFunds(address _address, uint256 _amount) internal;
    
     
    function validateTransaction() internal view;
    
     
    function handleTokens(address _address, uint256 _tokens) internal;

     
    function handleFunds(address _address, uint256 _ethers) internal;

}

 

 
contract BasicFundraiser is HasOwner, AbstractFundraiser {
    using SafeMath for uint256;

     
    uint8 constant DECIMALS = 18;   

     
    uint256 constant DECIMALS_FACTOR = 10 ** uint256(DECIMALS);

     
    uint256 public startTime;

     
    uint256 public endTime;

     
    address public beneficiary;

     
     
    uint256 public conversionRate;

     
    uint256 public totalRaised;

     
    event ConversionRateChanged(uint _conversionRate);

     
    function initializeBasicFundraiser(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _conversionRate,
        address _beneficiary
    )
        internal
    {
        require(_endTime >= _startTime, "Fundraiser's end is before its start");
        require(_conversionRate > 0, "Conversion rate is not set");
        require(_beneficiary != address(0), "The beneficiary is not set");

        startTime = _startTime;
        endTime = _endTime;
        conversionRate = _conversionRate;
        beneficiary = _beneficiary;
    }

     
    function setConversionRate(uint256 _conversionRate) public onlyOwner {
        require(_conversionRate > 0, "Conversion rate is not set");

        conversionRate = _conversionRate;

        emit ConversionRateChanged(_conversionRate);
    }

     
    function setBeneficiary(address _beneficiary) public onlyOwner {
        require(_beneficiary != address(0), "The beneficiary is not set");

        beneficiary = _beneficiary;
    }

     
    function receiveFunds(address _address, uint256 _amount) internal {
        validateTransaction();

        uint256 tokens = calculateTokens(_amount);
        require(tokens > 0, "The transaction results in zero tokens");

        totalRaised = totalRaised.plus(_amount);
        handleTokens(_address, tokens);
        handleFunds(_address, _amount);

        emit FundsReceived(_address, msg.value, tokens);
    }

     
    function getConversionRate() public view returns (uint256) {
        return conversionRate;
    }

     
    function calculateTokens(uint256 _amount) internal view returns(uint256 tokens) {
        tokens = _amount.mul(getConversionRate());
    }

     
    function validateTransaction() internal view {
        require(msg.value != 0, "Transaction value is zero");
        require(now >= startTime && now < endTime, "The fundraiser is not active");
    }

     
    function hasEnded() public view returns (bool) {
        return now >= endTime;
    }
}

 

contract StandardMintableToken is MintableToken {
    constructor(address _minter, string _name, string _symbol, uint8 _decimals)
        StandardToken(_name, _symbol, _decimals)
        MintableToken(_minter)
        public
    {
    }
}

 

 
contract MintableTokenFundraiser is BasicFundraiser {
     
    function initializeMintableTokenFundraiser(string _name, string _symbol, uint8 _decimals) internal {
        token = new StandardMintableToken(
            address(this),  
            _name,
            _symbol,
            _decimals
        );
    }

     
    function handleTokens(address _address, uint256 _tokens) internal {
        MintableToken(token).mint(_address, _tokens);
    }
}

 

 
contract IndividualCapsFundraiser is BasicFundraiser {
    uint256 public individualMinCap;
    uint256 public individualMaxCap;
    uint256 public individualMaxCapTokens;


    event IndividualMinCapChanged(uint256 _individualMinCap);
    event IndividualMaxCapTokensChanged(uint256 _individualMaxCapTokens);

     
    function initializeIndividualCapsFundraiser(uint256 _individualMinCap, uint256 _individualMaxCap) internal {
        individualMinCap = _individualMinCap;
        individualMaxCap = _individualMaxCap;
        individualMaxCapTokens = _individualMaxCap * conversionRate;
    }

    function setConversionRate(uint256 _conversionRate) public onlyOwner {
        super.setConversionRate(_conversionRate);

        if (individualMaxCap == 0) {
            return;
        }
        
        individualMaxCapTokens = individualMaxCap * _conversionRate;

        emit IndividualMaxCapTokensChanged(individualMaxCapTokens);
    }

    function setIndividualMinCap(uint256 _individualMinCap) public onlyOwner {
        individualMinCap = _individualMinCap;

        emit IndividualMinCapChanged(individualMinCap);
    }

    function setIndividualMaxCap(uint256 _individualMaxCap) public onlyOwner {
        individualMaxCap = _individualMaxCap;
        individualMaxCapTokens = _individualMaxCap * conversionRate;

        emit IndividualMaxCapTokensChanged(individualMaxCapTokens);
    }

     
    function validateTransaction() internal view {
        super.validateTransaction();
        require(
            msg.value >= individualMinCap,
            "The transaction value does not pass the minimum contribution cap"
        );
    }

     
    function handleTokens(address _address, uint256 _tokens) internal {
        require(
            individualMaxCapTokens == 0 || token.balanceOf(_address).plus(_tokens) <= individualMaxCapTokens,
            "The transaction exceeds the individual maximum cap"
        );

        super.handleTokens(_address, _tokens);
    }
}

 

 
contract GasPriceLimitFundraiser is HasOwner, BasicFundraiser {
    uint256 public gasPriceLimit;

    event GasPriceLimitChanged(uint256 gasPriceLimit);

     
    function initializeGasPriceLimitFundraiser(uint256 _gasPriceLimit) internal {
        gasPriceLimit = _gasPriceLimit;
    }

     
    function changeGasPriceLimit(uint256 _gasPriceLimit) public onlyOwner {
        gasPriceLimit = _gasPriceLimit;

        emit GasPriceLimitChanged(_gasPriceLimit);
    }

     
    function validateTransaction() internal view {
        require(gasPriceLimit == 0 || tx.gasprice <= gasPriceLimit, "Transaction exceeds the gas price limit");

        return super.validateTransaction();
    }
}

 

 
contract ForwardFundsFundraiser is BasicFundraiser {
     
    function handleFunds(address, uint256 _ethers) internal {
         
        beneficiary.transfer(_ethers);
    }
}

 

 
contract PresaleFundraiser is MintableTokenFundraiser {
     
    uint256 public presaleSupply;

     
    uint256 public presaleMaxSupply;

     
    uint256 public presaleStartTime;

     
    uint256 public presaleEndTime;

     
    uint256 public presaleConversionRate;

     
    function initializePresaleFundraiser(
        uint256 _presaleMaxSupply,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _conversionRate
    )
        internal
    {
        require(_endTime >= _startTime, "Pre-sale's end is before its start");
        require(_conversionRate > 0, "Conversion rate is not set");

        presaleMaxSupply = _presaleMaxSupply;
        presaleStartTime = _startTime;
        presaleEndTime = _endTime;
        presaleConversionRate = _conversionRate;
    }

     
    
    function isPresaleActive() internal view returns (bool) {
        return now < presaleEndTime && now >= presaleStartTime;
    }
     
    function getConversionRate() public view returns (uint256) {
        if (isPresaleActive()) {
            return presaleConversionRate;
        }
        return super.getConversionRate();
    }

     
    function validateTransaction() internal view {
        require(msg.value != 0, "Transaction value is zero");
        require(
            now >= startTime && now < endTime || isPresaleActive(),
            "Neither the pre-sale nor the fundraiser are currently active"
        );
    }

    function handleTokens(address _address, uint256 _tokens) internal {
        if (isPresaleActive()) {
            presaleSupply = presaleSupply.plus(_tokens);
            require(
                presaleSupply <= presaleMaxSupply,
                "Transaction exceeds the pre-sale maximum token supply"
            );
        }

        super.handleTokens(_address, _tokens);
    }

}

 

 

contract TieredFundraiser is BasicFundraiser {
     
    uint256 constant CONVERSION_RATE_FACTOR = 100;

     
    function getConversionRate() public view returns (uint256) {
        return super.getConversionRate().mul(CONVERSION_RATE_FACTOR);
    }

     
    function calculateTokens(uint256 _amount) internal view returns(uint256 tokens) {
        return super.calculateTokens(_amount).div(CONVERSION_RATE_FACTOR);
    }

     
    function getConversionRateFactor() public pure returns (uint256) {
        return CONVERSION_RATE_FACTOR;
    }
}

 

 

contract SPACEToken is MintableToken {
    constructor(address _minter)
        StandardToken(
            "SPACE",    
            "SP",  
            18   
        )
        
        MintableToken(_minter)
        public
    {
    }
}



 

contract SPACETokenSafe is TokenSafe {
  constructor(address _token)
    TokenSafe(_token)
    public
  {
    
     
    init(
      1,  
      1553821200  
    );
    add(
      1,  
      0xc5F7f03202c2f85c4d90e89Fc5Ce789c0249Ec26,   
      420000000000000000000000   
    );
  }
}



 

contract SPACETokenFundraiser is MintableTokenFundraiser, PresaleFundraiser, IndividualCapsFundraiser, ForwardFundsFundraiser, TieredFundraiser, GasPriceLimitFundraiser {
    SPACETokenSafe public tokenSafe;

    constructor()
        HasOwner(msg.sender)
        public
    {
        token = new SPACEToken(
        
        address(this)   
        );

        tokenSafe = new SPACETokenSafe(token);
        MintableToken(token).mint(address(tokenSafe), 420000000000000000000000);

        initializeBasicFundraiser(
            1553731200,  
            1893455940,   
            1,  
            0x0dE3D184765E4BCa547B12C5c1786765FE21450b      
        );

        initializeIndividualCapsFundraiser(
            (0 ether),  
            (0 ether)   
        );

        initializeGasPriceLimitFundraiser(
            3000000000000000  
        );

        initializePresaleFundraiser(
            1200000000000000000000000,
            1553558400,  
            1553731140,    
            1
        );

        

        

        
    }
    
     
    function getConversionRate() public view returns (uint256) {
        uint256 rate = super.getConversionRate();
        if (now >= 1553731200 && now < 1556495940)
            return rate.mul(105).div(100);
        

        return rate;
    }

     
    function mint(address _to, uint256 _value) public onlyOwner {
        MintableToken(token).mint(_to, _value);
    }

     
    function disableMinting() public onlyOwner {
        MintableToken(token).disableMinting();
    }
    
}