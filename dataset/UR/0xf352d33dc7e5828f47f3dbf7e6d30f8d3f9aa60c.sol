 

pragma solidity ^0.4.18;

 
 
contract Owned {
    address owner;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function Owned() public {
        owner = msg.sender;
    }

    function changeOwner(address _newOwner) public onlyOwner{
        owner = _newOwner;
    }
}


 
 
library SafeMath {

  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

}

contract tokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract ERC20Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant public returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract limitedFactor {
    uint256 public startTime;
    uint256 public stopTime;
    address public walletAddress;
    address public teamAddress;
    address public contributorsAddress;
    bool public tokenFrozen = true;
    modifier teamAccountNeedFreezeOneYear(address _address) {
        if(_address == teamAddress) {
            require(now > startTime + 1 years);
        }
        _;
    }
    
    modifier TokenUnFreeze() {
        require(!tokenFrozen);
        _;
    } 
}
contract standardToken is ERC20Token, limitedFactor {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public TokenUnFreeze teamAccountNeedFreezeOneYear(msg.sender) returns (bool success) {
        require (balances[msg.sender] > _value);            
        require (balances[_to] + _value > balances[_to]);   
        balances[msg.sender] -= _value;                      
        balances[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                   
        return true;
    }

     
    function approve(address _spender, uint256 _value) public TokenUnFreeze returns (bool success) {
        allowances[msg.sender][_spender] = _value;           
        Approval(msg.sender, _spender, _value);              
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public TokenUnFreeze returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);               
        approve(_spender, _value);                                       
        spender.receiveApproval(msg.sender, _value, this, _extraData);   
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public TokenUnFreeze returns (bool success) {
        require (balances[_from] > _value);                 
        require (balances[_to] + _value > balances[_to]);   
        require (_value <= allowances[_from][msg.sender]);   
        balances[_from] -= _value;                           
        balances[_to] += _value;                             
        allowances[_from][msg.sender] -= _value;             
        Transfer(_from, _to, _value);                        
        return true;
    }

     
    function allowance(address _owner, address _spender) constant public TokenUnFreeze returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

}

contract FansChainToken is standardToken,Owned {
    using SafeMath for uint;

    string constant public name="FansChain";
    string constant public symbol="FANSC";
    uint256 constant public decimals=18;
    
    uint256 public totalSupply = 0;
    uint256 constant public topTotalSupply = 24*10**7*10**decimals;
    uint256 public teamSupply = percent(25);
    uint256 public privateFundSupply = percent(25);
    uint256 public privateFundingSupply = 0;
    uint256 public ICOtotalSupply = percent(20);
    uint256 public ICOSupply = 0;
    uint256 public ContributorsSupply = percent(30);
    uint256 public exchangeRate;
    bool    public ICOStart;
    
    
     
    function() public payable {
        require (ICOStart);
        depositToken(msg.value);
    }
    
    
    function FansChainToken() public {
        owner=msg.sender;
    }
    
     
    function depositToken(uint256 _value) internal {
        uint256 tokenAlloc = buyPriceAt(getTime()) * _value;
        ICOSupply = ICOSupply.add(tokenAlloc);
        require (ICOSupply < ICOtotalSupply);
        mintTokens (msg.sender, tokenAlloc);
        forwardFunds();
    }
    
    function forwardFunds() internal {
        require(walletAddress != address(0));
        walletAddress.transfer(msg.value);
    }
    
     
    function mintTokens(address _to, uint256 _amount) internal {
        require (balances[_to] + _amount > balances[_to]);       
        balances[_to] = balances[_to].add(_amount);              
        totalSupply = totalSupply.add(_amount);
        Transfer(0x0, _to, _amount);                             
    }
    
     
    function buyPriceAt(uint256 _time) internal constant returns(uint256) {
        if (_time >= startTime && _time <= stopTime) {
            return exchangeRate;
        } else {
            return 0;
        }
    }
    
     
    function getTime() internal constant returns(uint256) {
        return now;
    }
    
     
    function setInitialVaribles(
        uint256 _icoStopTime,
        uint256 _exchangeRate,
        address _walletAddress,
        address _teamAddress,
        address _contributorsAddress
        )
        public
        onlyOwner {
            stopTime = _icoStopTime;
            exchangeRate=_exchangeRate;
            walletAddress = _walletAddress;
            teamAddress = _teamAddress;
            contributorsAddress = _contributorsAddress;
        }
    
     
    function setICOStart(bool _start) public onlyOwner {
        ICOStart = _start;
        startTime = now;
    }
    
     
    function withDraw() public payable onlyOwner {
        require (msg.sender != address(0));
        require (getTime() > stopTime);
        walletAddress.transfer(this.balance);
    }
    
     
    function unfreezeTokenTransfer(bool _freeze) public onlyOwner {
        tokenFrozen = !_freeze;
    }
    
     
    function allocateTokens(address[] _owners, uint256[] _values) public onlyOwner {
        require (_owners.length == _values.length);
        for(uint256 i = 0; i < _owners.length ; i++){
            address owner = _owners[i];
            uint256 value = _values[i];
            ICOSupply = ICOSupply.add(value);
            require(totalSupply < ICOtotalSupply);
            mintTokens(owner, value);
        }
    }
    
     
    function percent(uint256 percentage) internal  pure returns (uint256) {
        return percentage.mul(topTotalSupply).div(100);
    }
     
      
    function allocateTeamToken() public onlyOwner {
        mintTokens(teamAddress, teamSupply);
    }
    
     
    function allocatePrivateToken(address[] _privateFundingAddress, uint256[] _amount) public onlyOwner {
        require (_privateFundingAddress.length == _amount.length);
        for(uint256 i = 0; i < _privateFundingAddress.length ; i++){
            address owner = _privateFundingAddress[i];
            uint256 value = _amount[i];
            privateFundingSupply = privateFundingSupply.add(value);
            require(privateFundingSupply <= privateFundSupply);
            mintTokens(owner, value);
        }
    }
    
     
    function allocateContributorsToken() public onlyOwner {
        mintTokens(contributorsAddress, ContributorsSupply);
    }
}