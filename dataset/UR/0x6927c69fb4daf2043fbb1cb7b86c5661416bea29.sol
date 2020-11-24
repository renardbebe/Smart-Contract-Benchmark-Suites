 

pragma solidity ^0.4.21;

 
 
contract SafeMath {
    function mulsm(uint256 a, uint256 b) internal pure returns (uint256) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function divsm(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function subsm(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function addsm(uint256 a, uint256 b) internal pure returns (uint256) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function powsm(uint256 a, uint256 b) internal pure returns (uint256) {
        uint c = a ** b;
        assert(c >= a);
        return c;
    }
}

contract Owned {

    event NewOwner(address old, address current);
    event NewPotentialOwner(address old, address potential);

    address public owner = msg.sender;
    address public potentialOwner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPotentialOwner {
        require(msg.sender == potentialOwner);
        _;
    }

    function setOwner(address _new) public onlyOwner {
        emit NewPotentialOwner(owner, _new);
        potentialOwner = _new;
    }

    function confirmOwnership() public onlyPotentialOwner {
        emit NewOwner(owner, potentialOwner);
        owner = potentialOwner;
        potentialOwner = 0;
    }
}

contract Managed is Owned {

    event NewManager(address owner, address manager);

    mapping (address => bool) public manager;

    modifier onlyManager() {
        require(manager[msg.sender] == true || msg.sender == owner);
        _;
    }

    function setManager(address _manager) public onlyOwner {
        emit NewManager(owner, _manager);
        manager[_manager] = true;
    }

    function superManager(address _manager) internal {
        emit NewManager(owner, _manager);
        manager[_manager] = true;
    }

    function delManager(address _manager) public onlyOwner {
        emit NewManager(owner, _manager);
        manager[_manager] = false;
    }
}

 
contract ERC20 {

    function name() constant public returns (string);
    function symbol() constant public returns (string);
    function decimals() constant public returns (uint8);
    function totalSupply() constant public returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is SafeMath, ERC20  {

    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

     
    function name() public view returns (string) {
        return name;
    }

     
    function symbol() public view returns (string) {
        return symbol;
    }

     
    function decimals() public view returns (uint8) {
        return decimals;
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }


     
     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
     
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(this));  
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
      return allowed[_owner][_spender];
    }
}

 
contract ERC827 {

  function approve( address _spender, uint256 _value, bytes _data ) public returns (bool);
  function transfer( address _to, uint256 _value, bytes _data ) public returns (bool);
  function transferFrom( address _from, address _to, uint256 _value, bytes _data ) public returns (bool);

}

 
contract ERC827Token is ERC827, StandardToken {

   
  function approve(address _spender, uint256 _value, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.approve(_spender, _value);

    require(_spender.call(_data));

    return true;
  }

  function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transfer(_to, _value);

    require(_to.call(_data));
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transferFrom(_from, _to, _value);

    require(_to.call(_data));
    return true;
  }
}

contract MintableToken is ERC827Token {

        uint256 constant maxSupply = 1e30;  
        bool internal mintable = true;

        modifier isMintable() {
            require(mintable);
            _;
        }

        function stopMint() internal {
            mintable = false;
        }

         
        event Issuance(uint256 _amount);
         
        event Destruction(uint256 _amount);

         
        function issue(address _to, uint256 _amount) internal {
            assert(totalSupply + _amount <= maxSupply);  
            totalSupply +=  _amount;
            balances[_to] += _amount;
            emit Issuance(_amount);
            emit Transfer(this, _to, _amount);
        }

         
         
}

contract PaymentManager is MintableToken, Owned {

    uint256 public receivedWais;
    uint256 internal _price;
    bool internal paused = false;

    modifier isSuspended() {
        require(!paused);
        _;
    }

   function setPrice(uint256 _value) public onlyOwner returns (bool) {
        _price = _value;
        return true;
    }

    function watchPrice() public view returns (uint256 price) {
        return _price;
    }

    function rateSystem(address _to, uint256 _value) internal returns (bool) {
        uint256 _amount;
        if(_value >= (1 ether / 1000) && _value <= 1 ether) {
            _amount = _value * _price;
        } else
        if(_value >= 1 ether) {
             _amount = divsm(powsm(_value, 2), 1 ether) * _price;
        }
        issue(_to, _amount);
        if(paused == false) {
            if(totalSupply > 1 * 10e9 * 1 * 1 ether) paused = true;  
        }
        return true;
    }

     
    function transferEther(address _to, uint256 _value) public onlyOwner {
        _to.transfer(_value);
    }
}

