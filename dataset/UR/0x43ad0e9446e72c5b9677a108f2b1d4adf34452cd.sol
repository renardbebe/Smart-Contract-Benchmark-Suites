 

pragma solidity ^0.4.18;

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

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract PrayerCoinToken is Token {

    uint256 constant MAX_UINT256 = 2**256 - 1;

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
         
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

    function getBalance(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract Standard {
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract PrayerCoin is PrayerCoinToken {
  using SafeMath for uint256;
  address public god;

  string public name = "PrayerCoin";
  uint8 public decimals = 18;
  string public symbol = "PRAY";
  string public version = 'H1.0';  

  uint256 public totalSupply = 666666666 ether;
 
  uint private PRAY_ETH_RATIO = 6666;
  uint private PRAY_ETH_RATIO_BONUS1 = 7106;
  uint private PRAY_ETH_RATIO_BONUS2 = 11066;

  uint256 public totalDonations = 0;
  uint256 public totalPrayers = 0;

  bool private acceptingDonations = true;
  
  modifier divine {
    require(msg.sender == god);
    _;
  }

  function PrayerCoin() public {  
    god = msg.sender;
    balances[god] = totalSupply;  
  } 

  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);

     
     
     
    require(false == _spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
    return true;
  } 

  function startDonations() public divine {
    acceptingDonations = true;
  }

  function endDonations() public divine {
    acceptingDonations = false;
  }

  function fiatSend(address _to, uint256 amt, uint256 prayRatio) public divine {
    totalDonations += amt;
    uint256 prayersIssued = amt.mul(prayRatio);
    totalPrayers += prayersIssued;
    balances[_to] += prayersIssued;
    balances[god] -= prayersIssued;

    Transfer(address(this), _to, prayersIssued);
  }
  
  function() public payable {
    require(acceptingDonations == true);
    if (msg.value == 0) { return; }

    god.transfer(msg.value);

    totalDonations += msg.value;
    
    uint256 prayersIssued = 0;

    if (totalPrayers <= (6666666 * 1 ether)) {
        if (totalPrayers <= (666666 * 1 ether)) {
            prayersIssued = msg.value.mul(PRAY_ETH_RATIO_BONUS2);
        } else {
            prayersIssued = msg.value.mul(PRAY_ETH_RATIO_BONUS1);
        }
    } else {
        prayersIssued = msg.value.mul(PRAY_ETH_RATIO);
    }

    totalPrayers += prayersIssued;
    balances[msg.sender] += prayersIssued;
    balances[god] -= prayersIssued;

    Transfer(address(this), msg.sender, prayersIssued);
  }
 
}