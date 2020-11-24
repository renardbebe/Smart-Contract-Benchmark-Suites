 

 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


contract ERC223Interface {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value);
    function transfer(address to, uint value, bytes data);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}


  
 
contract ERC223ReceivingContract { 
 
    function tokenFallback(address _from, uint _value, bytes _data);
}
 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}




contract ERC223Token is ERC223Interface {
    using SafeMath for uint;

    mapping(address => uint) balances;  
    
     
    function transfer(address _to, uint _value, bytes _data) {
         
         
        uint codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        Transfer(msg.sender, _to, _value, _data);
    }
    
     
    function transfer(address _to, uint _value) {
        uint codeLength;
        bytes memory empty;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        Transfer(msg.sender, _to, _value, empty);
    }

    
     
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
}


contract PajCoin223 is ERC223Token {

    string public constant name = "PajCoin";
    bytes32 public constant symbol = "PJC";
    uint8 public constant decimals = 18;

    function PajCoin223() public {
        bytes memory empty;
        totalSupply = 150000000e18;
        balances[msg.sender] = totalSupply;
        Transfer(0x0, msg.sender, totalSupply, empty);
    }
}



contract Exchanger is ERC223ReceivingContract, Ownable {

    uint public rate = 30*1000000000;
    uint public fee = 100000*3e9;

    PajCoin223 public token = PajCoin223(0x1a85180ce3012e7715b913dd585afdf1a10f3025);

     
    event DataEvent(uint value, string comment);
     
     
     

     
    struct Deal {
        address user;
        uint money;
    }
     
    mapping(uint => Deal) ethSended;
    mapping(uint => Deal) coinSended;

     
     
     
     
    uint ethSendedNumber = 0;
    uint coinSendedNumber = 0;

    modifier allDealsArePaid {
        require(ethSendedNumber == 0);
        require(coinSendedNumber == 0);
        _;
    }

    event LogPriceUpdated(uint price);

    function Exchanger() public payable {
        updater = msg.sender;
    }

    function needUpdate() public view returns (bool) {
        return ethSendedNumber + coinSendedNumber > 0;
    }



     
    bool private reentrancy_lock = false;

     
    modifier nonReentrant() {
        require(!reentrancy_lock);
        reentrancy_lock = true;
        _;
        reentrancy_lock = false;
    }

     
    address updater;

    modifier onlyUpdater() {
        require(msg.sender == updater);
        _;
    }

    function setUpdater(address _updater) public onlyOwner() {
        updater = _updater;
    }

    function setFee(uint _fee) public onlyOwner() {
        fee = _fee;
    }

    function setToken(address addr) public onlyOwner {
        token = PajCoin223(addr);
    }

    function getEth(uint amount) public onlyOwner allDealsArePaid {
        owner.transfer(amount);
    }

    function getTokens(uint amount) public onlyOwner allDealsArePaid {
        token.transfer(owner, amount);
    }

    function() public payable {
        if (msg.sender != owner) {
            require(fee <= msg.value);
            DataEvent(msg.value, "Someone sent ether: amount");
            ethSended[ethSendedNumber++] = Deal({user: msg.sender, money: msg.value});
        }
    }

    function tokenFallback(address _from, uint _value, bytes _data) {
         

        require(msg.sender == address(token));
        if (_from != owner) {
            require(fee <= _value * 1e9 / rate);
            DataEvent(_value, "Someone sent coin: amount");
            coinSended[coinSendedNumber++] = Deal({user: _from, money: _value});
        }
    }

    function updateRate(uint _rate) public onlyUpdater nonReentrant{

        rate = _rate;
        LogPriceUpdated(rate);

        uint personalFee = fee / (ethSendedNumber + coinSendedNumber);
        DataEvent(personalFee, "Personal fee");

        proceedEtherDeals(personalFee);
        proceedTokenDeals(personalFee);

    }

    function proceedEtherDeals(uint personalFee) internal {
        for (uint8 i = 0; i < ethSendedNumber; i++) {
            address user = ethSended[i].user;
            DataEvent(ethSended[i].money, "Someone sent ether: amount");
            DataEvent(personalFee, "Fee: amount");
            uint money = ethSended[i].money - personalFee;

            DataEvent(money, "Discounted amount: amount");
            uint value = money * rate / 1e9;
            DataEvent(value, "Ether to tokens: amount");
            if (money < 0) {
                 
            } else if (token.balanceOf(this) < value) {
                DataEvent(token.balanceOf(this), "Not enough tokens: owner balance");
                 
                user.transfer(money);
            } else {
                token.transfer(user, value);
                DataEvent(value, "Tokens were sent to customer: amount");
            }
        }
        ethSendedNumber = 0;
    }

    function proceedTokenDeals(uint personalFee) internal {
        for (uint8 j = 0; j < coinSendedNumber; j++) {
            address user = coinSended[j].user;
            uint coin = coinSended[j].money;

            DataEvent(coin, "Someone sent tokens: amount");
            DataEvent(coin * 1e9 / rate, "Tokens to ether: amount");
            uint value = coin * 1e9 / rate - personalFee;
            DataEvent(personalFee, "Fee: amount");
            DataEvent(value, "Tokens to discounted ether: amount");

            if (value < 0) {
                 
            } else if (this.balance < value) {
                 
                DataEvent(this.balance, "Not enough ether: contract balance");

                token.transfer(user, coin);
            } else {
                user.transfer(value);
                DataEvent(value, "Ether was sent to customer: amount");
            }
        }
        coinSendedNumber = 0;
    }
}