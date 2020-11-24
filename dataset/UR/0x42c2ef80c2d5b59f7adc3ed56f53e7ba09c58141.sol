 

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
    uint256 public FoundationAddressFreezeTime;
    address public FoundationAddress;
    address public TeamAddress;
    modifier FoundationAccountNeedFreezeOneYear(address _address) {
        if(_address == FoundationAddress) {
            require(now >= FoundationAddressFreezeTime + 1 years);
        }
        _;
    }

}
contract standardToken is ERC20Token, limitedFactor {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public FoundationAccountNeedFreezeOneYear(msg.sender) returns (bool success) {
        require (balances[msg.sender] >= _value);            
        require (balances[_to] + _value >= balances[_to]);   
        balances[msg.sender] -= _value;                      
        balances[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                   
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        allowances[msg.sender][_spender] = _value;           
        Approval(msg.sender, _spender, _value);              
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
        Transfer(_from, _to, _value);                        
        return true;
    }

     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

}

contract NSilkRoadCoinToken is standardToken,Owned {
    using SafeMath for uint;

    string constant public name="NSilkRoadCoinToken";
    string constant public symbol="NSRC";
    uint256 constant public decimals=6;
    
    uint256 public totalSupply = 0;
    uint256 constant public topTotalSupply = 21*10**7*10**decimals;
    uint256 public FoundationSupply = percent(30);
	uint256 public TeamSupply = percent(25);
    uint256 public ownerSupply = topTotalSupply - FoundationSupply - TeamSupply;
    
     
    function() public payable {}
    
     
    function NSilkRoadCoinToken() public {
        owner = msg.sender;
        mintTokens(owner, ownerSupply);
    }
    
     
    function mintTokens(address _to, uint256 _amount) internal {
        require (balances[_to] + _amount >= balances[_to]);      
        balances[_to] = balances[_to].add(_amount);              
        totalSupply = totalSupply.add(_amount);
        require(totalSupply <= topTotalSupply);
        Transfer(0x0, _to, _amount);                             
    }
    
     
    function getTime() internal constant returns(uint256) {
        return now;
    }
    
     
    function setInitialVaribles(
        address _FoundationAddress,
        address _TeamAddress
        )
        public
        onlyOwner 
    {
        FoundationAddress = _FoundationAddress;
        TeamAddress = _TeamAddress;
    }
    
     
    function withDraw(address _walletAddress) public payable onlyOwner {
        require (_walletAddress != address(0));
        _walletAddress.transfer(this.balance);
    }
    
     
    function transferMultiAddress(address[] _recivers, uint256[] _values) public onlyOwner {
        require (_recivers.length == _values.length);
        for(uint256 i = 0; i < _recivers.length ; i++){
            address reciver = _recivers[i];
            uint256 value = _values[i];
            require (balances[msg.sender] >= value);            
            require (balances[reciver] + value >= balances[reciver]);   
            balances[msg.sender] -= value;                      
            balances[reciver] += value;                             
            Transfer(msg.sender, reciver, value);                   
        }
    }
    
     
    function percent(uint256 percentage) internal pure returns (uint256) {
        return percentage.mul(topTotalSupply).div(100);
    }
    
     
    function allocateFoundationToken() public onlyOwner {
        require(TeamAddress != address(0));
        require(balances[FoundationAddress] == 0);
        mintTokens(FoundationAddress, FoundationSupply);
        FoundationAddressFreezeTime = now;
    }
    
     
    function allocateTeamToken() public onlyOwner {
        require(TeamAddress != address(0));
        require(balances[TeamAddress] == 0);
        mintTokens(TeamAddress, TeamSupply);
    }
}