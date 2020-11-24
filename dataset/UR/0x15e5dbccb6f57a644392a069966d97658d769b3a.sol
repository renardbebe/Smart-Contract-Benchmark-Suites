 

pragma solidity ^0.4.15;

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

contract CoVEXTokenERC223 is ERC223Token{
    using SafeMath for uint256;

    string public name = "CoVEX Coin";
    string public symbol = "CoVEX";
    uint256 public decimals = 18;

     
    uint256 public totalSupply = 250*1000000 * (uint256(10) ** decimals);
    uint256 public totalRaised;  

    uint256 public startTimestamp;  
    uint256 public durationSeconds;  

    uint256 public maxCap;

    uint256 coinsPerETH;

    mapping(address => uint) etherBalance;

    mapping(uint => uint) public weeklyRewards;

    uint256 minPerUser = 0.1 ether;
    uint256 maxPerUser = 100 ether;

     
    address public fundsWallet;

    function CoVEXTokenERC223() {
        fundsWallet = msg.sender;
        
        startTimestamp = now;
        durationSeconds = 0;  

         
        balances[fundsWallet] = totalSupply;

        bytes memory empty;
        Transfer(0x0, fundsWallet, totalSupply, empty);

         
        fundsWallet.transfer(msg.value);
    }

    function() isIcoOpen checkMinMax payable{
        totalRaised = totalRaised.add(msg.value);

        uint256 tokenAmount = calculateTokenAmount(msg.value);
        balances[fundsWallet] = balances[fundsWallet].sub(tokenAmount);
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);

        etherBalance[msg.sender] = etherBalance[msg.sender].add(msg.value);

        bytes memory empty;
        Transfer(fundsWallet, msg.sender, tokenAmount, empty);
    }

    function transfer(address _to, uint _value){
        return super.transfer(_to, _value);
    }

    function transfer(address _to, uint _value, bytes _data){
        return super.transfer(_to, _value, _data);   
    }

    function calculateTokenAmount(uint256 weiAmount) constant returns(uint256) {
        uint256 tokenAmount = weiAmount.mul(coinsPerETH);
         
        for (uint i = 1; i <= 4; i++) {
            if (now <= startTimestamp + 7 days) {
                return tokenAmount.mul(100+weeklyRewards[i]).div(100);    
            }
        }
        return tokenAmount;
    }

     
    function adminBurn(uint256 _value) public {
      require(_value <= balances[msg.sender]);
       
       
      address burner = msg.sender;
      balances[burner] = balances[burner].sub(_value);
      totalSupply = totalSupply.sub(_value);
      bytes memory empty;
      Transfer(burner, address(0), _value, empty);
    }

    function adminAddICO(uint256 _startTimestamp, uint256 _durationSeconds, 
        uint256 _coinsPerETH, uint256 _maxCap, uint _week1Rewards,
        uint _week2Rewards, uint _week3Rewards, uint _week4Rewards) isOwner{

        startTimestamp = _startTimestamp;
        durationSeconds = _durationSeconds;
        coinsPerETH = _coinsPerETH;
        maxCap = _maxCap * 1 ether;

        weeklyRewards[1] = _week1Rewards;
        weeklyRewards[2] = _week2Rewards;
        weeklyRewards[3] = _week3Rewards;
        weeklyRewards[4] = _week4Rewards;

         
        totalRaised = 0;
    }

    modifier isIcoOpen() {
        require(now >= startTimestamp);
        require(now <= (startTimestamp + durationSeconds));
        require(totalRaised <= maxCap);
        _;
    }

    modifier checkMinMax(){
      require(msg.value >= minPerUser);
      require(msg.value <= maxPerUser);
      _;
    }

    modifier isOwner(){
        require(msg.sender == fundsWallet);
        _;
    }
}