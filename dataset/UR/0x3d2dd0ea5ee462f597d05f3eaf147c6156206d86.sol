 

pragma solidity ^0.4.18;

 
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

 
contract UpgradeAgent {

    bool public isUpgradeAgent = true;

    function upgradeFrom(address _from, uint _value) public;

}


 
contract MintableToken is StandardToken {

	bool public mintingFinished = false;

	 
	event Mint(address indexed to, uint amount);
  	event MintFinished();

	modifier canMint() {
		require(!mintingFinished);
		_;
	}

	 
	function mint(address _to, uint _amount)
		public
		onlyOwner
		canMint
	{
		totalSupply = totalSupply.add(_amount);
		balanceOf[_to] = balanceOf[_to].add(_amount);
		Mint(_to, _amount);
		Transfer(0, _to, _amount);
	}

	 
	function finishMinting()
		public
		onlyOwner
		canMint
	{
		mintingFinished = true;
		MintFinished();
	}

}

 
contract CappedToken is MintableToken {

    uint public cap;

     
    function mint(address _to, uint _amount)
        public
        onlyOwner
        canMint
    {
        require(totalSupply.add(_amount) <= cap);

        super.mint(_to, _amount);
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

         
        if (!upgradeAgent.isUpgradeAgent()) {
            revert();
        }

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

 
contract QNTU is UpgradableToken, CappedToken, PausableToken {

     
    function QNTU()
        public
    {
        symbol = "QNTU";
        name = "QNTU Token";
        decimals = 18;

        uint multiplier = 10 ** uint(decimals);

        cap = 120000000000 * multiplier;
        totalSupply = 72000000000 * multiplier;

         
        balanceOf[0xd83ef0076580e595b3be39d654da97184623b9b5] = 4800000000 * multiplier;
        balanceOf[0xd4e40860b41f666fbc6c3007f3d1434e353063d8] = 4800000000 * multiplier;
        balanceOf[0x84dd4187a87055495d0c08fe260ca9cc9e02f09e] = 4800000000 * multiplier;
        balanceOf[0x0556620d12c38babd0461e366b433682a5000fae] = 4800000000 * multiplier;
        balanceOf[0x0f363f18f49aa350ba8fcf233cdd155a7b77af99] = 4800000000 * multiplier;
        balanceOf[0x1a38292d3f685cd79bcdfc19fad7447ae762aa4c] = 4800000000 * multiplier;
        balanceOf[0xb262d04ee29ad9ebacb1ab9da99398916f425d84] = 4800000000 * multiplier;
        balanceOf[0xd8c2d6f12baf10258eb390be4377e460c1d033e2] = 4800000000 * multiplier;
        balanceOf[0x1ca70fd8433ec97fa0777830a152d028d71b88fa] = 4800000000 * multiplier;
        balanceOf[0x57be4b8c57c0bb061e05fdf85843503fba673394] = 4800000000 * multiplier;

        Transfer(0, 0xd83ef0076580e595b3be39d654da97184623b9b5, 4800000000 * multiplier);
        Transfer(0, 0xd4e40860b41f666fbc6c3007f3d1434e353063d8, 4800000000 * multiplier);
        Transfer(0, 0x84dd4187a87055495d0c08fe260ca9cc9e02f09e, 4800000000 * multiplier);
        Transfer(0, 0x0556620d12c38babd0461e366b433682a5000fae, 4800000000 * multiplier);
        Transfer(0, 0x0f363f18f49aa350ba8fcf233cdd155a7b77af99, 4800000000 * multiplier);
        Transfer(0, 0x1a38292d3f685cd79bcdfc19fad7447ae762aa4c, 4800000000 * multiplier);
        Transfer(0, 0xb262d04ee29ad9ebacb1ab9da99398916f425d84, 4800000000 * multiplier);
        Transfer(0, 0xd8c2d6f12baf10258eb390be4377e460c1d033e2, 4800000000 * multiplier);
        Transfer(0, 0x1ca70fd8433ec97fa0777830a152d028d71b88fa, 4800000000 * multiplier);
        Transfer(0, 0x57be4b8c57c0bb061e05fdf85843503fba673394, 4800000000 * multiplier);

         
        balanceOf[0xb6ff15b634571cb56532022fe00f96fee51322b3] = 4800000000 * multiplier;
        balanceOf[0x631c87278de77902e762ba0ab57d55c10716e0b6] = 4800000000 * multiplier;
        balanceOf[0x7fe443391d9a3eb0c401181c46a44eb6106bba2e] = 4800000000 * multiplier;
        balanceOf[0x94905c20fa2596fdc7d37bab6dd67b52e2335122] = 4800000000 * multiplier;
        balanceOf[0x6ad8038f53ae2800d45a31d8261b062a0b55d63b] = 4800000000 * multiplier;

        Transfer(0, 0xb6ff15b634571cb56532022fe00f96fee51322b3, 4800000000 * multiplier);
        Transfer(0, 0x631c87278de77902e762ba0ab57d55c10716e0b6, 4800000000 * multiplier);
        Transfer(0, 0x7fe443391d9a3eb0c401181c46a44eb6106bba2e, 4800000000 * multiplier);
        Transfer(0, 0x94905c20fa2596fdc7d37bab6dd67b52e2335122, 4800000000 * multiplier);
        Transfer(0, 0x6ad8038f53ae2800d45a31d8261b062a0b55d63b, 4800000000 * multiplier);
    }

}