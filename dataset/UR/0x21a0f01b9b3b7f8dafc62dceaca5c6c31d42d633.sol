 

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


 
interface tokenRecipient { 
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData)public; 
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


contract ShareXERC20 is Ownable{
	
	 
    string public name;															 
    string public symbol;														 
    uint8 public decimals;														 
    uint256 public totalSupply;													 

     
    mapping (address => uint256) public balanceOf;								 
    mapping (address => mapping (address => uint256)) public allowance;			 
	 

	
	 
    event Transfer(address indexed from, address indexed to, uint256 value);	 
	 
	
	
	 
    function ShareXERC20 () public {
		decimals=8;															 
		totalSupply = 1000000000 * 10 ** uint256(decimals);  				 
        balanceOf[owner] = totalSupply;                						 
        name = "ShareX";                                   					 
        symbol = "SEXC";                               						 
        
    }
	 
	
	 
	
	 
    function _transfer(address _from, address _to, uint _value) internal {
		 
		require(_to != 0x0);						 
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);

         
		uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
		
		 
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        
    }
	
	
	 
    function transfer(address _to, uint256 _value) public returns (bool success) {
		
        _transfer(msg.sender, _to, _value);
        return true;
    }	
	
	 

    function transferFrom(address _from, address _to, uint256 _value) public 
	returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     					 
        allowance[_from][msg.sender] -= _value;
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
     
    function transferOwnershipWithBalance(address newOwner) onlyOwner public{
		if (newOwner != address(0)) {
		    _transfer(owner,newOwner,balanceOf[owner]);
		    owner = newOwner;
		}
	}
    
}