contract InvestBox is PaymentManager, Managed {

     
    event BonusChanged(uint256 _amount);
     
    event Invested(address _from, uint256 _value);
     
    event InvestClosed(address _who, uint256 _value);
     
    event Counted(address _sender, uint256 _intervals);

    uint256 constant _day = 24 * 60 * 60 * 1 seconds;

    bytes5 internal _td = bytes5("day");
    bytes5 internal _tw = bytes5("week");
    bytes5 internal _tm = bytes5("month");
    bytes5 internal _ty = bytes5("year");

    uint256 internal _creation;
    uint256 internal _1sty;
    uint256 internal _2ndy;

    uint256 internal min_invest;
    uint256 internal max_invest;

    struct invest {
        bool exists;
        uint256 balance;
        uint256 created;  
        uint256 closed;   
    }

    mapping (address => mapping (bytes5 => invest)) public investInfo;

    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

     
    function stringToBytes5(string _data) public pure returns (bytes5) {
        return bytes5(stringToBytes32(_data));
    }

    struct intervalBytecodes {
        string day;
        string week;
        string month;
        string year;
    }

    intervalBytecodes public IntervalBytecodes;

     
    function setMinMaxInvestValue(uint256 _min, uint256 _max) public onlyOwner {
        min_invest = _min * 10 ** uint256(decimals);
        max_invest = _max * 10 ** uint256(decimals);
    }

     
    function countPeriod(address _investor, bytes5 _t) internal view returns (uint256) {
        uint256 _period;
        uint256 _now = now;  
        if (_t == _td) _period = 1 * _day;
        if (_t == _tw) _period = 7 * _day;
        if (_t == _tm) _period = 31 * _day;
        if (_t == _ty) _period = 365 * _day;
        invest storage inv = investInfo[_investor][_t];
        if (_now - inv.created < _period) return 0;
        return (_now - inv.created)/_period;  
    }

     
    function loopFor(uint256 _condition, uint256 _data, uint256 _bonus) internal pure returns (uint256 r) {
        assembly {
            for { let i := 0 } lt(i, _condition) { i := add(i, 1) } {
              let m := mul(_data, _bonus)
              let d := div(m, 100000)
              _data := add(_data, d)
            }
            r := _data
        }
    }

     
    function rewardController(address _investor, bytes5 _type) internal view returns (uint256) {

        uint256 _period;
        uint256 _balance;
        uint256 _created;

        invest storage inv = investInfo[msg.sender][_type];

        _period = countPeriod(_investor, _type);
        _balance = inv.balance;
        _created = inv.created;

        uint256 full_steps;
        uint256 last_step;
        uint256 _d;

        if(_type == _td) _d = 365;
        if(_type == _tw) _d = 54;
        if(_type == _tm) _d = 12;
        if(_type == _ty) _d = 1;

        full_steps = _period/_d;
        last_step = _period - (full_steps * _d);

        for(uint256 i=0; i<full_steps; i++) {  
            _balance = compaundIntrest(_d, _type, _balance, _created);
            _created += 1 years;
        }

        if(last_step > 0) _balance = compaundIntrest(last_step, _type, _balance, _created);

        return _balance;
    }

     
    function compaundIntrest(uint256 _period, bytes5 _type, uint256 _balance, uint256 _created) internal view returns (uint256) {
        uint256 full_steps;
        uint256 last_step;
        uint256 _d = 100;  
        uint256 _bonus = bonusSystem(_type, _created);

        if (_period>_d) {
            full_steps = _period/_d;
            last_step = _period - (full_steps * _d);
            for(uint256 i=0; i<full_steps; i++) {
                _balance = loopFor(_d, _balance, _bonus);
            }
            if(last_step > 0) _balance = loopFor(last_step, _balance, _bonus);
        } else
        if (_period<=_d) {
            _balance = loopFor(_period, _balance, _bonus);
        }
        return _balance;
    }

     
    function bonusSystem(bytes5 _t, uint256 _now) internal view returns (uint256) {
        uint256 _b;
        if (_t == _td) {
            if (_now < _1sty) {
                _b = 600;  
            } else
            if (_now >= _1sty && _now < _2ndy) {
                _b = 300;  
            } else
            if (_now >= _2ndy) {
                _b = 30;  
            }
        }
        if (_t == _tw) {
            if (_now < _1sty) {
                _b = 5370;  
            } else
            if (_now >= _1sty && _now < _2ndy) {
                _b = 2650;  
            } else
            if (_now >= _2ndy) {
                _b = 270;  
            }
        }
        if (_t == _tm) {
            if (_now < _1sty) {
                _b = 30000;  
            } else
            if (_now >= _1sty && _now < _2ndy) {

                _b = 14050;  
            } else
            if (_now >= _2ndy) {
                _b = 1340;  
            }
        }
        if (_t == _ty) {
            if (_now < _1sty) {
                _b = 3678000;  
            } else
            if (_now >= _1sty && _now < _2ndy) {
                _b = 517470;  
            } else
            if (_now >= _2ndy) {
                _b = 20020;  
            }
        }
        return _b;
    }

     
    function makeInvest(uint256 _value, bytes5 _interval) internal isMintable {
        require(min_invest <= _value && _value <= max_invest);  
        assert(balances[msg.sender] >= _value && balances[this] + _value > balances[this]);
        balances[msg.sender] -= _value;
        balances[this] += _value;
        invest storage inv = investInfo[msg.sender][_interval];
        if (inv.exists == false) {  
            inv.balance = _value;
            inv.created = now;
            inv.closed = 0;
            emit Transfer(msg.sender, this, _value);
        } else
        if (inv.exists == true) {
            uint256 rew = rewardController(msg.sender, _interval);
            inv.balance = _value + rew;
            inv.closed = 0;
            emit Transfer(0x0, this, rew);  
        }
        inv.exists = true;
        emit Invested(msg.sender, _value);
        if(totalSupply > maxSupply) stopMint();  
    }

    function makeDailyInvest(uint256 _value) public {
        makeInvest(_value * 10 ** uint256(decimals), _td);
    }

    function makeWeeklyInvest(uint256 _value) public {
        makeInvest(_value * 10 ** uint256(decimals), _tw);
    }

    function makeMonthlyInvest(uint256 _value) public {
        makeInvest(_value * 10 ** uint256(decimals), _tm);
    }

    function makeAnnualInvest(uint256 _value) public {
        makeInvest(_value * 10 ** uint256(decimals), _ty);
    }

     
    function closeInvest(bytes5 _interval) internal {
        uint256 _intrest;
        address _to = msg.sender;
        uint256 _period = countPeriod(_to, _interval);
        invest storage inv = investInfo[_to][_interval];
        uint256 _value = inv.balance;
        if (_period == 0) {
            balances[this] -= _value;
            balances[_to] += _value;
            emit Transfer(this, _to, _value);  
            emit InvestClosed(_to, _value);
        } else
        if (_period > 0) {
             
            balances[this] -= _value;
            totalSupply -= _value;
            emit Transfer(this, 0x0, _value);
            emit Destruction(_value);
             
            _intrest = rewardController(_to, _interval);
            if(manager[msg.sender]) {
                _intrest = mulsm(divsm(_intrest, 100), 105);  
            }
            issue(_to, _intrest);  
            emit InvestClosed(_to, _intrest);
        }
        inv.exists = false;  
        inv.balance = 0;
        inv.closed = now;
    }

    function closeDailyInvest() public {
        closeInvest(_td);
    }

    function closeWeeklyInvest() public {
        closeInvest(_tw);
    }

    function closeMonthlyInvest() public {
        closeInvest(_tm);
    }

    function closeAnnualInvest() public {
        closeInvest(_ty);
    }

     
    function isFullInvest(address _ms, bytes5 _t) internal returns (uint256) {
        uint256 res = countPeriod(_ms, _t);
        emit Counted(msg.sender, res);
        return res;
    }

    function countDays() public returns (uint256) {
        return isFullInvest(msg.sender, _td);
    }

    function countWeeks() public returns (uint256) {
        return isFullInvest(msg.sender, _tw);
    }

    function countMonths() public returns (uint256) {
        return isFullInvest(msg.sender, _tm);
    }

    function countYears() public returns (uint256) {
        return isFullInvest(msg.sender, _ty);
    }
}

