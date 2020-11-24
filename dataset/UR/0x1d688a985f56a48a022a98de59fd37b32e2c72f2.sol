 

pragma solidity ^0.4.16;


contract ERC20Token {
    event Transfer(address indexed from, address indexed _to, uint256 _value);
	event Approval(address indexed owner, address indexed _spender, uint256 _value);

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0 && _to != address(this));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
}


contract Owned {
    address public owner;

     
    function Owned() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}


contract Beercoin is ERC20Token, Owned {
    event Produce(uint256 value, string caps);
	event Burn(uint256 value);

    string public name = "Beercoin";
    string public symbol = "🍺";
	uint8 public decimals = 18;
	uint256 public totalSupply = 15496000000 * 10 ** uint256(decimals);

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    uint256 public unproducedCaps = 20800000000;
    uint256 public producedCaps = 0;

     
     
    mapping (address => bool) public redemptionLocked;

     
    function Beercoin() public {
		balanceOf[owner] = totalSupply;
    }

     
    function lockRedemption(bool lock) public returns (bool success) {
        redemptionLocked[msg.sender] = lock;
        return true;
    }

     
	function produce(uint256 numberOfCaps) public onlyOwner returns (bool success) {
        require(numberOfCaps <= unproducedCaps);

        uint256 value = 0;
        bytes memory caps = bytes(new string(numberOfCaps));
        
        for (uint256 i = 0; i < numberOfCaps; ++i) {
            uint256 currentCoin = producedCaps + i;

            if (currentCoin % 10000 == 0) {
                value += 10000;
                caps[i] = "D";
            } else if (currentCoin % 1000 == 0) {
                value += 100;
                caps[i] = "G";
            } else if (currentCoin % 10 == 0) {
                value += 10;
                caps[i] = "S";
            } else {
                value += 1;
                caps[i] = "B";
            }
        }

        unproducedCaps -= numberOfCaps;
        producedCaps += numberOfCaps;

        value = value * 10 ** uint256(decimals);
        totalSupply += value;
        balanceOf[this] += value;
        Produce(value, string(caps));

        return true;
	}

	 
	function scan(address user, byte cap) public onlyOwner returns (bool success) {
        if (cap == "D") {
            _transfer(this, user, 10000 * 10 ** uint256(decimals));
        } else if (cap == "G") {
            _transfer(this, user, 100 * 10 ** uint256(decimals));
        } else if (cap == "S") {
            _transfer(this, user, 10 * 10 ** uint256(decimals));
        } else {
            _transfer(this, user, 1 * 10 ** uint256(decimals));
        }
        
        return true;
	}

     
	function scanMany(address[] users, byte[] caps) public onlyOwner returns (bool success) {
        require(users.length == caps.length);

        for (uint16 i = 0; i < users.length; ++i) {
            scan(users[i], caps[i]);
        }

        return true;
	}

	 
    function redeem(address user, uint256 value) public onlyOwner returns (bool success) {
        require(redemptionLocked[user] == false);
        _transfer(user, owner, value);
        return true;
    }

     
    function redeemMany(address[] users, uint256[] values) public onlyOwner returns (bool success) {
        require(users.length == values.length);

        for (uint16 i = 0; i < users.length; ++i) {
            redeem(users[i], values[i]);
        }

        return true;
    }

     
    function transferMany(address[] recipients, uint256[] values) public onlyOwner returns (bool success) {
        require(recipients.length == values.length);

        for (uint16 i = 0; i < recipients.length; ++i) {
            transfer(recipients[i], values[i]);
        }

        return true;
    }

     
    function burn(uint256 value) public onlyOwner returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
		Burn(value);
        return true;
    }
}