 

pragma solidity ^0.4.24;

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
    public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
    public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

 
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

 
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
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

}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
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

     
    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
    public
    returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
    public
    returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

 
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;
    address public own_contract;


    function setCrowdsaleAddress(address _address) onlyOwner public{
        own_contract = _address;
    }
    
    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier hasMintPermission() {
        require(msg.sender == own_contract);
        _;
    }

     
    function mint(
        address _to,
        uint256 _amount
    )
    hasMintPermission
    canMint
    public
    returns (bool)
    {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        emit Transfer(owner, _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
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

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

 
contract Crowdsale is Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IQBankToken;

     
    IQBankToken public token;

     
    address public wallet;

     
     
     
     
    uint256 public rate;

     
    uint public bonusPercent = 0;

     
    uint256 public weiRaised;

     
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

     
    constructor(uint256 _rate, address _wallet, IQBankToken _token) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

     
     
     

     
    function () external whenNotPaused payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public whenNotPaused payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);

         
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens
        );

        _updatePurchasingState(_beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }

     
     
     

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

     
    function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
         
    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.safeTransfer(_beneficiary, _tokenAmount);
    }

     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

     
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
         
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(rate).mul(100 + bonusPercent).div(100);
    }

     
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}

 
contract IQBankToken is MintableToken {
    string public constant name = "IQ Bank token";  
    string public constant symbol = "IQTK";  
    uint8 public constant decimals = 18;  

    uint256 public constant LIMIT_SUPPLY = 30 * (10 ** (6 + uint256(decimals)));  
}

 
contract IQTKCrowdsale is Crowdsale {

     
    uint public constant MIN_INVEST_ETHER = 10 finney;

     
    uint public stage = 0;

     
    bool isFinalized = false;

     
    mapping(address => uint256) public balances;

    mapping(address => uint) public parts;

     
    uint256 public tokensIssued;

     
    event TokenDelivered(address indexed receiver, uint256 amount);

     
    event TokenAdded(address indexed beneficiary, uint256 amount);

     
     
    modifier NotFinalized() {
        require(!isFinalized, "Can't process. Crowdsale is finalized");     
        _;  
    }

     
    modifier Finalized() {
        require(isFinalized, "Can't process. Crowdsale is not finalized");  
        _;  
    }

     
    constructor(uint256 _rate, address _wallet, IQBankToken _token) Crowdsale(_rate, _wallet, _token) public {
        paused = true;  
    }

     
     
     

     
    function unpause(uint _stage, uint _bonusPercent) onlyOwner whenPaused public {
        super.unpause();  
        stage = _stage;
        bonusPercent = _bonusPercent;
    }

     
    function withdrawTokens() Finalized public {
        _withdrawTokensFor(msg.sender);
    }

     
    function addTokens(address _beneficiary, uint256 _tokenAmount) onlyOwner NotFinalized public {
        balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
        tokensIssued = tokensIssued.add(_tokenAmount);
        emit TokenAdded(_beneficiary, _tokenAmount);
    }

     
    function finalize() onlyOwner NotFinalized public {
        isFinalized = true;
    }

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(msg.value >= MIN_INVEST_ETHER, "Minimal invest 0.01 ETH");  
    }

     
    function _withdrawTokensFor(address receiver_) internal {
        uint256 amount = balances[receiver_];
        require(amount > 0);
        balances[receiver_] = 0;
        emit TokenDelivered(receiver_, amount);
        _deliverTokens(receiver_, amount);
    }

    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
    }

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.mint(_beneficiary, _tokenAmount);
    }
}