 

pragma solidity 0.4.24;


 
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


 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 public totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(msg.data.length>=(2*32)+4);
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer (msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}


 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_value==0||allowed[msg.sender][_spender]==0);
        require(msg.data.length>=(2*32)+4);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}


 
contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

 
contract  Lock is PausableToken{

    mapping(address => uint256) public teamLockTime;  
    mapping(address => uint256) public fundLockTime;  
    uint256 public issueDate =0 ; 
    mapping(address => uint256) public teamLocked; 
    mapping(address => uint256) public fundLocked; 
    mapping(address => uint256) public teamUsed;    
    mapping(address => uint256) public fundUsed;    
    mapping(address => uint256) public teamReverse;    
    mapping(address => uint256) public fundReverse;    
    

    
    function teamAvailable(address _to) internal constant returns (uint256) {
        require(teamLockTime[_to]>0);
         
        if(teamLockTime[_to] != issueDate)
        {
            teamLockTime[_to]= issueDate;
        }
        uint256 now1 = block.timestamp;
        uint256 lockTime = teamLockTime[_to];
        uint256 time = now1.sub(lockTime);
        uint256 percent = 0;
         
        if(time >= 365 days) {
          percent =  (time.div(30 days)) .add(1);
        }
        percent = percent > 12 ? 12 : percent;
        uint256 avail = teamLocked[_to];
        require(avail>0);
        avail = avail.mul(percent).div(12).sub(teamUsed[_to]);
        return avail ;
    }
    
     
    function fundAvailable(address _to) internal constant returns (uint256) {
        require(fundLockTime[_to]>0);
         
        if(fundLockTime[_to] != issueDate)
        {
            fundLockTime[_to]= issueDate;
        }
         
        uint256 lockTime = fundLockTime[_to];
         
        uint256 time = block.timestamp.sub(lockTime);
         
        uint256 percent = 250;
         
        if(time >= 30 days) {
            percent = percent.add( (((time.sub(30 days)).div (1 days)).add (1)).mul (5));
        }
        percent = percent > 1000 ? 1000 : percent;
        uint256 avail = fundLocked[_to];
        require(avail>0);
        avail = avail.mul(percent).div(1000).sub(fundUsed[_to]);
        return avail ;
    }
     
    function teamLock(address _to,uint256 _value) internal {
        require(_value>0);
        teamLocked[_to] = teamLocked[_to].add(_value);
        teamReverse[_to] = teamReverse[_to].add(_value);
        teamLockTime[_to] = block.timestamp;   
    }
     
    function fundLock(address _to,uint256 _value) internal {
        require(_value>0);
        fundLocked[_to] =fundLocked[_to].add(_value);
        fundReverse[_to] = fundReverse[_to].add(_value);
        if(fundLockTime[_to] == 0)
          fundLockTime[_to] = block.timestamp;   
    }

     
    function teamLockTransfer(address _to, uint256 _value) internal returns (bool) {
         
       uint256 availReverse = balances[msg.sender].sub((teamLocked[msg.sender].sub(teamUsed[msg.sender]))+(fundLocked[msg.sender].sub(fundUsed[msg.sender])));
       uint256 totalAvail=0;
       uint256 availTeam =0;
       if(issueDate==0)
        {
             totalAvail = availReverse;
        }
        else{
             
             availTeam = teamAvailable(msg.sender);
              
             totalAvail = availTeam.add(availReverse);
        }
        require(_value <= totalAvail);
        bool ret = super.transfer(_to,_value);
        if(ret == true && issueDate>0) {
             
            if(_value > availTeam){
                teamUsed[msg.sender] = teamUsed[msg.sender].add(availTeam);
                 teamReverse[msg.sender] = teamReverse[msg.sender].sub(availTeam);
          }
             
            else{
                teamUsed[msg.sender] = teamUsed[msg.sender].add(_value);
                teamReverse[msg.sender] = teamReverse[msg.sender].sub(_value);
            }
        }
        if(teamUsed[msg.sender] >= teamLocked[msg.sender]){
            delete teamLockTime[msg.sender];
            delete teamReverse[msg.sender];
        }
        return ret;
    }

     
    function teamLockTransferFrom(address _from,address _to, uint256 _value) internal returns (bool) {
        
       uint256 availReverse = balances[_from].sub((teamLocked[_from].sub(teamUsed[_from]))+(fundLocked[_from].sub(fundUsed[_from])));
       uint256 totalAvail=0;
       uint256 availTeam =0;
        if(issueDate==0)
        {
             totalAvail = availReverse;
        }
        else{
             
             availTeam = teamAvailable(_from);
               
             totalAvail = availTeam.add(availReverse);
        }
       require(_value <= totalAvail);
        bool ret = super.transferFrom(_from,_to,_value);
        if(ret == true && issueDate>0) {
             
            if(_value > availTeam){
                teamUsed[_from] = teamUsed[_from].add(availTeam);
                teamReverse[_from] = teamReverse[_from].sub(availTeam);
           }
             
            else{
                teamUsed[_from] = teamUsed[_from].add(_value);
                teamReverse[_from] = teamReverse[_from].sub(_value);
            }
        }
        if(teamUsed[_from] >= teamLocked[_from]){
            delete teamLockTime[_from];
            delete teamReverse[_from];
        }
        return ret;
    }

     
    function fundLockTransfer(address _to, uint256 _value) internal returns (bool) {
       
       uint256 availReverse = balances[msg.sender].sub((teamLocked[msg.sender].sub(teamUsed[msg.sender]))+(fundLocked[msg.sender].sub(fundUsed[msg.sender])));
       uint256 totalAvail=0;
       uint256 availFund = 0;
        if(issueDate==0)
        {
             totalAvail = availReverse;
        }
        else{
             require(now>issueDate);
             
             availFund = fundAvailable(msg.sender);
              
             totalAvail = availFund.add(availReverse);
        }
        require(_value <= totalAvail);
        bool ret = super.transfer(_to,_value);
        if(ret == true && issueDate>0) {
             
            if(_value > availFund){
                fundUsed[msg.sender] = fundUsed[msg.sender].add(availFund);
                fundReverse[msg.sender] = fundReverse[msg.sender].sub(availFund);
             }
             
            else{
                fundUsed[msg.sender] =  fundUsed[msg.sender].add(_value);
                fundReverse[msg.sender] = fundReverse[msg.sender].sub(_value);
            }
        }
        if(fundUsed[msg.sender] >= fundLocked[msg.sender]){
            delete fundLockTime[msg.sender];
            delete fundReverse[msg.sender];
        }
        return ret;
    }


     
    function fundLockTransferFrom(address _from,address _to, uint256 _value) internal returns (bool) {
          
        uint256 availReverse =  balances[_from].sub((teamLocked[_from].sub(teamUsed[_from]))+(fundLocked[_from].sub(fundUsed[_from])));
        uint256 totalAvail=0;
        uint256 availFund = 0;
        if(issueDate==0)
         {
             totalAvail = availReverse;
        }
        else{
             require(now>issueDate);
              
             availFund = fundAvailable(_from);
               
             totalAvail = availFund.add(availReverse);
         }
      
        require(_value <= totalAvail);
        bool ret = super.transferFrom(_from,_to,_value);
        if(ret == true && issueDate>0) {
            
            if(_value > availFund){
                fundUsed[_from] = fundUsed[_from].add(availFund);
                fundReverse[_from] = fundReverse[_from].sub(availFund);
            }
             
            else{
                fundUsed[_from] =  fundUsed[_from].add(_value);
                fundReverse[_from] = fundReverse[_from].sub(_value);
            }
        }
        if(fundUsed[_from] >= fundLocked[_from]){
            delete fundLockTime[_from];
        }
        return ret;
    }
}

 
contract HitToken is Lock {
    string public name;
    string public symbol;
    uint8 public decimals;
     
    uint256  public precentDecimal = 2;
     
    uint256 public mainFundPrecent = 2650; 
     
    uint256 public subFundPrecent = 350; 
     
    uint256 public devTeamPrecent = 1500;
     
    uint256 public hitFoundationPrecent = 5500;
     
    uint256 public  mainFundBalance;
     
    uint256 public subFundBalance;
     
    uint256 public  devTeamBalance;
     
    uint256 public hitFoundationBalance;
     
    address public subFundAccount;
     
    address public mainFundAccount;
    

     
    function HitToken(string _name, string _symbol, uint8 _decimals, uint256 _initialSupply,address _teamAccount,address _subFundAccount,address _mainFundAccount,address _hitFoundationAccount) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
         
        subFundAccount = _subFundAccount;
         
        mainFundAccount = _mainFundAccount;
         
        totalSupply_ = _initialSupply * 10 ** uint256(_decimals);
         
        mainFundBalance =  totalSupply_.mul(mainFundPrecent).div(100* 10 ** precentDecimal) ;
         
        subFundBalance =  totalSupply_.mul(subFundPrecent).div(100* 10 ** precentDecimal);
         
        devTeamBalance =  totalSupply_.mul(devTeamPrecent).div(100* 10 ** precentDecimal);
         
        hitFoundationBalance = totalSupply_.mul(hitFoundationPrecent).div(100* 10 ** precentDecimal) ;
         
        balances[_hitFoundationAccount] = hitFoundationBalance; 
         
        balances[_teamAccount] = devTeamBalance;
         
        balances[_subFundAccount] = subFundBalance;
          
        balances[_mainFundAccount]=mainFundBalance;
         
        teamLock(_teamAccount,devTeamBalance);
        
    }

     
    function burn(uint256 _value) public onlyOwner returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[address(0)] = balances[address(0)].add(_value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        if(issueDate==0)
        {
              
            require(msg.sender != mainFundAccount);
        }

        if(teamLockTime[msg.sender] > 0){
             return super.teamLockTransfer(_to,_value);
            }else if(fundLockTime[msg.sender] > 0){
                return super.fundLockTransfer(_to,_value);
            }else {
               return super.transfer(_to, _value);
            
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
          if(issueDate==0)
        {
               
            require(_from != mainFundAccount);
        }
      
        if(teamLockTime[_from] > 0){
            return super.teamLockTransferFrom(_from,_to,_value);
        }else if(fundLockTime[_from] > 0 ){  
            return super.fundLockTransferFrom(_from,_to,_value);
        }else{
            return super.transferFrom(_from, _to, _value);
        }
    }

     
    function mintFund(address _to, uint256 _value) public  returns (bool){
        require(msg.sender==mainFundAccount);
        require(mainFundBalance >0);
        require(_value >0);
        if(_value <= mainFundBalance){
            super.transfer(_to,_value);
            fundLock(_to,_value);
            mainFundBalance = mainFundBalance.sub(_value);
        }
    }

      
     function issue() public onlyOwner  returns (uint){
          
         require(issueDate==0);
         issueDate = now;
         return now;
     }
     
      
     function() public payable{
         revert();
     }
     
   
}