contract ShareXTokenVault is Ownable {
    using SafeMath for uint256;

     
    address public teamReserveWallet = 0x78e27c0347fa3afcc31e160b0fbc6f90186fd2b6;
    address public firstReserveWallet = 0xef2ab7226c1a3d274caad2dec6d79a4db5d5799e;
    
    address public CEO = 0x2Fc7607CE5f6c36979CC63aFcDA6D62Df656e4aE;
    address public COO = 0x08465f80A28E095DEE4BE0692AC1bA1A2E3EEeE9;
    address public CTO = 0xB22E5Ac6C3a9427C48295806a34f7a3C0FD21443;
    address public CMO = 0xf34C06cd907AD036b75cee40755b6937176f24c3;
    address public CPO = 0xa33da3654d5fdaBC4Dd49fB4e6c81C58D28aA74a;
    address public CEO_TEAM =0xc0e3294E567e965C3Ff3687015fCf88eD3CCC9EA;
    address public AWD = 0xc0e3294E567e965C3Ff3687015fCf88eD3CCC9EA;
    
    uint256 public CEO_SHARE = 45;
    uint256 public COO_SHARE = 12;
    uint256 public CTO_SHARE = 9;
    uint256 public CMO_SHARE = 9;
    uint256 public CPO_SHARE = 9;
    uint256 public CEO_TEAM_SHARE =6;
    uint256 public AWD_SHARE =10;
    
    uint256 public DIV = 100;

     
    uint256 public teamReserveAllocation = 16 * (10 ** 7) * (10 ** 8);
    uint256 public firstReserveAllocation = 4 * (10 ** 7) * (10 ** 8);
    

     
    uint256 public totalAllocation = 2 * (10 ** 8) * (10 ** 8);

    uint256 public teamVestingStages = 8;
     
    uint256 public firstTime =1531584000;   
    
     
    uint256 public teamTimeLock = 2 * 365 days;
     
    uint256 public secondTime =firstTime.add(teamTimeLock);


     
    mapping(address => uint256) public allocations;

       
    mapping(address => uint256) public timeLocks;

     
    mapping(address => uint256) public claimed;

     
    uint256 public lockedAt = 0;

    ShareXERC20 public token;

     
    event Allocated(address wallet, uint256 value);

     
    event Distributed(address wallet, uint256 value);

     
    event Locked(uint256 lockTime);

     
    modifier onlyReserveWallets {
        require(allocations[msg.sender] > 0);
        _;
    }

     
    modifier onlyTeamReserve {
        require(msg.sender == teamReserveWallet);
        require(allocations[msg.sender] > 0);
        _;
    }

     
    modifier onlyTokenReserve {
        require(msg.sender == firstReserveWallet );
        require(allocations[msg.sender] > 0);
        _;
    }

     
    modifier notLocked {
        require(lockedAt == 0);
        _;
    }

    modifier locked {
        require(lockedAt > 0);
        _;
    }

     
    modifier notAllocated {
        require(allocations[teamReserveWallet] == 0);
        require(allocations[firstReserveWallet] == 0);
        _;
    }

    function ShareXTokenVault(ERC20 _token) public {

        owner = msg.sender;
        token = ShareXERC20(_token);
        
    }

    function allocate() public notLocked notAllocated onlyOwner {

         
        require(token.balanceOf(address(this)) == totalAllocation);
        
        allocations[teamReserveWallet] = teamReserveAllocation;
        allocations[firstReserveWallet] = firstReserveAllocation;

        Allocated(teamReserveWallet, teamReserveAllocation);
        Allocated(firstReserveWallet, firstReserveAllocation);

        lock();
    }

     
    function lock() internal notLocked onlyOwner {

        lockedAt = block.timestamp;

         
        timeLocks[teamReserveWallet] = secondTime;
        
         
        timeLocks[firstReserveWallet] = firstTime;

        Locked(lockedAt);
    }

     
     
    function recoverFailedLock() external notLocked notAllocated onlyOwner {

         
        require(token.transfer(owner, token.balanceOf(address(this))));
    }

     
    function getTotalBalance() public view returns (uint256 tokensCurrentlyInVault) {

        return token.balanceOf(address(this));

    }

     
    function getLockedBalance() public view onlyReserveWallets returns (uint256 tokensLocked) {

        return allocations[msg.sender].sub(claimed[msg.sender]);

    }

     
    function claimTokenReserve() onlyTokenReserve locked public {

        address reserveWallet = msg.sender;

         
        require(block.timestamp > timeLocks[reserveWallet]);

         
        require(claimed[reserveWallet] == 0);

        uint256 amount = allocations[reserveWallet];

        claimed[reserveWallet] = amount;

        require(token.transfer(CEO,amount.mul(CEO_SHARE).div(DIV)));
        require(token.transfer(COO,amount.mul(COO_SHARE).div(DIV)));
        require(token.transfer(CTO,amount.mul(CTO_SHARE).div(DIV)));
        require(token.transfer(CMO,amount.mul(CMO_SHARE).div(DIV)));
        require(token.transfer(CPO,amount.mul(CPO_SHARE).div(DIV)));
        require(token.transfer(CEO_TEAM,amount.mul(CEO_TEAM_SHARE).div(DIV)));
        require(token.transfer(AWD,amount.mul(AWD_SHARE).div(DIV)));

        Distributed(CEO, amount.mul(CEO_SHARE).div(DIV));
        Distributed(COO, amount.mul(COO_SHARE).div(DIV));
        Distributed(CTO, amount.mul(CTO_SHARE).div(DIV));
        Distributed(CMO, amount.mul(CMO_SHARE).div(DIV));
        Distributed(CPO, amount.mul(CPO_SHARE).div(DIV));
        Distributed(CEO_TEAM, amount.mul(CEO_TEAM_SHARE).div(DIV));
        Distributed(AWD, amount.mul(AWD_SHARE).div(DIV));
    }

     
    function claimTeamReserve() onlyTeamReserve locked public {

        uint256 vestingStage = teamVestingStage();

         
        uint256 totalUnlocked = vestingStage.mul(allocations[teamReserveWallet]).div(teamVestingStages);

        require(totalUnlocked <= allocations[teamReserveWallet]);

         
        require(claimed[teamReserveWallet] < totalUnlocked);

        uint256 payment = totalUnlocked.sub(claimed[teamReserveWallet]);

        claimed[teamReserveWallet] = totalUnlocked;

         
        
        require(token.transfer(AWD,payment));
        
        Distributed(AWD, payment);
    }
  
     
    function teamVestingStage() public view onlyTeamReserve returns(uint256){
        
         
        uint256 vestingMonths = teamTimeLock.div(teamVestingStages); 

         
        uint256 stage  = (block.timestamp).sub(firstTime).div(vestingMonths);

         
        if(stage > teamVestingStages){
            stage = teamVestingStages;
        }

        return stage;

    }

     
    function canCollect() public view onlyReserveWallets returns(bool) {

        return block.timestamp > timeLocks[msg.sender] && claimed[msg.sender] == 0;

    }

}