contract EthereumRisen is InvestBox {

     
    address public devWallet = address(0x00FBB38c017843DFa86a97c31fECaCFF0a092F6F);
    uint256 constant public devReward = 100000 * 1e18;  

     
    address public bountyWallet = address(0x00Ed07D0170B1c5F3EeDe1fC7261719e04b15ecD);
    uint256 constant public bountyReward = 50000 * 1e18;  

     
    address public airdropWallet = address(0x000DdB5A903d15b2F7f7300f672d2EB9bF882143);
    uint256 constant public airdropReward = 99900 * 1e18;  

    bool internal _airdrop_status = false;
    uint256 internal _paySize;

     
    function startAirdrop() public onlyOwner {
        if(address(this).balance < 5 ether && _airdrop_status == true) revert();
        issue(airdropWallet, airdropReward);
        _paySize = 999 * 1e16;  
        _airdrop_status = true;
    }

     
    function airdropper(address [] _holders, uint256 _pay_size) public onlyManager {
        if(_pay_size == 0) _pay_size = _paySize;  
        if(_pay_size < 1 * 1e18) revert();  
        uint256 count = _holders.length;
        require(count <= 200);
        assert(_pay_size * count <= balanceOf(msg.sender));
        for (uint256 i = 0; i < count; i++) {
            transfer(_holders [i], _pay_size);
        }
    }

    function EthereumRisen() public {

        name = "Ethereum Risen";
        symbol = "ETR";
        decimals = 18;
        totalSupply = 0;
        _creation = now;
        _1sty = now + 365 * 1 days;
        _2ndy = now + 2 * 365 * 1 days;

        PaymentManager.setPrice(10000);
        Managed.setManager(bountyWallet);
        InvestBox.IntervalBytecodes = intervalBytecodes(
            "0x6461790000",
            "0x7765656b00",
            "0x6d6f6e7468",
            "0x7965617200"
        );
        InvestBox.setMinMaxInvestValue(1000,100000000);
        issue(bountyWallet, bountyReward);
        issue(devWallet, devReward);
    }

    function() public payable isSuspended {
        require(msg.value >= (1 ether / 100));
        if(msg.value >= 5 ether) superManager(msg.sender);  
        rateSystem(msg.sender, msg.value);
        receivedWais = addsm(receivedWais, msg.value);  
    }
}