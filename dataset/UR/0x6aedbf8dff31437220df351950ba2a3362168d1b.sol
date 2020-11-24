 

pragma solidity ^0.4.13;

contract ERC20Interface {

     
    function totalSupply()
    public constant returns (uint256 _totalSupply);

     
    function balanceOf(address _owner)
    public constant returns (uint256 balance);

     
    function transfer(address _to, uint256 _value)
    public returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool success);

     
    function approve(address _spender, uint256 _value)
    public returns (bool success);

     
    function allowance(address _owner, address _spender)
    public constant returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract DGS is ERC20Interface {

    string public constant NAME = "Dragonglass";
    string public constant SYMBOL = "DGS";
    uint public constant DECIMALS = 8;

    uint256 supply = 0;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    mapping (address => uint) allowedToMine;

    address public allocationAddressICO;

    uint256 public mineableSupply = 0;

    address founder;


    uint public constant DECIMAL_INDEX = 10**DECIMALS;

     
     
    uint private constant MINING_PERCENTAGE = 25892541;
    uint private constant STAKE_PERCENTAGE = 5 * DECIMAL_INDEX / 100;

    function DGS (uint256 _initial,
        address _founder) public {
            supply = _initial;
            mineableSupply = supply * 10;
            founder = _founder;
    }

    modifier onlyFounder {
        require(msg.sender == founder);
        _;
    }

    function totalSupply()
    public constant returns (uint256 _totalSupply) {
        _totalSupply = supply;
    }

    function balanceOf(address _owner)
    public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function getAllowedToMine(address _owner)
    public constant returns (uint _allowedToMine) {
        return allowedToMine[_owner];
    }

     
    function getMineableSupply()
    public constant returns (uint256 _mineableSupply){
        _mineableSupply = mineableSupply;
    }

    function transfer(address _to, uint256 _value)
    public returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        mine(msg.sender, _to, _value);
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(_to != address(0) && balances[_from] >= _value
            && allowance >= _value);
            balances[_from] -= _value;
            mine(_from, _to, _value);
            balances[_to] += _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
    }

    function approve(address _spender, uint256 _value)
    public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
    public constant returns (uint256 remaining){
        return  allowed[_owner][_spender];
    }

    function setIcoAddress(address _icoAddress) public onlyFounder() {
        require(allocationAddressICO == address(0));
        allocationAddressICO = _icoAddress;
        balances[allocationAddressICO] = totalSupply();
    }

    function calculateMinedCoinsForTX(uint stake, uint _value)
    public pure returns (uint _minedAmount) {

        var _max = SafeMath.max256(_value, stake);
        var _min = SafeMath.min256(_value, stake);

        uint factor = _min * DECIMAL_INDEX /_max;

        if(_value > stake)
            factor += factor * STAKE_PERCENTAGE / DECIMAL_INDEX;
        if(factor > DECIMAL_INDEX)
            factor = DECIMAL_INDEX;

        var totalStake = stake + _value;
        var factorInCoins = totalStake * factor / DECIMAL_INDEX;

        _minedAmount = factorInCoins *  MINING_PERCENTAGE / DECIMAL_INDEX;
    }

    function mine
    (address _sender, address _receiver, uint _transactionValue) private {
        if(_sender == allocationAddressICO) {
             
            allowedToMine[_receiver] += _transactionValue * 10;
        } else {
            doMining(_sender, _transactionValue);
        }
    }

    function doMining(address _miner, uint _transactionValue)
    private {
        uint _minedAmount = calculateMinedCoinsForTX(balanceOf(_miner), _transactionValue);
        if(allowedToMine[_miner] <= _minedAmount) {
            _minedAmount = allowedToMine[_miner];
            allowedToMine[_miner] = 0;
        } else {
            allowedToMine[_miner] -= _minedAmount;
        }
        balances[_miner] += _minedAmount;
        supply += _minedAmount;
        mineableSupply -= _minedAmount;
        Mined(_miner, _minedAmount);
    }

    event Mined(address indexed _miner, uint256 _minedAmount);
}

library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    uint c = a / b;
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
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