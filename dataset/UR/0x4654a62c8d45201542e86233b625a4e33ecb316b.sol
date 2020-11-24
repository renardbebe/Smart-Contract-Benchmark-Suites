 

pragma solidity 0.4.24;

 
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
}

 
contract Finalizable is Ownable {
    event Finish();

    bool public finalized = false;

    function finalize() public onlyOwner {
        finalized = true;
    }

    modifier notFinalized() {
        require(!finalized);
        _;
    }
}

 
contract IToken {
    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);
}

 
contract TokenReceivable is Ownable {
    event logTokenTransfer(address token, address to, uint256 amount);

    function claimTokens(address _token, address _to) public onlyOwner returns (bool) {
        IToken token = IToken(_token);
        uint256 balance = token.balanceOf(this);
        if (token.transfer(_to, balance)) {
            emit logTokenTransfer(_token, _to, balance);
            return true;
        }
        return false;
    }
}

contract EventDefinitions {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 value);
}

 
contract Token is Finalizable, TokenReceivable, EventDefinitions {
    using SafeMath for uint256;

    string public name = "FairWin Token";
    uint8 public decimals = 8;
    string public symbol = "FWIN";

    Controller controller;

     
    string public motd;

    function setController(address _controller) public onlyOwner notFinalized {
        controller = Controller(_controller);
    }

    modifier onlyController() {
        require(msg.sender == address(controller));
        _;
    }

    modifier onlyPayloadSize(uint256 numwords) {
        assert(msg.data.length >= numwords * 32 + 4);
        _;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return controller.balanceOf(_owner);
    }

    function totalSupply() public view returns (uint256) {
        return controller.totalSupply();
    }

     
    function transfer(address _to, uint256 _value) public
    onlyPayloadSize(2)
    returns (bool success) {
        success = controller.transfer(msg.sender, _to, _value);
        if (success) {
            emit Transfer(msg.sender, _to, _value);
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public
    onlyPayloadSize(3)
    returns (bool success) {
        success = controller.transferFrom(msg.sender, _from, _to, _value);
        if (success) {
            emit Transfer(_from, _to, _value);
        }
    }

     
    function approve(address _spender, uint256 _value) public
    onlyPayloadSize(2)
    returns (bool success) {
         
        require(controller.allowance(msg.sender, _spender) == 0);

        success = controller.approve(msg.sender, _spender, _value);
        if (success) {
            emit Approval(msg.sender, _spender, _value);
        }
        return true;
    }

     
    function increaseApproval(address _spender, uint256 _addedValue) public
    onlyPayloadSize(2)
    returns (bool success) {
        success = controller.increaseApproval(msg.sender, _spender, _addedValue);
        if (success) {
            uint256 newValue = controller.allowance(msg.sender, _spender);
            emit Approval(msg.sender, _spender, newValue);
        }
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public
    onlyPayloadSize(2)
    returns (bool success) {
        success = controller.decreaseApproval(msg.sender, _spender, _subtractedValue);
        if (success) {
            uint newValue = controller.allowance(msg.sender, _spender);
            emit Approval(msg.sender, _spender, newValue);
        }
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return controller.allowance(_owner, _spender);
    }

     
    function burn(uint256 _amount) public
    onlyPayloadSize(1)
    {
        bool success = controller.burn(msg.sender, _amount);
        if (success) {
            emit Burn(msg.sender, _amount);
        }
    }

    function controllerTransfer(address _from, address _to, uint256 _value) public onlyController {
        emit Transfer(_from, _to, _value);
    }

    function controllerApprove(address _owner, address _spender, uint256 _value) public onlyController {
        emit Approval(_owner, _spender, _value);
    }

    function controllerBurn(address _burner, uint256 _value) public onlyController {
        emit Burn(_burner, _value);
    }

    function controllerMint(address _to, uint256 _value) public onlyController {
        emit Mint(_to, _value);
    }

    event Motd(string message);

    function setMotd(string _motd) public onlyOwner {
        motd = _motd;
        emit Motd(_motd);
    }
}

contract Controller is Finalizable {

    Ledger public ledger;
    Token public token;
    address public sale;

    constructor (address _token, address _ledger) public {
        require(_token != 0);
        require(_ledger != 0);

        ledger = Ledger(_ledger);
        token = Token(_token);
    }

    function setToken(address _token) public onlyOwner {
        token = Token(_token);
    }

    function setLedger(address _ledger) public onlyOwner {
        ledger = Ledger(_ledger);
    }

    function setSale(address _sale) public onlyOwner {
        sale = _sale;
    }

    modifier onlyToken() {
        require(msg.sender == address(token));
        _;
    }

    modifier onlyLedger() {
        require(msg.sender == address(ledger));
        _;
    }

    modifier onlySale() {
        require(msg.sender == sale);
        _;
    }

    function totalSupply() public onlyToken view returns (uint256) {
        return ledger.totalSupply();
    }

    function balanceOf(address _a) public onlyToken view returns (uint256) {
        return ledger.balanceOf(_a);
    }

    function allowance(address _owner, address _spender) public onlyToken view returns (uint256) {
        return ledger.allowance(_owner, _spender);
    }

    function transfer(address _from, address _to, uint256 _value) public
    onlyToken
    returns (bool) {
        return ledger.transfer(_from, _to, _value);
    }

    function transferFrom(address _spender, address _from, address _to, uint256 _value) public
    onlyToken
    returns (bool) {
        return ledger.transferFrom(_spender, _from, _to, _value);
    }

    function burn(address _owner, uint256 _amount) public
    onlyToken
    returns (bool) {
        return ledger.burn(_owner, _amount);
    }

    function approve(address _owner, address _spender, uint256 _value) public
    onlyToken
    returns (bool) {
        return ledger.approve(_owner, _spender, _value);
    }

    function increaseApproval(address _owner, address _spender, uint256 _addedValue) public
    onlyToken
    returns (bool) {
        return ledger.increaseApproval(_owner, _spender, _addedValue);
    }

    function decreaseApproval(address _owner, address _spender, uint256 _subtractedValue) public
    onlyToken
    returns (bool) {
        return ledger.decreaseApproval(_owner, _spender, _subtractedValue);
    }

    function proxyMint(address _to, uint256 _value) public onlySale {
        token.controllerMint(_to, _value);
    }

    function proxyTransfer(address _from, address _to, uint256 _value) public onlySale {
        token.controllerTransfer(_from, _to, _value);
    }
}

contract PreSale is Finalizable {
    using SafeMath for uint256;

    Ledger public ledger;
    Controller public controller;

     
    address public wallet;

     
     
     
     
    uint256 public rate;

     
    uint256 public weiRaised;

     
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

     
    constructor(uint256 _rate, address _wallet, address _ledger, address _controller) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_ledger != address(0));
        require(_controller != address(0));

        rate = _rate;
        wallet = _wallet;
        ledger = Ledger(_ledger);
        controller = Controller(_controller);
    }

    function setRate(uint256 _rate) public notFinalized onlyOwner {
        require(_rate > 0);
        rate = _rate;
    }

    function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) public notFinalized payable {

        uint256 weiAmount = msg.value;
        require(_beneficiary != address(0));
        require(weiAmount != 0);

         
        uint256 tokens = weiAmount.mul(rate).div(10 ** 10);

         
        weiRaised = weiRaised.add(weiAmount);

         
        ledger.mint(_beneficiary, tokens);

         
        controller.proxyMint(_beneficiary, tokens);
        controller.proxyTransfer(0, _beneficiary, tokens);

        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens
        );

        _forwardFunds();
    }

    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}

