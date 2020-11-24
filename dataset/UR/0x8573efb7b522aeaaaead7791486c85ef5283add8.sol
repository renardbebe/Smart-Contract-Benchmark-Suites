 

 


pragma solidity ^0.5.8;

library SafeMath{
	 function add(uint a, uint b) internal pure returns(uint c)
	 {
	 	c=a+b;
		require(c>=a);
	 }
	 function sub(uint a, uint b) internal pure returns(uint c)
	 {
		c=a-b;
		require(c<=a);	 
	 }
	 function mul(uint a, uint b) internal pure returns(uint c)
	 {
		c=a*b;	 
		require(a==0||c/a==b);
	 }
	 function div(uint a,uint b) internal pure returns(uint c)
	 {
		require(b>0);
		c = a/b;	 
	 }
}

contract Owned{
	address public owner;
	address public newOwner;
	
	event OwnershipTransferred(address indexed _from, address indexed _to);
	
	constructor() public{
		owner=msg.sender;	
	}
	modifier onlyOwner{
		require(msg.sender==owner);
		_;	
	}
	function transferOwnership(address _newOwner) public onlyOwner
	{
		newOwner=_newOwner;	
	}
	function acceptOwnership() public{
		require(msg.sender==newOwner);
		emit OwnershipTransferred(owner,newOwner);
		owner=newOwner;
		newOwner=address(0);	
	}

}

contract GroupOwned is Owned{
    
    event GroupTransferred(address indexed from,address indexed to);
    
     
    mapping(bytes => mapping(address => int8)) public groups;
   
    

    modifier onlySuperior(bytes memory gname,address subject){
        require((groups[gname][msg.sender]>groups[gname][subject])||(msg.sender==owner));
        _;
    }
    
    modifier onlyGroup(bytes memory gname,int8 level)
    {
        require(groups[gname][msg.sender]>=level);
        _;
    }
   
    function groupmod(bytes memory gname,address user,int8 priority) internal returns(bool)
    {
        groups[gname][user]=priority;
        return true;
    }

    function CGroupMod(bytes memory gname, address user,int8 priority) public onlySuperior(gname,user) returns(bool)
    {		  
		  require((groups[gname][msg.sender]>priority)||(msg.sender==owner));
        if(groupmod(gname,user,priority))
        {
            return true;
        }
        return false;
    }  
 }

contract Child is Owned,GroupOwned
{
	address public root;
	address public token;
	
	function setRoot(address newroot) public onlyGroup('child_manage',2) returns(bool)
	{
		root=newroot;
		return true;	
	}
	
	function setToken(address newToken) public onlyGroup('child_manage',2) returns (bool)
	{
		token=newToken;
		return true;	
	}
}


contract ERC20Interface
{
    function balanceOf(address tokenOwner) public view returns(uint balance);
    function transfer(address to,uint tokens) public returns(bool success);
    
}

contract CC_ICO is Owned,GroupOwned,Child{
	 using SafeMath for uint;
    string public name;
    string public symbol;
    
    uint256 public sellcap;
    uint256 public qEC;
    uint256 public decimals;
    
	 event SellCapSet(uint256 indexed sc);    
    
    constructor() public 
    {
        name="*** CrackCoin Token Sale #1 ***";
        symbol="CRK ICO #1";
        qEC=100;
        decimals=18;
    }
    
    function setqEC(uint256 _qec) public onlyOwner returns(bool)
    {
        qEC=_qec;
        return true;
    }
    
     
     
    
    function setSellCap(uint256 amount) public onlyOwner returns(bool)
    {
		ERC20Interface coin=ERC20Interface(token);
		require(coin.balanceOf(address(this))>=amount);    	
    	sellcap=amount;
    	emit SellCapSet(sellcap);
	   return true;    
    }

	 function () payable external
	 {
	 	uint256 amCC=qEC.mul(msg.value);	
	 	ERC20Interface coin=ERC20Interface(token);
	 	if(amCC>coin.balanceOf(address(this))||amCC>sellcap)
	 	{
			msg.sender.transfer(msg.value);
	 	}
	 	else{
	 		coin.transfer(msg.sender,amCC);
			uint256 newBal=coin.balanceOf(address(this)); 
			if(sellcap>newBal)
			{
				sellcap=newBal;
			}	 
		}
	 }
	 
	 function wdCRCK(address wdloc,uint256 amount) public payable onlyOwner returns(bool)
	 {
		require(msg.sender==owner);
		ERC20Interface coin=ERC20Interface(token);
		uint256 bal=coin.balanceOf(address(this));
		require(bal>=amount);	 
		coin.transfer(wdloc,amount);	
		uint256 newBal=coin.balanceOf(address(this)); 
		if(sellcap>newBal)
		{
			sellcap=newBal;
		}
	 	return true;	 
	 }
	 
	 function wdEther(address wdloc,uint256 amount)	public onlyOwner returns(bool)
	 {
		 require(msg.sender==owner);	 	
		 require(address(this).balance>=amount);
		 address payable wd=address(uint160(wdloc));
		 wd.send(amount);
		 return true;	 
	 } 
}