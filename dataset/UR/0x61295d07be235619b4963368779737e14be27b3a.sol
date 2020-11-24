 

pragma solidity ^0.4.13;
 

 
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


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
 
 
 
 
contract Escapable {
    BasicToken public baseToken;

    address public escapeHatchCaller;
    address public escapeHatchDestination;

     
     
     
     
     
     
     
     
     
     
     
    function Escapable(
        address _baseToken,
        address _escapeHatchCaller,
        address _escapeHatchDestination) {
        baseToken = BasicToken(_baseToken);
        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = _escapeHatchDestination;
    }

     
     
    modifier onlyEscapeHatchCaller {
        require (msg.sender == escapeHatchCaller);
        _;
    }

     
     
    function escapeHatch() onlyEscapeHatchCaller {
        uint total = getBalance();
         
        transfer(escapeHatchDestination, total);
        EscapeHatchCalled(total);
    }
     
     
     
     
     
    function changeEscapeHatchCaller(address _newEscapeHatchCaller
        ) onlyEscapeHatchCaller 
    {
        escapeHatchCaller = _newEscapeHatchCaller;
        EscapeHatchCallerChanged(escapeHatchCaller);
    }
     
    function getBalance() constant returns(uint) {
        if (address(baseToken) != 0) {
            return baseToken.balanceOf(this);
        } else {
            return this.balance;
        }
    }
     
     
     
     
    function transfer(address _to, uint _amount) internal {
        if (address(baseToken) != 0) {
            require (baseToken.transfer(_to, _amount));
        } else {
            require ( _to.send(_amount));
        }
    }


 
 
 

     
     
    function receiveEther() payable {
         
        require (address(baseToken) == 0);
        EtherReceived(msg.sender, msg.value);
    }

 
 
 

     
     
     
     
    function claimTokens(address _token) public onlyEscapeHatchCaller {
        if (_token == 0x0) {
            escapeHatchDestination.transfer(this.balance);
            return;
        }

        BasicToken token = BasicToken(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(escapeHatchDestination, balance);
        ClaimedTokens(_token, escapeHatchDestination, balance);
    }

     
     
    function () payable {
        receiveEther();
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event EscapeHatchCalled(uint amount);
    event EscapeHatchCallerChanged(address indexed newEscapeHatchCaller);
    event EtherReceived(address indexed from, uint amount);
}

 
 
 
 
 


 
contract MexicoMatcher is Escapable {
    address public beneficiary;  

     
     
     
     
     
     
     
     
     
     
     
    function MexicoMatcher(
            address _beneficiary,  
            address _escapeHatchCaller,
            address _escapeHatchDestination
        )
         
        Escapable(0x0, _escapeHatchCaller, _escapeHatchDestination)
    {
        beneficiary = _beneficiary;
    }
    
     
    function depositETH() payable {
        DonationDeposited4Matching(msg.sender, msg.value);
    }
     
     
     
    function () payable {
        uint256 amount;
        
         
        if (this.balance >= msg.value*2){
            amount = msg.value*2;  
        
             
            require (beneficiary.send(amount));
            DonationMatched(msg.sender, amount);
        } else {
            amount = this.balance;
            require (beneficiary.send(amount));
            DonationSentButNotMatched(msg.sender, amount);
        }
    }
    event DonationDeposited4Matching(address indexed sender, uint amount);
    event DonationMatched(address indexed sender, uint amount);
    event DonationSentButNotMatched(address indexed sender, uint amount);
}