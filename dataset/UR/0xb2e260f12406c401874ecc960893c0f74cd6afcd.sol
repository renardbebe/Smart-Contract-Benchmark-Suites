 

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
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
contract BitUPToken is ERC20, Ownable {

    using SafeMath for uint;

 

    string public constant name = "BitUP Token";
    string public constant symbol = "BUT";

    uint8 public decimals = 18;                             
    
    mapping (address => uint256) balances;                  
    mapping (address => mapping (address => uint256)) allowed;  

 

    uint256 public totalSupply;
    
    uint256 public presaleSupply;                           
    uint256 public angelSupply;                           
    uint256 public marketingSupply;                            
    uint256 public foundationSupply;                        
    uint256 public teamSupply;                           
    uint256 public communitySupply;                  
    
    uint256 public teamSupply6Months;                           
    uint256 public teamSupply12Months;                           
    uint256 public teamSupply18Months;                           
    uint256 public teamSupply24Months;                           

    uint256 public TeamLockingPeriod6Months;                   
    uint256 public TeamLockingPeriod12Months;                   
    uint256 public TeamLockingPeriod18Months;                   
    uint256 public TeamLockingPeriod24Months;                   
    
    address public presaleAddress;                        
    address public angelAddress;                         
    address public marketingAddress;                        
    address public foundationAddress;                       
    address public teamAddress;                          
    address public communityAddress;                          

    function () {
          
          
         require(false);
    }

 

    modifier nonZeroAddress(address _to) {                  
        require(_to != 0x0);
        _;
    }

    modifier nonZeroAmount(uint _amount) {                  
        require(_amount > 0);
        _;
    }

    modifier nonZeroValue() {                               
        require(msg.value > 0);
        _;
    }

    modifier checkTeamLockingPeriod6Months() {                  
        assert(now >= TeamLockingPeriod6Months);
        _;
    }
    
    modifier checkTeamLockingPeriod12Months() {                  
        assert(now >= TeamLockingPeriod12Months);
        _;
    }
    
    modifier checkTeamLockingPeriod18Months() {                  
        assert(now >= TeamLockingPeriod18Months);
        _;
    }
    
    modifier checkTeamLockingPeriod24Months() {                  
        assert(now >= TeamLockingPeriod24Months);
        _;
    }
    
    modifier onlyTeam() {                              
        require(msg.sender == teamAddress);
        _;
    }
    
 
    
    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
         
        decrementBalance(burner, _value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

 

     
     
     
    function totalSupply() constant returns (uint256){
        return totalSupply;
    }

     
     
     
    function transfer(address _to, uint256 _amount) returns (bool success) {
        require(balanceOf(msg.sender) >= _amount);
        uint previousBalances = balances[msg.sender] + balances[_to];
        addToBalance(_to, _amount);
        decrementBalance(msg.sender, _amount);
        Transfer(msg.sender, _to, _amount);
        assert(balances[msg.sender] + balances[_to] == previousBalances);
        return true;
    }

     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
        require(balanceOf(_from) >= _amount);
        require(allowance(_from, msg.sender) >= _amount);
        uint previousBalances = balances[_from] + balances[_to];
        decrementBalance(_from, _amount);
        addToBalance(_to, _amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        Transfer(_from, _to, _amount);
        assert(balances[_from] + balances[_to] == previousBalances);
        return true;
    }

     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {
        require((_value == 0) || (allowance(msg.sender, _spender) == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function BitUPToken() {
        totalSupply  =    1000000000 * 1e18;                

        presaleSupply =    400000000 * 1e18;                
        angelSupply =       50000000 * 1e18;                
        teamSupply =       200000000 * 1e18;                
        foundationSupply = 150000000 * 1e18;                
        marketingSupply =  100000000 * 1e18;        
        communitySupply =  100000000 * 1e18;        
        
        teamSupply6Months = 50000000 * 1e18;                
        teamSupply12Months = 50000000 * 1e18;                
        teamSupply18Months = 50000000 * 1e18;                
        teamSupply24Months = 50000000 * 1e18;                
        
        angelAddress    = 0xeF01453A730486d262D0b490eF1aDBBF62C2Fe00;                          
        presaleAddress = 0x2822332F63a6b80E21cEA5C8c43Cb6f393eb5703;                          
        teamAddress = 0x8E199e0c1DD38d455815E11dc2c9A64D6aD893B7;                          
        foundationAddress = 0xcA972ac76F4Db643C30b86E4A9B54EaBB88Ce5aD;                          
        marketingAddress = 0xd2631280F7f0472271Ae298aF034eBa549d792EA;                          
        communityAddress = 0xF691e8b2B2293D3d3b06ecdF217973B40258208C;                          
        
        
        TeamLockingPeriod6Months = now.add(180 * 1 days);  
        TeamLockingPeriod12Months = now.add(360 * 1 days);  
        TeamLockingPeriod18Months = now.add(450 * 1 days);  
        TeamLockingPeriod24Months = now.add(730 * 1 days);  
        
        addToBalance(foundationAddress, foundationSupply);
        foundationSupply = 0;
        addToBalance(marketingAddress, marketingSupply);
        marketingSupply = 0;
        addToBalance(communityAddress, communitySupply);
        communitySupply = 0;
        addToBalance(presaleAddress, presaleSupply);
        presaleSupply = 0;
        addToBalance(angelAddress, angelSupply);
        angelSupply = 0;
    }

     
     
     
    function releaseTeamTokensAfter6Months() checkTeamLockingPeriod6Months onlyTeam returns(bool success) {
        require(teamSupply6Months > 0);
        addToBalance(teamAddress, teamSupply6Months);
        Transfer(0x0, teamAddress, teamSupply6Months);
        teamSupply6Months = 0;
        teamSupply.sub(teamSupply6Months);
        return true;
    }
    
     
     
     
    function releaseTeamTokensAfter12Months() checkTeamLockingPeriod12Months onlyTeam returns(bool success) {
        require(teamSupply12Months > 0);
        addToBalance(teamAddress, teamSupply12Months);
        Transfer(0x0, teamAddress, teamSupply12Months);
        teamSupply12Months = 0;
        teamSupply.sub(teamSupply12Months);
        return true;
    }
    
     
     
     
    function releaseTeamTokensAfter18Months() checkTeamLockingPeriod18Months onlyTeam returns(bool success) {
        require(teamSupply18Months > 0);
        addToBalance(teamAddress, teamSupply18Months);
        Transfer(0x0, teamAddress, teamSupply18Months);
        teamSupply18Months = 0;
        teamSupply.sub(teamSupply18Months);
        return true;
    }
    
     
     
     
    function releaseTeamTokensAfter24Months() checkTeamLockingPeriod24Months onlyTeam returns(bool success) {
        require(teamSupply24Months > 0);
        addToBalance(teamAddress, teamSupply24Months);
        Transfer(0x0, teamAddress, teamSupply24Months);
        teamSupply24Months = 0;
        teamSupply.sub(teamSupply24Months);
        return true;
    }

     
     
     
    function addToBalance(address _address, uint _amount) internal {
        balances[_address] = SafeMath.add(balances[_address], _amount);
    }

     
     
     
    function decrementBalance(address _address, uint _amount) internal {
        balances[_address] = SafeMath.sub(balances[_address], _amount);
    }
}