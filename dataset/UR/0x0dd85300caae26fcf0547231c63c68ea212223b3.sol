 

pragma solidity ^0.4.16;

 
library SafeMath {

     
    function sub(uint256 _subtrahend, uint256 _subtractor) internal returns (uint256) {

         
        if (_subtractor > _subtrahend)
            return 0;

        return _subtrahend - _subtractor;
    }
}

 
contract Owned {

     
    address owner;

     
    function Owned() {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

 
interface ERC20 {
    
 
    
     
    function totalSupply() constant returns (uint256);

     
    function balanceOf(address _owner) constant returns (uint256);

     
    function transfer(address _to, uint256 _value) returns (bool);

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool);

     
    function approve(address _spender, uint256 _value) returns (bool);

     
    function allowance(address _owner, address _spender) constant returns (uint256);

 

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract Token is ERC20 {

     
    string public name;
     
    string public symbol;

     
    uint8 public decimals;

     
    uint256 public totalSupply;

     
    address[] public holders;
     
    mapping(address => uint256) index;

     
    mapping(address => uint256) balances;
     
    mapping(address => mapping(address => uint256)) allowances;

     
    function Token(string _name, string _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

     
    function balanceOf(address _owner) constant returns (uint256) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) returns (bool) {

         
        if (balances[msg.sender] >= _value) {

             
            balances[msg.sender] -= _value;
            balances[_to] += _value;

             
            if (_value > 0 && index[_to] == 0) {
                index[_to] = holders.push(_to);
            }

            Transfer(msg.sender, _to, _value);

            return true;
        }

        return false;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {

         
        if (allowances[_from][msg.sender] >= _value &&
            balances[_from] >= _value ) {

             
            allowances[_from][msg.sender] -= _value;

             
            balances[_from] -= _value;
            balances[_to] += _value;

             
            if (_value > 0 && index[_to] == 0) {
                index[_to] = holders.push(_to);
            }

            Transfer(_from, _to, _value);

            return true;
        }

        return false;
    }

     
    function approve(address _spender, uint256 _value) returns (bool) {
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowances[_owner][_spender];
    }

     
    function unapprove(address _spender) {
        allowances[msg.sender][_spender] = 0;
    }

     
    function totalSupply() constant returns (uint256) {
        return totalSupply;
    }

     
    function holderCount() constant returns (uint256) {
        return holders.length;
    }
}


 
contract Cat is Token("Cat's Token", "CTS", 3), Owned {

     
    function emit(uint256 _value) onlyOwner returns (bool) {

         
        assert(totalSupply + _value >= totalSupply);

         
        totalSupply += _value;
        balances[owner] += _value;

        return true;
    }
}

 
contract CatICO {

    using SafeMath for uint256;

     
    uint256 public start = 1505970000;
     
    uint256 public end = 1511240400;

     
    address public wallet;

     
    Cat public cat;

    struct Stage {
         
        uint256 price;
         
        uint256 cap;
    }

     
    Stage simulator = Stage(0.01 ether / 1000, 900000000);
     
    Stage online = Stage(0.0125 ether / 1000, 2500000000);
     
    Stage sequels = Stage(0.016 ether / 1000, 3750000000);

     
    function CatICO(address _wallet) {
        cat = new Cat();
        wallet = _wallet;
    }

     
    function() payable onlyRunning {

        var supplied = cat.totalSupply();
        var tokens = tokenEmission(msg.value, supplied);

         
        require(tokens > 0);

         
        bool success = cat.emit(tokens);
        assert(success);

         
        success = cat.transfer(msg.sender, tokens);
        assert(success);

         
        wallet.transfer(msg.value);
    }

     
    function tokenEmission(uint256 _value, uint256 _supplied) private returns (uint256) {

        uint256 emission = 0;
        uint256 stageTokens;

        Stage[3] memory stages = [simulator, online, sequels];

         
        for (uint8 i = 0; i < 2; i++) {
            (stageTokens, _value, _supplied) = stageEmission(_value, _supplied, stages[i]);
            emission += stageTokens;
        }

         
        emission += _value / stages[2].price;

        return emission;
    }

     
    function stageEmission(uint256 _value, uint256 _supplied, Stage _stage)
        private
        returns (uint256 tokens, uint256 valueRemainder, uint256 newSupply)
    {

         
        if (_supplied >= _stage.cap) {
            return (0, _value, _supplied);
        }

         
        if (_value < _stage.price) {
            return (0, _value, _supplied);
        }

         
        var _tokens = _value / _stage.price;

         
        var remainder = _stage.cap.sub(_supplied);
        _tokens = _tokens > remainder ? remainder : _tokens;

         
        var _valueRemainder = _value.sub(_tokens * _stage.price);
        var _newSupply = _supplied + _tokens;

        return (_tokens, _valueRemainder, _newSupply);
    }

     
    function isRunning() constant returns (bool) {

         
        if (now < start) return false;
        if (now >= end) return false;

         
        if (cat.totalSupply() >= sequels.cap) return false;

        return true;
    }

     
    modifier onlyRunning() {

         
        require(now >= start);
        require(now < end);

         
        require(cat.totalSupply() < sequels.cap);

        _;
    }
}