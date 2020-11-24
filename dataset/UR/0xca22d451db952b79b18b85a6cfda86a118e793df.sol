 

pragma solidity ^0.4.16;

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

contract Owned {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
    using SafeMath for uint;
    
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    uint256 public totalSupply;
   
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                     
        name = tokenName;                                        
        symbol = tokenSymbol;                                    
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public 
        returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      

        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);

        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }   

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);


         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        balanceOf[_to] = balanceOf[_to].add(_value);


        emit Transfer(_from, _to, _value);
    } 
}

contract WEKUToken is Owned, TokenERC20 {
    
    string public constant TOKEN_SYMBOL  = "WEKU"; 
    string public constant TOKEN_NAME    = "WEKU Token";  
    uint public constant INITIAL_SUPPLLY = 4 * 10 ** 8; 

    uint256 deployedTime;    
    address team;            
    uint256 teamTotal;       
    uint256 teamWithdrawed;  

    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool frozen);

    function WEKUToken(
        address _team
    ) TokenERC20(INITIAL_SUPPLLY, TOKEN_NAME, TOKEN_SYMBOL) public {
        deployedTime = now;
        team = _team; 
        teamTotal = (INITIAL_SUPPLLY * 10 ** 18) / 5; 
         
        _transfer(owner, team, teamTotal);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    
     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);

        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;

        emit FrozenFunds(target, freeze);
    }

     
     
     
    function assignToEarlyBirds(address[] earlyBirds, uint256 amount) onlyOwner public {
        require(amount > 0);

        for (uint i = 0; i < earlyBirds.length; i++)
            _transfer(msg.sender, earlyBirds[i], amount * 10 ** 18);
    }

     
    function _transfer(address _from, address _to, uint _value) internal { 
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        

         
        if(_from == team){
            bool flag = _limitTeamWithdraw(_value, teamTotal, teamWithdrawed, deployedTime, now);
            if(!flag)
                revert();
        }          
             
        balanceOf[_from] = balanceOf[_from].sub(_value);                   
        balanceOf[_to] = balanceOf[_to].add(_value);                       

        if(_from == team) teamWithdrawed = teamWithdrawed.add(_value);     

        emit Transfer(_from, _to, _value);
    }

     
     
     
     
     
    function _limitTeamWithdraw(uint _amount, uint _teamTotal, uint _teamWithrawed, uint _deployedTime, uint _currentTime) internal pure returns(bool){
        
        bool flag  = true;

        uint _tenPercent = _teamTotal / 10;    
        if(_currentTime <= _deployedTime + 1 days && _amount + _teamWithrawed >= _tenPercent * 4) 
            flag = false;
        else if(_currentTime <= _deployedTime + 365 days && _amount + _teamWithrawed >= _tenPercent * 7) 
            flag = false; 

        return flag;

    }
}