contract Ledger is Finalizable {
    using SafeMath for uint256;

    address public controller;
    address public sale;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    uint256 internal totalSupply_;
    bool public mintFinished = false;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    function setController(address _controller) public onlyOwner notFinalized {
        controller = _controller;
    }

    function setSale(address _sale) public onlyOwner notFinalized {
        sale = _sale;
    }

    modifier onlyController() {
        require(msg.sender == controller);
        _;
    }

    modifier canMint() {
        require(!mintFinished);
        _;
    }

    function finishMint() public onlyOwner canMint {
        mintFinished = true;
        emit MintFinished();
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function transfer(address _from, address _to, uint256 _value) public onlyController returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);

         
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        return true;
    }

     
    function transferFrom(address _spender, address _from, address _to, uint256 _value) public onlyController returns (bool) {
        uint256 allow = allowed[_from][_spender];
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allow);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][_spender] = allow.sub(_value);
        return true;
    }

     
    function approve(address _owner, address _spender, uint256 _value) public onlyController returns (bool) {
         
        if ((_value != 0) && (allowed[_owner][_spender] != 0)) {
            return false;
        }

        allowed[_owner][_spender] = _value;
        return true;
    }

     
    function increaseApproval(address _owner, address _spender, uint256 _addedValue) public onlyController returns (bool) {
        allowed[_owner][_spender] = allowed[_owner][_spender].add(_addedValue);
        return true;
    }

     
    function decreaseApproval(address _owner, address _spender, uint256 _subtractedValue) public onlyController returns (bool) {
        uint256 oldValue = allowed[_owner][_spender];
        if (_subtractedValue > oldValue) {
            allowed[_owner][_spender] = 0;
        } else {
            allowed[_owner][_spender] = oldValue.sub(_subtractedValue);
        }
        return true;
    }

     
    function burn(address _burner, uint256 _amount) public onlyController returns (bool) {
        require(balances[_burner] >= _amount);
         
         

        balances[_burner] = balances[_burner].sub(_amount);
        totalSupply_ = totalSupply_.sub(_amount);
        return true;
    }

     
    function mint(address _to, uint256 _amount) public canMint returns (bool) {
        require(msg.sender == controller || msg.sender == sale || msg.sender == owner);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        return true;
    }
}