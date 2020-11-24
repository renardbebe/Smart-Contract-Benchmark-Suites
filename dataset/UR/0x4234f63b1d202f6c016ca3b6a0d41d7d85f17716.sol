 

pragma solidity 0.4.18;

 
contract ReceivingContract {

     
    function tokenFallback(address _from, uint _value) public;

}

 
library SafeMath {

     
    function mul(uint _a, uint _b)
        internal
        pure
        returns (uint)
    {
        if (_a == 0) {
            return 0;
        }
    
        uint c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

     
    function div(uint _a, uint _b)
        internal
        pure
        returns (uint)
    {
         
        uint c = _a / _b;
        return c;
    }

     
    function sub(uint _a, uint _b)
        internal
        pure
        returns (uint)
    {
        assert(_b <= _a);
        return _a - _b;
    }

     
    function add(uint _a, uint _b)
        internal
        pure
        returns (uint)
    {
        uint c = _a + _b;
        assert(c >= _a);
        return c;
    }

}

 
contract Ownable {

    address public owner;

     
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function Ownable() public {
        owner = msg.sender;
        OwnershipTransferred(0, owner);
    }

     
    function transferOwnership(address _newOwner)
        public
        onlyOwner
    {
        require(_newOwner != 0);

        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

}

 
contract StandardToken is Ownable {

    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) internal allowed;

     
    event ChangeTokenInformation(string name, string symbol);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

     
    function changeTokenInformation(string _name, string _symbol)
        public
        onlyOwner
    {
        name = _name;
        symbol = _symbol;
        ChangeTokenInformation(_name, _symbol);
    }

     
    function transfer(address _to, uint _value)
        public
        returns (bool)
    {
        require(_to != 0);
        require(_value > 0);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint _value)
        public
        returns (bool)
    {
        require(_to != 0);
        require(_value > 0);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint _value)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function increaseApproval(address _spender, uint _addedValue)
        public
        returns (bool)
    {
        require(_addedValue > 0);

        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue)
        public
        returns (bool)
    {
        require(_subtractedValue > 0);

        uint oldValue = allowed[msg.sender][_spender];

        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;

        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint)
    {
        return allowed[_owner][_spender];
    }

}

 
contract PausableToken is StandardToken {

    bool public isTradable = true;

     
    event FreezeTransfer();
    event UnfreezeTransfer();

    modifier canTransfer() {
        require(isTradable);
        _;
    }

     
    function freezeTransfer()
        public
        onlyOwner
    {
        isTradable = false;
        FreezeTransfer();
    }

     
    function unfreezeTransfer()
        public
        onlyOwner
    {
        isTradable = true;
        UnfreezeTransfer();
    }

     
    function transfer(address _to, uint _value)
        public
        canTransfer
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value)
        public
        canTransfer
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }

     
    function approve(address _spender, uint _value)
        public
        canTransfer
        returns (bool)
    {
        return super.approve(_spender, _value);
    }

     
    function increaseApproval(address _spender, uint _addedValue)
        public
        canTransfer
        returns (bool)
    {
        return super.increaseApproval(_spender, _addedValue);
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue)
        public
        canTransfer
        returns (bool)
    {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

}

 
contract UpgradeAgent {

    bool public isUpgradeAgent = true;

    function upgradeFrom(address _from, uint _value) public;

}

 
contract UpgradableToken is StandardToken {

    address public upgradeMaster;

     
    UpgradeAgent public upgradeAgent;

    bool public isUpgradable = false;

     
    uint public totalUpgraded;

     
    event ChangeUpgradeMaster(address newMaster);
    event ChangeUpgradeAgent(address newAgent);
    event FreezeUpgrade();
    event UnfreezeUpgrade();
    event Upgrade(address indexed from, address indexed to, uint value);

    modifier onlyUpgradeMaster() {
        require(msg.sender == upgradeMaster);
        _;
    }

    modifier canUpgrade() {
        require(isUpgradable);
        _;
    }

     
    function changeUpgradeMaster(address _newMaster)
        public
        onlyOwner
    {
        require(_newMaster != 0);

        upgradeMaster = _newMaster;
        ChangeUpgradeMaster(_newMaster);
    }

     
    function changeUpgradeAgent(address _newAgent)
        public
        onlyOwner
    {
        require(totalUpgraded == 0);

        upgradeAgent = UpgradeAgent(_newAgent);

        require(upgradeAgent.isUpgradeAgent());

        ChangeUpgradeAgent(_newAgent);
    }

     
    function freezeUpgrade()
        public
        onlyOwner
    {
        isUpgradable = false;
        FreezeUpgrade();
    }

     
    function unfreezeUpgrade()
        public
        onlyOwner
    {
        isUpgradable = true;
        UnfreezeUpgrade();
    }

     
    function upgrade()
        public
        canUpgrade
    {
        uint amount = balanceOf[msg.sender];

        require(amount > 0);

        processUpgrade(msg.sender, amount);
    }

     
    function forceUpgrade(address[] _holders)
        public
        onlyUpgradeMaster
        canUpgrade
    {
        uint amount;

        for (uint i = 0; i < _holders.length; i++) {
            amount = balanceOf[_holders[i]];

            if (amount == 0) {
                continue;
            }

            processUpgrade(_holders[i], amount);
        }
    }

    function processUpgrade(address _holder, uint _amount)
        private
    {
        balanceOf[_holder] = balanceOf[_holder].sub(_amount);

         
        totalSupply = totalSupply.sub(_amount);
        totalUpgraded = totalUpgraded.add(_amount);

         
        upgradeAgent.upgradeFrom(_holder, _amount);
        Upgrade(_holder, upgradeAgent, _amount);
    }

}

 
contract QNTU is UpgradableToken, PausableToken {

     
    function QNTU(address[] _wallets, uint[] _amount)
        public
    {
        require(_wallets.length == _amount.length);

        symbol = "QNTU";
        name = "QNTU Token";
        decimals = 18;

        uint num = 0;
        uint length = _wallets.length;
        uint multiplier = 10 ** uint(decimals);

        for (uint i = 0; i < length; i++) {
            num = _amount[i] * multiplier;

            balanceOf[_wallets[i]] = num;
            Transfer(0, _wallets[i], num);

            totalSupply += num;
        }
    }

     
    function transferToContract(address _to, uint _value)
        public
        canTransfer
        returns (bool)
    {
        require(_value > 0);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        ReceivingContract receiver = ReceivingContract(_to);
        receiver.tokenFallback(msg.sender, _value);

        Transfer(msg.sender, _to, _value);
        return true;
    }

}