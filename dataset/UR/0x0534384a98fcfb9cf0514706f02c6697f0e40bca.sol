 

pragma solidity ^0.5.0;

 
 
 
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

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract Owned {
    constructor() public { owner = msg.sender; }
    address payable owner;

     
     
     
     
     
     
     
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
}

 
 
interface HEX{
	
	 
	
    struct XfLobbyEntryStore {
        uint96 rawAmount;
        address referrerAddr;
    }
	
    struct XfLobbyQueueStore {
        uint40 headIndex;
        uint40 tailIndex;
        mapping(uint256 => XfLobbyEntryStore) entries;
    }
	
	function xfLobbyMembers(uint256 i, address _XfLobbyQueueStore) external view returns(uint40 headIndex, uint40 tailIndex);
	function xfLobbyEnter(address referrerAddr) external payable;
	function currentDay() external view returns (uint256);
	function xfLobbyExit(uint256 enterDay, uint256 count) external;
	
	
	 
	 
	
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
 
contract ERC20Distributor is Owned{
	using SafeMath for uint256;
	
    IERC20 public handledToken;
    
    struct Account {
        address addy;
        uint256 share;
    }
    
	Account[] accounts;
    uint256 totalShares = 0;
	uint256 totalAccounts = 0;
	uint256 fullViewPercentage = 10000;
	
     
    constructor(IERC20 _token) public {
        handledToken = _token;
    }
	
	function getGlobals() public view returns(
		uint256 _tokenBalance, 
		uint256 _totalAccounts, 
		uint256 _totalShares, 
		uint256 _fullViewPercentage){
		return (
			handledToken.balanceOf(address(this)), 
			totalAccounts, 
			totalShares, 
			fullViewPercentage
		);
	}
	
	function getAccountInfo(uint256 index) public view returns(
		uint256 _tokenBalance,
		uint256 _tokenEntitled,
		uint256 _shares, 
		uint256 _percentage,
		address _address){
		return (
			handledToken.balanceOf(accounts[index].addy),
			(accounts[index].share.mul(handledToken.balanceOf(address(this)))).div(totalShares),
			accounts[index].share, 
			(accounts[index].share.mul(fullViewPercentage)).div(totalShares), 
			accounts[index].addy
		);
	}

    function writeAccount(address _address, uint256 _share) public onlyOwner {
        require(_address != address(0), "address can't be 0 address");
        require(_address != address(this), "address can't be this contract address");
        require(_share > 0, "share must be more than 0");
		deleteAccount(_address);
        Account memory acc = Account(_address, _share);
        accounts.push(acc);
        totalShares += _share;
		totalAccounts++;
    }
    
    function deleteAccount(address _address) public onlyOwner{
        for(uint i = 0; i < accounts.length; i++)
        {
			if(accounts[i].addy == _address){
				totalShares -= accounts[i].share;
				if(i < accounts.length - 1){
					accounts[i] = accounts[accounts.length - 1];
				}
				delete accounts[accounts.length - 1];
				accounts.length--;
				totalAccounts--;
			}
		}
    }
 
    function distributeTokens() public payable { 
		uint256 sharesProcessed = 0;
		uint256 currentAmount = handledToken.balanceOf(address(this));
		
        for(uint i = 0; i < accounts.length; i++)
        {
			if(accounts[i].share > 0 && accounts[i].addy != address(0)){
				uint256 amount = (currentAmount.mul(accounts[i].share)).div(totalShares.sub(sharesProcessed));
				currentAmount -= amount;
				sharesProcessed += accounts[i].share;
				handledToken.transfer(accounts[i].addy, amount);
			}
		}
    }
	
	function withdrawERC20(IERC20 _token) public payable onlyOwner{
		require(_token.balanceOf(address(this)) > 0);
		_token.transfer(owner, _token.balanceOf(address(this)));
	}
}

 

contract HEXAutomator is Owned{
	HEX public HEXcontract = HEX(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39);
	ERC20Distributor public Distributor;
	
	bool public autoDistribution = true;
	uint256 public distributionWeekday = 5; 
	uint256 public distributionCycle = 1;
	uint256 public distributionCycleCounter = 0;
	
	constructor(ERC20Distributor _distAddr) public {
        Distributor = ERC20Distributor(_distAddr);
    }
	
	function () payable external{
		require(msg.value > 0);
		
		 
		HEXcontract.xfLobbyEnter.value(msg.value)(address(this));
		
		 
		selfLobbyExitAll();
		
		 
		withdrawHEXToDistributor();
		
		 
		checkAutoDistribution();
	}
	
	 
	function hexCurrentDay() public view 
		returns(uint256 currentDay){
		return HEXcontract.currentDay();
	}
	
	 
	 
	function getOpenLobbyDays() public view returns(
		uint256[] memory openLobbyDays,
		uint256 openLobbyDaysCount
	){
		uint256 currentDay = hexCurrentDay();
		openLobbyDaysCount = 0;
		
		uint256[] memory openLobbyDaysIterator = new uint256[](currentDay + 1);
		
		for(uint256 i = 0; i <= currentDay; i++)
		{
			(uint40 HEX_headIndex, uint40 HEX_tailIndex) = 
			    HEXcontract.xfLobbyMembers(i, address(this));
			if(HEX_tailIndex > 0 && HEX_headIndex < HEX_tailIndex){
				openLobbyDaysIterator[i] = i + 1;
				openLobbyDaysCount++;
			}
		}
		
		uint256 counter = 0; 
		
		openLobbyDays = new uint256[](openLobbyDaysCount);
		
		for(uint i = 0; i <= currentDay; i++)
		{
			if(openLobbyDaysIterator[i] != 0){
				openLobbyDays[counter] = openLobbyDaysIterator[i] - 1;
				counter++;
			}
		}
		
		return (openLobbyDays, openLobbyDaysCount);
	}
	
	 
	function selfLobbyExitAll() public {
		uint256[] memory openLobbyDays;
		
		(openLobbyDays,) = getOpenLobbyDays();
		
		for(uint i = 0; i < openLobbyDays.length; i++)
		{
			if(openLobbyDays[i] < hexCurrentDay()){
				selfLobbyExit(openLobbyDays[i], 0);
			}
		}
	}
	
	 
	 
	function selfLobbyExit(uint256 _enterDay, uint256 _count) public {
		
		require(_enterDay < hexCurrentDay());
		
		(uint40 HEX_headIndex, uint40 HEX_tailIndex) = 
			HEXcontract.xfLobbyMembers(_enterDay, address(this));
			
		if(HEX_tailIndex > 0 && HEX_headIndex < HEX_tailIndex){
			HEXcontract.xfLobbyExit(_enterDay, _count);
			distributionCycleCounter++;
		}
	}
	
	 
	function withdrawHEXToDistributor() public {
		uint256 HEX_balance = HEXcontract.balanceOf(address(this));
		if(HEX_balance > 0){
			HEXcontract.transfer(address(Distributor), HEX_balance);
		}
	}
	
	 
	 
	function checkAutoDistribution() private {
		if(autoDistribution){
			if((distributionWeekday != 0 && (hexCurrentDay() + 7 - distributionWeekday) % 7 == 0) || 
				(distributionCycle != 0 && distributionCycleCounter >= distributionCycle)){
				if(HEXcontract.balanceOf(address(Distributor)) > 0){
					distributionCycleCounter = 0;
					Distributor.distributeTokens();
				}
			}
		}
	}
	
	 
	function changeDistributor(ERC20Distributor _distAddr) public onlyOwner{
        Distributor = ERC20Distributor(_distAddr);
	}
	
	 
	function switchAutoDistribution() public onlyOwner{
		if(autoDistribution){
			autoDistribution = false;
		} else {
			autoDistribution = true;
		}
	}
	
	 
	 
	function changeDistributionWeekday(int256 _weekday) public onlyOwner{
		require(_weekday >= -1, "_weekday must be between -1 to 6");
		require(_weekday <= 6, "_weekday must be between -1 to 6");
		if(_weekday >= 0){
			distributionWeekday = 5 + uint256(_weekday);
			 
			 
		} else {
			distributionWeekday = 0;
		}
	}
	
	 
	 
	function changeDistributionCycle(uint256 _cycle) public onlyOwner{
		require(_cycle < 350, "Can't go higher than 350 cycles/days");
		distributionCycle = _cycle;
	}
		
	 
	 
	function withdrawERC20(IERC20 _token) public onlyOwner {
		require(_token.balanceOf(address(this)) > 0, "no balance");
		_token.transfer(owner, _token.balanceOf(address(this)));
	}

	 
	 
	 
	function kill(bool _die) public onlyOwner {
		require(_die);
		selfdestruct(owner);
	}
}