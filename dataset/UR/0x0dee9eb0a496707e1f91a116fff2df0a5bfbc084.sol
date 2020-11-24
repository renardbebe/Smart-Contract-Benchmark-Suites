 

pragma solidity ^0.5.2;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}





 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) public _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;
    
    
    

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    function transfeFromOwner(address owner,address to, uint256 value) public returns (bool) {
        _transfer(owner, to, value);
        return true;
    }
     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
         

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}


 
contract Ownable {
    address private _owner;
    

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    

}




 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}



contract AladinCoin is ERC20, Ownable, ERC20Detailed {
	uint public initialSupply = 4750000000;
	mapping (address => uint256) public freezeList;
	
	mapping (address => uint256) public whiteList;
	mapping (address => LockItem[]) public lockList;
	mapping (address => LockItemByTime[]) public lockListByTime;
	mapping (uint8 => uint256) public priceList;
	mapping(address => uint256) public addrs;
	
	uint256 currentRound=0;
	uint256 currentPrice = 0;
	uint8 count =0;
	
	
    struct LockItem {
    uint256  round;
    uint256  amount;
    }
    
    struct LockItemByTime {
    uint256  time;
    uint256  amount;
    }
    
    function nextRound() public onlyOwner{
       if(currentRound <= 70)
       {
            currentRound += 1;  
       }
        
    }
    function previousRound() public onlyOwner{
       if(currentRound >=1)
       {
            currentRound -= 1;  
       }
        
    }
    
    function getCurrentRound() public view returns (uint256)
    {
        return currentRound;
    }
     
    function setPrice(uint256  _price) public onlyOwner
    {
         
         
         
        currentPrice = _price;
    }
    
    function getCurrentPrice() public view returns (uint256 _price)
    {
        return currentPrice;
    }
	
	constructor() public ERC20Detailed("OLOCLA", "CLA", 8) 
	{  
		_mint(msg.sender, initialSupply*100000000);
		   
    
    
    
	}


	function isLocked(address lockedAddress) public view returns (bool isLockedAddress)
	{
		if(lockList[lockedAddress].length>0)
		{
		    for(uint i=0; i< lockList[lockedAddress].length; i++)
		    {
		        if(lockList[lockedAddress][i].round <= 11)
		        return true;
		    }
		}
		return false;
	}

	function transfer(address _receiver, uint256 _amount) public returns (bool success)
	{
	    
	    uint256 remain = balanceOf(msg.sender).sub(_amount);
	    require(remain>=getLockedAmount(msg.sender));
	    
		
        return ERC20.transfer(_receiver, _amount);
	}
	
	function getTokenAmount(uint256 _amount) public view returns(uint256)
	{
        return _amount/currentPrice;
	}
	
 
	function round0(address _receiver, uint256 _amount) public onlyOwner
	{
	    if(count<22)
	    {
	       for(uint256 i=12;i<70;i++)
    	    {
    	        transferAndLock(_receiver, _amount*17/10*1/100,i);
    	    }
            transferAndLock(_receiver, _amount*14/10*1/100,70); 
            count +=1;
	    }
	    
	}
 
	function round1(address _receiver, uint256 _amount) public
	{
	    
        require(balanceOf(owner()) >= _amount);
        transferAndLock(_receiver, _amount*3/100,2);
        for(uint i=3;i<=11;i++)
	    {
	        transferAndLock(_receiver, _amount*19/10*1/100,i);
	    }
        for(uint j=12;j<=58;j++)
	    {
	        transferAndLock(_receiver, _amount*17/10*1/100,j);
	    }
	}
 
	function round2(address _receiver, uint256 _amount) public
	{
         
        require(balanceOf(owner()) >= _amount);
        transferAndLock(_receiver,_amount*38/10*1/100,3);
        for(uint i=4;i<=11;i++)
	    {
	        transferAndLock(_receiver, _amount*238/100*1/100,i);
	    }
	    for(uint j=12;j<=46;j++)
	    {
	        transferAndLock(_receiver, _amount*216/100*1/100,j);
	    }
        transferAndLock(_receiver,_amount*156/100*1/100,47);
        
	}
	
 
	function round3(address _receiver, uint256 _amount) public
	{
         
        require(balanceOf(owner()) >= _amount);
        transferAndLock(_receiver,_amount*46/10*1/100, 4);
        for(uint i=5;i<=11;i++)
	    {
	        transferAndLock(_receiver, _amount*29/10*1/100,i);
	    }
	    for(uint j=12;j<=39;j++)
	    {
	        transferAndLock(_receiver, _amount*261/100*1/100,j);
	    }
        transferAndLock(_receiver,_amount*202/100*1/100,40);
	}
	
	
	 
	function round4(address _receiver, uint256 _amount) public
	{
         
        require(balanceOf(owner()) >= _amount);
        transferAndLock(_receiver,_amount*5/100, 5);
        for(uint i=6;i<=11;i++)
	    {
	        transferAndLock(_receiver, _amount*3/100,i);
	    }
	    for(uint j=12;j<=35;j++)
	    {
	        transferAndLock(_receiver, _amount*31/10*1/100,j);
	    }
        transferAndLock(_receiver,_amount*26/10*1/100,36);
	}
	
	 
	function round5(address _receiver, uint256 _amount) public
	{
         
        require(balanceOf(owner()) >= _amount);
        transferAndLock(_receiver,_amount*62/10*1/100, 6);
        for(uint i=7;i<=11;i++)
	    {
	        transferAndLock(_receiver, _amount*39/10*1/100,i);
	    }
	    for(uint j=12;j<=32;j++)
	    {
	        transferAndLock(_receiver, _amount*352/100*1/100,j);
	    }
        transferAndLock(_receiver,_amount*38/100*1/100,33);
	}
	
	 
	function round6(address _receiver, uint256 _amount) public
	{
         
        require(balanceOf(owner()) >= _amount);
        transferAndLock(_receiver,_amount*7/100, 7);
        for(uint i=8;i<=11;i++)
	    {
	        transferAndLock(_receiver, _amount*44/10*1/100,i);
	    }
	    for(uint j=12;j<=29;j++)
	    {
	        transferAndLock(_receiver, _amount*398/100*1/100,j);
	    }
        transferAndLock(_receiver,_amount*376/100*1/100,33);
	}
	
	 
	function round7(address _receiver, uint256 _amount) public
	{
         
        require(balanceOf(owner()) >= _amount);
        transferAndLock(_receiver,_amount*78/10*1/100, 8);
        for(uint i=9;i<=11;i++)
	    {
	        transferAndLock(_receiver, _amount*488/100*1/100,i);
	    }
	    for(uint j=12;j<=28;j++)
	    {
	        transferAndLock(_receiver, _amount*443/100*1/100,j);
	    }
        transferAndLock(_receiver,_amount*225/100*1/100,29);
	}
	
	
	 
	function round8(address _receiver, uint256 _amount) public
	{
         
        require(balanceOf(owner()) >= _amount);
        transferAndLock(_receiver,_amount*86/10*1/100, 9);
        for(uint i=10;i<=11;i++)
	    {
	        transferAndLock(_receiver, _amount*538/100*1/100,i);
	    }
	    for(uint j=12;j<=27;j++)
	    {
	        transferAndLock(_receiver, _amount*489/100*1/100,j);
	    }
        transferAndLock(_receiver,_amount*24/10*1/100,28);
	}

     
	function round9(address _receiver, uint256 _amount) public
	{
         
        require(balanceOf(owner()) >= _amount);
        transferAndLock(_receiver,_amount*94/10*1/100, 10);
        transferAndLock(_receiver, _amount*588/100*1/100,11);
	    
	    for(uint j=12;j<=26;j++)
	    {
	        transferAndLock(_receiver, _amount*534/100*1/100,j);
	    }
        transferAndLock(_receiver,_amount*462/100*1/100,27);
	}

 
	function round10(address _receiver, uint256 _amount) public
	{
         
        require(balanceOf(owner()) >= _amount);
        transferAndLock(_receiver,_amount*102/10*1/100, 11);
	    for(uint j=12;j<=26;j++)
	    {
	        transferAndLock(_receiver, _amount*58/10*1/100,j);
	    }
        transferAndLock(_receiver,_amount*28/10*1/100,27);
	}

	function transferAndLock(address _receiver, uint256 _amount, uint256 _round) public returns (bool success)
	{
        transfeFromOwner(owner(),_receiver,_amount);
        
    	LockItem memory item = LockItem({amount:_amount, round:_round});
		lockList[_receiver].push(item);
	
        return true;
	}
	

	function getLockedListSize(address lockedAddress) public view returns(uint256 _lenght)
	{
	    return lockList[lockedAddress].length;
	}
	function getLockedAmountAtRound(address lockedAddress,uint8 _round) public view returns(uint256 _amount)
	{
	    uint256 lockedAmount =0;
	    for(uint256 j = 0;j<getLockedListSize(lockedAddress);j++)
	    {
	        uint256 round = getLockedTimeAt(lockedAddress,j);
	        if(round==_round)
	        {
	            uint256 temp = getLockedAmountAt(lockedAddress,j);
	            lockedAmount += temp;
	        }
	    }
	    return lockedAmount;
	}
	function getLockedAmountAt(address lockedAddress, uint256 index) public view returns(uint256 _amount)
	{
	    
	    return lockList[lockedAddress][index].amount;
	}
	
	function getLockedTimeAt(address lockedAddress, uint256 index) public view returns(uint256 _time)
	{
	    return lockList[lockedAddress][index].round;
	}

	
	function getLockedAmount(address lockedAddress) public view returns(uint256 _amount)
	{
	    uint256 lockedAmount =0;
	    for(uint256 j = 0;j<getLockedListSize(lockedAddress);j++)
	    {
	        uint256 round = getLockedTimeAt(lockedAddress,j);
	        if(round>currentRound)
	        {
	            uint256 temp = getLockedAmountAt(lockedAddress,j);
	            lockedAmount += temp;
	        }
	    }
	    return lockedAmount;
	}

    function () payable external
    {   
        revert();
    }


}