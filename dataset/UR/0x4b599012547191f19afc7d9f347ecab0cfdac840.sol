 

pragma solidity ^0.4.25;

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract Operated {
    mapping(address => bool) private _ops;

    event OperatorChanged(
        address indexed operator,
        bool active
    );

     
    constructor() internal {
        _ops[msg.sender] = true;
        emit OperatorChanged(msg.sender, true);
    }

     
    modifier onlyOps() {
        require(isOps(), "only operations accounts are allowed to call this function");
        _;
    }

     
    function isOps() public view returns(bool) {
        return _ops[msg.sender];
    }

     
    function setOps(address _account, bool _active) public onlyOps {
        _ops[_account] = _active;
        emit OperatorChanged(_account, _active);
    }
}

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns(address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);  
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
contract WhiskyToken is IERC20, Ownable, Operated {
    using SafeMath for uint256;
    using SafeMath for uint64;

     
    string public name = "Whisky Token";
    string public symbol = "WHY";
    uint8 public decimals = 18;
    uint256 public initialSupply = 28100000 * (10 ** uint256(decimals));
    uint256 public totalSupply;

     
    address public crowdSaleContract;

     
    uint64 public assetValue;

     
    uint64 public feeCharge;

     
    bool public freezeTransfer;

     
    bool private tokenAvailable;

     
    uint64 private constant feeChargeMax = 20;

     
    address private feeReceiver;

     
    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) internal allowed;
    mapping(address => bool) public frozenAccount;

     
    event Fee(address indexed payer, uint256 fee);
    event FeeCharge(uint64 oldValue, uint64 newValue);
    event AssetValue(uint64 oldValue, uint64 newValue);
    event Burn(address indexed burner, uint256 value);
    event FrozenFunds(address indexed target, bool frozen);
    event FreezeTransfer(bool frozen);

     
    constructor(address _tokenOwner) public {
        transferOwnership(_tokenOwner);
        setOps(_tokenOwner, true);
        crowdSaleContract = msg.sender;
        feeReceiver = _tokenOwner;
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
        assetValue = 0;
        feeCharge = 15;
        freezeTransfer = true;
        tokenAvailable = true;
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        if (!tokenAvailable) {
            return 0;
        }
        return balances[_owner];
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "zero address is not allowed");
        require(_value >= 1000, "must transfer more than 1000 sip");
        require(!freezeTransfer || isOps(), "all transfers are currently frozen");
        require(!frozenAccount[_from], "sender address is frozen");
        require(!frozenAccount[_to], "receiver address is frozen");

        uint256 transferValue = _value;
        if (msg.sender != owner() && msg.sender != crowdSaleContract) {
            uint256 fee = _value.div(1000).mul(feeCharge);
            transferValue = _value.sub(fee);
            balances[feeReceiver] = balances[feeReceiver].add(fee);
            emit Fee(msg.sender, fee);
            emit Transfer(_from, feeReceiver, fee);
        }

         
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(transferValue);
        if (tokenAvailable) {
            emit Transfer(_from, _to, transferValue);
        }
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender], "requesting more token than allowed");

        _transfer(_from, _to, _value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(!freezeTransfer || isOps(), "all transfers are currently frozen");
        require(_spender != address(0), "zero address is not allowed");
        require(_value >= 1000, "must approve more than 1000 sip");

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        require(!freezeTransfer || isOps(), "all transfers are currently frozen");
        require(_spender != address(0), "zero address is not allowed");
        require(_addedValue >= 1000, "must approve more than 1000 sip");
        
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        require(!freezeTransfer || isOps(), "all transfers are currently frozen");
        require(_spender != address(0), "zero address is not allowed");
        require(_subtractedValue >= 1000, "must approve more than 1000 sip");

        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    } 

     
    function burn(uint256 _value) public {
        require(!freezeTransfer || isOps(), "all transfers are currently frozen");
        require(_value <= balances[msg.sender], "address has not enough token to burn");
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }

     
    function setAssetValue(uint64 _value) public onlyOwner {
        uint64 oldValue = assetValue;
        assetValue = _value;
        emit AssetValue(oldValue, _value);
    }

     
    function setFeeCharge(uint64 _value) public onlyOwner {
        require(_value <= feeChargeMax, "can not increase fee charge over it's limit");
        uint64 oldValue = feeCharge;
        feeCharge = _value;
        emit FeeCharge(oldValue, _value);
    }


     
    function freezeAccount(address _target, bool _freeze) public onlyOwner {
        require(_target != address(0), "zero address is not allowed");

        frozenAccount[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }

     
    function setFreezeTransfer(bool _freeze) public onlyOwner {
        freezeTransfer = _freeze;
        emit FreezeTransfer(_freeze);
    }

     
    function setFeeReceiver(address _feeReceiver) public onlyOwner {
        require(_feeReceiver != address(0), "zero address is not allowed");
        feeReceiver = _feeReceiver;
    }

     
    function setTokenAvailable(bool _available) public onlyOwner {
        tokenAvailable = _available;
    }
}