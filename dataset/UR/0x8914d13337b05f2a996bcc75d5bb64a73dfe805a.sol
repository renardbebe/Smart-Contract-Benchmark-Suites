 

pragma solidity 0.4.25;

 
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
    mapping(address => bool) owners;

    event OwnerAdded(address indexed newOwner);
    event OwnerDeleted(address indexed owner);

     
    constructor() public {
        owners[msg.sender] = true;
    }

     
    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    function addOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        owners[_newOwner] = true;
        emit OwnerAdded(_newOwner);
    }

    function delOwner(address _owner) external onlyOwner {
        require(owners[_owner]);
        owners[_owner] = false;
        emit OwnerDeleted(_owner);
    }

    function isOwner(address _owner) public view returns (bool) {
        return owners[_owner];
    }
}


 
contract ERC20 {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
 
contract StandardToken is ERC20, Ownable{
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) balances;

    uint256 _totalSupply;


     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function transfer(address _to, uint256 _value)  public returns (bool) {
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


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)  public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


    function burn(uint256 value) onlyOwner external {
        _totalSupply = _totalSupply.sub(value);
        balances[msg.sender] = balances[msg.sender].sub(value);
        emit Transfer(msg.sender, address(0), value);
    }

}


 
contract ErbNToken is StandardToken {
    string public constant name = "Erbauer Netz";  
    string public constant symbol = "ErbN";  
    uint8 public constant decimals = 18;  

    uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));


    constructor() public {
        _totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }

}




 
library SafeERC20 {
    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    )
    internal
    {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}


 
contract Crowdsale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

     
    ERC20 public token;

     
    address public wallet;

     
     
     
     
    uint256 public rate;
    uint256 public preSaleRate;
    uint256 minPurchase = 10000000000000000;
    uint256 tokenSold;

     
    uint256 public weiRaised;

    bool public isPreSale = false;
    bool public isICO = false;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event Finalized();
     
    modifier onlyWhileOpen {
         
        require(isPreSale || isICO);
        _;
    }


    constructor(uint256 _rate, uint256 _preSaleRate, address _wallet, address _token) public {
        require(_rate > 0);
        require(_preSaleRate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        preSaleRate = _preSaleRate;
        rate = _rate;
        wallet = _wallet;
        token = ERC20(_token);
    }

     
     
     

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);
        _postValidatePurchase(tokens);

         
        tokenSold = tokenSold.add(tokens);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        _forwardFunds();
    }


    function manualSale(address _beneficiary, uint256 _amount) onlyOwner external {
        _processPurchase(_beneficiary, _amount);
    }

     
     
     

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) onlyWhileOpen internal view {
        require(_beneficiary != address(0));
        require(_weiAmount >= minPurchase);
    }


    function _postValidatePurchase(uint256 _tokens) internal view {
        if (isPreSale) {
            require(tokenSold.add(_tokens) <= 200000000 ether);
        }

    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.safeTransfer(_beneficiary, _tokenAmount);
    }

     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        if (isPreSale) return _weiAmount.mul(preSaleRate);
        if (isICO) return _weiAmount.mul(rate);
        return 0;
    }

     
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    function finalize() onlyOwner public {
        finalization();
        emit Finalized();
    }

     
    function finalization() internal {
        token.safeTransfer(msg.sender, token.balanceOf(this));
    }


    function setRate(uint _rate) onlyOwner external {
        rate = _rate;
    }

    function setPreSaleRate(uint _rate) onlyOwner external {
        preSaleRate = _rate;
    }


    function setPresaleStatus(bool _status) onlyOwner external {
        isPreSale = _status;
    }

    function setICOStatus(bool _status) onlyOwner external {
        isICO = _status;
    }

    function setMinPurchase(uint _val) onlyOwner external {
        minPurchase = _val;
    }
}


 
contract TokenTimelock is Ownable {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

     
    ERC20 public token;
    uint releaseTime;

    mapping(address => uint256) public balances;

    constructor(ERC20 _token) public {
        token = _token;
        releaseTime = now + 375 days;
    }

    function addTokens(address _owner, uint256 _value) onlyOwner external returns (bool) {
        require(_owner != address(0));
         
         
        balances[_owner] = balances[_owner].add(_value);
        return true;
    }


    function getTokens() external {
        require(balances[msg.sender] > 0);
        require(releaseTime < now);

        token.safeTransfer(msg.sender, balances[msg.sender]);
        balances[msg.sender] = 0;
    }
}