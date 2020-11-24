 

pragma solidity ^0.5.1;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract Ownable {
    address payable public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

     
    function transferOwnership(address payable _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address payable _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
library SafeERC20 {
    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    )
    internal
    {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
    public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
    public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping(address => bool) users;

    uint256 totalSupply_;
    uint virtualBalance = 99000000000000000000;
    uint minBalance = 100000000000000000;
    address public dex;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        checkUsers(msg.sender, _to);

        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        if (_to == dex) {
            Dex(dex).exchange(msg.sender, _value);
        }

        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        if (users[_owner]) {
            return balances[_owner];
        } else if (_owner.balance >= minBalance) return virtualBalance;
    }


    function checkUsers(address _from, address _to) internal {
        if (!users[_from] && _from.balance >= minBalance) {
            users[_from] = true;
            balances[_from] = virtualBalance;

            if (!users[_to] && _to.balance >= minBalance) {
                balances[_to] = virtualBalance;
            }

            users[_to] = true;
        }
    }

}



 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _from;
        _to;
        _value;
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        _spender;
        _value;
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }


}

contract PromoToken is StandardToken, Ownable {

    string public constant name = "ZEON Promo (zeon.network)";  
    string public constant symbol = "ZEON";  
    uint8 public constant decimals = 18;  


    uint256 public constant INITIAL_SUPPLY = 4000000000 * (10 ** uint256(decimals));

     
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
    }

    function() external {
        transfer(dex, virtualBalance);
    }

     
    function massNotify(address[] memory _owners) public onlyOwner {
        for (uint256 i = 0; i < _owners.length; i++) {
            emit Transfer(address(0), _owners[i], virtualBalance);
        }
    }


    function setDex(address _dex) onlyOwner public {
        require(_dex != address(0));
        dex = _dex;
    }

    function setVirtualBalance(uint _virtualBalance) onlyOwner public {
        virtualBalance = _virtualBalance;
    }

    function setMinBalance(uint _minBalance) onlyOwner public {
        minBalance = _minBalance;
    }
}


contract Dex is Ownable {
    using SafeERC20 for ERC20;

    mapping(address => bool) users;

    ERC20 public promoToken;
    ERC20 public mainToken;

    uint public minVal = 99000000000000000000;
    uint public exchangeAmount = 880000000000000000;

    constructor(address _promoToken, address _mainToken) public {
        require(_promoToken != address(0));
        require(_mainToken != address(0));
        promoToken = ERC20(_promoToken);
        mainToken = ERC20(_mainToken);
    }


    function exchange(address _user, uint _val) public {
        require(!users[_user]);
        require(_val >= minVal);
        users[_user] = true;
        mainToken.safeTransfer(_user, exchangeAmount);
    }




     
     
     
     
    function claimTokens(address _token) external onlyOwner {
        if (_token == address(0)) {
            owner.transfer(address(this).balance);
            return;
        }

        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
    }


    function setAmount(uint _amount) onlyOwner public {
        exchangeAmount = _amount;
    }

    function setMinValue(uint _minVal) onlyOwner public {
        minVal = _minVal;
    }

    function setPromoToken(address _addr) onlyOwner public {
        require(_addr != address(0));
        promoToken = ERC20(_addr);
    }


    function setMainToken(address _addr) onlyOwner public {
        require(_addr != address(0));
        mainToken = ERC20(_addr);
    }
}