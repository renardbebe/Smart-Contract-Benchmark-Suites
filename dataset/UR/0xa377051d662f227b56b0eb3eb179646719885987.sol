 

pragma solidity >=0.5;
 
 
 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = tx.origin;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
interface ERC20 {  
    function balanceOf(address _owner) external view returns (uint256 balance); 
    function transfer(address _to, uint256 _value) external returns (bool success) ; 
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success); 
    function approve(address _spender, uint256 _value) external returns (bool success); 
    function allowance(address _owner, address _spender) view external returns (uint256 remaining); 
}

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface IDex { 
    function airdrop(address to,address token,uint256 amount) external;  
    function depositToken(address token, uint256 amount)    external;  
    function deposit() payable external;  
    function withdraw(address token) external;
    function authorizedWithdraw(address to,address token,uint256 amount,uint256 nonce,uint expiredTime,address relayer,uint8 v, bytes32 r,bytes32 s) external;
    function submitWithdrawApplication()  external;
    function cancelWithdrawApplication()  external;
    function balanceOf(address token, address user) view external returns(uint256);
 }

  
contract LiteAirdrop is Ownable {  

    using SafeMath for uint256;
    
    address public _dex;   
 
    mapping( bytes32=> bool)  _claims;
    mapping (address=> bool)  _relayers;
 
    event DepositDex(address indexed token, address indexed user, uint256 amount, uint256 beforeBalance,uint256 balance);
    event WithdrawDex(address indexed token,address indexed user, uint256 amount, uint256 beforeBalance,uint256 balance); 
    event Drop(address indexed token,address sender,address recipient,uint256 amount);
    event Claim(address indexed user,address indexed token,uint256 amount,uint256 nonce); 


    modifier onlyDEXisSet() {
        require( _dex != address(0));
        _;
    }  

    constructor(address dex) public {
        _dex = dex;
    }


      
    function setDex(address dex) public 
        onlyOwner 
    {
        _dex = dex;
    }   

      
    function setRelayer(address relayer, bool isRelayer) public 
        onlyOwner 
    {
        _relayers[relayer] = isRelayer;
    }  
    
      
    function withdraw(address token) public 
        onlyOwner  
   {    
       if(token == address(0))
       {
            msg.sender.transfer(address(this).balance); 
       }else{
            uint256 amount = ERC20(token).balanceOf(address(this));
            ERC20(token).transfer(msg.sender,amount);  
       }  
    } 

      
    function withdrawFromDex(address token) public 
        onlyOwner 
        onlyDEXisSet
   {  
       uint256 balance = _balanceOfDex(token);
     
       require(balance != 0);

       IDex(_dex).withdraw(token);  

       if(token == address(0))
       {
            msg.sender.transfer(balance); 
       }else{
            ERC20(token).transfer(msg.sender,balance);  
       } 

       emit WithdrawDex(token,msg.sender,balance,balance,0); 
    }  

      
    function authorizedWithdraw(address token,uint256 amount,uint256 nonce,uint expiredTime,address relayer,uint8 v, bytes32 r,bytes32 s) 
        public       
        onlyOwner 
        onlyDEXisSet
    {
        uint256 beforeBalance = _balanceOfDex(token);

        require(beforeBalance >= amount);

        IDex(_dex).authorizedWithdraw(address(this),token,amount,nonce,expiredTime,relayer,v, r,s );  

        if(token == address(0))
        {
            msg.sender.transfer(amount); 
        }else{
            ERC20(token).transfer(msg.sender,amount);  
        } 

        uint256 balance = _balanceOfDex(token);

        emit WithdrawDex(token,msg.sender,amount,beforeBalance,balance);   
    }

      
    function() payable external 
        onlyDEXisSet
    {
        uint256 beforeBalance = _balanceOfDex(address(0));

        IDex(_dex).deposit.value(msg.value); 
        emit DepositDex(address(0), msg.sender, msg.value,beforeBalance,_balanceOfDex(address(0)));  
    } 

      
    function depositToDex(address token,uint256 amount) public  
        onlyDEXisSet
   { 
        uint256 beforeBalance = _balanceOfDex(token);

        require(token != address(0));
        
        require(ERC20(token).transferFrom(msg.sender,address(this),amount)); 

        require(ERC20(token).approve(address(_dex),amount));

        IDex(_dex).depositToken(token,amount); 
 
        uint256 balance = _balanceOfDex(token);

        emit DepositDex(token, msg.sender, amount,beforeBalance,balance); 
    }  

      
    function _balanceOfDex(address token) view internal 
        returns(uint256) 
    { 
        return IDex(_dex).balanceOf(token,address(this));
    }

      
    function _airdrop(address to,address token,uint256 amount) internal 
        returns(uint256) 
    { 
        IDex(_dex).airdrop(to,token,amount);
    }
  
       
    function drops(address token,address[] memory recipients,uint256[] memory amounts) public 
        onlyOwner
        onlyDEXisSet
    { 
        uint256 total = 0;
        for(uint256 i =0; i < recipients.length; i++){ 
           total = total.add(amounts[i]);
        } 

       require(_balanceOfDex(token) >= total);

       for(uint256 i =0; i < recipients.length; i++){  

           _airdrop(recipients[i],token,amounts[i]);
 
           emit Drop(token,msg.sender,recipients[i],amounts[i]);
       } 
    } 

       
    function drop(address token,address recipient,uint256 amount)       public 
        onlyOwner
        onlyDEXisSet 
    {  
        require(_balanceOfDex(token) >= amount);

        _airdrop(recipient,token,amount);  

        emit Drop(token,msg.sender,recipient,amount); 
    }   

       
    function submitWithdrawApplication() public 
        onlyOwner 
    {
        IDex(_dex).submitWithdrawApplication(); 
    } 

       
    function cancelWithdrawApplication() public 
    onlyOwner
    {
        IDex(_dex).cancelWithdrawApplication(); 
    }

        
    function claim(address user,address token,uint256 amount,uint256 nonce,uint expiredTime,address relayer,uint8 v, bytes32 r,bytes32 s) public 
    {
        require(_relayers[relayer] == true);
        require(expiredTime >= block.timestamp);

        bytes32 hash = keccak256(abi.encodePacked(this,user, token, amount, nonce, expiredTime));
        
        if (_claims[hash]) {
            revert("The task have been canceled or executed!");    
        }    

        if (ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s) != relayer) {
            revert("Wrong sign!");
        } 
 
        _claims[hash] = true; 

        _airdrop(user,token,amount); 
 
        emit Claim(user,token,amount,nonce); 
    }

       
    function cancelClaim(address user,address token,uint256 amount,uint256 nonce,uint expiredTime,address relayer,uint8 v, bytes32 r,bytes32 s) public 
    {
        require(_relayers[relayer] == true);
        require(expiredTime >= block.timestamp); 

        bytes32 hash = keccak256(abi.encodePacked(this,user, token, amount, nonce, expiredTime));
        
        if (_claims[hash]) {
            revert("The task have been canceled or executed!");    
        }    

        if (ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s) != relayer) {
            revert("Wrong sign!");
        } 
 
        _claims[hash] = true; 
    }
}