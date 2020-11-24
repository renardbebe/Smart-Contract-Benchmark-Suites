 

pragma solidity ^0.4.13;

contract GCCExchangeAccessControl {
    address public owner;
    address public operator;

    modifier onlyOwner() {require(msg.sender == owner);_;}
    modifier onlyOperator() {require(msg.sender == operator);_;}
    modifier onlyOwnerOrOperator() {require(msg.sender == owner || msg.sender == operator);_;}

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    function transferOperator(address newOperator) public onlyOwner {
        require(newOperator != address(0));
        operator = newOperator;
    }

    function withdrawBalance(address _recipient, uint256 amount) external onlyOwnerOrOperator {
        require(amount > 0);
        require(amount <= this.balance);
        require(_recipient != address(0));
        _recipient.transfer(amount);
    }

    function depositBalance() external payable {}
}

contract GCCExchangePausable is GCCExchangeAccessControl {
    bool public paused;

    modifier whenPaused() {require(paused);_;}
    modifier whenNotPaused() {require(!paused);_;}

    function pause() public onlyOwnerOrOperator whenNotPaused {
        paused = true;
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
    }
}

contract GCCExchangeCoinOperation is GCCExchangePausable {
    GoCryptobotCoinERC827 internal coin;

    function setCoinContract(address _address) external onlyOwnerOrOperator {
        GoCryptobotCoinERC827 _contract = GoCryptobotCoinERC827(_address);
         
        coin = _contract;
    }

    function unpause() public {
        require(coin != address(0));
        super.unpause();
    }

    function operate(bytes data) external onlyOwnerOrOperator {
        require(coin.call(data));
    }
}

contract GCCExchangeCore is GCCExchangeCoinOperation {
    uint8 constant FEE_RATE = 5;
    uint256 public exchangeRate;
    address internal coinStorage;

    event ExchangeRateChange(uint256 from, uint256 to);
    event Withdrawal(address claimant, uint256 mgccAmount, uint256 weiAmount);

    function GCCExchangeCore() public {
        coinStorage = this;
         
        exchangeRate = 1000000000000 wei;

        paused = true;

        owner = msg.sender;
        operator = msg.sender;
    }

    function setCoinStorage(address _address) public onlyOwnerOrOperator {
        coinStorage = _address;
    }

    function setExchangeRate(uint256 rate) external onlyOwnerOrOperator {
        ExchangeRateChange(exchangeRate, rate);
        exchangeRate = rate;
    }

    function withdraw(address _claimant, uint256 _mgcc) public whenNotPaused {
         
        require(coin.allowance(_claimant, this) >= _mgcc);
        require(coin.transferFrom(_claimant, coinStorage, _mgcc));
        uint256 exchange = (_convertToWei(_mgcc) / 100) * (100 - FEE_RATE);
        _claimant.transfer(exchange);
        Withdrawal(_claimant, _mgcc, exchange);
    }

    function _convertToWei(uint256 mgcc) internal view returns (uint256) {
        return mgcc * exchangeRate;
    }

    function () external payable {
        revert();
    }
}

contract GoCryptobotCoinERC20 {
    using SafeMath for uint256;

    string public constant name = "GoCryptobotCoin";
    string public constant symbol = "GCC";
    uint8 public constant decimals = 3;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 totalSupply_;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract GoCryptobotCoinERC827 is GoCryptobotCoinERC20 {
     
    function approve( address _spender, uint256 _value, bytes _data ) public returns (bool) {
        require(_spender != address(this));
        super.approve(_spender, _value);
        require(_spender.call(_data));
        return true;
    }

     
    function transfer( address _to, uint256 _value, bytes _data ) public returns (bool) {
        require(_to != address(this));
        super.transfer(_to, _value);
        require(_to.call(_data));
        return true;
    }

     
    function transferFrom( address _from, address _to, uint256 _value, bytes _data ) public returns (bool) {
        require(_to != address(this));
        super.transferFrom(_from, _to, _value);
        require(_to.call(_data));
        return true;
    }

     
    function increaseApproval(address _spender, uint _addedValue, bytes _data) public returns (bool) {
        require(_spender != address(this));
        super.increaseApproval(_spender, _addedValue);
        require(_spender.call(_data));
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue, bytes _data) public returns (bool) {
        require(_spender != address(this));
        super.decreaseApproval(_spender, _subtractedValue);
        require(_spender.call(_data));
        return true;
    }
}

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