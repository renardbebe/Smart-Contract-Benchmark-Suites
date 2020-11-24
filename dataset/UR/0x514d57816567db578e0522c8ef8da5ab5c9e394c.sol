 

pragma solidity ^0.4.18;

 
 
contract Owned {
    address public owner;
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
    using SafeMath for uint;
    
    uint256 public totalSupply = 0;
    uint256 public topTotalSupply = 18*10**8*10**18;
    uint256 public teamSupply = percent(15);
    uint256 public teamAlloacting = 0;
    uint256 internal teamReleasetokenEachMonth = 5 * teamSupply / 100;
    uint256 public creationInvestmentSupply = percent(15);
    uint256 public creationInvestmenting = 0;
    uint256 public ICOtotalSupply = percent(30);
    uint256 public ICOSupply = 0;
    uint256 public communitySupply = percent(20);
    uint256 public communityAllocating = 0;
    uint256 public angelWheelFinanceSupply = percent(20);
    uint256 public angelWheelFinancing = 0;
    address public walletAddress;
    uint256 public teamAddressFreezeTime = startTimeRoundOne;
    address public teamAddress;
    uint256 internal teamAddressTransfer = 0;
    uint256 public exchangeRateRoundOne = 16000;
    uint256 public exchangeRateRoundTwo = 10000;
    uint256 internal startTimeRoundOne = 1526313600;
    uint256 internal stopTimeRoundOne =  1528991999;
    
    modifier teamAccountNeedFreeze18Months(address _address) {
        if(_address == teamAddress) {
            require(now >= teamAddressFreezeTime + 1.5 years);
        }
        _;
    }
    
    modifier releaseToken (address _user, uint256 _time, uint256 _value) {
        if (_user == teamAddress){
            require (teamAddressTransfer + _value <= calcReleaseToken(_time)); 
        }
        _;
    }
    
    function calcReleaseToken (uint256 _time) internal view returns (uint256) {
        uint256 _timeDifference = _time - (teamAddressFreezeTime + 1.5 years);
        return _timeDifference / (3600 * 24 * 30) * teamReleasetokenEachMonth;
    } 
    
      
    function percent(uint256 percentage) internal view returns (uint256) {
        return percentage.mul(topTotalSupply).div(100);
    }

}

contract standardToken is ERC20Token, limitedFactor {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) 
        public 
        teamAccountNeedFreeze18Months(msg.sender) 
        releaseToken(msg.sender, now, _value)
        returns (bool success) 
    {
        require (balances[msg.sender] >= _value);            
        require (balances[_to] + _value >= balances[_to]);   
        balances[msg.sender] -= _value;                      
        balances[_to] += _value;                             
        if (msg.sender == teamAddress) {
            teamAddressTransfer += _value;
        }
        emit Transfer(msg.sender, _to, _value);                   
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        allowances[msg.sender][_spender] = _value;           
        emit Approval(msg.sender, _spender, _value);              
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);               
        approve(_spender, _value);                                       
        spender.receiveApproval(msg.sender, _value, this, _extraData);   
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require (balances[_from] >= _value);                 
        require (balances[_to] + _value >= balances[_to]);   
        require (_value <= allowances[_from][msg.sender]);   
        balances[_from] -= _value;                           
        balances[_to] += _value;                             
        allowances[_from][msg.sender] -= _value;             
        emit Transfer(_from, _to, _value);                        
        return true;
    }

     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

}

contract MMChainToken is standardToken,Owned {
    using SafeMath for uint;

    string constant public name="MONEY MONSTER";
    string constant public symbol="MM";
    uint256 constant public decimals=6;
    
    bool public ICOStart;
    
     
    function() public payable {
        require (ICOStart);
        depositToken(msg.value);
    }
    
     
    function MMChainToken() public {
        owner=msg.sender;
        ICOStart = true;
    }
    
     
    function depositToken(uint256 _value) internal {
        uint256 tokenAlloc = buyPriceAt(getTime()) * _value;
        require(tokenAlloc != 0);
        ICOSupply = ICOSupply.add(tokenAlloc);
        require (ICOSupply <= ICOtotalSupply);
        mintTokens(msg.sender, tokenAlloc);
        forwardFunds();
    }
    
     
    function forwardFunds() internal {
        if (walletAddress != address(0)){
            walletAddress.transfer(msg.value);
        }
    }
    
     
    function mintTokens(address _to, uint256 _amount) internal {
        require (balances[_to] + _amount >= balances[_to]);      
        balances[_to] = balances[_to].add(_amount);              
        totalSupply = totalSupply.add(_amount);
        require(totalSupply <= topTotalSupply);
        emit Transfer(0x0, _to, _amount);                             
    }
    
     
    function buyPriceAt(uint256 _time) internal constant returns(uint256) {
        if (_time >= startTimeRoundOne && _time <= stopTimeRoundOne) {
            return exchangeRateRoundOne;
        }  else {
            return 0;
        }
    }
    
     
    function getTime() internal constant returns(uint256) {
        return now;
    }
    
     
    function setInitialVaribles(address _walletAddress, address _teamAddress) public onlyOwner {
        walletAddress = _walletAddress;
        teamAddress = _teamAddress;
    }
    
     
    function withDraw(address _etherAddress) public payable onlyOwner {
        require (_etherAddress != address(0));
        address contractAddress = this;
        _etherAddress.transfer(contractAddress.balance);
    }
    
     
    function allocateTokens(address[] _owners, uint256[] _values) public onlyOwner {
        require (_owners.length == _values.length);
        for(uint256 i = 0; i < _owners.length ; i++){
            address owner = _owners[i];
            uint256 value = _values[i];
            mintTokens(owner, value);
        }
    }
    
     
    function allocateTeamToken() public onlyOwner {
        require(balances[teamAddress] == 0);
        mintTokens(teamAddress, teamSupply);
        teamAddressFreezeTime = now;
    }
    
    function allocateCommunityToken (address[] _commnityAddress, uint256[] _amount) public onlyOwner {
        communityAllocating = mintMultiToken(_commnityAddress, _amount, communityAllocating);
        require (communityAllocating <= communitySupply);
    }
     
    function allocateCreationInvestmentingToken(address[] _creationInvestmentingingAddress, uint256[] _amount) public onlyOwner {
        creationInvestmenting = mintMultiToken(_creationInvestmentingingAddress, _amount, creationInvestmenting);
        require (creationInvestmenting <= creationInvestmentSupply);
    }
    
     
    function allocateAngelWheelFinanceToken(address[] _angelWheelFinancingAddress, uint256[] _amount) public onlyOwner {
         
        angelWheelFinancing = mintMultiToken(_angelWheelFinancingAddress, _amount, angelWheelFinancing);
        require (angelWheelFinancing <= angelWheelFinanceSupply);
    }
    
    function mintMultiToken (address[] _multiAddr, uint256[] _multiAmount, uint256 _target) internal returns (uint256){
        require (_multiAddr.length == _multiAmount.length);
        for(uint256 i = 0; i < _multiAddr.length ; i++){
            address owner = _multiAddr[i];
            uint256 value = _multiAmount[i];
            _target = _target.add(value);
            mintTokens(owner, value);
        }
        return _target;
    }
}