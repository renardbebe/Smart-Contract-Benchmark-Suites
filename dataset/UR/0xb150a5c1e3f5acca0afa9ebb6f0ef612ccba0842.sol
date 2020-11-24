 

pragma solidity ^0.4.23;

contract EIP20Interface {

    uint256 public totalSupply;
    uint256 public decimals;
    
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract OwnableContract {
 
    address superOwner;
		
	constructor() public { 
        superOwner = msg.sender;  
    }
	
	modifier onlyOwner() {
        require(msg.sender == superOwner);
        _;
    } 
    
    function viewSuperOwner() public view returns (address owner) {
        return superOwner;
    }
    
	function changeOwner(address newOwner) onlyOwner public {
        superOwner = newOwner;
    }
}


contract BlockableContract is OwnableContract{
 
    bool public blockedContract;
	
	constructor() public { 
        blockedContract = false;  
    }
	
	modifier contractActive() {
        require(!blockedContract);
        _;
    } 
	
	function doBlockContract() onlyOwner public {
        blockedContract = true;
    }
    
    function unBlockContract() onlyOwner public {
        blockedContract = false;
    }
}

contract Hodl is BlockableContract{
    
    struct Safe{
        uint256 id;
        address user;
        address tokenAddress;
        uint256 amount;
        uint256 time;
    }
    
     
    mapping( address => uint256[]) public _userSafes;
    mapping( uint256 => Safe) private _safes;
    uint256 private _currentIndex;
    
    mapping( address => uint256) public _totalSaved;
     
     
    uint256 public comission;  
    mapping( address => uint256) private _systemReserves;
    address[] public _listedReserves;
     
     
    constructor() public { 
        _currentIndex = 1;
        comission = 10;
    }
    
 
    function () public payable {
        require(msg.value>0);
        _systemReserves[0x0] = add(_systemReserves[0x0], msg.value);
    }
    
 
    function GetUserSafesLength(address a) public view returns (uint256 length) {
        return _userSafes[a].length;
    }
    
 
    function GetReserveAmount(address tokenAddress) public view returns (uint256 amount){
        return _systemReserves[tokenAddress];
    }
    
 
    function Getsafe(uint256 _id) public view
        returns (uint256 id, address user, address tokenAddress, uint256 amount, uint256 time)
    {
        Safe storage s = _safes[_id];
        return(s.id, s.user, s.tokenAddress, s.amount, s.time);
    }
    
    
 
    function HodlEth(uint256 time) public contractActive payable {
        require(msg.value > 0);
        require(time>now);
        
        _userSafes[msg.sender].push(_currentIndex);
        _safes[_currentIndex] = Safe(_currentIndex, msg.sender, 0x0, msg.value, time); 
        
        _totalSaved[0x0] = add(_totalSaved[0x0], msg.value);
        
        _currentIndex++;
    }
    
 
    function ClaimHodlToken(address tokenAddress, uint256 amount, uint256 time) public contractActive {
        require(tokenAddress != 0x0);
        require(amount>0);
        require(time>now);
          
        EIP20Interface token = EIP20Interface(tokenAddress);
        require( token.transferFrom(msg.sender, address(this), amount) );
        
        _userSafes[msg.sender].push(_currentIndex);
        _safes[_currentIndex] = Safe(_currentIndex, msg.sender, tokenAddress, amount, time);
        
        _totalSaved[tokenAddress] = add(_totalSaved[tokenAddress], amount);
        
        _currentIndex++;
    }
    
 
    function UserRetireHodl(uint256 id) public {
        Safe storage s = _safes[id];
        
        require(s.id != 0);
        require(s.user == msg.sender);
        
        RetireHodl(id);
    }
    
 
    function RetireHodl(uint256 id) private {
        Safe storage s = _safes[id]; 
        require(s.id != 0); 
        
        if(s.time < now)  
        {
            if(s.tokenAddress == 0x0) 
                PayEth(s.user, s.amount);
            else  
                PayToken(s.user, s.tokenAddress, s.amount);
        }
        else  
        {
            uint256 realComission = mul(s.amount, comission) / 100;
            uint256 realAmount = sub(s.amount, realComission);
            
            if(s.tokenAddress == 0x0) 
                PayEth(s.user, realAmount);
            else  
                PayToken(s.user, s.tokenAddress, realAmount);
                
            StoreComission(s.tokenAddress, realComission);
        }
        
        DeleteSafe(s);
    }
    
 
    function PayEth(address user, uint256 amount) private {
        require(address(this).balance >= amount);
        user.transfer(amount);
    }
    
 
    function PayToken(address user, address tokenAddress, uint256 amount) private{
        EIP20Interface token = EIP20Interface(tokenAddress);
        require(token.balanceOf(address(this)) >= amount);
        token.transfer(user, amount);
    }
    
 
    function StoreComission(address tokenAddress, uint256 amount) private {
        _systemReserves[tokenAddress] = add(_systemReserves[tokenAddress], amount);
        
        bool isNew = true;
        for(uint256 i = 0; i < _listedReserves.length; i++) {
            if(_listedReserves[i] == tokenAddress) {
                isNew = false;
                break;
            }
        } 
        
        if(isNew) _listedReserves.push(tokenAddress); 
    }
    
 
    function DeleteSafe(Safe s) private  {
        _totalSaved[s.tokenAddress] = sub(_totalSaved[s.tokenAddress], s.amount);
        delete _safes[s.id];
        
        uint256[] storage vector = _userSafes[msg.sender];
        uint256 size = vector.length; 
        for(uint256 i = 0; i < size; i++) {
            if(vector[i] == s.id) {
                vector[i] = vector[size-1];
                vector.length--;
                break;
            }
        } 
    }
    
    
 
    function OwnerRetireHodl(uint256 id) public onlyOwner {
        Safe storage s = _safes[id]; 
        require(s.id != 0); 
        RetireHodl(id);
    }

 
    function ChangeComission(uint256 newComission) onlyOwner public {
        comission = newComission;
    }
    
 
    function WithdrawReserve(address tokenAddress) onlyOwner public
    {
        require(_systemReserves[tokenAddress] > 0);
        
        uint256 amount = _systemReserves[tokenAddress];
        _systemReserves[tokenAddress] = 0;
        
        EIP20Interface token = EIP20Interface(tokenAddress);
        require(token.balanceOf(address(this)) >= amount);
        token.transfer(msg.sender, amount);
    }
    
 
    function WithdrawAllReserves() onlyOwner public {
         
        uint256 x = _systemReserves[0x0];
        if(x > 0 && x <= address(this).balance) {
            _systemReserves[0x0] = 0;
            msg.sender.transfer( _systemReserves[0x0] );
        }
         
         
        address ta;
        EIP20Interface token;
        for(uint256 i = 0; i < _listedReserves.length; i++) {
            ta = _listedReserves[i];
            if(_systemReserves[ta] > 0)
            { 
                x = _systemReserves[ta];
                _systemReserves[ta] = 0;
                
                token = EIP20Interface(ta);
                token.transfer(msg.sender, x);
            }
        } 
        
        _listedReserves.length = 0; 
    }
    
 
    function WithdrawSpecialEth(uint256 amount) onlyOwner public
    {
        require(amount > 0); 
        uint256 freeBalance = address(this).balance - _totalSaved[0x0];
        require(freeBalance >= amount); 
        msg.sender.transfer(amount);
    }
    
 
    function WithdrawSpecialToken(address tokenAddress, uint256 amount) onlyOwner public
    {
        EIP20Interface token = EIP20Interface(tokenAddress);
        uint256 freeBalance = token.balanceOf(address(this)) - _totalSaved[tokenAddress];
        require(freeBalance >= amount);
        token.transfer(msg.sender, amount);
    } 
    
    
     
	
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }
    
     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
    
    
}