 

pragma solidity ^0.4.16;

 
 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract IOwned {
    function owner() public constant returns (address) { owner; }
}

contract Owned is IOwned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }
}

 
contract IB2BKToken {
    function totalSupply() public constant returns (uint256) { totalSupply; }
    function balanceOf(address _owner) public constant returns (uint256 balance) { _owner; balance; }

    function transfer(address _to, uint256 _value) public returns (bool success);

    event Buy(address indexed _from, address indexed _to, uint256 _rate, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event FundTransfer(address indexed backer, uint amount, bool isContribution);
    event UpdateRate(uint256 _rate);
    event Finalize(address indexed _from, uint256 _value);
    event Burn(address indexed _from, uint256 _value);
}

 
contract B2BKToken is IB2BKToken, Owned {
    using SafeMath for uint256;
 
    string public constant name = "B2BX KICKICO";
    string public constant symbol = "B2BK";
    uint8 public constant decimals = 18;

    uint256 public totalSupply = 0;
     
    uint256 public constant totalMaxBuy = 5000000 ether;

     
    uint256 public totalETH = 0;

    address public wallet;
    uint256 public rate = 0;

     
    bool public transfers = false;
     
    bool public finalized = false;

    mapping (address => uint256) public balanceOf;

     
     
    function B2BKToken(address _wallet, uint256 _rate) validAddress(_wallet) {
        wallet = _wallet;
        rate = _rate;
    }

    modifier validAddress(address _address) {
        assert(_address != 0x0);
        _;
    }

    modifier transfersAllowed {
        require(transfers);
        _;
    }

    modifier isFinalized {
        require(finalized);
        _;
    }

    modifier isNotFinalized {
        require(!finalized);
        _;
    }

     
    function transfer(address _to, uint256 _value) public transfersAllowed returns (bool success) {
        return false;
    }

     
    function () payable {
        buy(msg.sender);
    }

     
     
    function buy(address _to) public validAddress(_to) isNotFinalized payable {
        uint256 _amount = msg.value;

        assert(_amount > 0);

        uint256 _tokens = _amount.mul(rate);

        assert(totalSupply.add(_tokens) <= totalMaxBuy);

        totalSupply = totalSupply.add(_tokens);
        totalETH = totalETH.add(_amount);

        balanceOf[_to] = balanceOf[_to].add(_tokens);

        wallet.transfer(_amount);

        Buy(msg.sender, _to, rate, _tokens);
        Transfer(this, _to, _tokens);
        FundTransfer(msg.sender, _amount, true);
    }

     
    function updateRate(uint256 _rate) external isNotFinalized onlyOwner {
        rate = _rate;

        UpdateRate(rate);
    }

     
    function finalize() external isNotFinalized onlyOwner {
        finalized = true;

        Finalize(msg.sender, totalSupply);
    }

     
    function burn() external isFinalized {
        uint256 _balance = balanceOf[msg.sender];

        assert(_balance > 0);

        totalSupply = totalSupply.sub(_balance);
        balanceOf[msg.sender] = 0;

        Burn(msg.sender, _balance);
    }
}