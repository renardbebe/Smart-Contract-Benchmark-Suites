 

pragma solidity ^0.4.0;

 
contract Ownable {
    modifier onlyOwner() {
        checkOwner();
        _;
    }

    function checkOwner() internal;
}

 
contract OwnableImpl is Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function OwnableImpl() public {
        owner = msg.sender;
    }

     
    function checkOwner() internal {
        require(msg.sender == owner);
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

 
contract ReadOnlyToken {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function allowance(address owner, address spender) public constant returns (uint256);
}

 
contract Token is ReadOnlyToken {
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MintableToken is Token {
    event Mint(address indexed to, uint256 amount);

    function mint(address _to, uint256 _amount) public returns (bool);
}

 
contract Sale {
     
    event Purchase(address indexed buyer, address token, uint256 value, uint256 sold, uint256 bonus);
     
    event RateAdd(address token);
     
    event RateRemove(address token);

     
    function getRate(address token) constant public returns (uint256);
     
    function getBonus(uint256 sold) constant public returns (uint256);
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

 
contract ExternalToken is Token {
    event Mint(address indexed to, uint256 value, bytes data);
    event Burn(address indexed burner, uint256 value, bytes data);

    function burn(uint256 _value, bytes _data) public;
}

 
contract ReceiveAdapter {

     
    function onReceive(address _token, address _from, uint256 _value, bytes _data) internal;
}

 
contract ERC20ReceiveAdapter is ReceiveAdapter {
    function receive(address _token, uint256 _value, bytes _data) public {
        Token token = Token(_token);
        token.transferFrom(msg.sender, this, _value);
        onReceive(_token, msg.sender, _value, _data);
    }
}

 
contract TokenReceiver {
    function onTokenTransfer(address _from, uint256 _value, bytes _data) public;
}

 
contract ERC223ReceiveAdapter is TokenReceiver, ReceiveAdapter {
    function tokenFallback(address _from, uint256 _value, bytes _data) public {
        onReceive(msg.sender, _from, _value, _data);
    }

    function onTokenTransfer(address _from, uint256 _value, bytes _data) public {
        onReceive(msg.sender, _from, _value, _data);
    }
}

contract EtherReceiver {
	function receiveWithData(bytes _data) payable public;
}

contract EtherReceiveAdapter is EtherReceiver, ReceiveAdapter {
    function () payable public {
        receiveWithData("");
    }

    function receiveWithData(bytes _data) payable public {
        onReceive(address(0), msg.sender, msg.value, _data);
    }
}

 
contract CompatReceiveAdapter is ERC20ReceiveAdapter, ERC223ReceiveAdapter, EtherReceiveAdapter {

}

contract AbstractSale is Sale, CompatReceiveAdapter, Ownable {
    using SafeMath for uint256;

    event Withdraw(address token, address to, uint256 value);
    event Burn(address token, uint256 value, bytes data);

    function onReceive(address _token, address _from, uint256 _value, bytes _data) internal {
        uint256 sold = getSold(_token, _value);
        require(sold > 0);
        uint256 bonus = getBonus(sold);
        address buyer;
        if (_data.length == 20) {
            buyer = address(toBytes20(_data, 0));
        } else {
            require(_data.length == 0);
            buyer = _from;
        }
        checkPurchaseValid(buyer, sold, bonus);
        doPurchase(buyer, sold, bonus);
        Purchase(buyer, _token, _value, sold, bonus);
        onPurchase(buyer, _token, _value, sold, bonus);
    }

    function getSold(address _token, uint256 _value) constant public returns (uint256) {
        uint256 rate = getRate(_token);
        require(rate > 0);
        return _value.mul(rate).div(10**18);
    }

    function getBonus(uint256 sold) constant public returns (uint256);

    function getRate(address _token) constant public returns (uint256);

    function doPurchase(address buyer, uint256 sold, uint256 bonus) internal;

    function checkPurchaseValid(address  , uint256  , uint256  ) internal {

    }

    function onPurchase(address  , address  , uint256  , uint256  , uint256  ) internal {

    }

    function toBytes20(bytes b, uint256 _start) pure internal returns (bytes20 result) {
        require(_start + 20 <= b.length);
        assembly {
            let from := add(_start, add(b, 0x20))
            result := mload(from)
        }
    }

    function withdrawEth(address _to, uint256 _value) onlyOwner public {
        withdraw(address(0), _to, _value);
    }

    function withdraw(address _token, address _to, uint256 _value) onlyOwner public {
        require(_to != address(0));
        verifyCanWithdraw(_token, _to, _value);
        if (_token == address(0)) {
            _to.transfer(_value);
        } else {
            Token(_token).transfer(_to, _value);
        }
        Withdraw(_token, _to, _value);
    }

    function verifyCanWithdraw(address token, address to, uint256 amount) internal;

    function burnWithData(address _token, uint256 _value, bytes _data) onlyOwner public {
        ExternalToken(_token).burn(_value, _data);
        Burn(_token, _value, _data);
    }
}

 
contract MintingSale is AbstractSale {
    MintableToken public token;

    function MintingSale(address _token) public {
        token = MintableToken(_token);
    }

    function doPurchase(address buyer, uint256 sold, uint256 bonus) internal {
        token.mint(buyer, sold.add(bonus));
    }

    function verifyCanWithdraw(address, address, uint256) internal {

    }
}

 
contract Secured {
    modifier only(string role) {
        require(msg.sender == getRole(role));
        _;
    }

    function getRole(string role) constant public returns (address);
}

contract Whitelist is Secured {
	mapping(address => bool) whitelist;
	event WhitelistChange(address indexed addr, bool allow);

	function isInWhitelist(address addr) constant public returns (bool) {
		return whitelist[addr];
	}

	function setWhitelist(address addr, bool allow) only("operator") public {
		setWhitelistInternal(addr, allow);
	}

	function setWhitelistInternal(address addr, bool allow) internal {
		whitelist[addr] = allow;
		WhitelistChange(addr, allow);
	}
}

contract WhitelistSale is AbstractSale, Whitelist {
	function checkPurchaseValid(address buyer, uint256 sold, uint256 bonus) internal {
		super.checkPurchaseValid(buyer, sold, bonus);
		require(isInWhitelist(buyer));
	}
}

contract SecuredImpl is Ownable, Secured {
	mapping(string => address) users;
	event RoleTransferred(address indexed previousUser, address indexed newUser, string role);

	function getRole(string role) constant public returns (address) {
		return users[role];
	}

	function transferRole(string role, address to) onlyOwner public {
		require(to != address(0));
		RoleTransferred(users[role], to, role);
		users[role] = to;
	}
}

contract RatesChangingSale is AbstractSale {
	event RateChange(address token, uint256 rate);
	mapping (address => uint256) rates;

	function getRate(address _token) constant public returns (uint256) {
		return rates[_token];
	}

	function setRate(address _token, uint256 _rate) onlyOwner public {
		rates[_token] = _rate;
		RateChange(_token, _rate);
		if (_rate == 0) {
			RateRemove(_token);
		} else {
			RateAdd(_token);
		}
	}
}

contract HcftSale is OwnableImpl, SecuredImpl, MintingSale, WhitelistSale, RatesChangingSale {
	address public btcToken;

	function HcftSale(address _mintableToken, address _btcToken)
	MintingSale(_mintableToken) {
		btcToken = _btcToken;
		setRates(1000 * 10**18, 10000 * 10**28, 10**34);
	}

	function getSold(address _token, uint256 _value) constant public returns (uint256) {
		return super.getSold(_token, _value).div(99).mul(98);
	}

	function getBonus(uint256  ) constant public returns (uint256) {
		return 0;
	}

	function setRates(uint256 ethRate, uint256 btcRate, uint256 usdRate) onlyOwner public {
		setRate(address(0), ethRate);
		setRate(btcToken, btcRate);
		setRate(address(1), usdRate);
	}

	function transferTokenOwnership(address newOwner) onlyOwner public {
		OwnableImpl(token).transferOwnership(newOwner);
	}

	function pauseToken() onlyOwner public {
		Pausable(token).pause();
	}

	function unpauseToken() onlyOwner public {
		Pausable(token).unpause();
	}

	function withdrawBtc(bytes _to, uint256 _value) onlyOwner public {
		burnWithData(btcToken, _value, _to);
	}

	function transfer(address beneficiary, uint256 amount) onlyOwner public {
		emulatePurchase(beneficiary, address(10), 0, amount);
	}

	function emulatePurchase(address beneficiary, address paymentMethod, uint256 value, uint256 amount) onlyOwner public {
		setWhitelistInternal(beneficiary, true);
		doPurchase(beneficiary, amount, 0);
		Purchase(beneficiary, paymentMethod, value, amount, 0);
		onPurchase(beneficiary, paymentMethod, value, amount, 0);
	}
}